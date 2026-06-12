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
| G10 | Progress & Art Smoke Foundation | 当前进度整理与美术接入基础验证 | In progress on `godot/g10-progress-art-smoke-foundation` |

## Naming Rule

Use the formal name in new planning and handoff documents, and keep the historical label in parentheses when it helps locate old branches or validation scripts.

Example: `UI Core Flow Baseline (G9 Final)`.

## Current Mainline

Current main HEAD: `a13a6fae3208850ae43e4b511511e008eb311a3e`.

The current mainline includes G9 UI core flow baseline but does not represent complete final UI, complete MetaProgress, complete Deploy persistence, or complete long-term system completion.

G10 is a bounded foundation branch for progress整理, stability/BUG fixes, UI interaction fixes, dev-only diagnostics, art smoke, responsive reservation, and future content planning. It does not represent complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, full art replacement, or broad architecture reshaping.
