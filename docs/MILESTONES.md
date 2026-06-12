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
| G11 | Mainline Testability & UX Readability Repair | 主线可测性与 UX 可读性修补 | R3 complete and pushed at `e261ac7d8671b59e7e72750122e6581af6ea6644`; R4 docs-only closeout |

## Naming Rule

Use the formal name in new planning and handoff documents, and keep the historical label in parentheses when it helps locate old branches or validation scripts.

Example: `UI Core Flow Baseline (G9 Final)`.

## Current Mainline

Current main HEAD: `e261ac7d8671b59e7e72750122e6581af6ea6644`.

The current mainline includes G10 Progress & Art Smoke Foundation, the G10 closeout follow-up, and the completed G11-R3 mainline UX readability pass. It does not represent complete final UI, complete MetaProgress, complete Deploy persistence, or complete long-term system completion.

G10 was a bounded foundation branch for progress整理, stability/BUG fixes, UI interaction fixes, dev-only diagnostics, art smoke, responsive reservation, and future content planning. It is complete, merged to main, and closed. It does not represent complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, full art replacement, or broad architecture reshaping.

G11-R3 is complete and pushed. G11-R4 is docs-only closeout. It is not G10 continuation, not G12, not a new gameplay phase, and not a new systems phase.
