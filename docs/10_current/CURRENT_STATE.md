# Current State

文档状态：I3 已关闭的当前仓库事实。
最后更新：2026-07-23

## 当前身份

    active_repo: git rev-parse --show-toplevel
    observed_branch: codex/i3-player-experience-calibration
    i3_entry_head: 09aaafe283aa2e4c2f30708c5f88b89ebf7753eb
    i3_entry_tree: a077da34237dce5e4a6081d833efd939098b4641
    current_stage: NONE
    latest_closed_non_art_baseline: I3 / CLOSED / PASS_WITH_NOTES
    latest_closed_art_stage: ART21
    later_scoped_page_ui_evidence: ART23
    successor_authorization: NONE
    godot_project: <active_repo>/Godot/GraytailGodot
    local_godot_observation: E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe

路径和 Godot 工程位置必须动态解析。本机盘符只记录关闭时观测，不是跨机器权威。

## I3 关闭事实

- I3.0–I3.7 是同一阶段。其前审计、实现、定向验收、完成审计和反馈处置分别由总契约、
  切片台账、validation、handoff 与反馈矩阵保存。
- 地图形成 5×5 玩家中心局部小地图与共享公开语义，展开图支持选择/确认分离以及
  Esc、右键和外点关闭，同时保持 KnownMap 防泄漏。
- 箱子形成搜索、揭示、稳定查看与拾取闭环；已开箱再次靠近直接展示；地面物靠近自动
  显示但拾取仍走显式权威命令。
- HUD、背包、世界物品、替换和结果面复用共享物品描述；输入走单一路径，角色表现支持
  appearance/animation-set 替换，减弱动态保留静态可读姿态。
- 战斗补入场、预备、命中、恢复和死亡表现；战斗房离开必须显式确认；特殊房、撤离和
  成功/失败/放弃结果改为玩家可解释信息，保存失败重试保持幂等。
- 主菜单角色真实走入洞口，长期系统转场整体下移；Deploy 地图仍是同页双栏；Settings
  schema v2 的主音量真实应用 AudioServer；长期系统只投影 M7 真实研究前置链，没有
  杜撰 talent 规则。
- RunScene 的模态/调试布局计算迁至独立只读模型，文件由 2687 行/161 函数降至
  2646 行/159 函数；这不是全面解耦声明。

## 生产与 Base 证据

- 三条 production runner 都从生产 main.tscn 开始并使用公开输入，各自 headless 与
  rendered PASS；共 47 张 1280×720 PNG 和 6 组 JSON/CSV，覆盖成功、失败、放弃、
  满包真实替换、保存重试和空间转场。
- 人工以原始分辨率检查 17 张代表图；未见阻断性裁切、模态偏心、对象/弹窗重叠或结果
  原因缺失。该检查不等于最终审美、动画/音频手感或设备矩阵验收。
- 25 份原始策划以原 basename、原字节和原 SHA 进入 sources/base/原始策划案。
- 1407 个 art/draw member 按 SHA-256 保存为 1012 个对象与 395 个 alias，折叠
  79,256,439 bytes；所有 Base art 仍为 not_admitted。

## 验证与性能

    I3_BASE_IMPORT_VERIFY=PASS files=1041 planning=25 art_members=1407 art_unique=1012 aliases=395
    I3_BASE_COMMITTED_VERIFY=PASS files=1041 planning=25 art_members=1407 art_unique=1012 aliases=395
    I3_PRODUCTION_INPUT_JOURNEY=PASS headless_and_rendered
    I3_PRODUCTION_FULL_BAG_REPLACEMENT=PASS headless_and_rendered
    I3_PRODUCTION_TERMINAL_BRANCHES=PASS headless_and_rendered
    I3_FULL_WORKTREE=PASS_75_OF_75
    I3_FULL_WORKTREE_REPORT_SHA256=5E07C1FDA64391738ABAC8ABDFA2E71AFE398F88EF1C4DF0F567FECEF710D34D
    I3_STAGE=CLOSED_PASS_WITH_NOTES

worktree full 中 42 个 runner 为纯 PASS，33 个为 PASS_WITH_CLEANUP_DIAGNOSTIC，
blocking 为 0，时长 785952 ms。首次 quick/full 失败、原因、补救和复验链见 I3
validation 原文。

冻结 headless CPU 五轮中，enemy5 与弹幕峰值主要分位改善或收敛；enemy1 的
p50/p95/p99/max 仍有约 +0.036/+0.099/+0.122/+0.447 ms 的低基数残余。该结果不能替代
目标设备 GPU/FPS、长局或输入手感。

## 明确未完成

- 最终角色动画/时装、跨页视觉 token、音频、动态交互手感和完整键鼠/手柄人工体验。
- 目标设备 GPU/FPS、长局、内存、CI full、导出与发布。
- 退出时 18 个生产 RefCounted/GDScript 资源仍在使用的生命周期 owner 债务。
- 批量售卖、真实天赋规则、跨进程 active-run 恢复、完整深层经济和更深内容。
- RunScene 仍是大型协调器；I3 只关闭已登记的职责迁移，不宣称全面解耦。

## 阶段与交付判断

项目继续处于增量开发与存量修改并行阶段，不是维护期。I3 是最新闭合非美术基线；
ART21 仍是项目级 latest art，ART23 仍是 scoped page/UI evidence。

I3 的关闭以同一候选提交通过 exact-head/full、push 成功且远端 SHA 与本地一致为外部
交付条件。真实提交 SHA 由最终交付记录提供，不在本文预写；任一门失败都使关闭无效并
重新打开 I3.7。当前没有 active stage，也没有自动授权的后继阶段。
