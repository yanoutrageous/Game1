# Source Registry

文档状态：I3 当前来源注册表。
最后更新：2026-07-23

## 当前仓库权威

```text
active_repo: git rev-parse --show-toplevel
godot_project: <active_repo>/Godot/GraytailGodot
docs_entry: <active_repo>/docs
```

当前机器观测 repo 为 `E:\AGAME1`，但该盘符不是跨机器权威。代码、资源、manifest 和当前 docs 事实必须从解析后的 worktree root 定位。

## I3 用户注入来源与仓库内 Base

| Source | Current observation | Identity | Repository handling |
| --- | --- | --- | --- |
| I3 source pack | workspace file `sources.zip`（不提交） | SHA256 `A1035F69C412680016E6FB1C4FB181E77E75A517FDB252D6EBBC76D7F7957E71`; 1626 members | 只由 `tools/i3/import_base_sources.py` 读取 |
| 原始策划案 | archive `sources/docs/` | 25 files / 728214 bytes | 原名、原字节保存在 `sources/base/原始策划案/`；关系表位于 `docs/70_sources/base_docs/I3_ORIGINAL_PLANNING_RELATIONSHIP_REGISTRY.md` |
| Base 美术 | archive `sources/art/` + `sources/draw/` | 1407 members / 1012 unique SHA objects / 395 aliases | 内容寻址保存在 `sources/base/美术素材/blobs/`；路径别名和保留说明见 `BASE_ART_ALIAS_MANIFEST.csv` |
| Governance snapshot | archive `sources/docs_governance/` | 192 files | 复制型历史快照；只登记 inventory，不重复导入正文 |
| Nested Art.zip | archive member `sources/draw/Art.zip` | 38.69 MiB historical nested archive | 其 23 图片在外层有相同内容；不重复导入，hash/理由保留在 inventory |

本次入库来自用户对 I3 的明确授权，不改变“不要把 Base 正文复制进 `repo/docs`”的
位置规则：原件位于 `sources/base`，`docs` 只保存索引、关系、裁决与消费者记录。
Base 入库也不等于运行时准入；当前所有 Base art 初始状态均为
`pending_verification + pending_review + not_admitted`。

可复现清单：

- `sources/base/manifests/ORIGINAL_PLANNING_MANIFEST.csv`
- `sources/base/manifests/BASE_ART_ALIAS_MANIFEST.csv`
- `sources/base/manifests/SOURCE_ARCHIVE_INVENTORY.csv`
- `sources/base/manifests/BASE_IMPORT_SUMMARY.json`

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
- Base Docs / Connection 正文不得为解决引用问题而复制进 repo docs。I3 经用户明确授权的原始策划仅进入 `sources/base/原始策划案`，repo docs 仍只登记路径、hash、关系和使用边界。
- 外部美术不得直接成为 production runtime asset；必须经过来源、许可、hash、manifest、import 和 runtime key 门。
- 历史截图和 UI 参考不定义玩法、容量、碰撞或结算规则。
- 不对受保护来源做破坏性去重。
- 任何绝对路径必须注明 `current local observation` 或 `historical evidence`；未标注的固定盘符不能进入当前操作指令。
