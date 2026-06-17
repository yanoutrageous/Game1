# Handoff: G22 Deploy Prep Full Module Content Preview

## Current Branch

- Branch: `godot/g22-deploy-prep-full-module-content-preview`.
- Base main commit: `85a5b4fe5251071054573147c6ff3a3947e11600`.
- G22-R2 implementation commit: `bd1ce6373c4332d04d7262474ed6055a24698096`.
- G22-R4B status: branch closeout docs are recorded on this branch.
- Main has not been merged.
- Branch has not been pushed by R4B.

## What G22-R2 Added

G22-R2 expands the existing Deploy Prep foundation into a fuller content preview for:

- 地图
- 仓库
- 申领
- 出勤配置
- 作业许可

The changes are limited to preview data, right-side summary wording, card detail display, and start / continue / abandon preview copy.

## Validation

- G22-R3 static validation PASS.
- Godot headless project-load/parser smoke PASS.
- `git diff --check` had no whitespace error; only LF/CRLF warnings.
- Smoke added no dirty side effects.

## Boundaries

This branch does not implement real asset writes, real warehouse behavior, real claim purchase, real reward grant, real RunScene start / continue / abandon, real map generation, real settlement, real persistence, real gacha, or a complete long-term system.

Do not report G22-R3 smoke as gameplay runtime PASS or manual playtest PASS.
