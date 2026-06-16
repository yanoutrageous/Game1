# 决策记录

本文件是 G20-R3d2 新增的轻量 ADR / decision register。它只登记已经形成的阶段性决策和执行安全决策，不启动 G21，不处理分支，不删除、移动、重命名或清理任何历史文档。

## 记录规则

- `id`: 稳定决策编号。
- `stage`: 决策所属阶段或执行批次。
- `decision`: 已采用的决策。
- `reason`: 当时采用该决策的原因。
- `impact`: 对后续文档、实现或验收的影响。
- `non_goals`: 该决策明确不做的事。
- `evidence`: 可追溯证据文件。
- `follow_up`: 后续只读验收或单独授权事项。
- `status`: 当前登记状态。

## DL-G17-001

- `id`: DL-G17-001
- `stage`: G17
- `decision`: G17 先做 `AppShell / NavigationIntent / PageRouter / MainMenuShell`，而不是继续把正式主菜单、出发探索、长期系统堆进 `run_scene.gd`。
- `reason`: Post-G16 架构方向判断认为主要风险已经从 Encounter / Combat 转移到顶层应用壳 ownership；继续扩展临时 shell 会提高后续返工成本。
- `impact`: 主菜单只发导航意图，AppShell / PageRouter 负责页面切换；RunScene 继续保留局内 orchestration。
- `non_goals`: 不实现正式出发准备、不实现长期系统、不实现仓库、图鉴、抽奖、MetaProgress、Deploy persistence，也不把 parser smoke 写成 manual playtest PASS 或 gameplay runtime PASS。
- `evidence`: `docs/design_sources/architecture/G16_POST_ARCHITECTURE_DIRECTION_REFERENCE.md`; `docs/stage_summaries/G17_SUMMARY.md`; `docs/validation/G17_APP_SHELL_MAIN_MENU_VALIDATION.md`; `docs/route_analysis/ROUTE_ANALYSIS_G10_TO_G19.md`。
- `follow_up`: 后续 shell 扩展必须继续通过 public intent / snapshot / contract 边界推进。
- `status`: active / recorded in G20-R3d2。

## DL-G18-001

- `id`: DL-G18-001
- `stage`: G18
- `decision`: G18 只做 `DeployPrepShell / DeployConfig / RunStartConfig` preview foundation，不启动或继续 RunScene。
- `reason`: 出发准备需要先建立页面位置、五个 placeholder tabs、公开配置预览和 deploy_start_intent preview；在 Asset Contract、Warehouse、Permit、真实地图生成和 settlement/history contract 之前直接启动 RunScene 会混淆 preview 与真实执行。
- `impact`: DeployPrepShell 只展示 public preview，不 dispatch run CommandBus，不写 RunContext，不生成真实地图，不写 persistence。
- `non_goals`: 不实现真实 run start、不实现仓库/申领/作业许可规则、不实现结算报告/历史、不实现长期系统、抽奖、MetaProgress 或 Deploy persistence，不声明 manual playtest PASS 或 full gameplay runtime PASS。
- `evidence`: `docs/stage_summaries/G18_SUMMARY.md`; `docs/validation/G18_DEPLOY_PREP_FOUNDATION_VALIDATION.md`; `docs/route_analysis/ROUTE_ANALYSIS_G10_TO_G19.md`; `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`。
- `follow_up`: 真实 run-start handoff 需要单独阶段、单独验收和明确资产/许可/结算边界。
- `status`: active / recorded in G20-R3d2。

## DL-G19-001

- `id`: DL-G19-001
- `stage`: G19
- `decision`: G19 从早期七页/七 tab 设想收敛为六模块 LongTermShell：目标、图鉴、研究、个人资历、抽奖、收藏 / 外观。
- `reason`: 当前阶段只需要顶层信息架构和 display-only preview；六模块能覆盖目标、内容索引、研究、档案、抽奖和收藏外观入口，同时避免把真实长期系统提前实现。
- `impact`: LongTermShell 替换旧 placeholder route，但只暴露 placeholder / preview / disabled state 和 display-only interface preview。
- `non_goals`: 不实现真实目标、任务进度、成就检查、委托接取、图鉴数据、研究、个人资历成长、历史存储、真实抽奖、奖励领取、red-dot 清除、资产系统、MetaProgress 或 persistence。
- `evidence`: `docs/stage_summaries/G19_SUMMARY.md`; `docs/validation/G19_LONG_TERM_SHELL_FOUNDATION_VALIDATION.md`; `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md`; `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`。
- `follow_up`: 后续长期系统必须按模块拆分 contract、snapshot、policy 和 persistence 边界。
- `status`: active / recorded in G20-R3d2。

