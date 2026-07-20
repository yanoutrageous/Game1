# Source Registry

文档状态：I1 当前来源注册表。
最后更新：2026-07-20

## 当前仓库权威

```text
active_repo: git rev-parse --show-toplevel
godot_project: <active_repo>/Godot/GraytailGodot
docs_entry: <active_repo>/docs
```

当前机器观测 repo 为 `E:\AGAME1`，但该盘符不是跨机器权威。代码、资源、manifest 和当前 docs 事实必须从解析后的 worktree root 定位。

## G40 历史外部来源

| Source | G40 recorded path | Pre-G40 legacy path | 2026-07-20 local observation | Rule |
| --- | --- | --- | --- | --- |
| Planning originals | `D:\AGAME1\sources\docs` | `D:\AGAME1\Base Docs` | unavailable on this machine | historical pointer only; do not infer replacement |
| Governance snapshots | `D:\AGAME1\sources\docs_governance` | `D:\AGAME1\Base Docs_Governance` | unavailable on this machine | external snapshot; not current repo fact source |
| Base art | `D:\AGAME1\sources\art` | `D:\AGAME1\Base Art` | unavailable on this machine | source-only unless imported through an audited gate |
| Draw/candidate art | `D:\AGAME1\sources\draw` | `D:\AGAME1\Draw` | unavailable on this machine | candidate-only unless imported through an audited gate |
| Connection handoff | `D:\AGAME1\handoff\connection` | `D:\AGAME1\Connection` | unavailable on this machine | register only; do not copy content into repo |

上述五个路径在本机只读检查均不存在。不存在不代表可以删除历史登记，也不授权把其他相似目录猜作同一来源；需要使用外部 source pack 时，用户必须显式提供当前路径，再经过 import/source gate。

## 其他历史指针

| Evidence | Historical path | Current handling |
| --- | --- | --- |
| Legacy Godot shell/reference | `D:\AGAME1\external\godot_reference\Godot`（更早为 `D:\AGAME1\Godot`） | historical reference only; not active project or engine source |
| Code audit 20260622 | `D:\AGAME1\reports\code_audit_20260622` | historical report pointer; not current code truth |
| G40 cleanup reports | `D:\AGAME1\reports\g40\...` | historical working evidence; availability not assumed |
| I0 historical active repo | `D:\AGAME1\active\Game1_work` | historical machine layout; not current repo selector |

## 当前 Godot 说明

本机执行环境观测为 `E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe`。它属于工具链执行身份，不是 planning/art/connection source pack；跨机器规则见 `docs/00_governance/EXECUTION_ENVIRONMENT.md`。

## 来源使用规则

- 外部来源可以支持需求或审计，但只有经代码、资源或当前 docs 明确实现后才成为仓库事实。
- Base Docs / Connection 正文不得为解决引用问题而复制进 repo docs；只登记路径、hash 和使用边界。
- 外部美术不得直接成为 production runtime asset；必须经过来源、许可、hash、manifest、import 和 runtime key 门。
- 历史截图和 UI 参考不定义玩法、容量、碰撞或结算规则。
- 不对受保护来源做破坏性去重。
- 任何绝对路径必须注明 `current local observation` 或 `historical evidence`；未标注的固定盘符不能进入当前操作指令。
