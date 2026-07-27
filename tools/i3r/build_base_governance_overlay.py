#!/usr/bin/env python3
"""Build and verify the I3R semantic Base and runtime crosswalk overlays.

I3 keeps source bytes immutable.  This tool adds the missing decision layer
without changing any planning original or content-addressed Base object:

* one semantic row for every unique Base art/draw object;
* one crosswalk row for every exact Base/runtime SHA match;
* strict validation of the explicit runtime-promotion registry.

The generated CSV files live in ``docs/00_governance`` because
``sources/base`` is the immutable I3 import result.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict
from functools import lru_cache
from pathlib import Path, PurePosixPath
from typing import Iterable


SEMANTIC_OUTPUT = "docs/00_governance/I3R_BASE_SEMANTIC_OBJECT_REGISTRY.csv"
RUNTIME_OUTPUT = "docs/00_governance/I3R_BASE_RUNTIME_CROSSWALK.csv"
ALIAS_DEBT_OUTPUT = "docs/00_governance/I3R_BASE_RUNTIME_ALIAS_DEBT.csv"
BASE_MANIFEST = "sources/base/manifests/BASE_ART_ALIAS_MANIFEST.csv"
RUNTIME_MANIFEST = "Godot/GraytailGodot/data/assets/asset_manifest.csv"
PROMOTION_REGISTRY = "docs/00_governance/I3_RUNTIME_ASSET_PROMOTION_REGISTRY.csv"
VISUAL_REVIEW_REGISTRY = (
    "docs/00_governance/I3R_BASE_VISUAL_REVIEW_REGISTRY.csv"
)
PROJECT_ROOT = "Godot/GraytailGodot"

VISUAL_REVIEW_DECISIONS = {
    "visual_reviewed_existing_runtime",
    "visual_reviewed_staging_reference",
    "visual_reviewed_restricted_baked_text",
    "visual_reviewed_restricted_input_glyph",
    "visual_reviewed_semantic_mismatch",
}

SEMANTIC_FIELDS = [
    "object_sha256",
    "repository_object",
    "extension",
    "media_kind",
    "semantic_family",
    "lifecycle_role",
    "canonical_source_member",
    "alias_count",
    "source_layers",
    "distinct_names",
    "same_name_other_sha_count",
    "runtime_match_count",
    "runtime_paths",
    "base_authority",
    "rights_status",
    "review_status",
    "runtime_admission",
    "semantic_decision",
    "decision_note",
]

RUNTIME_FIELDS = [
    "asset_id",
    "runtime_path",
    "runtime_sha256",
    "base_object",
    "base_source_member",
    "base_alias_count",
    "manifest_source",
    "manifest_license_status",
    "manifest_source_status",
    "runtime_key",
    "declared_consumer",
    "declared_consumer_resolution",
    "consumer_binding_kind",
    "consumer_evidence",
    "promotion_id",
    "promotion_validation_evidence",
    "runtime_alias_group",
    "runtime_alias_decision",
    "crosswalk_decision",
    "decision_note",
]

ALIAS_DEBT_FIELDS = [
    "runtime_path",
    "runtime_sha256",
    "alias_asset_ids",
    "semantic_states",
    "debt_asset_ids",
    "manifest_replacement_flags",
    "debt_decision",
    "semantic_closure",
    "required_resolution",
]

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".svg"}
TABLE_EXTENSIONS = {".csv", ".tsv", ".ods", ".xlsx"}
DOCUMENT_EXTENSIONS = {".md", ".txt", ".html", ".htm", ".pdf"}
VIDEO_EXTENSIONS = {".mp4", ".webm", ".mov", ".avi"}

RUNTIME_TEXT_SUFFIXES = {".gd", ".tscn", ".tres", ".cfg", ".json"}
FINAL_CONSUMER_SUFFIXES = {".gd", ".tscn", ".tres"}
CONTRACT_NAME_MARKERS = (
    "_asset_contract.gd",
    "_mapping.gd",
    "manifest_asset_mapping.gd",
    "placement_contract.gd",
)
NON_PRODUCTION_PATH_MARKERS = (
    "/tests/",
    "/test/",
    "/tools/",
    "/addons/",
    "/localization/",
)
NON_PRODUCTION_NAME_MARKERS = (
    "_preview.",
    "_gallery.",
    "_runner.",
)


def resolve_repo_root(explicit: str | None) -> Path:
    cwd = Path(explicit).resolve() if explicit else Path.cwd()
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=cwd,
        check=True,
        capture_output=True,
        text=True,
    )
    root = Path(result.stdout.strip()).resolve()
    if explicit and root != cwd:
        raise RuntimeError(f"--repo-root is not the active worktree: {cwd} != {root}")
    return root


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as stream:
        return list(csv.DictReader(stream))


def csv_bytes(fields: list[str], rows: Iterable[dict[str, object]]) -> bytes:
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
    writer.writeheader()
    for row in rows:
        writer.writerow(row)
    return stream.getvalue().encode("utf-8")


def sha256_path(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def runtime_file(repo_root: Path, godot_path: str) -> Path:
    if not godot_path.startswith("res://"):
        raise RuntimeError(f"runtime path is not res:// relative: {godot_path}")
    relative = PurePosixPath(godot_path.removeprefix("res://"))
    if relative.is_absolute() or ".." in relative.parts:
        raise RuntimeError(f"unsafe runtime path: {godot_path}")
    return repo_root / PROJECT_ROOT / relative


def media_kind(extension: str) -> str:
    if extension in IMAGE_EXTENSIONS:
        return "image"
    if extension in TABLE_EXTENSIONS:
        return "table"
    if extension == ".json":
        return "metadata"
    if extension in DOCUMENT_EXTENSIONS:
        return "document"
    if extension in VIDEO_EXTENSIONS:
        return "video"
    if extension in {".zip", ".7z", ".rar"}:
        return "archive"
    return "other"


def lifecycle_role(rows: list[dict[str, str]]) -> str:
    """Describe source maturity independently from visual semantics."""
    layer_roles = {
        "00_raw": "raw_source",
        "03_selected": "selected_source",
        "05_export_runtime_candidates": "runtime_candidate",
        "08_visual_targets": "visual_target",
        "10_working": "working_candidate",
        "20_processed": "processed_source",
        "30_game_ready": "game_ready_source",
        "stage_output": "stage_evidence",
        "M1": "prototype_reference",
        "Base": "packaged_base_input",
        "art_other": "source_reference",
        "draw_other": "source_reference",
        "draw_root": "source_reference",
    }
    roles = {
        layer_roles.get(row.get("source_layer", ""), "source_reference")
        for row in rows
    }
    return ";".join(sorted(roles))


def semantic_family(paths: list[str], extension: str) -> str:
    """Classify subject matter without reading lifecycle folder names as motion."""
    tail_parts: list[str] = []
    for value in paths:
        tail_parts.extend(PurePosixPath(value.lower()).parts[-3:])
    joined = " ".join(tail_parts)
    if media_kind(extension) != "image":
        return {
            "table": "source_registry",
            "metadata": "source_metadata",
            "document": "source_documentation",
            "video": "motion_reference",
            "archive": "nested_source_archive",
        }.get(media_kind(extension), "source_support")
    if any(token in joined for token in ("debug_", "detected_boxes")):
        return "debug_artifact"
    if any(token in joined for token in ("屏幕截图", "screenshot", "capture")):
        return "reference_capture"
    if "npc_portrait" in joined:
        return "actor_portrait"
    subject_families = [
        (("visual_target", "ui_demo"), "reference_capture"),
        (("main_menu", "zhucaidan"), "main_menu"),
        (("deploy", "chufa"), "deploy"),
        (("minimap", "map_icon", "map_cell", "map_tile", "ditu"), "map"),
        (("item", "inventory", "warehouse", "daoju"), "item"),
        (("prop", "baoxiang", "chest", "cheli", "shangren"), "world_prop"),
        (("room", "fangjian"), "room"),
        (
            ("ui_button", "key_bar_button", "ui_panel", "ui_frame", "tooltip"),
            "ui_component",
        ),
    ]
    for needles, family in subject_families:
        if any(token in joined for token in needles):
            return family
    if any(
        re.search(
            rf"(^|[/_. -]){re.escape(token.strip('_'))}($|[/_. -])",
            joined,
        )
        for token in (
            "_idle",
            "_walk",
            "_run",
            "_attack",
            "_hurt",
            "_defeated",
            "_back_",
            "_front_",
            "_left_",
            "_right_",
            "tuzigai",
            "huanxionggai",
            "maogai",
            "huligai",
            "角色",
        )
    ):
        return "actor_animation_source"
    if any(
        token in joined for token in ("zuhe", "zujian", "1.png", "2.png", "3.png", "4.png", "5.png", "6.png", "2ui.png")
    ):
        return "source_composite"
    if any(
        token in joined
        for token in ("/icons/", "_icon", "number_", "shuzi_", "图标")
    ):
        return "iconography"
    tokens = [
        (("visual_target", "ui_demo"), "reference_capture"),
        (("main_menu", "zhucaidan", "主菜单"), "main_menu"),
        (("deploy", "chufa", "出发"), "deploy"),
        (("minimap", "map_icon", "map_cell", "map_tile", "ditu", "地图"), "map"),
        (("item", "inventory", "warehouse", "daoju", "物品"), "item"),
        (("prop", "baoxiang", "chest", "cheli", "shangren"), "world_prop"),
        (("room", "fangjian", "房间"), "room"),
        (("monster", "actor", "character", "player", "juese"), "actor"),
        (("fx", "effect", "burst", "pulse"), "effect"),
        (
            (
                "button",
                "panel",
                "frame",
                "tab",
                "tooltip",
                "ui_",
                "mianban",
                "kuang",
                "anniu",
                "tishi",
                "kuaijie",
                "xuetiao",
                "xieyi",
                "jiemian",
            ),
            "ui_component",
        ),
    ]
    for needles, family in tokens:
        if any(token in joined for token in needles):
            return family
    return "uncategorized_image"


def normalize_repo_path(value: str) -> str:
    return value.replace("\\", "/").lstrip("./")


def promotion_by_runtime_path(
    rows: list[dict[str, str]],
) -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    for row in rows:
        runtime_path = normalize_repo_path(row.get("runtime_path", ""))
        if not runtime_path:
            continue
        if runtime_path in result:
            raise RuntimeError(f"duplicate promotion runtime path: {runtime_path}")
        result[runtime_path] = row
    return result


def visual_review_by_asset_id(
    rows: list[dict[str, str]],
) -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    for row in rows:
        asset_id = row.get("asset_id", "").strip()
        if not asset_id:
            raise RuntimeError("visual review registry contains an empty asset_id")
        if asset_id in result:
            raise RuntimeError(f"duplicate visual review asset_id: {asset_id}")
        result[asset_id] = row
    return result


def load_runtime_text_index(project_root: Path) -> dict[Path, str]:
    index: dict[Path, str] = {}
    for directory, names, filenames in os.walk(project_root):
        names[:] = sorted(name for name in names if name != ".godot")
        base = Path(directory)
        for filename in sorted(filenames):
            path = base / filename
            if path.suffix.lower() not in RUNTIME_TEXT_SUFFIXES:
                continue
            try:
                index[path.resolve()] = path.read_text(
                    encoding="utf-8", errors="ignore"
                )
            except OSError:
                continue
    return index


def _project_relative(project_root: Path, path: Path) -> str:
    return normalize_repo_path(path.relative_to(project_root).as_posix())


def _repo_relative(repo_root: Path, path: Path) -> str:
    return normalize_repo_path(path.relative_to(repo_root).as_posix())


@lru_cache(maxsize=None)
def _is_non_production(project_root: Path, path: Path) -> bool:
    relative = f"/{_project_relative(project_root, path).lower()}"
    name = path.name.lower()
    return any(marker in relative for marker in NON_PRODUCTION_PATH_MARKERS) or any(
        marker in name for marker in NON_PRODUCTION_NAME_MARKERS
    )


@lru_cache(maxsize=None)
def _is_contract_source(project_root: Path, path: Path) -> bool:
    if _is_non_production(project_root, path) or path.suffix.lower() != ".gd":
        return False
    name = path.name.lower()
    return any(marker in name for marker in CONTRACT_NAME_MARKERS)


@lru_cache(maxsize=None)
def _is_final_consumer(project_root: Path, path: Path) -> bool:
    return (
        path.suffix.lower() in FINAL_CONSUMER_SUFFIXES
        and not _is_non_production(project_root, path)
        and not _is_contract_source(project_root, path)
    )


def split_declared_consumers(value: str) -> list[str]:
    """The manifest contract uses semicolons for multiple independent consumers."""
    return [entry.strip() for entry in value.split(";") if entry.strip()]


def _resolve_declared_entry(
    repo_root: Path,
    project_root: Path,
    source_index: dict[Path, str],
    entry: str,
) -> list[Path]:
    normalized = normalize_repo_path(entry)
    candidates: set[Path] = set()
    if normalized.startswith("res://"):
        candidates.add(runtime_file(repo_root, normalized).resolve())
    else:
        candidates.add((project_root / PurePosixPath(normalized)).resolve())
        candidates.add((repo_root / PurePosixPath(normalized)).resolve())
        declared_name = PurePosixPath(normalized).name.casefold()
        if declared_name:
            candidates.update(
                path for path in source_index if path.name.casefold() == declared_name
            )
        if "/" not in normalized and "." not in normalized:
            class_pattern = re.compile(
                rf"^\s*class_name\s+{re.escape(normalized)}\s*$"
            )
            candidates.update(
                path
                for path, text in source_index.items()
                if any(
                    class_pattern.search(line)
                    for line in text.splitlines()
                )
            )
    return sorted(path for path in candidates if path in source_index)


def declared_consumer_resolution(
    repo_root: Path,
    project_root: Path,
    source_index: dict[Path, str],
    declared_value: str,
) -> tuple[list[Path], str]:
    resolved: list[Path] = []
    descriptions: list[str] = []
    for entry in split_declared_consumers(declared_value):
        paths = _resolve_declared_entry(
            repo_root, project_root, source_index, entry
        )
        resolved.extend(paths)
        if not paths:
            descriptions.append(f"{entry}=>unresolved")
            continue
        path_descriptions: list[str] = []
        for path in paths:
            if _is_contract_source(project_root, path):
                role = "contract"
            elif _is_final_consumer(project_root, path):
                role = "production"
            else:
                role = "excluded"
            path_descriptions.append(f"{_repo_relative(repo_root, path)}[{role}]")
        descriptions.append(f"{entry}=>{'|'.join(path_descriptions)}")
    unique_paths = sorted(set(resolved))
    return unique_paths, ";".join(descriptions)


def _runtime_tokens(runtime_row: dict[str, str]) -> list[tuple[str, str]]:
    tokens: list[tuple[str, str]] = []
    for label, field in (
        ("asset_id", "asset_id"),
        ("godot_path", "godot_path"),
        ("runtime_key", "theme_key"),
    ):
        value = runtime_row.get(field, "").strip()
        if value and value not in {token for _, token in tokens}:
            tokens.append((label, value))
    return tokens


def _find_token(
    paths: Iterable[Path],
    source_index: dict[Path, str],
    tokens: list[tuple[str, str]],
) -> tuple[Path, int, str, str] | None:
    for path in sorted(set(paths)):
        text = source_index.get(path, "")
        for label, token in tokens:
            search_from = 0
            while True:
                offset = text.find(token, search_from)
                if offset < 0:
                    break
                line_start = text.rfind("\n", 0, offset) + 1
                line_end = text.find("\n", offset)
                if line_end < 0:
                    line_end = len(text)
                if not text[line_start:line_end].lstrip().startswith("#"):
                    return (
                        path,
                        text.count("\n", 0, offset) + 1,
                        label,
                        token,
                    )
                search_from = offset + len(token)
    return None


def _contract_identifiers(
    project_root: Path, path: Path, text: str
) -> tuple[list[str], str]:
    identifiers: list[str] = []
    for line in text.splitlines():
        match = re.match(r"^\s*class_name\s+([A-Za-z0-9_]+)\s*$", line)
        if match:
            identifiers.append(match.group(1))
            break
    resource_path = f"res://{_project_relative(project_root, path)}"
    identifiers.append(resource_path)
    return identifiers, resource_path


def _find_contract_consumer(
    project_root: Path,
    source_index: dict[Path, str],
    contract_path: Path,
    preferred_paths: Iterable[Path],
) -> tuple[Path, int] | None:
    identifiers, resource_path = _contract_identifiers(
        project_root, contract_path, source_index[contract_path]
    )
    final_paths = [
        path
        for path in source_index
        if _is_final_consumer(project_root, path)
    ]
    ordered = list(
        dict.fromkeys(
            [
                *(
                    path
                    for path in preferred_paths
                    if _is_final_consumer(project_root, path)
                ),
                *sorted(final_paths),
            ]
        )
    )
    for path in ordered:
        lines = source_index[path].splitlines()
        for line_number, line in enumerate(lines, start=1):
            if line.lstrip().startswith("#"):
                continue
            class_hit = any(
                identifier != resource_path
                and re.search(rf"\b{re.escape(identifier)}\b", line)
                for identifier in identifiers
            )
            if class_hit:
                return path, line_number
            if resource_path not in line:
                continue
            alias_match = re.search(
                r"\b(?:const|var)\s+([A-Za-z0-9_]+)\s*:?=\s*preload", line
            )
            if not alias_match:
                return path, line_number
            alias = alias_match.group(1)
            for call_line_number, call_line in enumerate(lines, start=1):
                if call_line_number != line_number and re.search(
                    rf"\b{re.escape(alias)}\s*[.(]", call_line
                ):
                    return path, call_line_number
    return None


def consumer_binding(
    repo_root: Path,
    project_root: Path,
    source_index: dict[Path, str],
    runtime_row: dict[str, str],
    non_admitted: bool,
    proof_cache: dict[
        tuple[tuple[str, str], ...], tuple[str, str] | None
    ]
    | None = None,
    contract_consumer_cache: dict[Path, tuple[Path, int] | None]
    | None = None,
) -> tuple[str, str, str]:
    resolved, resolution = declared_consumer_resolution(
        repo_root,
        project_root,
        source_index,
        runtime_row.get("linked_scene", ""),
    )
    tokens = _runtime_tokens(runtime_row)
    cache_key = tuple(tokens)
    if proof_cache is not None and cache_key in proof_cache:
        cached = proof_cache[cache_key]
        if cached is not None:
            return cached[0], cached[1], resolution
        fallback = (
            "staging_no_consumer"
            if non_admitted
            else "no_production_consumer"
        )
        return fallback, "no_production_consumer_proven", resolution
    final_paths = [
        path
        for path in source_index
        if _is_final_consumer(project_root, path)
    ]
    preferred_final = [
        path for path in resolved if _is_final_consumer(project_root, path)
    ]
    direct = _find_token(
        [*preferred_final, *final_paths], source_index, tokens
    )
    if direct:
        path, line_number, label, token = direct
        binding_kind = (
            "scene_resource"
            if path.suffix.lower() in {".tscn", ".tres"}
            else "direct_token"
        )
        evidence = (
            f"{_repo_relative(repo_root, path)}:{line_number}"
            f"[{label}={token}]"
        )
        if proof_cache is not None:
            proof_cache[cache_key] = (binding_kind, evidence)
        return binding_kind, evidence, resolution

    contract_paths = [
        path
        for path in source_index
        if _is_contract_source(project_root, path)
    ]
    for contract_path in contract_paths:
        contract_hit = _find_token([contract_path], source_index, tokens)
        if not contract_hit:
            continue
        if (
            contract_consumer_cache is not None
            and contract_path in contract_consumer_cache
        ):
            consumer_hit = contract_consumer_cache[contract_path]
        else:
            consumer_hit = _find_contract_consumer(
                project_root, source_index, contract_path, []
            )
            if contract_consumer_cache is not None:
                contract_consumer_cache[contract_path] = consumer_hit
        if not consumer_hit:
            continue
        consumer_path, consumer_line = consumer_hit
        _, contract_line, label, token = contract_hit
        evidence = (
            f"{_repo_relative(repo_root, consumer_path)}:{consumer_line}"
            f"->"
            f"{_repo_relative(repo_root, contract_path)}:{contract_line}"
            f"[{label}={token}]"
        )
        if proof_cache is not None:
            proof_cache[cache_key] = ("dynamic_contract", evidence)
        return "dynamic_contract", evidence, resolution

    if proof_cache is not None:
        proof_cache[cache_key] = None
    if non_admitted:
        return (
            "staging_no_consumer",
            "no_production_consumer_proven",
            resolution,
        )
    return "no_production_consumer", "no_production_consumer_proven", resolution


def build_runtime_alias_debt(
    runtime_hashed: list[tuple[dict[str, str], str]],
    base_by_sha: dict[str, list[dict[str, str]]],
) -> tuple[
    list[dict[str, object]],
    dict[str, tuple[str, str]],
]:
    rows_by_path: dict[str, list[tuple[dict[str, str], str]]] = defaultdict(list)
    for row, sha in runtime_hashed:
        if sha in base_by_sha:
            rows_by_path[row.get("godot_path", "")].append((row, sha))

    debt_rows: list[dict[str, object]] = []
    alias_metadata: dict[str, tuple[str, str]] = {}
    for godot_path, group in sorted(rows_by_path.items()):
        asset_ids = sorted(
            {row.get("asset_id", "") for row, _ in group if row.get("asset_id", "")}
        )
        if len(asset_ids) < 2:
            continue
        alias_group = ";".join(asset_ids)
        semantic_states = sorted(
            {
                row.get("linked_data", "")
                or row.get("state", "")
                or row.get("asset_id", "")
                for row, _ in group
            }
        )
        debt_assets = sorted(
            {
                row.get("asset_id", "")
                for row, _ in group
                if "until dedicated" in row.get("note", "").lower()
                or row.get("replacement_needed", "").lower() == "true"
            }
        )
        is_cross_semantic_minimap = (
            "/minimap/" in godot_path.lower() and len(set(semantic_states)) > 1
        )
        if is_cross_semantic_minimap and debt_assets:
            alias_decision = "replacement_debt_open"
            debt_rows.append(
                {
                    "runtime_path": normalize_repo_path(
                        f"{PROJECT_ROOT}/{godot_path.removeprefix('res://')}"
                    ),
                    "runtime_sha256": group[0][1],
                    "alias_asset_ids": alias_group,
                    "semantic_states": ";".join(semantic_states),
                    "debt_asset_ids": ";".join(debt_assets),
                    "manifest_replacement_flags": ";".join(
                        f"{row.get('asset_id', '')}="
                        f"{row.get('replacement_needed', '')}"
                        for row, _ in sorted(
                            group, key=lambda item: item[0].get("asset_id", "")
                        )
                    ),
                    "debt_decision": alias_decision,
                    "semantic_closure": "not_closed",
                    "required_resolution": (
                        "provide dedicated semantic art, update the runtime "
                        "manifest, and rerun independent visual validation"
                    ),
                }
            )
        else:
            alias_decision = "shared_bytes_no_replacement_debt"
        alias_metadata[godot_path] = (alias_group, alias_decision)
    return debt_rows, alias_metadata


def promotion_validation_evidence(
    repo_root: Path, promotion: dict[str, str]
) -> str:
    validation = promotion.get("visual_validation", "").strip()
    if "_PASS_" not in validation:
        return ""
    validation_id, evidence_token = validation.split("_PASS_", 1)
    manifest_path = repo_root / "tools/i1/validation_manifest.json"
    evidence: list[str] = []
    if manifest_path.is_file():
        for line_number, line in enumerate(
            manifest_path.read_text(
                encoding="utf-8", errors="ignore"
            ).splitlines(),
            start=1,
        ):
            if validation_id in line and "pass_marker" in line:
                evidence.append(
                    f"{_repo_relative(repo_root, manifest_path)}:{line_number}"
                )
                break
    runtime_key = promotion.get("runtime_key", "").strip()
    tests_root = repo_root / PROJECT_ROOT / "tests"
    if tests_root.is_dir():
        for path in sorted(tests_root.rglob("*")):
            if not path.is_file() or path.suffix.lower() not in {
                ".gd",
                ".py",
                ".ps1",
            }:
                continue
            lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
            has_key = any(runtime_key and runtime_key in line for line in lines)
            if not has_key:
                continue
            for line_number, line in enumerate(lines, start=1):
                if validation_id in line and "=PASS" in line and evidence_token in line:
                    evidence.append(
                        f"{_repo_relative(repo_root, path)}:{line_number}"
                    )
                    break
            if len(evidence) >= 2:
                break
    return ";".join(evidence)


def build_outputs(repo_root: Path) -> tuple[dict[Path, bytes], dict[str, int]]:
    base_rows = read_csv(repo_root / BASE_MANIFEST)
    runtime_rows = read_csv(repo_root / RUNTIME_MANIFEST)
    promotion_rows = read_csv(repo_root / PROMOTION_REGISTRY)
    visual_review_rows = read_csv(repo_root / VISUAL_REVIEW_REGISTRY)
    project_root = repo_root / PROJECT_ROOT
    source_index = load_runtime_text_index(project_root)

    base_by_sha: dict[str, list[dict[str, str]]] = defaultdict(list)
    basename_shas: dict[str, set[str]] = defaultdict(set)
    for row in base_rows:
        sha = row.get("sha256", "").upper()
        base_by_sha[sha].append(row)
        basename_shas[PurePosixPath(row.get("source_member", "")).name.casefold()].add(
            sha
        )

    runtime_hashed: list[tuple[dict[str, str], str]] = []
    runtime_by_sha: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in runtime_rows:
        godot_path = row.get("godot_path", "").strip()
        if not godot_path:
            continue
        path = runtime_file(repo_root, godot_path)
        if not path.is_file():
            continue
        sha = sha256_path(path)
        runtime_hashed.append((row, sha))
        runtime_by_sha[sha].append(row)

    semantic_rows: list[dict[str, object]] = []
    for sha, group in sorted(base_by_sha.items()):
        canonical_rows = [
            row for row in group if row.get("disposition") == "canonical_content_object"
        ]
        if len(canonical_rows) != 1:
            raise RuntimeError(f"Base SHA {sha} has {len(canonical_rows)} canonical rows")
        canonical = canonical_rows[0]
        names = sorted(
            {PurePosixPath(row.get("source_member", "")).name for row in group},
            key=str.casefold,
        )
        paths = sorted(
            {row.get("source_member", "") for row in group}, key=str.casefold
        )
        same_name_other_sha = sum(
            max(0, len(basename_shas[name.casefold()]) - 1) for name in names
        )
        extension = canonical.get("extension", "").lower()
        runtime_matches = runtime_by_sha.get(sha, [])
        if runtime_matches:
            decision = "runtime_crosswalk_required"
            note = "Exact runtime bytes exist; authority is decided per runtime row."
        elif media_kind(extension) in {"image", "video"}:
            decision = "base_reference_only_pending_promotion"
            note = "Retained as source/reference; not admitted to runtime."
        else:
            decision = "source_support_not_runtime_art"
            note = "Registry, metadata, document, or other support object."
        semantic_rows.append(
            {
                "object_sha256": sha,
                "repository_object": canonical.get("repository_object", ""),
                "extension": extension,
                "media_kind": media_kind(extension),
                "semantic_family": semantic_family(paths, extension),
                "lifecycle_role": lifecycle_role(group),
                "canonical_source_member": canonical.get("source_member", ""),
                "alias_count": len(group),
                "source_layers": ";".join(
                    sorted({row.get("source_layer", "") for row in group})
                ),
                "distinct_names": ";".join(names),
                "same_name_other_sha_count": same_name_other_sha,
                "runtime_match_count": len(runtime_matches),
                "runtime_paths": ";".join(
                    sorted({row.get("godot_path", "") for row in runtime_matches})
                ),
                "base_authority": canonical.get("authority", ""),
                "rights_status": canonical.get("license_status", ""),
                "review_status": canonical.get("review_status", ""),
                "runtime_admission": canonical.get("runtime_admission", ""),
                "semantic_decision": decision,
                "decision_note": note,
            }
        )

    promotion_map = promotion_by_runtime_path(promotion_rows)
    visual_review_map = visual_review_by_asset_id(visual_review_rows)
    alias_debt_rows, alias_metadata = build_runtime_alias_debt(
        runtime_hashed, base_by_sha
    )
    runtime_output_rows: list[dict[str, object]] = []
    decision_counts: Counter[str] = Counter()
    consumer_counts: Counter[str] = Counter()
    proof_cache: dict[
        tuple[tuple[str, str], ...], tuple[str, str] | None
    ] = {}
    contract_consumer_cache: dict[Path, tuple[Path, int] | None] = {}
    for runtime_row, sha in sorted(
        runtime_hashed, key=lambda pair: pair[0].get("godot_path", "")
    ):
        if sha not in base_by_sha:
            continue
        runtime_path = normalize_repo_path(
            f"{PROJECT_ROOT}/{runtime_row.get('godot_path', '').removeprefix('res://')}"
        )
        base_group = base_by_sha[sha]
        canonical = next(
            row
            for row in base_group
            if row.get("disposition") == "canonical_content_object"
        )
        promotion = promotion_map.get(runtime_path, {})
        license_status = runtime_row.get("license_status", "")
        source_status = runtime_row.get("source_status", "")
        asset_id = runtime_row.get("asset_id", "")
        visual_review = visual_review_map.get(asset_id, {})
        if visual_review and visual_review.get("runtime_sha256", "").upper() != sha:
            raise RuntimeError(
                f"visual review SHA drift: {asset_id} "
                f"{visual_review.get('runtime_sha256', '')} != {sha}"
            )
        if promotion:
            decision = "approved_by_explicit_promotion_gate"
            note = "Explicit promotion row binds source, bytes, runtime key, consumer, and rollback."
        elif license_status in {"", "unknown", "pending_verification"}:
            decision = "quarantined_runtime_manifest"
            note = "Runtime manifest lacks a resolved source/license status."
        elif visual_review:
            decision = visual_review.get("review_decision", "")
            note = visual_review.get("review_note", "")
        elif "pending" in source_status or "staged" in source_status:
            decision = "existing_stage_evidence_visual_review_pending"
            note = "Runtime predates I3 Base; source identity exists but visual review remains pending."
        elif license_status.startswith("internal_generated"):
            decision = "independent_generated_lineage"
            note = "Runtime has an internal generated lineage independent of Base admission."
        else:
            decision = "existing_stage_evidence_backfilled"
            note = "Existing audited runtime lineage is cross-referenced; Base remains source-only."
        decision_counts[decision] += 1
        non_admitted = (
            decision
            in {
                "quarantined_runtime_manifest",
                "existing_stage_evidence_visual_review_pending",
                "visual_reviewed_staging_reference",
                "visual_reviewed_restricted_baked_text",
                "visual_reviewed_restricted_input_glyph",
                "visual_reviewed_semantic_mismatch",
            }
            or "pending" in source_status
            or "staged" in source_status
        )
        binding_kind, evidence, declared_resolution = consumer_binding(
            repo_root,
            project_root,
            source_index,
            runtime_row,
            non_admitted,
            proof_cache,
            contract_consumer_cache,
        )
        consumer_counts[binding_kind] += 1
        alias_group, alias_decision = alias_metadata.get(
            runtime_row.get("godot_path", ""), ("", "")
        )
        promotion_validation = (
            promotion_validation_evidence(repo_root, promotion)
            if promotion
            else ""
        )
        runtime_output_rows.append(
            {
                "asset_id": asset_id,
                "runtime_path": runtime_path,
                "runtime_sha256": sha,
                "base_object": canonical.get("repository_object", ""),
                "base_source_member": canonical.get("source_member", ""),
                "base_alias_count": len(base_group),
                "manifest_source": runtime_row.get("source_repo_path", ""),
                "manifest_license_status": license_status,
                "manifest_source_status": source_status,
                "runtime_key": runtime_row.get("theme_key", ""),
                "declared_consumer": runtime_row.get("linked_scene", ""),
                "declared_consumer_resolution": declared_resolution,
                "consumer_binding_kind": binding_kind,
                "consumer_evidence": evidence,
                "promotion_id": promotion.get("promotion_id", ""),
                "promotion_validation_evidence": promotion_validation,
                "runtime_alias_group": alias_group,
                "runtime_alias_decision": alias_decision,
                "crosswalk_decision": decision,
                "decision_note": note,
            }
        )

    outputs = {
        repo_root / SEMANTIC_OUTPUT: csv_bytes(SEMANTIC_FIELDS, semantic_rows),
        repo_root / RUNTIME_OUTPUT: csv_bytes(RUNTIME_FIELDS, runtime_output_rows),
        repo_root / ALIAS_DEBT_OUTPUT: csv_bytes(
            ALIAS_DEBT_FIELDS, alias_debt_rows
        ),
    }
    stats = {
        "base_objects": len(semantic_rows),
        "runtime_rows": len(runtime_output_rows),
        "runtime_paths": len(
            {row["runtime_path"] for row in runtime_output_rows}
        ),
        "runtime_shas": len(
            {row["runtime_sha256"] for row in runtime_output_rows}
        ),
        "explicit_promotions": decision_counts[
            "approved_by_explicit_promotion_gate"
        ],
        "pending_visual_review": decision_counts[
            "existing_stage_evidence_visual_review_pending"
        ],
        "visual_reviewed": sum(
            decision_counts[decision] for decision in VISUAL_REVIEW_DECISIONS
        ),
        "visual_existing_runtime": decision_counts[
            "visual_reviewed_existing_runtime"
        ],
        "visual_staging_reference": decision_counts[
            "visual_reviewed_staging_reference"
        ],
        "visual_restricted": (
            decision_counts["visual_reviewed_restricted_baked_text"]
            + decision_counts["visual_reviewed_restricted_input_glyph"]
        ),
        "visual_semantic_mismatch": decision_counts[
            "visual_reviewed_semantic_mismatch"
        ],
        "quarantined": decision_counts["quarantined_runtime_manifest"],
        "consumer_direct_token": consumer_counts["direct_token"],
        "consumer_dynamic_contract": consumer_counts["dynamic_contract"],
        "consumer_scene_resource": consumer_counts["scene_resource"],
        "consumer_staging_no_consumer": consumer_counts[
            "staging_no_consumer"
        ],
        "consumer_no_production_consumer": consumer_counts[
            "no_production_consumer"
        ],
        "alias_debt_groups": len(alias_debt_rows),
        "alias_debt_assets": sum(
            len(str(row["debt_asset_ids"]).split(";"))
            for row in alias_debt_rows
        ),
    }
    return outputs, stats


def validate_promotion_registry(repo_root: Path) -> list[str]:
    diagnostics: list[str] = []
    base_rows = read_csv(repo_root / BASE_MANIFEST)
    runtime_rows = read_csv(repo_root / RUNTIME_MANIFEST)
    promotion_rows = read_csv(repo_root / PROMOTION_REGISTRY)
    base_identity = {
        (row.get("source_member", ""), row.get("sha256", "").upper()): row
        for row in base_rows
    }
    runtime_by_path: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in runtime_rows:
        repo_path = normalize_repo_path(
            f"{PROJECT_ROOT}/{row.get('godot_path', '').removeprefix('res://')}"
        )
        runtime_by_path[repo_path].append(row)

    seen_ids: set[str] = set()
    seen_paths: set[str] = set()
    for row in promotion_rows:
        promotion_id = row.get("promotion_id", "")
        source_member = row.get("source_member", "")
        source_sha = row.get("source_sha256", "").upper()
        runtime_path = normalize_repo_path(row.get("runtime_path", ""))
        if not promotion_id or promotion_id in seen_ids:
            diagnostics.append(f"PROMOTION_ID_DUPLICATE_OR_EMPTY {promotion_id!r}")
        seen_ids.add(promotion_id)
        if not runtime_path or runtime_path in seen_paths:
            diagnostics.append(f"PROMOTION_RUNTIME_DUPLICATE_OR_EMPTY {runtime_path!r}")
        seen_paths.add(runtime_path)
        base_row = base_identity.get((source_member, source_sha))
        if base_row is None:
            diagnostics.append(
                f"PROMOTION_SOURCE_MISSING id={promotion_id} member={source_member}"
            )
            continue
        base_object = repo_root / PurePosixPath(row.get("base_object", ""))
        if not base_object.is_file() or sha256_path(base_object) != source_sha:
            diagnostics.append(f"PROMOTION_BASE_OBJECT id={promotion_id}")
        runtime_file_path = repo_root / PurePosixPath(runtime_path)
        runtime_sha = row.get("runtime_sha256", "").upper()
        if not runtime_file_path.is_file() or sha256_path(runtime_file_path) != runtime_sha:
            diagnostics.append(f"PROMOTION_RUNTIME_HASH id={promotion_id}")
        manifest_matches = runtime_by_path.get(runtime_path, [])
        if not manifest_matches:
            diagnostics.append(f"PROMOTION_MANIFEST_PATH id={promotion_id}")
        runtime_key = row.get("runtime_key", "")
        if not any(
            runtime_key
            and runtime_key
            in {
                manifest.get("asset_id", ""),
                manifest.get("theme_key", ""),
                manifest.get("linked_data", ""),
            }
            for manifest in manifest_matches
        ):
            diagnostics.append(f"PROMOTION_RUNTIME_KEY id={promotion_id}")
        consumer = repo_root / PurePosixPath(row.get("consumer", ""))
        if not consumer.is_file():
            diagnostics.append(f"PROMOTION_CONSUMER id={promotion_id}")
        else:
            project_root = repo_root / PROJECT_ROOT
            if not _is_final_consumer(project_root, consumer):
                diagnostics.append(
                    f"PROMOTION_CONSUMER_NOT_PRODUCTION id={promotion_id}"
                )
            consumer_lines = consumer.read_text(
                encoding="utf-8", errors="ignore"
            ).splitlines()
            consumer_hit = next(
                (
                    line_number
                    for line_number, line in enumerate(
                        consumer_lines, start=1
                    )
                    if runtime_key and runtime_key in line
                ),
                0,
            )
            if not consumer_hit:
                diagnostics.append(
                    f"PROMOTION_CONSUMER_BINDING id={promotion_id} "
                    f"runtime_key={runtime_key!r}"
                )
        validation_evidence = promotion_validation_evidence(repo_root, row)
        evidence_parts = [
            part for part in validation_evidence.split(";") if part
        ]
        if (
            len(evidence_parts) < 2
            or not any(
                part.startswith("tools/i1/validation_manifest.json:")
                for part in evidence_parts
            )
            or not any("/tests/" in f"/{part}" for part in evidence_parts)
        ):
            diagnostics.append(
                f"PROMOTION_VALIDATION_PROOF id={promotion_id} "
                f"evidence={validation_evidence!r}"
            )
        for field in (
            "license_decision",
            "review_decision",
            "visual_validation",
            "rollback",
            "status",
        ):
            value = row.get(field, "").strip().lower()
            if not value or value in {"unknown", "pending", "pending_review"}:
                diagnostics.append(f"PROMOTION_UNRESOLVED id={promotion_id} field={field}")
    return diagnostics


def validate_visual_review_registry(repo_root: Path) -> list[str]:
    diagnostics: list[str] = []
    review_rows = read_csv(repo_root / VISUAL_REVIEW_REGISTRY)
    runtime_rows = read_csv(repo_root / RUNTIME_MANIFEST)
    runtime_by_asset_id: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in runtime_rows:
        runtime_by_asset_id[row.get("asset_id", "")].append(row)

    seen_ids: set[str] = set()
    for row in review_rows:
        asset_id = row.get("asset_id", "").strip()
        decision = row.get("review_decision", "").strip()
        expected_sha = row.get("runtime_sha256", "").upper()
        if not asset_id or asset_id in seen_ids:
            diagnostics.append(
                f"VISUAL_REVIEW_ID_DUPLICATE_OR_EMPTY {asset_id!r}"
            )
            continue
        seen_ids.add(asset_id)
        if decision not in VISUAL_REVIEW_DECISIONS:
            diagnostics.append(
                f"VISUAL_REVIEW_DECISION id={asset_id} decision={decision!r}"
            )
        for field in (
            "runtime_sha256",
            "semantic_fit",
            "text_policy",
            "admission_scope",
            "review_note",
        ):
            if not row.get(field, "").strip():
                diagnostics.append(
                    f"VISUAL_REVIEW_FIELD id={asset_id} field={field}"
                )
        matches = runtime_by_asset_id.get(asset_id, [])
        if len(matches) != 1:
            diagnostics.append(
                f"VISUAL_REVIEW_RUNTIME_ID id={asset_id} matches={len(matches)}"
            )
            continue
        runtime_row = matches[0]
        runtime_path = runtime_file(repo_root, runtime_row.get("godot_path", ""))
        if not runtime_path.is_file():
            diagnostics.append(f"VISUAL_REVIEW_RUNTIME_MISSING id={asset_id}")
            continue
        actual_sha = sha256_path(runtime_path)
        if actual_sha != expected_sha:
            diagnostics.append(
                f"VISUAL_REVIEW_RUNTIME_HASH id={asset_id} "
                f"expected={expected_sha} actual={actual_sha}"
            )
        source_status = runtime_row.get("source_status", "")
        if "pending" not in source_status and "staged" not in source_status:
            diagnostics.append(
                f"VISUAL_REVIEW_NOT_PENDING_SOURCE id={asset_id} "
                f"source_status={source_status!r}"
            )
    return diagnostics


def validate_semantic_fixtures() -> list[str]:
    diagnostics: list[str] = []
    fixtures = [
        (
            "map_tile",
            ["sources/art/05_export_runtime_candidates/map_tile_icon/map_tile_explored.png"],
            "map",
        ),
        (
            "medkit",
            ["sources/art/05_export_runtime_candidates/item_consumable/item_consumable_medkit.png"],
            "item",
        ),
        (
            "chest",
            ["sources/draw/30_game_ready/props/00_baoxiang_kai.png"],
            "world_prop",
        ),
        (
            "ui_button",
            ["sources/art/05_export_runtime_candidates/ui_deploy_button/ui_button_nav_warehouse.png"],
            "deploy",
        ),
        (
            "run_hud_ui_button",
            ["sources/art/ART-20/03_cut_output/run_hud/run_bottom_key_bar_button/run_bottom_key_bar_button_ui_button_blank_dark.png"],
            "ui_component",
        ),
    ]
    for fixture_id, paths, expected in fixtures:
        actual = semantic_family(paths, ".png")
        if actual != expected:
            diagnostics.append(
                f"SEMANTIC_FIXTURE id={fixture_id} "
                f"expected={expected} actual={actual}"
            )
    lifecycle = lifecycle_role(
        [
            {"source_layer": "05_export_runtime_candidates"},
            {"source_layer": "30_game_ready"},
        ]
    )
    if lifecycle != "game_ready_source;runtime_candidate":
        diagnostics.append(
            f"LIFECYCLE_FIXTURE expected=game_ready_source;runtime_candidate "
            f"actual={lifecycle}"
        )
    if split_declared_consumers("a.gd; b.gd ;c.gd") != [
        "a.gd",
        "b.gd",
        "c.gd",
    ]:
        diagnostics.append("CONSUMER_SPLIT_FIXTURE")
    return diagnostics


def _csv_rows_from_output(data: bytes) -> list[dict[str, str]]:
    return list(csv.DictReader(io.StringIO(data.decode("utf-8"))))


def validate_generated_contracts(
    repo_root: Path, outputs: dict[Path, bytes]
) -> list[str]:
    diagnostics: list[str] = []
    runtime_rows = _csv_rows_from_output(outputs[repo_root / RUNTIME_OUTPUT])
    semantic_rows = _csv_rows_from_output(outputs[repo_root / SEMANTIC_OUTPUT])
    debt_rows = _csv_rows_from_output(outputs[repo_root / ALIAS_DEBT_OUTPUT])
    allowed_bindings = {
        "direct_token",
        "dynamic_contract",
        "scene_resource",
        "staging_no_consumer",
        "no_production_consumer",
    }
    for row in runtime_rows:
        asset_id = row.get("asset_id", "")
        binding = row.get("consumer_binding_kind", "")
        evidence = row.get("consumer_evidence", "")
        if binding not in allowed_bindings:
            diagnostics.append(
                f"CONSUMER_BINDING_KIND id={asset_id} binding={binding!r}"
            )
        if binding in {"direct_token", "dynamic_contract", "scene_resource"}:
            final_evidence = evidence.split("->", 1)[0]
            if not re.search(r":\d+(?:\[|$)", final_evidence):
                diagnostics.append(
                    f"CONSUMER_TRACE id={asset_id} evidence={evidence!r}"
                )
            forbidden = (
                "/tests/",
                "asset_manifest",
                ".translation",
                "manifest_asset_mapping.gd",
                "_asset_contract.gd",
                "_mapping.gd",
            )
            if any(
                marker in f"/{final_evidence.lower()}" for marker in forbidden
            ):
                diagnostics.append(
                    f"CONSUMER_SELF_PROOF id={asset_id} evidence={evidence!r}"
                )
        declared_parts = split_declared_consumers(
            row.get("declared_consumer", "")
        )
        resolution_parts = split_declared_consumers(
            row.get("declared_consumer_resolution", "")
        )
        if len(declared_parts) != len(resolution_parts):
            diagnostics.append(
                f"CONSUMER_DECLARATION_PARSE id={asset_id} "
                f"declared={len(declared_parts)} resolved={len(resolution_parts)}"
            )
        decision = row.get("crosswalk_decision", "")
        if (
            binding == "staging_no_consumer"
            and (
                decision == "approved_by_explicit_promotion_gate"
                or row.get("promotion_id", "")
            )
        ):
            diagnostics.append(
                f"STAGING_CONSUMER_ADMISSION id={asset_id} decision={decision}"
            )
        if row.get("promotion_id", ""):
            proof_parts = [
                part
                for part in row.get(
                    "promotion_validation_evidence", ""
                ).split(";")
                if part
            ]
            if binding not in {
                "direct_token",
                "dynamic_contract",
                "scene_resource",
            } or len(proof_parts) < 2:
                diagnostics.append(
                    f"PROMOTION_RUNTIME_CHAIN id={asset_id} "
                    f"binding={binding} validation={len(proof_parts)}"
                )

    for row in semantic_rows:
        if row.get("semantic_family", "") in {
            "working_candidate",
            "stage_evidence_capture",
            "prototype_reference",
        }:
            diagnostics.append(
                f"SEMANTIC_LIFECYCLE_LEAK sha={row.get('object_sha256', '')} "
                f"family={row.get('semantic_family', '')}"
            )
        if (
            row.get("semantic_family", "") == "actor_animation_source"
            and any(
                token in row.get("canonical_source_member", "").lower()
                for token in ("map_tile", "medkit", "baoxiang", "ui_button")
            )
        ):
            diagnostics.append(
                f"SEMANTIC_ACTOR_FALSE_POSITIVE "
                f"sha={row.get('object_sha256', '')}"
            )

    debt_assets: set[str] = set()
    for row in debt_rows:
        debt_assets.update(
            asset_id
            for asset_id in row.get("debt_asset_ids", "").split(";")
            if asset_id
        )
        if (
            row.get("debt_decision", "") != "replacement_debt_open"
            or row.get("semantic_closure", "") != "not_closed"
        ):
            diagnostics.append(
                f"ALIAS_DEBT_CLOSURE path={row.get('runtime_path', '')}"
            )
    for expected_asset in ("icon.room.spawn", "icon.room.event"):
        if expected_asset not in debt_assets:
            diagnostics.append(
                f"ALIAS_DEBT_MISSING asset_id={expected_asset}"
            )
    return diagnostics


def verify_outputs(
    outputs: dict[Path, bytes], promotion_diagnostics: list[str]
) -> list[str]:
    diagnostics = list(promotion_diagnostics)
    for path, expected in outputs.items():
        if not path.is_file():
            diagnostics.append(f"OVERLAY_MISSING {path}")
            continue
        actual = path.read_bytes()
        if actual != expected:
            diagnostics.append(
                f"OVERLAY_DRIFT {path} expected_sha={hashlib.sha256(expected).hexdigest().upper()} "
                f"actual_sha={hashlib.sha256(actual).hexdigest().upper()}"
            )
    return diagnostics


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root")
    parser.add_argument("--mode", choices=("write", "verify"), default="verify")
    args = parser.parse_args()

    repo_root = resolve_repo_root(args.repo_root)
    outputs, stats = build_outputs(repo_root)
    promotion_diagnostics = validate_promotion_registry(repo_root)
    visual_review_diagnostics = validate_visual_review_registry(repo_root)
    fixture_diagnostics = validate_semantic_fixtures()
    generated_contract_diagnostics = validate_generated_contracts(
        repo_root, outputs
    )
    if args.mode == "write":
        for path, data in outputs.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            if not path.exists() or path.read_bytes() != data:
                path.write_bytes(data)

    diagnostics = verify_outputs(
        outputs,
        promotion_diagnostics
        + visual_review_diagnostics
        + fixture_diagnostics
        + generated_contract_diagnostics,
    )
    if stats["pending_visual_review"]:
        diagnostics.append(
            f"VISUAL_REVIEW_REMAINING count={stats['pending_visual_review']}"
        )
    if diagnostics:
        for diagnostic in diagnostics[:100]:
            print(diagnostic, file=sys.stderr)
        print(
            f"I3R_BASE_GOVERNANCE=FAIL failures={len(diagnostics)}",
            file=sys.stderr,
        )
        return 1
    print(
        "I3R_BASE_GOVERNANCE=PASS "
        f"base_objects={stats['base_objects']} "
        f"runtime_rows={stats['runtime_rows']} "
        f"runtime_paths={stats['runtime_paths']} "
        f"runtime_shas={stats['runtime_shas']} "
        f"promotions={stats['explicit_promotions']} "
        f"visual_reviewed={stats['visual_reviewed']} "
        f"visual_existing_runtime={stats['visual_existing_runtime']} "
        f"visual_staging_reference={stats['visual_staging_reference']} "
        f"visual_restricted={stats['visual_restricted']} "
        f"visual_semantic_mismatch={stats['visual_semantic_mismatch']} "
        f"pending_visual_review={stats['pending_visual_review']} "
        f"quarantined={stats['quarantined']} "
        f"consumer_direct_token={stats['consumer_direct_token']} "
        f"consumer_dynamic_contract={stats['consumer_dynamic_contract']} "
        f"consumer_scene_resource={stats['consumer_scene_resource']} "
        f"consumer_staging_no_consumer={stats['consumer_staging_no_consumer']} "
        f"consumer_no_production_consumer={stats['consumer_no_production_consumer']} "
        f"alias_debt_groups={stats['alias_debt_groups']} "
        f"alias_debt_assets={stats['alias_debt_assets']} "
        "semantic_fixtures=5"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
