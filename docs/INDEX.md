# G28A Docs Index Update

Current G28A docs-only entry point:

- `docs/20_product/ITEM_ASSET_CONTENT_AND_WAREHOUSE_VIEW_CONTRACT.md`

Read with:

- `docs/20_product/ASSET_DOMAIN_AND_WAREHOUSE_VIEW_CONTRACT.md`
- `docs/10_current/CURRENT_STATE.md`
- `docs/10_current/CAPABILITY_MATRIX.yaml`
- `docs/00_governance/OPEN_DECISIONS.md`
- `docs/route_analysis/ROADMAP_G20_PLUS.md`

G28A is documentation-only item asset content / warehouse view content contract work. It does not approve Godot schema changes, UI consumer changes, Base Docs writes, Connection writes, real warehouse behavior, real asset writes, runtime catalog / ContentDB, rewards, gacha, settlement warehouse writes, objective progress, FileAccess/user persistence, gameplay runtime PASS, or manual playtest PASS.

Any remaining G27A/G27B/G27C index wording below this update is historical / superseded / resolved unless explicitly reopened by a future gate.

# G27A Docs Index Update

Current G27A docs-only entry point:

- `docs/20_product/ASSET_DOMAIN_AND_WAREHOUSE_VIEW_CONTRACT.md`

Read with:

- `docs/10_current/CURRENT_STATE.md`
- `docs/10_current/CAPABILITY_MATRIX.yaml`
- `docs/00_governance/OPEN_DECISIONS.md`
- `docs/route_analysis/ROADMAP_G20_PLUS.md`

G27A is a documentation-only asset-domain / warehouse-view contract foundation. It does not approve Godot code changes, Base Docs changes, Connection changes, real warehouse behavior, real asset writes, rewards, gacha, settlement mutation, persistence, gameplay runtime PASS, or manual playtest PASS.

Any remaining P2 / G26 / prior G27 index wording below this update is historical / superseded / resolved unless explicitly named as the current G27A split or future G27B / G27C / G28 candidate.

# AGAME1 Unified Docs Index

文档状态：G27A 当前入口；P2 统一入口为 historical / superseded
适用范围：仓库 `docs` 根目录的当前入口、归属和阅读顺序
最后更新：2026/06/23

本文件当前服务 G27A docs-only 入口；原 P2 文档治理说明为 historical / superseded。它不新增玩法规则，不替代验证记录，不把外部来源材料写成定案。

## 1. 当前必读入口

新对话或审计复查优先读取以下 5 个文件：

1. `docs/INDEX.md`
2. `docs/10_current/CURRENT_STATE.md`
3. `docs/10_current/NEXT_ACTION.md`
4. `docs/10_current/CAPABILITY_MATRIX.yaml`
5. `docs/00_governance/SOURCE_REGISTRY.md`

旧的 `PROJECT_BASELINE.md`、`ENGINEERING_STATUS.md`、`NEXT_HANDOFF.md`、`DOCS_INDEX.md` 保留为扩展证据和历史状态材料，不再作为第一轮必须通读入口。

## 2. 阶段边界

```text
P2 = historical / superseded 策划文档统一整理与仓库文档同步执行。
G25 = UI Structure Stabilization & Playable Route Recovery，已作为工程阶段关闭。
G26 = completed / historical；不再是后续产品 / 原型阶段占位。
```

Historical / superseded P2 note: G27A 当前仍只处理 allowlist docs，不执行 Godot 工程实现，不运行 Godot；Git gate 仅限 G27A docs branch。

## 3. 目录归属

| 目录 | 定位 |
| --- | --- |
| `00_governance/` | 文档治理、来源注册、生命周期、待确认事项、声明台账 |
| `10_current/` | 当前状态、下一步、能力矩阵 |
| `20_product/` | 产品契约草案和待确认产品边界 |
| `30_engineering/` | 工程文档入口与 Godot docs 只读注册 |
| `40_validation/` | 验证证据索引 |
| `50_stages/` | 阶段索引；历史阶段保留证据价值 |
| `60_interfaces/` | Connection 外部只读交接登记与接口说明；不保存内容镜像 |
| `70_sources/` | Base Docs、UI 图片等外部来源登记与此前获授权的冻结历史快照 |
| `90_archive/` | 历史、生成报告、旧体系归档说明 |

既有 `handoff/`、`validation/`、`stage_summaries/`、`route_analysis/`、`project_governance/`、`design_sources/` 不删除；P2 historical / superseded references are retained only as older index context; G27A current references are listed at the top of this file.

## 4. 使用规则

```text
1. 当前事实先看 10_current。
2. 来源归属先看 00_governance/SOURCE_REGISTRY.md。
3. Base Docs 是当前归档后的外部只读策划事实来源之一；读取前应按当前目录和相近文件名重新定位。
4. UI 图片只作为确定图、示例图、问题截图或未知图登记。
5. 未确认内容不得写成最终规则。
6. Connection 是外部并行交接区，不得进入 Git 或作为 Godot 资源导入。
7. 外部来源完整边界见 `docs/00_governance/EXTERNAL_SOURCE_BOUNDARY.md`。
```
