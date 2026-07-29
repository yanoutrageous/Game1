# Audit Scope

文档状态：I4 活动阶段的当前审计边界；不是关闭结论。
最后更新：2026-07-30

## 身份与阶段

    active_repo: git rev-parse --show-toplevel
    active_stage: I4 / ACTIVE / QUALITY_STANDARD_FROZEN
    delivery_branch: codex/i4-production-interaction-convergence
    i4_entry_head: 4127bd27a05b75cb5e3071cf6dc87d9287f679a9
    i4_entry_tree: e1455ffd8c7a754c63eb2141a47e41f8fe5cdf3a
    i3_historical_head: 09aaafe283aa2e4c2f30708c5f88b89ebf7753eb
    i3_historical_tree: a077da34237dce5e4a6081d833efd939098b4641
    i3r_entry_head: 35189aaf524157761d1ab9cdddc39e76baa0d7ca
    i3r_entry_tree: 82f100059add24ecb2c12e7fca0bfb17f3a95c50

I3 保持历史记录。I3R 的机器复验、静态视觉复核与空间治理保持历史原义；用户后续
生产反馈未接受其外部体验边界。I4 是当前用户授权的活动阶段并接管这些开放项。

## 本次纳入

- 当前 Godot 生产代码、生产消费者、状态机和可复现运行事实。
- 主菜单、出发探索、长期系统、局内、特殊房、撤离、结果、设置、字体、边框、
  动画、图层、战斗输入与攻击判定等 I3R 返工范围。
- 地图/小地图、KnownMap 防泄漏、搜索、箱子、地面物、周围雷险、HUD、协议、
  背包、物品、终局叙事和保存失败恢复。
- 教程作为 Deploy 地图目录中的 `tutorial_5x5`，沿 `standard_run` 启动；不建立
  独立生产教程接口。
- 原始策划案和 Base 素材的原名、原字节、原 SHA、去重关系、保留理由与
  runtime admission 边界。
- I1 历史验证快照的内容寻址归档、独立恢复证明、源工作树清理和项目容量治理。
- 自动化、渲染预览、污染检查、玩家/视觉签收、目标设备和外部交付门。
- `I4-QA-FROZEN-1` 定义的当前内容普查、R/S/G/V/H/F/P、边框层级/带宽、
  动作预算、真实渲染逐原图和旧断言处置。
- I4-R043–R049 定义的折叠/展开地图局部层、静态阻挡—可见物对应、协议安全区、
  左下内容驱动密度、跨表面品质色和物品纹理/fallback。

## 证据优先级

1. 当前 Godot 代码、权威模型、真实消费者和可复现生产运行；
2. 当前自动化、公开输入旅程、渲染、性能、失败恢复和污染证据；
3. I3R 契约、执行台账、需求矩阵与 Base manifests；
4. 原始策划案的设计意图及版本关系；
5. UE/Lua/历史截图与报告的有边界参考。

用户观察必须逐项处置，但不能覆盖仓库事实。UE 只用于解释体验差异，不能替代
Godot 对 KnownMap、GroundLoot、保存、结算、fixed tick、伤害和容量替换的权威。

2026-07-30 用户当前 Deploy 截图已作为仓库事实的外部可见反例登记：它不改变领域权威，
但证明此前机器/静态视觉门不足，I4.4/I4.7 已重新打开。截图生成和几何 runner 的成功
最多产生 `VISUAL_CANDIDATE`。

同日用户新增局内直接观察作为第二组外部反例登记。当前代码进一步确认地图负 offset/
共中心叠层、匿名房型阻挡、空纹理节点隐藏 fallback 和固定空包区域，因此 I4.5 也已重开。
该反例没有独立截图 SHA，必须由当前候选新鲜捕获补齐 bbox；不得用旧 gallery 关闭。

## 最终工作树 full

