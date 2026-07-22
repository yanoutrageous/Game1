# Active Stage Index

文档状态：NO_ACTIVE_STAGE。
最后更新：2026-07-23

## 当前阶段

| Item | Current fact |
| --- | --- |
| Active stage | NONE |
| Latest closed non-art baseline | I3 / CLOSED / PASS_WITH_NOTES |
| Latest closed art stage | ART21 |
| Later accepted page/UI evidence | ART23 / scoped only |
| Successor authorization | NONE |

I3 已完成范围内审计、实现、生产公开输入、Base、性能、全量 worktree 与收口文档，
关闭为 PASS_WITH_NOTES。I3.0–I3.7 只是该阶段内部门，不是可单独延续的 active stage。

## 外部交付条件

I3 关闭仍以同一候选提交通过 exact-head/full、push 成功且远端 SHA 与本地一致为条件。
这些结果由最终交付记录提供，不在索引预写未知 SHA。任一门失败时，NO_ACTIVE_STAGE
立即失效，必须重新打开 I3.7。

## 后继限制

- I3 关闭不自动授权 I4、ART22 或其他后继阶段。
- ART21 仍是项目级最新闭合美术阶段；ART23 和 I3 UI 改动不提升 art-stage authority。
- 后续工作必须取得用户明确授权，并另建范围、验收、回退和来源门。

## 当前入口

- docs/50_stages/closed/STAGE_INDEX.md
- docs/validation/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_VALIDATION.md
- docs/handoff/HANDOFF_I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION.md
- docs/10_current/CURRENT_STATE.md
- docs/10_current/NEXT_ACTION.md