## DL-G20-001

- `id`: DL-G20-001
- `stage`: G20
- `decision`: G20 先做 docs-only project knowledge governance，而不是直接启动 Asset Contract。
- `reason`: G19 之后系统入口增多，但设计源、阶段总结、系统边界、依赖关系、当前事实源、历史引用和 future roadmap 尚未集中治理；直接做 Asset Contract 容易混淆外部 Base Docs 原件、R3a design source copies、当前事实源和路线建议。
- `impact`: G20 先完成文本设计源入库、project governance、stage summaries、route analysis、branch / commit / validation matrices、decision log、glossary 和 temporary/deprecated inventory。
- `non_goals`: 不实现 Asset Contract、Warehouse、Settlement、Objective、Gacha、gameplay，不运行 Godot，不声明 Godot headless project-load/parser smoke PASS、manual playtest PASS 或 gameplay runtime PASS。
- `evidence`: `docs/route_analysis/ROUTE_ANALYSIS_G10_TO_G19.md`; `docs/route_analysis/ROADMAP_G20_PLUS.md`; `docs/project_governance/SOURCE_OF_TRUTH_POLICY.md`; `docs/project_governance/SOURCE_REGISTRY.md`。
- `follow_up`: G20 closeout 和 G21+ 必须单独授权、单独验收；G21 未启动。
- `status`: active / recorded in G20-R3d2。

## DL-G20-002

- `id`: DL-G20-002
- `stage`: G20-R3a
- `decision`: Base Docs Markdown / TXT 设计源以仓库内文本副本形式同步到 `docs/design_sources/`，外部原件不移动、不删除、不覆盖、不重命名。
- `reason`: 仓库需要可审计的文本设计源；同时外部 `D:\AGAME1\Base Docs` 是用户原件，不能由本仓库治理批次处理。
- `impact`: `docs/design_sources/` 成为可引用的 design source copy；外部 Base Docs 原件仍是 external original reference，不是本轮可修改对象。
- `non_goals`: 不复制 PNG，不移动 Base Docs 原件，不清理外部目录，不把设计源直接当作实现清单。
- `evidence`: `docs/design_sources/DESIGN_SOURCE_INDEX.md`; `docs/project_governance/SOURCE_REGISTRY.md`; `docs/NEXT_HANDOFF.md`; `docs/PROJECT_BASELINE.md`。
- `follow_up`: 任何外部原件处理或图片入库都需要用户单独授权。
- `status`: active / recorded in G20-R3d2。

## DL-G20-003

- `id`: DL-G20-003
- `stage`: G20-R3b
- `decision`: Base Docs PNG 暂缓入库，仅在 registry 中登记为 `external_reference / pending_user_authorization`。
- `reason`: 图片资产可能涉及授权、文件体积、命名、位置和资产治理规则；R3b/R3d2 只登记事实，不处理外部图片。
- `impact`: PNG 仍保留在外部 Base Docs 原件位置；仓库只记录它们是外部视觉参考。
- `non_goals`: 不复制 PNG，不生成替代图片，不压缩、移动、删除或重命名外部图片，不把 PNG 状态改成 imported。
- `evidence`: `docs/project_governance/SOURCE_REGISTRY.md`; `docs/design_sources/DESIGN_SOURCE_INDEX.md`。
- `follow_up`: 若未来需要图片入库，必须先获得用户授权并定义资产位置、命名和来源登记。
- `status`: active / recorded in G20-R3d2。

## DL-G20-004

