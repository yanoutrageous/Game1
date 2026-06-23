# Current State

文档状态：当前入口
适用范围：P2 后仓库文档当前事实摘要
最后更新：2026/06/23

本文件只汇总当前事实入口，不替代验证记录、历史 handoff 或外部策划来源。

## 1. 当前阶段

```text
当前文档治理阶段：P2
阶段性质：docs-only 文档整理与来源同步
工程实现阶段：未启动新工程阶段
G26 状态：未启动；不得由 P2 占用
```

P2 只整理仓库 `docs`，不改工程代码、Godot 场景、脚本、资源、导入文件或项目配置。

## 2. 最近已关闭工程阶段

G25 UI Structure Stabilization & Playable Route Recovery 已合入 `main`。

```text
G25 implementation commit：ae6f2ab6abd50b51c6f8f600cb8f5cda1cda7462
G25 closeout docs commit：022d3f74e9982fffae62e174df04b8f8f55a8958
G25 验证：static validation PASS；Godot headless project-load/parser smoke PASS
未声明：gameplay runtime PASS；manual playtest PASS
```

G25 只处理 UI 结构与当前可玩路线恢复，不实现真实仓库、奖励、结算、抽奖、目标、红点、SaveManager、资产写入、LongTerm 后端、真实设置或美术导入。

## 3. 当前能力摘要

| 模块 | 当前状态 | 证据入口 |
| --- | --- | --- |
| 主菜单 / AppShell | foundation 已建立；G25 增加当前可玩路线入口 | `docs/validation/G25_UI_STRUCTURE_PLAYABLE_ROUTE_VALIDATION.md` |
| 出发探索 / DeployPrep | foundation / preview；G22 为完整模块内容预览，不是真实出发系统 | `docs/validation/G22_DEPLOY_PREP_FULL_MODULE_CONTENT_PREVIEW_VALIDATION.md` |
| 长期系统 / LongTerm | 六模块 foundation / preview；不是完整长期系统 | `docs/validation/G24_LONG_TERM_CONTENT_FRAMEWORK_FOUNDATION_VALIDATION.md` |
| 物品 / 资产 | G21 为契约 foundation；不是真实资产系统或仓库 | `docs/validation/G21_ASSET_ITEM_FLOW_CONTRACT_VALIDATION.md` |
| 结算 / 历史 | G23 为 snapshot foundation；不是真实结算或持久历史 | `docs/validation/G23_SETTLEMENT_HISTORY_SNAPSHOT_FOUNDATION_VALIDATION.md` |
| 战斗遭遇 | G15/G16 为 encounter/combat foundation | `docs/validation/G15_ENCOUNTER_CONTRACT_VALIDATION.md`、`docs/validation/G16_COMBAT_ENCOUNTER_FOUNDATION_VALIDATION.md` |
| 文档治理 | P2 已建立统一入口；2026/06/23 补充外部归档与并行交接只读边界 | `docs/00_governance/SOURCE_REGISTRY.md`、`docs/00_governance/EXTERNAL_SOURCE_BOUNDARY.md` |

## 4. 当前边界

```text
1. Godot headless project-load/parser smoke PASS 不等于 gameplay runtime PASS。
2. foundation / preview / display-only 不等于完整系统。
3. Base Docs 是仓库外当前归档后的只读策划事实来源之一；仓库历史副本不覆盖当前外部原件。
4. UI 图片不作为规则权威。
5. G26 需要后续单独授权，不由 P2 自动开启。
6. Connection 是仓库外并行交接区；不得进入 Git、不得作为 Godot 资源导入。
7. 旧文件名失效时，应在外部根目录内按主题、相近名称、更新时间和文档状态重新定位。
```

## 5. 扩展证据

扩展证据和历史正文仍保留：

```text
docs/PROJECT_BASELINE.md
docs/ENGINEERING_STATUS.md
docs/NEXT_HANDOFF.md
docs/DOCS_INDEX.md
Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md
```

P2 后第一入口仍以本文件和 `docs/INDEX.md` 为准。