`.tmp/i1/20260726T171400780Z_6f66cb6f/report.json`：

    result: PASS / 96 of 96
    plain_runner_count: 53
    cleanup_diagnostic_runner_count: 43
    hard_failure_count: 0
    duration_ms: 1053141
    manifest_sha256: 11B32B377A244B9DDF98637020CC9F263ABCDEB488472FA624F11F5A0A575406
    report_sha256: 3CDF02791EC61CD580B78489A4C5B2581EF7E974AADEEA897AF06FEBD1494BC4
    business_file_count: 2333
    business_fingerprint_sha256: E7ACAA39576A6DFEEB8B22EA18C41B0914A008F84F33348637183B1541C25A1F

该报告绑定最终 Godot/tools 业务快照。其后只回写治理文档与空间终态，并以最终
静态/治理检查单独覆盖；不得反向声称 full 业务指纹包含这些文档回写。

## 空间治理事实

- 审计起点项目占用为 `113.296 GiB`。
- 当前 123 个快照（I3R 60）已进入内容寻址归档；全局 CAS 为 6489 个对象、
  735449033 bytes。
- 固定归档索引 SHA-256 为
  `16974A206B007F737CB4CC45163720F3D10AF1170A657EC1DD477B26DE61AEAE`。
- 最终 full 快照 V2 独立恢复、两次完整树校验和恢复副本移除均通过；proof 为
  `ACE86F8E3614CBA2BB8E0A52EC82B1E3A320609422CF20FD17AC274F1D483195`。
- 本轮 38/38 快照工作树已按事务凭证删除；所有快照均无 worktree 镜像，
  tombstone 为 0；最终全局 verifier 为 `PASS`。
- 最终 proof SHA-256 为
  `A9B1286576B9E877642F9B2D0FACC7FE90F22C06D40C14856A1C7C7D97A377C4`。
- 76 个验证瞬态目标与 752427027-byte 孤立 restore staging 已按精确目标清理；
  事故取证目录保留。
- 清理后项目为 `9.1937 GiB / 56331 files`，E 盘可用
  `112984649728 bytes / 105.2252 GiB`。

123 个快照只证明存储治理范围，不代表 I3R 产品进度。原始 `sources.zip`、Base
原始策划案、Base 素材和运行时素材是基线或生产来源，不是缓存，不得作为空间清理对象。
阶段 Git worktree 也不属于快照缓存：I2 含修改，I3/I3-baseline 虽可重建但可能绑定
历史任务，均未删除。以后最多保留一个活动验证镜像；候选提交与 exact-head 证据形成后，
必须按 archive → verify → V2 restore → transaction prune 顺序清理，禁止通配或手工删除。

## 保护边界

- 仓库根必须由 `git rev-parse --show-toplevel` 动态解析。
- 实现写入只发生在活动 Git worktree；`E:\UE` 仅作只读参考。
- Base 原始策划案不得减少信息或更名；Base 素材按内容去重，但保留项和 alias
  必须可解释。
- UI/表现不得拥有或猜测地图真值、掉落、伤害、经济、保存、结算或状态机权威。
- `project.godot`、scene/resource、`.uid`、`.translation`、import metadata
  和运行时二进制只有在专门门允许时才能暂存。

## 审计与关闭门

- 工程质量标准：`docs/20_product/I4_ENGINEERING_QUALITY_AND_ACCEPTANCE_STANDARD.md`。
- 页面/工作区/卡片/紧凑控件边框 16/8/4/2、最多两层完整框和信息无损门。
- 当前生产内容普查、布局等价证明、12 组真实捕获和逐原图人工记录。
- 地图两表面 15 状态、全房型 obstacle descriptor/通行扫描、协议五等级极值、
  左下 0/1/3/4/满包和全 item ID 五消费者纹理/品质门。
- 候选提交的 exact-head/full 与 Git 远端一致性由本次最终交付记录提供。
- 真实键鼠/手柄、控制器、音频设备、减少动态、完整玩家与动态视觉签收。
- 目标 GPU/FPS、内存和长局稳定性。
- 平台导出、打包、商店和 release gate。

上述 I4 契约门全部满足前，I4 必须保持 `ACTIVE`；不得由旧 I3R full、截图生成、
V2 恢复证明或空间回收结果推导为阶段关闭，也不得自动启动新内容、ART22 或其他后继阶段。
