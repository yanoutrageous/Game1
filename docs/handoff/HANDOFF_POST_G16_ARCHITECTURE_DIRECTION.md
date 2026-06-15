# Post-G16 Architecture Direction Handoff

## 文档定位

本文档是 Post-G16 阶段的工程方向基线。它把用户提供的外部 GPT 工程评估结果整理为仓库内可接力的结构化摘要，用于指导后续 G17 起点。

本文档不是外部评估全文转储，不替代设计策划案原文，也不表示后续 G17 阶段已经开始或结束。

## 当前事实源

- 仓库：`D:\AGAME1\_repo_cache\Game1_work`
- Remote：`https://github.com/yanoutrageous/Game1.git`
- 当前工作分支：`main`
- Post-G16 方向导入前的 main HEAD：`9af74aeefd3a28b6b417fa0667532737cddc916b docs: mark G16 merged to main`
- G15：Encounter contract foundation 已合入 main。
- G16：combat encounter foundation 已合入 main。
- G16 验证事实：已通过 Godot headless project-load/parser smoke PASS。
- 验证边界：G16 smoke 只是 headless project-load/parser smoke PASS，不是完整 gameplay runtime PASS，也不是 manual playtest PASS。

## G15 / G16 定位

G15/G16 的局内 Encounter / Combat 基础可以保留。当前架构没有失控，但已经进入需要明确顶层应用壳边界的阶段。

- G15 建立 `EncounterContract`、`EncounterResolver`、public `encounter_view_model` / `encounter_result_summary`、`select_encounter_option` additive bridge、`RunSurface` EncounterSlot。
- G16 在 G15 之上加入最小 `combat_basic` / `monster_basic` / `attack_basic` foundation。
- G15/G16 默认冻结语义，只做 additive 扩展。
- 后续不应改写 `fight_current_enemy` / `fight_enemy` / settlement 旧语义来承载局外系统。

## 外部评估核心结论

外部评估给出的核心判断是：

1. 当前架构没有失控。
2. G15/G16 形成的是可保留的局内 Encounter / Combat 基础。
3. 当前项目已到“必须拆出顶层应用壳”的节点。
4. G17 不应继续把主菜单、出发探索、长期系统塞进 `run_scene.gd` 或临时 shell。
5. G17 应命名为：`G17：AppShell / NavigationIntent / PageRouter / MainMenuShell`，而不是单纯“主菜单实现”。

## 当前架构健康度判断

健康部分：

- 局内 run、Encounter、Combat、CommandBus、QueryFacade、RunSurface 之间已经有基本分层。
- UI 通过 public snapshot / ViewModel 展示 EncounterSlot，不应直接读规则私有状态。
- Combat encounter 当前只是最小规则桥，不是完整战斗系统。

主要薄弱点：

- 顶层应用路由仍缺少明确所有者。
- 主菜单、出发探索、长期系统、设置、RunScene 之间缺少统一导航意图。
- 如果继续直接把局外入口接到 `run_scene.gd` 或临时 shell，会使 app-level 与 run-level 职责混杂。

## 当前最大风险

- High：继续扩写 `run_scene.gd`，让它同时承担主菜单、出发页、长期系统、RunScene 和结算回流。
- High：主菜单直接启动或继续 RunScene，绕过 Deploy/RunStartConfig 边界。
- High：在 `PlayerProfileSnapshot` / save / unlock skeleton 之前实现抽奖、唯一藏品或长期奖励。
- Medium：出发探索先做完整 UI，而没有稳定 `RunStartConfig / DeployConfig` 输出。
- Low：先做最小 AppShell / NavigationIntent / PageRouter / MainMenuShell 合同。

## G17+ 推荐路线

- G17：`AppShell / NavigationIntent / PageRouter / MainMenuShell`
- G18：`DeployPrepShell / RunStartConfig / DeployConfig`
- G19：`LongTermShell / LongTermSnapshot / UnlockSnapshot` 入口骨架
- G20：`PlayerProfileSnapshot / Meta / Save` 最小骨架
- G21：Warehouse / Codex / Collection adapters
- G22：Lottery / unique collectibles / appearance collection
- G23：RunResultSummary / SettlementAdapter integration audit
- G24+：批量局内内容与长期内容扩展

这些是方向建议，不代表任何后续阶段已经启动。

## 低耦合原则

- 主菜单只负责导航、氛围、轻量提示与跳转。
- 主菜单不得直接启动 / 继续 RunScene。
- 出发探索应输出 `RunStartConfig / DeployConfig`。
- 长期系统应输出 `PlayerProfileSnapshot / LongTermSnapshot / UnlockSnapshot`。
- Run 只消费出发配置。
- 结算通过 `RunResultSummary / SettlementAdapter` 回流局外。
- UI 不直接读取 TruthMap、Ledger、RunRuleService、RunAssetLedger 或规则私有状态。
- G15/G16 Encounter / Combat 语义默认冻结，只允许 additive extension。

## 推荐目标架构

```text
MainMenuShell
  -> NavigationIntent
  -> PageRouter / SceneRouter
  -> AppShell / GameShell
      -> MainMenuShell
      -> DeployPrepShell
          -> RunStartConfig / DeployConfig
          -> RunScene
              -> G15/G16 Encounter / Combat foundation
              -> RunResultSummary
      -> LongTermShell
          -> PlayerProfileSnapshot / LongTermSnapshot / UnlockSnapshot
      -> SettingsShell

RunResultSummary
  -> SettlementAdapter
  -> LongTerm/Profile integration later
```

## G17 起点建议

G17-R1 建议只做审计 + 计划：

- 读取主菜单策划案。
- 审计现有 `run_scene.gd`、G9 shell、现有 shell routing。
- 规划 `AppShell / GameShell` 的所有权。
- 规划 `NavigationIntent` 字段与发起方。
- 规划 `PageRouter / SceneRouter` 的 page 切换职责。
- 规划 `MainMenuShell`，但不让它直接启动 RunScene。
- 将出发探索与长期系统限制为 placeholder route，不展开完整系统。

G17-R2 才考虑最小执行切片：最小 AppShell + MainMenuShell + route placeholder。G17-R3 再做验收、docs closeout 和 Godot headless parser smoke，前提是用户授权运行 Godot。

## 禁止项

- 不把 G17 做成“主菜单美术实现”。
- 不让主菜单直接启动 / 继续 RunScene。
- 不把出发探索、长期系统、设置继续塞进 `run_scene.gd`。
- 不在 G17 实现完整出发探索。
- 不在 G17 实现完整长期系统。
- 不在 G17 实现完整 MetaProgress。
- 不在 G17 实现 Deploy persistence。
- 不在 G17 实现抽奖、唯一藏品、仓库经济、图鉴、外观库。
- 不在 G17 改写 G15/G16 Encounter / Combat 语义。
- 不把 G16 headless parser smoke 写成完整 gameplay runtime PASS 或 manual playtest PASS。

## 后续审计 / 执行建议

下一轮建议是 G17-R1：`AppShell / NavigationIntent / PageRouter / MainMenuShell` 审计 + 计划。

G17-R1 应输出：

- 当前 shell / routing / run ownership 审计。
- `AppShell / GameShell` ownership 计划。
- `NavigationIntent` schema 计划。
- `PageRouter / SceneRouter` 计划。
- `MainMenuShell` 最小职责边界。
- 出发探索 / 长期系统 placeholder route 边界。
- G17-R2 最小执行切片。

G17-R1 不应实现代码，不应启动 G17-R2，不应重新审计 G15/G16。
