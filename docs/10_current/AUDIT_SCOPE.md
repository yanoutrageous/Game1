# Audit Scope

文档状态：I3 关闭完成审计范围。
最后更新：2026-07-23

## 已纳入并完成审计

- 独立 I3 worktree 的 Git 身份、差异、污染、保护路径、全量 worktree 门和交付条件。
- 用户对主菜单、出发探索、长期系统、局内、特殊房、撤离和结果的全部反馈处置。
- 地图/小地图共享语义、KnownMap 防泄漏、搜索/箱子/地面物反馈、HUD/协议、背包/
  物品、输入、角色表现、战斗/特殊房、撤离和结果叙事。
- 生产 main.tscn 的公开输入连续路线：三条 runner 各自 headless/rendered PASS，
  共 47 张 1280×720 PNG 和 6 组 JSON/CSV。
- 主菜单空间转场、Deploy 同页双栏、长期研究前置链投影与主音量设置真实效果。
- 同机冻结战斗 workload 五轮分布，以及 enemy1 低基数残余的非隐藏登记。
- sources.zip 的 25 份原始策划与 1407 个 art/draw member；原名/原字节、SHA 去重、
  395 个 alias、保留理由、关系与 runtime admission 边界。
- 最终 worktree full 75/75 PASS、报告绑定和首次失败补救链。

## 证据优先级

1. 当前 Godot 代码、权威快照、真实消费者和可复现生产运行；
2. 当前自动化、公开输入旅程、渲染、人工检查、性能与失败恢复证据；
3. I3 契约、切片台账、反馈处置矩阵与 Base manifests；
4. 原始策划案的设计意图及版本关系；
5. UE/Lua/历史截图与报告的有边界参考。

用户观察必须逐项处理，但不能覆盖仓库事实。UE 参考不能覆盖 Godot 的 KnownMap、
GroundLoot、保存、结算、fixed tick 和容量替换权威。

## 保护边界

- 仓库根由 git rev-parse --show-toplevel 动态解析。
- E:\UE 只读；主工作树和 UE 的用户既有 dirty 不属于 I3 暂存对象。
- Base 原始策划不复制到 repo docs；Base art 保持 not_admitted。
- project.godot、scene/resource、.uid、.translation、import metadata 和运行时二进制
  只有在专门门允许时才能修改或暂存。
- UI/表现不得拥有或猜测地图真值、掉落、伤害、经济、保存、结算或状态机权威。

## 未包含或仍为 notes

- 最终跨页面审美、统一视觉 token、角色动画/时装、音频和整体交互手感。
- 目标设备 GPU/FPS、完整键鼠/手柄人工旅程、长局、内存和发布性能。
- 退出时 18 个生产 RefCounted/GDScript 资源仍在使用的生命周期债务。
- 批量售卖、完整天赋规则、跨进程 active-run 恢复、完整经济与更深内容。
- 平台认证、导出、商店与 release gate。

## 关闭与交付口径

- I3.0–I3.7 的详细门与反馈处置分别由 ledger 和 matrix 冻结。
- I3 状态为 CLOSED / PASS_WITH_NOTES，是最新闭合非美术基线。
- worktree full 为 75/75 PASS；报告 SHA-256 为
  5E07C1FDA64391738ABAC8ABDFA2E71AFE398F88EF1C4DF0F567FECEF710D34D。
- exact-head/full 与 push 后远端 SHA 一致是外部交付门。最终交付记录必须证明两者；
  任一失败都使关闭无效并重新打开 I3.7。
- 当前没有 active stage，也没有自动授权的后继阶段。项目级 latest art 仍为 ART21。
