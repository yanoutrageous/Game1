# I4 执行台账

文档状态：`ACTIVE`

总契约：`docs/20_product/I4_PRODUCTION_INTERACTION_CONVERGENCE_CONTRACT.md`

入口：`4127bd27a05b75cb5e3071cf6dc87d9287f679a9` /
tree `e1455ffd8c7a754c63eb2141a47e41f8fe5cdf3a`

## 状态规则

每个切片按 `PRECHECK → IMPLEMENTING → TARGETED_PASS → PRODUCTION_PASS → ACCEPTED`
前进。自动 PASS、截图生成和单个 runner 均不能替代生产旅程与动态验收。

| Gate | 状态 | 当前事实 | 剩余门 |
| --- | --- | --- | --- |
| I4.0 | `IMPLEMENTING` | 用户已明确授权 I4 全过程和 push；远端 `main` 与入口 HEAD 一致；入口 Godot metadata 已保存至 stash；发现并修复 Base overlay 的 Windows CRLF 假漂移，单元测试证明真实内容变化仍 fail closed | 契约/矩阵/当前入口更新；入口特征门 |
| I4.1 | `PRECHECK` | 现有 profile save path、debug gate 和 RunScene 调试命令可复用；现状仅记录 `debug_used`，不能证明默认档零污染 | sandbox profile、taint 结算门、设置入口、哈希证据 |
| I4.2 | `PRECHECK` | 已有 RunScene debug panel controller 和多个命令；尚未形成读写分区、场景目录和失败包 | 面板、场景、失败证据、生产连接 |
| I4.3 | `PRECHECK` | 出售已有实例级原子 batch；购买仍是单实例函数；携带上限为 3 个消耗品实例 | 原子 N 件购买、统一数量草稿、幂等/回滚测试 |
| I4.4 | `PRECHECK` | 普通 Deploy 为 248/372；摘要固定四行；金币全页常驻；卡片为整张 Button | 两行卡、310/310、滚动摘要、上下文金币、焦点门 |
| I4.5 | `PRECHECK` | 局内底层已保留精确实例；重复物品主要按实例逐行展示 | 聚合投影、单实例使用/丢弃、结算回归 |
| I4.6 | `PRECHECK` | 当前长期系统为 6 模块/25 页面；已有三级 Esc 旅程 | 通知直达、未读清除语义、页面历史与状态保持 |
| I4.7 | `PRECHECK` | display/readable 角色当前返回同一 FusionPixel 栈且统一关闭 AA/subpixel | 字体角色拆分、安全区、几何、分辨率/缩放矩阵 |
| I4.8 | `NOT_STARTED` | 未运行 I4 最终门 | 重复旅程、设备/动态、worktree/exact-head、审计、push |

## I4.0 入口审计记录

```text
remote_main=4127bd27a05b75cb5e3071cf6dc87d9287f679a9
local_entry=4127bd27a05b75cb5e3071cf6dc87d9287f679a9
ahead_behind=0/0
preexisting_dirty=project.godot line-ending materialization + 7 generated .translation files
preservation=stash "pre-i4 generated Godot metadata 2026-07-30"
entry_exact_head_attempt=FAIL
failure=I3R Base overlay byte comparison treated CRLF checkout as semantic drift
disposition=I4.0 cross-platform verifier repair; semantic field drift remains blocking
```

## 证据登记规则

每项证据必须记录：

- commit/tree；
- source mode；
- Godot 版本；
- profile/scenario/seed；
- 输入类型与输入序列；
- 保存 profile 与前后语义哈希；
- 报告/截图/日志路径；
- 自动、静态人工、动态人工、设备和性能边界。

未执行项目保持 `NOT_RUN`，不得根据相邻门推断通过。
