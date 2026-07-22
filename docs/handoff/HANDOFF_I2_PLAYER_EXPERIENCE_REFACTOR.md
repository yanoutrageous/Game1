# I2 Player-experience Refactor Handoff

文档状态：`CLOSED / PASS_WITH_NOTES`。
最后更新：2026-07-22

## 1. 交接结论

I2 将既有 Godot 工程能力按获批范围转换为可复核的玩家体验增量，并保持 I1 的领域、保存与结算权威。I2 是单一阶段；I2.0–I2.7 是已结束的内部风险门。I2 关闭不自动授权 I3、发布、导出或任何新的功能范围。

运行时实现 commit 为 `c500bdb8b931fada26f4f617a3feaad643281b4c`，tree 为 `7b04e81882961f65a516e192c33093ec98162667`。quick/worktree 48/48、ui/worktree 49/49 与 full/worktree 67/67 已通过；full/worktree 报告为 `E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260722T113228922Z_4f00a3b8\report.json`，SHA256 `A6F7978C038EFC6F5FFCA9FA058A0DA161AA28B12DD0B589F87354E126FABCAB`。关闭文档无法自指其最终 commit；最终交付必须报告 exact full/head、远端分支与 push 结果，未通过不得推送为闭合基线。

## 2. 已交付的获批范围

- 真实设置、共享 focus/modal、reduced-motion 与玩家可见失败反馈基础。
- 主菜单文字/锚点安全回退和可取消的导航表现边界；Deploy 地图仍保持同一页双栏，八个既有地图 ID 未变。
- Deploy 的选择/详情/摘要、局外权威金币、真实单件交易与回执；长期任务档案、模块工作区和角色表现端口。
- 局内世界对象投影、箱/门/地面物 proximity 信息、品质冗余、动态快捷背包、公开地图/邻雷数、协议、tooltip 和统一 Esc/modal。
- 战斗房显式撤离确认、特殊房“发现→意图→结果→离开”旅程、撤离摘要、雷房反馈，以及成功/失败/放弃/保存失败结果解释与恢复。

上述范围只代表已验证行为和信息表达，不代表最终审美、完整动画手感、绝对 FPS 改善、长时人工游玩、最终音频、设备矩阵、导出或发布通过。

## 3. 必须继承的权威

- `RunStateMachine` 是局内 phase 唯一写入者；UI、动画、转场和 tooltip 不写领域状态。
- `RunAssetLedger` 是局内物品位置权威；proximity/hover/focus 只能展示或候选焦点，不能自动拾取、搜索、替换或改库存。
- `RunRuntimeController`/meta adapter 负责 terminal settlement 的单次提交；结果页不能计算奖励或成为第二保存权威。
- `SaveAdapter` 的原子写入、备份、未来 schema 保护和失败回滚不得降级；pending failure salvage 确认前不写局外。
- 同一 `result_id` 不重复提交；retry 必须重用同一 terminal/finalized snapshot，不能重发结果信号或重复奖励。

## 4. 最短运行与复核顺序

先从活动仓库根目录解析路径，再按下面顺序执行。`E:\Godot` 是本机观测路径；跨机器仍按 runner 的解析与 identity check 规则处理。

```powershell
$repo = git rev-parse --show-toplevel
$godot = 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
Set-Location $repo
```

1. 生产预览与三分辨率 capture：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1_preview.ps1 -All -GodotExe $godot
```

2. I2.6 定向运行时/结算复核：

```powershell
& $godot --headless --path "$repo\Godot\GraytailGodot" --script res://tests/i2_combat_room_experience_runner.gd
& $godot --headless --path "$repo\Godot\GraytailGodot" --script res://tests/i2_special_room_player_experience_runner.gd
& $godot --headless --path "$repo\Godot\GraytailGodot" --script res://tests/i2_terminal_result_authority_runner.gd
& $godot --headless --path "$repo\Godot\GraytailGodot" --script res://tests/i2_terminal_commit_recovery_runner.gd
```

3. 工作树回归：普通修改至少 `quick`；UI/交互修改还跑 `ui`；跨层或关闭候选跑 `full`。

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 -Profile quick -SourceMode worktree -GodotExe $godot
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 -Profile ui -SourceMode worktree -GodotExe $godot
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 -Profile full -SourceMode worktree -GodotExe $godot
```

