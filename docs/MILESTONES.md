# Milestones

This file maps the historical G-number labels to stable milestone names. It does not rename branches, rewrite Git history, or remove the historical labels.

| Historical label | Formal name | Chinese name | Status |
| --- | --- | --- | --- |
| G5 | Asset UI Presentation Baseline | 资产 UI 表现基线 | In main as historical baseline |
| G6 | Playable Lua Parity Core | Lua 可玩等价核心 | In main as historical baseline |
| G7 | Playable Flow Baseline | 可玩流程基线 | In main |
| G8 | Asset Ledger & Settlement Core | 资产账本与结算核心 | In main |
| G8.1 | Architecture Hardening | 架构硬化 | In main |
| G8.2 | Kernel Protocol Baseline | 内核协议基线 | In main |
| G8.2 hotfix | Runtime Parse Hotfix | 运行时解析修复 | In main |
| G9 Presentation | UI Presentation Layering Contracts | UI 表现图层合同 | In main |
| G9 Final | UI Core Flow Baseline | UI 核心流程基线 | In main |
| G10 | Progress & Art Smoke Foundation | 当前进度整理与美术接入基础验证 | Complete; merged to main and closed at `aa19db2f1989c6ebfc22676d84b83da5c6977f64` |
| G11 | Mainline Testability & UX Readability Repair | 主线可测性与 UX 可读性修补 | Complete and closed at `4be0010dd68abe1b0e74966775db64f736d78e15` |
| G12 | Legacy Demo Core Loop, Chinese Readability & Typography Parity | 旧 Demo 核心体验、中文可读性与字体排版轻量对齐 | Complete; R3 at `2855ca9889e394fb79d22c468b1355cd3871fd39`, closeout at `e90bd271ad2fc747051c9a49ff6a50c64e8fa49f` |
| G13 | Fixed Resolution Layout Adaptation | 固定分辨率档位与布局适配 | Complete and closed at `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf`; static validation only, no runtime PASS |
| G14 | Legacy Demo UI Surface Sprint | 旧 Demo 主局 UI 表层快速复现 | Active; R3 adds minimal `RunSurface` / `RunSurfaceModel` shell from baseline `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf` |

G14 current correction: R3 is complete, committed, and pushed at `1d33c894b6b2c948bf2c7f9c5a55387dce717fc5` (`1d33c89 feat(godot): add legacy demo run surface shell`). The `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf` value is the G13 closeout / G14-R3 baseline history only.

## Naming Rule

Use the formal name in new planning and handoff documents, and keep the historical label in parentheses when it helps locate old branches or validation scripts.

Example: `UI Core Flow Baseline (G9 Final)`.

## Current Mainline

Current main HEAD: `1d33c894b6b2c948bf2c7f9c5a55387dce717fc5`.

Current remote live main HEAD: `1d33c894b6b2c948bf2c7f9c5a55387dce717fc5`.

G14-R3 commit: `1d33c89 feat(godot): add legacy demo run surface shell`.

G14-R3 baseline before implementation: `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf`.

The current mainline includes G10 Progress & Art Smoke Foundation, the G10 closeout follow-up, the completed G11 mainline UX readability pass, G11 closeout, the completed G12 legacy Demo readability/typography parity pass, G13 fixed resolution layout support and closeout, and the active G14 run surface sprint. It does not represent complete final UI, complete MetaProgress, complete Deploy persistence, complete long-term system completion, complete 1:1 legacy Demo reproduction, or runtime PASS.

G10 was a bounded foundation branch for progress整理, stability/BUG fixes, UI interaction fixes, dev-only diagnostics, art smoke, responsive reservation, and future content planning. It is complete, merged to main, and closed. It does not represent complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, full art replacement, or broad architecture reshaping.

G11, G12, and G13 are complete and closed. G14 is active and bounded to visible run UI surface work; it is not G15, not a complete settings system, not a new gameplay phase or new systems phase, and not runtime PASS. G14-R3 acceptance follow-up records that `RunSurface` is UI-only composition, `RunSurfaceModel` is display-only, CommandBus dispatch and event / loot / extract decisions stay in `run_scene.gd`, and the outside-repository temporary-script incident was reported as cleaned without repository commit residue.