- `id`: DL-G20-004
- `stage`: G20 执行安全
- `decision`: 当前环境的 `PATCH_MODE=AGAME1_ROOT`；本轮所有 `apply_patch` 路径必须以 `_repo_cache/Game1_work/` 开头。
- `reason`: root probe 证明 `apply_patch` 的相对路径基准在 `D:\AGAME1`，直接使用 `docs/...` 或 `Godot/...` 会落到错误根。
- `impact`: 所有写入路径均带仓库前缀，避免触碰 `D:\AGAME1\Godot\GraytailGodot` 等错误外部路径。
- `non_goals`: 不在 patch 中使用绝对路径、`../`、裸 `docs/...` 或裸 `Godot/...`，不通过 shell 写文档文件。
- `evidence`: `docs/project_governance/EXECUTION_ENVIRONMENT.md`; 本轮 G20-R3d2 root probe。
- `follow_up`: 每个新执行批次写入前都必须重新做 root probe。
- `status`: active / recorded in G20-R3d2。

## DL-G20-005

- `id`: DL-G20-005
- `stage`: G20 执行治理
- `decision`: 每个执行批次新开执行框，用完即停。
- `reason`: 分批执行能降低上下文漂移、误承接 closeout/final 或下一批次任务的风险。
- `impact`: G20-R3d2 只负责决策记录、术语表、临时/过期文件登记和导航更新；完成后停止。
- `non_goals`: 不在本执行框承接 G20 closeout、G20-R4A、G21、分支处理、代码实现或 Godot 验证。
- `evidence`: `docs/project_governance/HANDOFF_TEMPLATE.md`; `docs/project_governance/EXECUTION_ENVIRONMENT.md`; 本轮执行指令。
- `follow_up`: 后续 R4A 或 closeout 必须使用新的授权与执行框。
- `status`: active / recorded in G20-R3d2。

## DL-G20-006

- `id`: DL-G20-006
- `stage`: G20-R3d1 / G20-R3d2
- `decision`: G20 分支和历史分支只登记，不删除本地分支、不删除远端分支、不执行 remote prune。
- `reason`: G20-R3d1 的 branch inventory 是治理登记，不是清理授权；历史分支仍可能是审计证据。
- `impact`: `BRANCH_INVENTORY.md`、`COMMIT_MILESTONE_MAP.md`、`VALIDATION_STATUS_MATRIX.md` 仅作为事实矩阵；R3d2 仅补充 decision/glossary/deprecated inventory。
- `non_goals`: 不删除分支，不清理远端引用，不改写历史，不合并 main，不处理 protective stash，不把登记动作解释为清理授权。
- `evidence`: `docs/project_governance/BRANCH_INVENTORY.md`; `docs/project_governance/COMMIT_MILESTONE_MAP.md`; `docs/project_governance/VALIDATION_STATUS_MATRIX.md`; `docs/project_governance/TEMP_AND_DEPRECATED_INVENTORY.md`。
- `follow_up`: 任何分支清理都需要用户后续明确授权，并且不得由 G20-R3d2 执行。
- `status`: active / recorded in G20-R3d2。

## DL-G21-005

- `id`: DL-G21-005
- `stage`: G21-R5
- `decision`: 在进入 G22 前先做 docs-only Design Alignment Calibration，并将下一阶段校准为 G18-align / 出发探索资产出勤视角。
- `reason`: Base Docs 全量一致性审计完成后未发现 P0，但发现 P1/P2 设计口径与 foundation 完成度问题：G18 出发探索仍是 foundation，结算报告 / 历史战绩仍缺快照系统，主菜单存在 warehouse 快捷入口口径风险，G21 AssetEvent 动作口径偏最小，旧长期七模块、旧“天赋”页签和旧 G21/G22 排序需要标注为历史参考。
- `impact`: G22 不再直接按旧 Warehouse / Asset Page Shell 口径启动；G22 前应先规划 G18-align，包括出发探索资产出勤视角、二级标签、卡片详情、深层跳转、开始/继续/放弃强确认口径。
- `non_goals`: 不实现真实仓库、长期系统扩展、抽奖、奖励领取、结算历史、AssetEvent 写入、事件总线、存档或 gameplay；不修改代码、不运行 Godot、不修改 Base Docs 原件、不进入 G22。
- `evidence`: `docs/route_analysis/ROADMAP_G20_PLUS.md`; `docs/route_analysis/SYSTEM_BOUNDARY_MAP.md`; `docs/PROJECT_BASELINE.md`; `docs/NEXT_HANDOFF.md`。
- `follow_up`: 下一执行建议进入 G18-align 计划模式；任何 G22 都必须在 G18-align 后重新审计和计划。
- `status`: active / recorded in G21-R5。
