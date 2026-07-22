#!/usr/bin/env python3
"""Audit, import, and verify the I3 Base source pack.

The importer deliberately does not expand the archive tree verbatim. Planning
originals retain their exact names and bytes. Art/draw members are stored once
per SHA-256 while the complete source-path identity remains in CSV manifests.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import subprocess
import sys
import zipfile
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Iterable


EXPECTED_ARCHIVE_SHA256 = (
    "A1035F69C412680016E6FB1C4FB181E77E75A517FDB252D6EBBC76D7F7957E71"
)
PLANNING_PREFIX = "sources/docs/"
ART_PREFIXES = ("sources/art/", "sources/draw/")
EXCLUDED_NESTED_ARCHIVE = "sources/draw/Art.zip"
EXPECTED_PLANNING_COUNT = 25
EXPECTED_ARCHIVE_MEMBER_COUNT = 1626
EXPECTED_ART_MEMBER_COUNT = 1407
EXPECTED_ART_UNIQUE_COUNT = 1012
EXPECTED_ART_ALIAS_COUNT = 395


@dataclass(frozen=True)
class Member:
    path: str
    size: int
    sha256: str
    extension: str
    category: str


def sha256_path(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def resolve_repo_root(explicit: str | None) -> Path:
    command = ["git", "rev-parse", "--show-toplevel"]
    cwd = Path(explicit).resolve() if explicit else Path.cwd()
    result = subprocess.run(
        command, cwd=cwd, check=True, capture_output=True, text=True
    )
    resolved = Path(result.stdout.strip()).resolve()
    if explicit and resolved != cwd:
        raise RuntimeError(
            f"--repo-root must be the active worktree root: {cwd} != {resolved}"
        )
    return resolved


def normalized_member_path(raw: str) -> str:
    path = raw.replace("\\", "/")
    pure = PurePosixPath(path)
    if pure.is_absolute() or ".." in pure.parts:
        raise RuntimeError(f"unsafe archive member path: {raw!r}")
    return pure.as_posix()


def classify(path: str) -> str:
    if path.startswith(PLANNING_PREFIX):
        relative = path[len(PLANNING_PREFIX) :]
        if relative and "/" not in relative:
            return "planning_original"
        return "planning_non_root"
    if path == EXCLUDED_NESTED_ARCHIVE:
        return "nested_duplicate_archive"
    if path.startswith(ART_PREFIXES):
        return "art_source"
    if path.startswith("sources/docs_governance/"):
        return "governance_snapshot"
    return "other"


def source_layer(path: str) -> str:
    relative = path.removeprefix("sources/")
    parts = relative.split("/")
    if len(parts) < 2:
        return "root"
    for token in (
        "00_raw",
        "10_working",
        "20_processed",
        "30_game_ready",
        "03_selected",
        "05_export_runtime_candidates",
        "08_visual_targets",
        "Base",
        "M1",
    ):
        if token in parts:
            return token
    if any(part.startswith("ART-") for part in parts):
        return "stage_output"
    if parts[0] == "draw" and len(parts) == 2:
        return "draw_root"
    return f"{parts[0]}_other"


def canonical_rank(path: str) -> tuple[int, int, str]:
    """Prefer least-derived, human-meaningful members for identity labels."""

    layer = source_layer(path)
    rank = {
        "draw_root": 0,
        "Base": 1,
        "00_raw": 2,
        "M1": 3,
        "10_working": 4,
        "20_processed": 5,
        "30_game_ready": 6,
        "03_selected": 7,
        "05_export_runtime_candidates": 8,
        "08_visual_targets": 9,
        "stage_output": 10,
    }.get(layer, 11)
    return rank, len(path), path.casefold()


def read_members(archive: Path) -> tuple[list[Member], dict[str, bytes]]:
    members: list[Member] = []
    selected_bytes: dict[str, bytes] = {}
    seen_paths: set[str] = set()
    with zipfile.ZipFile(archive, "r") as source:
        for entry in source.infolist():
            path = normalized_member_path(entry.filename)
            if entry.is_dir() or not path:
                continue
            if path in seen_paths:
                raise RuntimeError(f"duplicate archive member name: {path}")
            seen_paths.add(path)
            data = source.read(entry)
            category = classify(path)
            member = Member(
                path=path,
                size=len(data),
                sha256=sha256_bytes(data),
                extension=PurePosixPath(path).suffix.lower(),
                category=category,
            )
            members.append(member)
            if category in {"planning_original", "art_source"}:
                selected_bytes[path] = data
    members.sort(key=lambda item: item.path.casefold())
    return members, selected_bytes


def art_blob_path(base_root: Path, member: Member) -> Path:
    extension = member.extension or ".bin"
    return (
        base_root
        / "美术素材"
        / "blobs"
        / member.sha256[:2].lower()
        / f"{member.sha256.lower()}{extension}"
    )


def planning_destination(base_root: Path, member: Member) -> Path:
    name = member.path[len(PLANNING_PREFIX) :]
    return base_root / "原始策划案" / name


def csv_bytes(fieldnames: list[str], rows: Iterable[dict[str, object]]) -> bytes:
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=fieldnames, lineterminator="\n")
    writer.writeheader()
    for row in rows:
        writer.writerow(row)
    return stream.getvalue().encode("utf-8")


def build_outputs(
    repo_root: Path,
    archive_sha: str,
    members: list[Member],
    selected_bytes: dict[str, bytes],
) -> tuple[dict[Path, bytes], dict[str, object]]:
    base_root = repo_root / "sources" / "base"
    outputs: dict[Path, bytes] = {}
    planning = [m for m in members if m.category == "planning_original"]
    art = [m for m in members if m.category == "art_source"]

    if len(planning) != EXPECTED_PLANNING_COUNT:
        raise RuntimeError(
            f"planning original count drift: {len(planning)} != {EXPECTED_PLANNING_COUNT}"
        )

    planning_rows: list[dict[str, object]] = []
    for member in planning:
        destination = planning_destination(base_root, member)
        outputs[destination] = selected_bytes[member.path]
        planning_rows.append(
            {
                "file_name": destination.name,
                "source_member": member.path,
                "sha256": member.sha256,
                "bytes": member.size,
                "repository_path": destination.relative_to(repo_root).as_posix(),
                "retention_reason": "user-authorized original planning source; exact name and information retained",
                "content_policy": "byte_exact_no_rename_no_reduction",
                "authority": "planning_intent_requires_runtime_conflict_adjudication",
            }
        )

    art_groups: dict[str, list[Member]] = defaultdict(list)
    for member in art:
        art_groups[member.sha256].append(member)

    canonical_by_sha: dict[str, Member] = {}
    for sha, group in art_groups.items():
        canonical = min(group, key=lambda item: canonical_rank(item.path))
        canonical_by_sha[sha] = canonical
        outputs[art_blob_path(base_root, canonical)] = selected_bytes[canonical.path]

    art_rows: list[dict[str, object]] = []
    for member in art:
        canonical = canonical_by_sha[member.sha256]
        group_size = len(art_groups[member.sha256])
        disposition = (
            "canonical_content_object"
            if member.path == canonical.path
            else "alias_exact_duplicate"
        )
        retention_reason = (
            f"unique bytes retained once; {group_size} original paths remain traceable"
            if group_size > 1
            else "only observed art/draw member with this SHA-256"
        )
        art_rows.append(
            {
                "source_member": member.path,
                "sha256": member.sha256,
                "bytes": member.size,
                "extension": member.extension,
                "source_layer": source_layer(member.path),
                "disposition": disposition,
                "canonical_source_member": canonical.path,
                "repository_object": art_blob_path(base_root, canonical)
                .relative_to(repo_root)
                .as_posix(),
                "duplicate_group_size": group_size,
                "retention_reason": retention_reason,
                "authority": "base_source_evidence_only",
                "license_status": "pending_verification",
                "review_status": "pending_review",
                "runtime_admission": "not_admitted",
                "consumer": "none_until_separate_runtime_gate",
            }
        )

    inventory_rows: list[dict[str, object]] = []
    for member in members:
        if member.category == "planning_original":
            disposition = "imported_original_name_and_bytes"
            reason = "authorized original planning baseline"
        elif member.category == "art_source":
            canonical = canonical_by_sha[member.sha256]
            disposition = (
                "imported_canonical_content_object"
                if member.path == canonical.path
                else "registered_exact_duplicate_alias"
            )
            reason = "art/draw baseline deduplicated by SHA-256"
        elif member.category == "nested_duplicate_archive":
            disposition = "excluded_nested_archive"
            reason = "nested Art.zip duplicates members already represented outside the archive"
        elif member.category == "governance_snapshot":
            disposition = "excluded_governance_snapshot"
            reason = "copy-only historical governance snapshot; not an original planning or art source"
        else:
            disposition = "excluded_out_of_scope"
            reason = "not a root planning original or art/draw source member"
        inventory_rows.append(
            {
                "source_member": member.path,
                "sha256": member.sha256,
                "bytes": member.size,
                "extension": member.extension,
                "category": member.category,
                "disposition": disposition,
                "reason": reason,
            }
        )

    manifests = base_root / "manifests"
    outputs[manifests / "ORIGINAL_PLANNING_MANIFEST.csv"] = csv_bytes(
        [
            "file_name",
            "source_member",
            "sha256",
            "bytes",
            "repository_path",
            "retention_reason",
            "content_policy",
            "authority",
        ],
        planning_rows,
    )
    outputs[manifests / "BASE_ART_ALIAS_MANIFEST.csv"] = csv_bytes(
        [
            "source_member",
            "sha256",
            "bytes",
            "extension",
            "source_layer",
            "disposition",
            "canonical_source_member",
            "repository_object",
            "duplicate_group_size",
            "retention_reason",
            "authority",
            "license_status",
            "review_status",
            "runtime_admission",
            "consumer",
        ],
        art_rows,
    )
    outputs[manifests / "SOURCE_ARCHIVE_INVENTORY.csv"] = csv_bytes(
        [
            "source_member",
            "sha256",
            "bytes",
            "extension",
            "category",
            "disposition",
            "reason",
        ],
        inventory_rows,
    )

    selected_art_bytes = sum(member.size for member in art)
    canonical_art_bytes = sum(
        canonical.size for canonical in canonical_by_sha.values()
    )
    summary: dict[str, object] = {
        "schema": "i3_base_import/v1",
        "archive_sha256": archive_sha,
        "archive_member_count": len(members),
        "archive_uncompressed_bytes": sum(member.size for member in members),
        "planning_original_count": len(planning),
        "planning_original_bytes": sum(member.size for member in planning),
        "planning_policy": "exact name and bytes; no information reduction",
        "art_source_member_count": len(art),
        "art_unique_content_count": len(canonical_by_sha),
        "art_exact_duplicate_alias_count": len(art) - len(canonical_by_sha),
        "art_selected_member_bytes": selected_art_bytes,
        "art_canonical_bytes": canonical_art_bytes,
        "art_deduplicated_bytes": selected_art_bytes - canonical_art_bytes,
        "excluded_nested_archive_count": sum(
            member.category == "nested_duplicate_archive" for member in members
        ),
        "excluded_governance_snapshot_count": sum(
            member.category == "governance_snapshot" for member in members
        ),
        "runtime_admission": "none",
    }
    outputs[manifests / "BASE_IMPORT_SUMMARY.json"] = (
        json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    ).encode("utf-8")
    return outputs, summary


def audit_existing_outputs(
    repo_root: Path, outputs: dict[Path, bytes]
) -> tuple[int, int, int, list[str]]:
    missing = 0
    mismatched = 0
    unexpected = 0
    diagnostics: list[str] = []
    for destination, expected in sorted(outputs.items(), key=lambda pair: str(pair[0])):
        if not destination.exists():
            missing += 1
            diagnostics.append(f"MISSING {destination}")
            continue
        actual_sha = sha256_path(destination)
        expected_sha = sha256_bytes(expected)
        if actual_sha != expected_sha:
            mismatched += 1
            diagnostics.append(
                f"MISMATCH {destination} expected={expected_sha} actual={actual_sha}"
            )
    expected_paths = {path.resolve() for path in outputs}
    base_root = repo_root / "sources" / "base"
    for generated_root in (
        base_root / "原始策划案",
        base_root / "美术素材" / "blobs",
        base_root / "manifests",
    ):
        if not generated_root.exists():
            continue
        for actual in generated_root.rglob("*"):
            if actual.is_file() and actual.resolve() not in expected_paths:
                unexpected += 1
                diagnostics.append(f"UNEXPECTED {actual}")
    return missing, mismatched, unexpected, diagnostics


def write_outputs(outputs: dict[Path, bytes]) -> None:
    for destination, data in sorted(outputs.items(), key=lambda pair: str(pair[0])):
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists() and destination.read_bytes() == data:
            continue
        destination.write_bytes(data)


def read_csv_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as stream:
        return list(csv.DictReader(stream))


def verify_committed_base(repo_root: Path) -> list[str]:
    base_root = repo_root / "sources" / "base"
    manifest_root = base_root / "manifests"
    diagnostics: list[str] = []

    summary_path = manifest_root / "BASE_IMPORT_SUMMARY.json"
    planning_path = manifest_root / "ORIGINAL_PLANNING_MANIFEST.csv"
    art_path = manifest_root / "BASE_ART_ALIAS_MANIFEST.csv"
    inventory_path = manifest_root / "SOURCE_ARCHIVE_INVENTORY.csv"
    required_manifests = (summary_path, planning_path, art_path, inventory_path)
    for path in required_manifests:
        if not path.is_file():
            diagnostics.append(f"MISSING_MANIFEST {path}")
    if diagnostics:
        return diagnostics

    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    expected_summary = {
        "schema": "i3_base_import/v1",
        "archive_sha256": EXPECTED_ARCHIVE_SHA256,
        "archive_member_count": EXPECTED_ARCHIVE_MEMBER_COUNT,
        "planning_original_count": EXPECTED_PLANNING_COUNT,
        "art_source_member_count": EXPECTED_ART_MEMBER_COUNT,
        "art_unique_content_count": EXPECTED_ART_UNIQUE_COUNT,
        "art_exact_duplicate_alias_count": EXPECTED_ART_ALIAS_COUNT,
        "runtime_admission": "none",
    }
    for key, expected in expected_summary.items():
        if summary.get(key) != expected:
            diagnostics.append(
                f"SUMMARY_DRIFT key={key} expected={expected!r} actual={summary.get(key)!r}"
            )

    planning_rows = read_csv_rows(planning_path)
    if len(planning_rows) != EXPECTED_PLANNING_COUNT:
        diagnostics.append(
            f"PLANNING_COUNT expected={EXPECTED_PLANNING_COUNT} actual={len(planning_rows)}"
        )
    seen_planning_names: set[str] = set()
    expected_generated: set[Path] = {path.resolve() for path in required_manifests}
    for row in planning_rows:
        file_name = row.get("file_name", "")
        source_member = row.get("source_member", "")
        repository_path = row.get("repository_path", "")
        if not file_name or PurePosixPath(source_member).name != file_name:
            diagnostics.append(
                f"PLANNING_NAME_DRIFT source={source_member!r} file={file_name!r}"
            )
            continue
        if file_name in seen_planning_names:
            diagnostics.append(f"PLANNING_DUPLICATE_NAME {file_name}")
        seen_planning_names.add(file_name)
        expected_repository_path = (
            PurePosixPath("sources") / "base" / "原始策划案" / file_name
        ).as_posix()
        if repository_path != expected_repository_path:
            diagnostics.append(
                f"PLANNING_PATH_DRIFT file={file_name} path={repository_path!r}"
            )
        destination = (repo_root / PurePosixPath(repository_path)).resolve()
        expected_generated.add(destination)
        if not destination.is_file():
            diagnostics.append(f"PLANNING_MISSING {destination}")
            continue
        expected_sha = row.get("sha256", "").upper()
        actual_sha = sha256_path(destination)
        if actual_sha != expected_sha:
            diagnostics.append(
                f"PLANNING_HASH file={file_name} expected={expected_sha} actual={actual_sha}"
            )
        if destination.stat().st_size != int(row.get("bytes", "-1")):
            diagnostics.append(f"PLANNING_SIZE file={file_name}")
        if row.get("content_policy") != "byte_exact_no_rename_no_reduction":
            diagnostics.append(f"PLANNING_POLICY file={file_name}")

    art_rows = read_csv_rows(art_path)
    if len(art_rows) != EXPECTED_ART_MEMBER_COUNT:
        diagnostics.append(
            f"ART_MEMBER_COUNT expected={EXPECTED_ART_MEMBER_COUNT} actual={len(art_rows)}"
        )
    art_groups: dict[str, list[dict[str, str]]] = defaultdict(list)
    seen_art_members: set[str] = set()
    for row in art_rows:
        member = row.get("source_member", "")
        sha = row.get("sha256", "").upper()
        if member in seen_art_members:
            diagnostics.append(f"ART_DUPLICATE_MEMBER {member}")
        seen_art_members.add(member)
        art_groups[sha].append(row)
        if row.get("authority") != "base_source_evidence_only":
            diagnostics.append(f"ART_AUTHORITY member={member}")
        if row.get("runtime_admission") != "not_admitted":
            diagnostics.append(f"ART_RUNTIME_ADMISSION member={member}")
        if row.get("license_status") != "pending_verification":
            diagnostics.append(f"ART_LICENSE member={member}")
        if row.get("review_status") != "pending_review":
            diagnostics.append(f"ART_REVIEW member={member}")

    if len(art_groups) != EXPECTED_ART_UNIQUE_COUNT:
        diagnostics.append(
            f"ART_UNIQUE_COUNT expected={EXPECTED_ART_UNIQUE_COUNT} actual={len(art_groups)}"
        )
    alias_count = 0
    for sha, group in art_groups.items():
        canonical_rows = [
            row
            for row in group
            if row.get("disposition") == "canonical_content_object"
        ]
        aliases = [
            row for row in group if row.get("disposition") == "alias_exact_duplicate"
        ]
        alias_count += len(aliases)
        if len(canonical_rows) != 1:
            diagnostics.append(
                f"ART_CANONICAL_COUNT sha={sha} actual={len(canonical_rows)}"
            )
            continue
        canonical = canonical_rows[0]
        canonical_member = canonical.get("source_member", "")
        repository_object = canonical.get("repository_object", "")
        if canonical.get("canonical_source_member") != canonical_member:
            diagnostics.append(f"ART_CANONICAL_ID sha={sha}")
        if any(
            row.get("canonical_source_member") != canonical_member
            or row.get("repository_object") != repository_object
            or int(row.get("duplicate_group_size", "0")) != len(group)
            for row in group
        ):
            diagnostics.append(f"ART_GROUP_MAPPING sha={sha}")
        destination = (repo_root / PurePosixPath(repository_object)).resolve()
        expected_prefix = (base_root / "美术素材" / "blobs").resolve()
        if expected_prefix not in destination.parents:
            diagnostics.append(f"ART_OBJECT_OUTSIDE_BASE sha={sha} path={destination}")
            continue
        expected_generated.add(destination)
        if not destination.is_file():
            diagnostics.append(f"ART_OBJECT_MISSING sha={sha} path={destination}")
            continue
        actual_sha = sha256_path(destination)
        if actual_sha != sha:
            diagnostics.append(
                f"ART_OBJECT_HASH expected={sha} actual={actual_sha} path={destination}"
            )
        if destination.stat().st_size != int(canonical.get("bytes", "-1")):
            diagnostics.append(f"ART_OBJECT_SIZE sha={sha}")
    if alias_count != EXPECTED_ART_ALIAS_COUNT:
        diagnostics.append(
            f"ART_ALIAS_COUNT expected={EXPECTED_ART_ALIAS_COUNT} actual={alias_count}"
        )

    inventory_rows = read_csv_rows(inventory_path)
    if len(inventory_rows) != EXPECTED_ARCHIVE_MEMBER_COUNT:
        diagnostics.append(
            f"INVENTORY_COUNT expected={EXPECTED_ARCHIVE_MEMBER_COUNT} actual={len(inventory_rows)}"
        )
    if len({row.get("source_member", "") for row in inventory_rows}) != len(
        inventory_rows
    ):
        diagnostics.append("INVENTORY_DUPLICATE_MEMBER")
    if sum(
        row.get("category") == "nested_duplicate_archive"
        for row in inventory_rows
    ) != 1:
        diagnostics.append("INVENTORY_NESTED_ARCHIVE_COUNT")
    if sum(
        row.get("category") == "governance_snapshot" for row in inventory_rows
    ) != int(summary.get("excluded_governance_snapshot_count", -1)):
        diagnostics.append("INVENTORY_GOVERNANCE_COUNT")

    for generated_root in (
        base_root / "原始策划案",
        base_root / "美术素材" / "blobs",
        manifest_root,
    ):
        if not generated_root.exists():
            diagnostics.append(f"GENERATED_ROOT_MISSING {generated_root}")
            continue
        for actual in generated_root.rglob("*"):
            if actual.is_file() and actual.resolve() not in expected_generated:
                diagnostics.append(f"UNEXPECTED {actual}")
    return diagnostics


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive")
    parser.add_argument("--repo-root")
    parser.add_argument(
        "--mode",
        choices=("audit", "import", "verify", "committed"),
        default="audit",
    )
    args = parser.parse_args()

    repo_root = resolve_repo_root(args.repo_root)
    if args.mode == "committed":
        diagnostics = verify_committed_base(repo_root)
        if diagnostics:
            for diagnostic in diagnostics[:100]:
                print(diagnostic, file=sys.stderr)
            print(
                f"I3_BASE_COMMITTED_VERIFY=FAIL failures={len(diagnostics)}",
                file=sys.stderr,
            )
            return 4
        print(
            "I3_BASE_COMMITTED_VERIFY=PASS "
            f"planning={EXPECTED_PLANNING_COUNT} "
            f"art_members={EXPECTED_ART_MEMBER_COUNT} "
            f"art_unique={EXPECTED_ART_UNIQUE_COUNT} "
            f"aliases={EXPECTED_ART_ALIAS_COUNT}"
        )
        return 0
    if not args.archive:
        parser.error("--archive is required for audit, import, and verify modes")
    archive = Path(args.archive).resolve()
    if not archive.is_file():
        raise FileNotFoundError(archive)
    archive_sha = sha256_path(archive)
    if archive_sha != EXPECTED_ARCHIVE_SHA256:
        raise RuntimeError(
            f"archive identity mismatch: {archive_sha} != {EXPECTED_ARCHIVE_SHA256}"
        )

    members, selected_bytes = read_members(archive)
    outputs, summary = build_outputs(
        repo_root, archive_sha, members, selected_bytes
    )
    missing, mismatched, unexpected, diagnostics = audit_existing_outputs(
        repo_root, outputs
    )

    if args.mode == "audit":
        print(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True))
        print(
            "I3_BASE_IMPORT_AUDIT=PASS "
            f"planned_files={len(outputs)} missing={missing} "
            f"mismatched={mismatched} unexpected={unexpected}"
        )
        return 0

    if args.mode == "import":
        if mismatched:
            print("Refusing to overwrite mismatched Base outputs:", file=sys.stderr)
            for diagnostic in diagnostics[:20]:
                if diagnostic.startswith("MISMATCH"):
                    print(diagnostic, file=sys.stderr)
            return 2
        write_outputs(outputs)
        missing, mismatched, unexpected, diagnostics = audit_existing_outputs(
            repo_root, outputs
        )

    if missing or mismatched or unexpected:
        for diagnostic in diagnostics[:50]:
            print(diagnostic, file=sys.stderr)
        print(
            "I3_BASE_IMPORT_VERIFY=FAIL "
            f"missing={missing} mismatched={mismatched} unexpected={unexpected}",
            file=sys.stderr,
        )
        return 3

    print(
        "I3_BASE_IMPORT_VERIFY=PASS "
        f"files={len(outputs)} planning={summary['planning_original_count']} "
        f"art_members={summary['art_source_member_count']} "
        f"art_unique={summary['art_unique_content_count']} "
        f"aliases={summary['art_exact_duplicate_alias_count']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
