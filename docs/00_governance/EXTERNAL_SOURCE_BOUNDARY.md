# External Planning And Handoff Source Boundary

Status: current governance rule after I0.6.

This document defines how the repository cites external planning, art, and handoff material after the G40 topology rebuild. It does not copy source bodies into Git and does not authorize runtime asset import.

## Current External Roots

```text
D:\AGAME1\sources\docs
D:\AGAME1\sources\docs_governance
D:\AGAME1\sources\art
D:\AGAME1\sources\draw
D:\AGAME1\handoff\connection
```

## Legacy Path Labels

- Legacy path before G40: `D:\AGAME1\Base Docs`
  Moved to: `D:\AGAME1\sources\docs`
  Do not use as current canonical path: `D:\AGAME1\Base Docs`
- Legacy path before G40: `D:\AGAME1\Base Docs_Governance`
  Moved to: `D:\AGAME1\sources\docs_governance`
  Do not use as current canonical path: `D:\AGAME1\Base Docs_Governance`
- Legacy path before G40: `D:\AGAME1\Base Art`
  Moved to: `D:\AGAME1\sources\art`
  Do not use as current canonical path: `D:\AGAME1\Base Art`
- Legacy path before G40: `D:\AGAME1\Draw`
  Moved to: `D:\AGAME1\sources\draw`
  Do not use as current canonical path: `D:\AGAME1\Draw`
- Legacy path before G40: `D:\AGAME1\Connection`
  Moved to: `D:\AGAME1\handoff\connection`
  Do not use as current canonical path: `D:\AGAME1\Connection`

## Source Use Rules

1. Planning originals under `D:\AGAME1\sources\docs` are protected source material. Register and cite them; do not rewrite or copy their bodies into repo docs.
2. Governance snapshots under `D:\AGAME1\sources\docs_governance` are external snapshots. They are not the current repository fact source.
3. Art sources under `D:\AGAME1\sources\art` and `D:\AGAME1\sources\draw` are not runtime assets unless an approved art import gate imports them.
4. Handoff material under `D:\AGAME1\handoff\connection` is an external collaboration area. Register paths and hashes when needed; do not import content into Git by default.
5. Repository facts live under `D:\AGAME1\active\Game1_work\docs`, implementation evidence, and committed code.

## Current Read Order

1. Repository current state, validation, handoff, and implementation evidence.
2. Registered external source paths under `D:\AGAME1\sources`.
3. Registered handoff paths under `D:\AGAME1\handoff\connection`.
4. Historical snapshots only for explaining prior stages, not for overriding current source roots.

## Forbidden Reverse Inference

1. Do not infer rules from UI images alone.
2. Do not infer planning approval from temporary engineering implementation.
3. Do not infer task authorization from handoff material.
4. Do not infer current canonical external paths from pre-G40 legacy paths.
5. Do not treat hash registration as content approval, execution authorization, or acceptance.
