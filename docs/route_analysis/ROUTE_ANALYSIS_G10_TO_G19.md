# G10-G19 路线分析

## 分析边界

- 本文只分析 G10-G19。
- G20 是 docs-only knowledge governance，不纳入 G10-G19 阶段成果范围。
- G21 未启动。
- 本文不登记完整分支库存、提交矩阵、验证矩阵、临时/过期文件清单；这些留给 R3d。

## G10-G19 的路线为何如此演进

G10-G19 的路线从“稳定现有 playable/UI 基线”逐步转向“建立可承接未来系统的外壳与合同”。前半段 G10-G14 先处理已存在主线的可读性、验证链、固定分辨率和 visible run surface；后半段 G15-G19 再在较稳定的 surface 与 routing 上建立 Encounter、Combat、AppShell、DeployPrepShell、LongTermShell foundation。

核心逻辑是：先让已有流程可读、可测、可定位，再添加更高层的系统边界。否则后续 Encounter、Combat、Deploy、LongTerm、Asset Contract 会挤进 `run_scene.gd` 或直接读写 private state，导致职责混乱。

## 为什么先稳定旧 Demo / UI / 布局

- G10 先修稳定性、交互阻塞、返回路径、pause/settings、diagnostics gating 和 art smoke。
- G11 修当前主线可测试性和玩家可见文案。
- G12 对齐旧 Demo core-loop feel 和中文可读性。
- G13 固定 16:9 分辨率层级，使 UI 验证有稳定尺寸。
- G14 把 run UI surface 整理成 display-only composition。

这些阶段不是为了完成最终 UI，而是为了让后续系统有可靠显示落点和验证口径。

## 为什么 G15/G16 先做遭遇与战斗 foundation

G14 之后，run surface 已有基本展示结构，但规则层仍不能让 UI 直接读 `TruthMap`、Ledger、`RunRuleService` 或 private `RunContext`。G15 因此先做 public Encounter contract 和 `select_encounter_option` additive bridge。G16 再用同一 contract 接入最小 Monster `attack_basic`，证明 Combat foundation 可以通过 public snapshot 和既有 deterministic fight path 扩展。

G15/G16 的目标不是完整 encounter/combat，而是冻结并验证“UI 消费 public snapshot、命令走 CommandBus、规则仍在规则层”的边界。

## 为什么 G17 先做 AppShell，而不是继续堆 run_scene

Post-G16 direction 记录的结构压力是 top-level app ownership，而不是更多 run-level encounter work。主菜单、出发准备、长期系统、settings、run 入口如果继续塞进 `run_scene.gd`，会让 run orchestration 承担应用导航职责。

G17 因此先做 AppShell / NavigationIntent / PageRouter / MainMenuShell foundation。MainMenuShell 只发 navigation intent，不直接启动或继续 RunScene。这样 G18/G19 才能作为 AppShell 下的独立 shell 接入。

## 为什么 G18 做 DeployPrepShell，但不启动 RunScene

G18 的作用是建立出发准备页面位置、五个 placeholder tabs、DeployConfig / RunStartConfig preview 和 deploy_start_intent preview。它刻意不启动 RunScene，是为了避免在没有 Asset Contract、Warehouse、Permit、真实地图生成、settlement/history 合同前，把 preview 误接成真实 run start。

G18 只回答“未来出发准备如何展示和输出 preview”，不回答“如何消耗真实资产并生成真实 run”。

## 为什么 G19 做 LongTermShell，但不实现长期系统

G19 建立长期系统的顶层信息架构：目标、图鉴、研究、个人资历、抽奖、收藏/外观。它只显示 placeholder/preview/disabled state 和 display-only interface preview，不实现真实目标、资产、抽奖、历史、奖励、red-dot、MetaProgress 或 persistence。

原因是长期系统涉及资产合同、奖励合同、历史快照、解锁/研究、抽奖池和唯一藏品等多条线；直接实现会绕过前置合同。

## 为什么 G20 改为知识治理，而不是直接 Asset Contract

G19 之后，未来系统入口已经很多，但设计源、阶段总结、系统边界、依赖关系还没有集中治理。若直接启动 Asset Contract，容易混淆外部 Base Docs 原件、R3a design source copies、当前事实源、future roadmap 与已实现系统。

G20 改为 docs-only knowledge governance，是为了先入库文本设计源、建立项目治理、阶段总结、路线分析、系统边界和依赖图。G20 不运行 Godot，不实现 Asset Contract、Warehouse 或 gameplay。

## 已确认路线

- UI 不直接读规则 private state。
- CommandBus 仍是玩家/debug UI command entry。
- Encounter/Combat foundation 保持 additive extension。
- AppShell 负责 top-level route ownership。
- DeployPrepShell 只输出 preview，不启动 RunScene。
- LongTermShell 只做 display-only foundation，不实现长期系统。
- G20 先做知识治理，再考虑后续 Asset Contract。

## 已废弃或延期路线

- 延期：完整 MetaProgress。
- 延期：Deploy persistence。
- 延期：真实 run-start handoff。
- 延期：Warehouse / requisition / permit rules。
- 延期：Settlement / History snapshot。
- 延期：Objective / Reward event contract。
- 延期：Gacha / unique collectible。
- 废弃为当前阶段目标：把 main menu、deploy、long-term 继续堆进 `run_scene.gd`。
- 废弃为当前阶段目标：把 parser smoke 写成 complete gameplay runtime PASS 或 manual playtest PASS。

## 事实来源

- `docs/PROJECT_BASELINE.md`
- `docs/NEXT_HANDOFF.md`
- `docs/ENGINEERING_STATUS.md`
- `docs/MILESTONES.md`
- `docs/handoff/HANDOFF_POST_G16_ARCHITECTURE_DIRECTION.md`
- `docs/stage_summaries/*.md`