4. 仅在提交后，针对 exact HEAD 跑最终 full：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 -Profile full -SourceMode head -GodotExe $godot
```

capture、headless、动态人工、性能、CI、导出和发布是不同证据。任何一项成功均不能替代另一项。

## 5. 玩家操作复核

| 场景 | 正确操作与预期 |
| --- | --- |
| 战斗房撤离 | 接近离开边界不会自动逃离、扣费或过门。使用当前明确的撤离意图（键盘 `T` 或鼠标确认入口）后才显示确认；取消保持原房间和领域状态，确认只发一次逃离/过门请求。 |
| Event / Exit | 必须先进入 proximity 才显示对应的玩家信息与可行动作；不得通过旧 RunSurface 工程按钮绕过距离条件。Event 选择显示结构化结果；Exit 靠近显示基于权威快照的未结算摘要，且与实体提示互斥。 |
| 箱子 / 地面物 | 首次打开后直接显示箱内真实物品；重访已开箱仅在靠近时展示内容，不能二次发奖。地面物靠近只显示候选物，拾取必须有显式意图，满包/替换失败不得改 ledger。 |
| 背包详情 | 鼠标 hover 与键盘/手柄 focus 都显示同一只读详情；移动、使用、丢弃等领域动作必须通过明确操作发出，tooltip 不能遮住当前模态的主要动作。 |
| Esc / 模态 | Esc 只关闭当前最高优先级层；暂停、设置、地图、详情和放弃确认按栈顶顺序返回，并恢复先前焦点。放弃必须经过破坏性确认，取消不改变 run。 |
| 保存失败结果 | 结果页显示“尚未保存”而非伪称成功；“重试保存”重放同一快照，成功后允许正常离开，重复重试保持幂等。若必须离开未保存结果，使用两次明确的放弃未保存结果确认，且界面不把它写成已保存。 |

## 6. 明确延期与重新开启门

| 延期项 | owner | 重新开启门 |
| --- | --- | --- |
| 最终角色动画/时装替换 | 美术/动画管线 | 获批离线/逐帧方案、真实替换夹具、reduced-motion、动态人工与性能门 |
| 空间叙事转场 | 产品 UX / 导航表现 | 洞口/下层原型、取消/失败回退、输入焦点和动态可见验收 |
| 批量出售 | 经济/产品规则 | 价格、确认、原子性、幂等、保存失败回滚与真实命令契约 |
| 真实天赋树 | 成长系统产品 | 点数、成本、依赖、节点效果、重置/返还、持久化权威 |
| 最终角色移动手感 | 角色表现 / UX QA | 动态启停/转向/受击人工验收与最终素材门 |
| 跨页最终视觉风格 | UI 美术系统 | 获批视觉方向、资产门、跨页动态人工复核 |
| 战斗房绝对性能 | 性能/战斗体验 | 同机设备/GPU/长时 workload 与玩家可见掉帧验收；现有 A/B/A 只能证明无系统性相对代码退化 |
| 整合键鼠/手柄 UX | UX QA | 跨页面输入、长文本/DPI、焦点、reduced-motion 和动态人工路径 |
| 长时人工游玩 | QA / 产品 | 多终局、返回/恢复、稳定性与玩家理解的独立长局回归 |

## 7. 资产与 UE 边界

Godot 是唯一实现和运行时目标。I2 复用已治理 Godot 资产；UE 仅用于只读的交互、信息层级和视觉语义参考。不得复制 UE 架构、Tick/UI 组织、烤字固定布局或 `.uasset`；不得未经 source/license/hash/import/runtime-key gate 导入外部资产。运行时骨骼自动生成不是本次获批方案，区域→难度分步页也不允许替代 Deploy 的同页地图/难度结构。

## 8. 回滚与后续授权

I2.6 相关范围的回滚基点为 `0b88f7b`。回滚只能针对明确的故障范围执行，且不得重置或覆盖用户已有工作。任何 I2 后的功能、架构、资产或性能工作都需要新的用户授权、allowed/protected path 清单、characterization、风险相称测试和清晰的 capability 声明。
