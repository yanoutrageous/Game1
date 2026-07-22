# Handoff Docs

文档状态：阶段交接原文入口。
最后更新：2026-07-23

最新闭合交接为 HANDOFF_I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION.md，状态
CLOSED / PASS_WITH_NOTES。当前无 active stage，I3 关闭不自动授权新阶段。

## I3 交接范围

- 玩家感知闭环：局部小地图与公开地图、搜索/箱子/地面物、HUD/物品/输入、战斗与
  特殊房、撤离和结果原因均有真实消费者与回归门。
- 局外体验：主菜单空间转场、出发探索同页双栏、真实主音量设置与研究前置链投影已
  接入；没有杜撰批量售卖、完整天赋或新经济权威。
- 工程基线：RunScene 的模态/调试布局职责迁出并有独立模型门；领域、KnownMap、
  fixed tick、保存、结算与幂等权威保持。
- Base：25 份原始策划保持原名、原字节和完整信息；1407 个 art/draw member 形成
  1012 个 canonical 对象与 395 个可追溯 alias，默认不获准进入运行时。
- 关闭验证：worktree full 75/75 PASS；详细失败补救链、production 旅程、性能与
  cleanup 分类见 I3 validation 原文。

## PASS_WITH_NOTES 边界

未交接为完成的内容包括最终跨页视觉 token、最终角色/动画/音频手感、目标设备 GPU/FPS
和长局、enemy1 低基数性能残余、退出 cleanup 生命周期债务（production 为 18-resource 子集）、批量售卖、真实天赋
规则、跨进程 active-run 恢复、完整深层经济、导出和发布。

ART21 仍是项目级最新闭合美术阶段；ART23 仍只是较晚的页面/UI 范围证据。

## 外部交付条件

handoff 只有在同一候选提交通过 exact-head/full、push 成功且远端 SHA 与本地一致时
生效。提交 SHA 由最终交付记录提供，不在本文预写。任一门失败使 I3 关闭无效，并要求
重新打开 I3.7。

## 使用规则

1. 新 handoff 命名使用 HANDOFF_<stage>_<topic>.md，并至少提供中文摘要。
2. 旧 handoff 保留历史时间点，不因 current chain 更新而重写。
3. handoff 只交接已验证范围，不把 notes 或排除项改写成完成。
4. handoff 不自动授权后继阶段；当前 successor authorization 为 NONE。
