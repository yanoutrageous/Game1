# Handoff G26 Engineering Architecture Structure Readiness

## Goal

G26 prepares a reviewable engineering architecture structure before any new functional contract or gameplay slice.

```text
G26 = Engineering Architecture Structure Readiness Foundation
G26-R1 = PASS with preconditions
G26-R2A = docs-only reviewable workspace preparation
```

G25 is complete as UI Structure Stabilization & Playable Route Recovery at final `main` / `origin/main` `17f8406dcf745f81c829e78478663bec6cbd4e68`.

## Route Conclusion

The previous Prototype-Facing Objective / Reward / Pool Contract Foundation candidate is not the current G26 implementation target.

Recommended route:

```text
G26: architecture responsibility and execution-boundary readiness.
G27 or later: separately audited Objective / Reward / Pool Contract Foundation candidate.
```

G26 does not implement real objectives, rewards, pools, reward grant, gacha, warehouse, asset writes, persistence, player-playable prototype v1, SaveManager, AssetLedger behavior, or CommandBus behavior.

## Responsibility Boundaries

| Area | Owns | Must not own in G26 |
| --- | --- | --- |
| `core` | domain state owners, deterministic rules, public service boundaries | UI nodes, presentation formatting, preview-only fake state |
| `ui` | rendering, input intent emission, accessibility/readability | private core state, rule mutation, reward/asset settlement |
| `preview` | display-only sample/projection data and disabled-state explanation | persistence, authoritative state, real grant/write behavior |
| `contract` | stable public schemas, normalized payloads, validation rules | runtime ownership, UI composition, content balancing |
| `content` | declarative definitions and identifiers consumed through contracts | direct scene orchestration, private state mutation |
| `validation` | static checks, parser smoke evidence, contract tests, explicit result boundaries | production authorization or claims beyond tested scope |
| `docs` | current route, ownership, non-goals, evidence links, allowlists | invented implementation facts or implicit authorization |

Cross-boundary rule:

```text
UI emits intent and consumes public projections.
Core owns rules and state transitions.
Preview remains non-authoritative.
Contracts describe exchange shapes, not ownership.
Content remains declarative.
Validation proves only its explicit scope.
Docs record facts and gates; they do not create runtime authority.
```

## Lua And Godot Lines

```text
Lua line: gameplay hypothesis and rule-feel validation.
Godot line: formal system skeleton, public interface, integration boundary, and production-oriented validation readiness.
```

Lua prototype behavior is evidence for gameplay exploration, not automatic authorization to copy implementation structure. Godot temporary behavior is engineering evidence, not automatic planning authority.

## Precise Allowlist Template

Every functional follow-up must declare:

```yaml
stage_id: G27-or-later
goal: one bounded contract or integration outcome
allowed_modify:
  - exact/path/one
  - exact/path/two
allowed_add:
  - exact/new/path
forbidden:
  - project.godot
  - "**/*.translation"
  - protected dirty paths
  - unrelated scripts/scenes/resources/docs
dependencies_read_only:
  - exact/evidence/path
validation:
  - static command
  - contract-specific command
  - parser smoke only when separately authorized
git_gate:
  stage_allowed: false
  commit_allowed: false
  push_allowed: false
```

The execution report must compare pre/post changed paths and prove that only the declared allowlist changed.

## G26 Commit Isolation Rule

The current workspace contains independent P2 edits in these shared tracked files:

```text
docs/PROJECT_BASELINE.md
docs/NEXT_HANDOFF.md
docs/ENGINEERING_STATUS.md
```

These shared documents must never be staged as whole files for G26. A command equivalent to `git add <shared-file>` is forbidden because it would absorb non-G26 P2 hunks.

The future G26 Git gate must:

```text
1. Use `git add -p` or an equivalent explicit patch-staging mechanism for each shared document.
2. Stage only the G26 section and historicalization hunks listed in the G26 validation attribution ledger.
3. Stage the two new G26 validation/handoff documents only after exact-path review.
4. Include ROADMAP and GODOT_CURRENT_STATUS only after reviewing their complete diffs as G26-attributable.
5. Exclude all P2 content, protected dirty, governance docs, first-real engineering bundle files, Godot metadata, translations, tools, scripts, scenes, and resources.
6. Compare pre/post changed paths.
7. Run `git diff --cached --name-only`, `git diff --cached --check`, and inspect the complete `git diff --cached`.
8. Stop if any staged hunk contains non-G26 content or if the staged path set exceeds the seven-file allowlist.
```

The only commit-eligible content after that review is:

```text
G26-attributable hunks in the five existing allowlist documents
the complete new G26 validation document
the complete new G26 handoff document
```

G26-R2A-FIX does not run `git add`, does not create a staged diff, and does not authorize commit or push.

## Protected Dirty

Do not absorb, restore, delete, stage, or commit:

```text
Godot/GraytailGodot/project.godot
Godot/GraytailGodot/data/assets/asset_manifest.*.translation
docs/validation/FIRST_REAL_ENGINEERING_WORK_BUNDLE_VALIDATION.md
tools/validate_lua_require_graph.ps1
tools/validate_lua_selftest_registry.ps1
```

The first-real engineering bundle requires its own scoped gate.

## External Governance Sources

Read-only boundary evidence:

```text
docs/00_governance/EXTERNAL_SOURCE_BOUNDARY.md
docs/00_governance/EXTERNAL_SOURCE_BOUNDARY_UPDATE_REPORT.md
```

`D:\AGAME1\Base Docs` is a current post-archive read-only planning source. Locate current documents by topic, similar name, update time, and document status; do not assume an old path is unique.

`D:\AGAME1\Connection` is an external parallel handoff area. Do not write, clean, roll back, move, overwrite, commit, or import it into Godot.

These governance documents are independent prior work and are not absorbed into G26-R2A.

## Validation Boundary

G26-R2A runs documentation and Git read-only checks only.

```text
Godot run: no
gameplay runtime PASS: not claimed
manual playtest: no
manual playtest PASS: not claimed
stage/commit/push/merge: not performed
```

## Next Gate

Review the G26-R2A workspace diff in G26-R2B. Only after that review may a separate Git gate or a separately scoped G27 planning/audit request be considered.
