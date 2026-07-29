# Current State

文档状态：I4 活动阶段事实。

最后更新：2026-07-30

```text
current_stage=I4 / ACTIVE / PLAN_AUDIT
entry_commit=4127bd27a05b75cb5e3071cf6dc87d9287f679a9
entry_tree=e1455ffd8c7a754c63eb2141a47e41f8fe5cdf3a
branch=codex/i4-production-interaction-convergence
remote_main_at_entry=4127bd27a05b75cb5e3071cf6dc87d9287f679a9
godot=4.6.3.stable.official.7d41c59c4
```

## 当前判断

项目已经具备真实生产主菜单、Deploy、局内、结果、仓库交易和长期系统，但当前玩家
任务仍被页面覆盖导向、重复详情/确认、固定摘要、信息错栏和实例逐行显示拖长。
I4 不新增内容，而是把这些已有功能整理为可理解、可撤销、一次提交和可复现的闭环。

当前实现事实：

- 普通 Deploy 工作区为左 248、间隔 12、右 372；地图为 198/424。
- 右侧摘要固定四行，超出内容被截断。
- 金币在 Deploy 所有页面常驻。
- 购买接口一次创建一个实例；批量出售已有原子实例集合接口。
- 携带和局内账本已经保留多个精确实例，允许在展示层安全聚合。
- display/readable 字体角色当前返回同一 FusionPixel 栈，并统一关闭 AA/subpixel。
- debug gate 和 RunScene 调试命令存在，但 `debug_used` 标记本身不能证明默认档零污染。
- 长期系统当前生产口径是 6 模块、25 页面、58 运行资产。

## I4 当前进度

| Gate | 状态 |
| --- | --- |
| I4.0 计划审计与入口冻结 | `IMPLEMENTING` |
| I4.1 正式档隔离与测试场 | `PRECHECK` |
| I4.2 诊断与可复现场景 | `PRECHECK` |
| I4.3 数量与原子交易 | `PRECHECK` |
| I4.4 Deploy 交互 | `PRECHECK` |
| I4.5 局内聚合 | `PRECHECK` |
| I4.6 长期导航 | `PRECHECK` |
| I4.7 字体与输入表现 | `PRECHECK` |
| I4.8 终验与交付 | `NOT_STARTED` |

## 入口审计事实

- 本地与远端 `main` 在入口时均为 `4127bd2`，ahead/behind 为 0/0。
- 入口前已有 `project.godot` 换行物化和 7 个 Godot 生成 `.translation` 修改；
  已保存到 stash `pre-i4 generated Godot metadata 2026-07-30`，未并入 I4。
- 首次 I3R exact-head/full 在 Base overlay 前置门失败。
- 失败根因是 Windows `core.autocrlf=true` 将三份 CSV 物化为 CRLF，而生成器输出 LF；
  文本行完全一致。
- I4.0 已修改验证器，只归一化 CRLF/LF；真实字段变化仍产生 `OVERLAY_DRIFT`，
  并新增单元测试。

## 历史边界

I3R 的机器矩阵和静态复核仍是历史有效证据，但用户通过实际生产截图提出的字体、
遮挡、信息层级、数量交互和操作链问题证明外部体验门未通过。I4 明确接管这些开放项。

I2 仍是最新已经生效的闭合非美术基线；I4 关闭和远端证明完成前不得提升这一权威。
ART21 仍是项目级最新闭合美术阶段。

## 当前未完成

- I4 sandbox profile、taint 结算门、测试场和诊断面板。
- 原子 N 件购买和共享数量投影。
- Deploy 两行卡片、等分工作区、滚动摘要和上下文金币。
- 局内重复物品聚合。
- 长期通知直达与页面历史。
- 字体角色拆分和几何矩阵。
- worktree/full、exact-head/full、真实设备/动态复核、完成审计与 push。
