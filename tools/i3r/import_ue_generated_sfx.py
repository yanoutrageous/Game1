#!/usr/bin/env python3
"""Import the project's programmatically generated UE prototype SFX.

The UE repository is not runtime authority.  This narrow gate only accepts the
nine files bound by ``I3R_UE_GENERATED_SFX_IMPORT_REGISTRY.csv``.  For every
file it verifies:

* the historical UE commit and Git LFS pointer;
* the hydrated source bytes and size;
* the declared internal-generated origin and admission decision;
* the destination bytes after copying.

No BGM or unregistered audio can pass this gate.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import re
import shutil
import subprocess
import sys
from pathlib import Path, PurePosixPath


REGISTRY = "docs/00_governance/I3R_UE_GENERATED_SFX_IMPORT_REGISTRY.csv"
ASSET_MANIFEST = "Godot/GraytailGodot/data/assets/asset_manifest.csv"
GODOT_PROJECT_PREFIX = PurePosixPath("Godot/GraytailGodot")
EXPECTED_ORIGIN = "project_programmatic_synthesis"
EXPECTED_RIGHTS = "internal_generated_no_external_material"
EXPECTED_ADMISSION = "approved_for_i3r_import"
LFS_POINTER = re.compile(
    r"\Aversion https://git-lfs\.github\.com/spec/v1\r?\n"
    r"oid sha256:([0-9a-f]{64})\r?\n"
    r"size ([0-9]+)\r?\n?\Z"
)


def run_git(repo: Path, *arguments: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), *arguments],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def resolve_active_repo(explicit: str | None) -> Path:
    cwd = Path(explicit).resolve() if explicit else Path.cwd()
    root = Path(run_git(cwd, "rev-parse", "--show-toplevel")).resolve()
    if explicit and root != cwd:
        raise RuntimeError(f"--repo-root is not the active worktree: {cwd} != {root}")
    return root


def resolve_ue_repo(explicit: str) -> Path:
    requested = Path(explicit).resolve()
    root = Path(run_git(requested, "rev-parse", "--show-toplevel")).resolve()
    if root != requested:
        raise RuntimeError(f"--ue-root must be the UE Git root: {requested} != {root}")
    return root


def safe_relative(value: str, label: str) -> PurePosixPath:
    result = PurePosixPath(value)
    if result.is_absolute() or not result.parts or ".." in result.parts:
        raise RuntimeError(f"unsafe {label}: {value!r}")
    return result


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def read_registry(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as stream:
        rows = list(csv.DictReader(stream))
    if len(rows) != 9:
        raise RuntimeError(f"SFX registry must contain exactly 9 rows, found {len(rows)}")
    return rows


def verify_asset_manifest(
    repo_root: Path,
    registry_rows: list[dict[str, str]],
) -> list[str]:
    manifest_path = repo_root / ASSET_MANIFEST
    if not manifest_path.is_file():
        return ["ASSET_MANIFEST_MISSING"]
    with manifest_path.open("r", encoding="utf-8", newline="") as stream:
        manifest_rows = list(csv.DictReader(stream))
    registered = {
        row.get("asset_id", ""): row
        for row in manifest_rows
        if row.get("asset_id", "").startswith("audio.sfx.")
    }
    diagnostics: list[str] = []
    if len(registered) != 9:
        diagnostics.append(f"ASSET_MANIFEST_SFX_COUNT expected=9 actual={len(registered)}")
    for registry_row in registry_rows:
        asset_id = registry_row.get("asset_id", "")
        manifest_row = registered.get(asset_id)
        if manifest_row is None:
            diagnostics.append(f"ASSET_MANIFEST_ID id={asset_id}")
            continue
        runtime_relative = safe_relative(
            registry_row.get("runtime_path", ""), "runtime_path"
        )
        try:
            project_relative = runtime_relative.relative_to(GODOT_PROJECT_PREFIX)
        except ValueError:
            diagnostics.append(f"ASSET_MANIFEST_RUNTIME_PREFIX id={asset_id}")
            continue
        expected_godot_path = f"res://{project_relative.as_posix()}"
        if manifest_row.get("godot_path") != expected_godot_path:
            diagnostics.append(f"ASSET_MANIFEST_GODOT_PATH id={asset_id}")
        if manifest_row.get("type") != "audio":
            diagnostics.append(f"ASSET_MANIFEST_TYPE id={asset_id}")
        if manifest_row.get("license_status") != EXPECTED_RIGHTS:
            diagnostics.append(f"ASSET_MANIFEST_RIGHTS id={asset_id}")
        if (
            manifest_row.get("linked_scene")
            != "scripts/presentation/player_feedback_service.gd"
        ):
            diagnostics.append(f"ASSET_MANIFEST_CONSUMER id={asset_id}")
        if manifest_row.get("theme_key") != asset_id:
            diagnostics.append(f"ASSET_MANIFEST_RUNTIME_KEY id={asset_id}")
        if manifest_row.get("source_status") != "i3r_ue_generated_sfx_imported":
            diagnostics.append(f"ASSET_MANIFEST_STATUS id={asset_id}")
    return diagnostics


def verify_row(
    repo_root: Path,
    ue_root: Path | None,
    row: dict[str, str],
    copy: bool,
) -> list[str]:
    diagnostics: list[str] = []
    asset_id = row.get("asset_id", "")
    commit = row.get("source_commit", "")
    source_relative = safe_relative(row.get("source_path", ""), "source_path")
    runtime_relative = safe_relative(row.get("runtime_path", ""), "runtime_path")
    expected_sha = row.get("source_sha256", "").upper()
    expected_bytes = int(row.get("source_bytes", "-1"))

    if row.get("source_origin") != EXPECTED_ORIGIN:
        diagnostics.append(f"SOURCE_ORIGIN id={asset_id}")
    if row.get("rights_status") != EXPECTED_RIGHTS:
        diagnostics.append(f"RIGHTS_STATUS id={asset_id}")
    if row.get("admission_status") != EXPECTED_ADMISSION:
        diagnostics.append(f"ADMISSION_STATUS id={asset_id}")
    if row.get("runtime_key") != asset_id:
        diagnostics.append(f"RUNTIME_KEY id={asset_id}")

    destination = repo_root / runtime_relative
    source: Path | None = None
    if ue_root is not None:
        try:
            pointer_text = run_git(
                ue_root, "show", f"{commit}:{source_relative.as_posix()}"
            )
        except subprocess.CalledProcessError:
            diagnostics.append(f"SOURCE_COMMIT_PATH id={asset_id}")
            return diagnostics
        pointer_match = LFS_POINTER.fullmatch(pointer_text + "\n")
        if pointer_match is None:
            diagnostics.append(f"SOURCE_LFS_POINTER id={asset_id}")
        else:
            pointer_sha = pointer_match.group(1).upper()
            pointer_bytes = int(pointer_match.group(2))
            if pointer_sha != expected_sha:
                diagnostics.append(f"SOURCE_LFS_SHA id={asset_id}")
            if pointer_bytes != expected_bytes:
                diagnostics.append(f"SOURCE_LFS_SIZE id={asset_id}")

        source = ue_root / source_relative
        if not source.is_file():
            diagnostics.append(f"SOURCE_MISSING id={asset_id}")
            return diagnostics
        if source.stat().st_size != expected_bytes:
            diagnostics.append(f"SOURCE_SIZE id={asset_id}")
        if sha256(source) != expected_sha:
            diagnostics.append(f"SOURCE_SHA id={asset_id}")
    if diagnostics:
        return diagnostics

    if copy:
        if source is None:
            diagnostics.append(f"SOURCE_REQUIRED_FOR_WRITE id={asset_id}")
            return diagnostics
        destination.parent.mkdir(parents=True, exist_ok=True)
        if not destination.is_file() or sha256(destination) != expected_sha:
            shutil.copyfile(source, destination)
    if not destination.is_file():
        diagnostics.append(f"RUNTIME_MISSING id={asset_id}")
    else:
        if destination.stat().st_size != expected_bytes:
            diagnostics.append(f"RUNTIME_SIZE id={asset_id}")
        if sha256(destination) != expected_sha:
            diagnostics.append(f"RUNTIME_SHA id={asset_id}")
    return diagnostics


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root")
    parser.add_argument("--ue-root")
    parser.add_argument("--mode", choices=("write", "verify"), default="verify")
    args = parser.parse_args()

    repo_root = resolve_active_repo(args.repo_root)
    if args.mode == "write" and not args.ue_root:
        parser.error("--ue-root is required in write mode")
    ue_root = resolve_ue_repo(args.ue_root) if args.ue_root else None
    rows = read_registry(repo_root / REGISTRY)
    seen_ids: set[str] = set()
    seen_runtime_paths: set[str] = set()
    diagnostics: list[str] = []
    for row in rows:
        asset_id = row.get("asset_id", "")
        runtime_path = row.get("runtime_path", "")
        if not asset_id or asset_id in seen_ids:
            diagnostics.append(f"ASSET_ID_DUPLICATE_OR_EMPTY {asset_id!r}")
            continue
        if not runtime_path or runtime_path in seen_runtime_paths:
            diagnostics.append(
                f"RUNTIME_PATH_DUPLICATE_OR_EMPTY id={asset_id} path={runtime_path!r}"
            )
            continue
        seen_ids.add(asset_id)
        seen_runtime_paths.add(runtime_path)
        diagnostics.extend(
            verify_row(
                repo_root,
                ue_root,
                row,
                copy=args.mode == "write",
            )
        )
    diagnostics.extend(verify_asset_manifest(repo_root, rows))

    if diagnostics:
        for diagnostic in diagnostics:
            print(diagnostic, file=sys.stderr)
        print(
            f"I3R_UE_GENERATED_SFX_IMPORT=FAIL failures={len(diagnostics)}",
            file=sys.stderr,
        )
        return 1
    commit = rows[0]["source_commit"]
    print(
        "I3R_UE_GENERATED_SFX_IMPORT=PASS "
        f"mode={args.mode} files={len(rows)} manifest={len(rows)} source_commit={commit} "
        f"source_gate={'full' if ue_root is not None else 'registry_runtime_only'}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
