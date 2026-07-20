# I1 Incremental Development Baseline Contract

文档状态：当前 I1 实施契约；worktree acceptance 已通过，committed HEAD 与交付待完成。
阶段：`I1`
最后更新：2026-07-20

## 1. 中文摘要

I1 的目标不是再次声明“全面重写”，而是把当前已经可玩的程序、页面与内容整理成可持续增量开发的基线：任何后续程序、界面、资源或规则修改，都必须能够通过统一命令快速得到隔离的自动化结果、生产场景预览和明确的人工复核入口。

仓库事实支持在 I1 验收后从“核心能力集中开发”转为“新增能力与存量修改并行”。这个判断是有条件的：项目已有 G41、M6、M7 等真实运行闭环，但仍有跨进程局内恢复、完整经济、最终视觉、长时间人工游玩、通用性能、导出与发布等未完成项，因此不是维护期，也不是功能冻结。

## 2. Goal / Non-goals

Goal：建立可重复、可移植、可快速阅览与测试的跨程序、美术、文档及治理基线，并降低后续局部修改的验证成本。

Non-goals：

- 不以 I1 名义补齐所有内容、经济、Boss、音频、平衡或发布能力。
- 不把 headless、静态检查或截图生成扩写为完整人工游玩、最终视觉或交互手感验收。
- 不实现退出 Godot 进程后的 active-run 检查点恢复。
- 不把单一战斗刷新微基准扩写为整机、整局或设备矩阵性能结论。
- 不删除或重写历史 validation、handoff、失败审计和旧阶段证据。

## 3. 范围

| 方面 | I1 范围 | 明确边界 |
| --- | --- | --- |
| 程序职责 | 命令处理拆分、状态机单一写入权、终局提交权、刷新作用域、运行安全 | 不承诺一次性拆完大型 `RunScene` |
| 存档可靠性 | 临时写入、备份恢复、损坏保护、未来 schema 防降级 | 不等于 active-run 跨进程恢复 |
| 战斗性能 | combat scope 轻量刷新与生产场景微基准 | 不等于通用性能验收 |
| UI / 交互 | 生产控件焦点、最小字号、命令反馈、禁用原因、三档分辨率布局契约 | 鼠标手感和动画观感仍需可见人工复核 |
| 动画 / 资源 | 运行时贴图缓存、状态帧、受击可见时间、减弱动效、来源和许可门 | 不声明最终动画、美术或音频完成 |
| 工具链 | I1 隔离 mirror、锁定 Godot、分 profile runner、JSON 报告、污染守卫 | CI 配置存在不等于云端已执行通过 |
| 预览 | 从生产 `main.tscn` 生成九状态、三分辨率 PNG | capture PASS 只证明生成成功 |
| 文档治理 | 当前入口、契约、评估、架构、runbook、validation、handoff、来源与重复台账 | 历史绝对路径只保留为时间点证据 |

## 4. 权威边界

```text
active_repo: git rev-parse --show-toplevel
godot_project: <active_repo>/Godot/GraytailGodot
code_authority: current repository code and runtime behavior
documentation_role: contract, navigation, evidence boundary, and operating instructions
local_engine_observation: E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
portable_engine_resolution: -GodotExe -> I1_GODOT_EXE/GODOT4/GODOT_EXE -> PATH
```

本机路径只是 2026-07-20 的观测和命令示例，不是跨机器默认值。Godot 版本、文件名、大小、SHA-256 和 `--version` 必须由 I1 harness 对照锁定描述复验。

## 5. 架构不变量

1. `RunStateMachine` 是局内 phase 的唯一写入者；兼容入口只能委托状态机。
2. `RunRuntimeController` 负责 runtime 生命周期和终局持久化提交协调；结果 UI 只展示摘要。
3. `RunAssetLedger` 继续是局内物品位置权威；MetaProgress 只消费最终结算快照。
4. 同一 `result_id` 最多提交一次；失败保全确认前不得写局外。
5. 普通重开必须要求确认；debug restart 使用独立命令并受 debug gate 约束。
6. 战斗伤害只发出 combat scope 快照；全量刷新不得成为战斗热路径的默认行为。
7. 保存不得用当前 schema 覆盖未来 schema 的主文件或备份。
8. UI 不得成为 gameplay、结算或持久化的第二权威。
9. `project.godot`、场景、`.uid`、`.translation` 和 import metadata 只有在明确 gate 下才可变更或暂存。

## 6. 验收门

I1 只有同时满足以下条件才能关闭：

1. `tools/i1/validate_static.ps1` 通过，所有发现的 runner / probe 要么注册为 blocking，要么登记为 `EXCLUDED_NON_SLICE`。
2. `preflight`、`quick`、`core`、`ui`、`full` 在 `SourceMode worktree` 下通过，并保留 JSON 报告路径。
3. 提交后 `full` 在 `SourceMode head` 下通过，证明验收对象不是未提交工作树。
4. combat refresh 微基准满足 runner 中的生产场景阈值；结论只限该微基准。
5. 生产预览按需要生成并完成人工图片审查；生成成功不得记为自动视觉 PASS。
6. ART25 资源来源、许可、manifest 和确定性生成门通过；未验证来源不得进入 production。
7. 当前入口链、注册表、索引和未完成清单一致，Markdown/YAML/引用与 UTF-8 门通过。
8. 最终 diff 不含无授权 `.translation`、`.uid`、import metadata、缓存或临时报告。
9. GitHub Actions 只有在远端实际运行成功后，才能从 `configured_unproven` 改为 `proven`。

## 7. 失败与停止条件

- 任一 blocking runner、污染守卫、未来 schema 保护或状态权威检查失败。
- 可见预览存在明显遮挡、越界、不可读或状态错误，却仅凭静态/runner 结果要求关闭。
- 最终文档把未运行项目写成 PASS，或把 ART24R2 的失败历史改写为合格美术基线。
- 未解释的 dirty / staged 状态，或出现无明确 gate 的 Godot metadata 变更。

## 8. 相关文档

- 当前评估：`docs/10_current/I1_BASELINE_ASSESSMENT.md`
- 架构基线：`docs/30_engineering/architecture/I1_ARCHITECTURE_BASELINE.md`
- 操作手册：`docs/30_engineering/godot/I1_DEVELOPMENT_PREVIEW_VALIDATION_RUNBOOK.md`
- 验证记录：`docs/validation/I1_INCREMENTAL_DEVELOPMENT_BASELINE_VALIDATION.md`
- 交接：`docs/handoff/HANDOFF_I1_INCREMENTAL_DEVELOPMENT_BASELINE.md`
