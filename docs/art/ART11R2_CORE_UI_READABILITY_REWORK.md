# ART-11R2 核心 UI 可读性、字体层级、背景层与文字边界返工

## 0. 文档定位

ART-11R2 是 ART-11 后的返工修正阶段，目标是解决实际运行复查中暴露的可读性问题：字体大小、行高、文字边界、文字重叠、冗余说明、背景遮罩和 HUD 信息密度。

本文档记录执行结果和验证证据，不代表最终美术皮肤、最终角色立绘、完整动画或 ART-12 polish 已完成。

## 1. 基线问题

Slice 0 使用真实 Godot 项目运行并对照 Base 确定稿、M1 / Lua demo 和 ART-11 截图。主要问题如下：

- 主菜单中部说明和公告文字偏密，左侧 hero 区仍像占位块。
- 出发探索右侧摘要、装备槽和说明文字互相抢层级。
- 长期系统右栏是连续段落，卡片主要信息依赖截断。
- HUD 左扫描器、右协议栏和底部 key bar 信息密度高，`Player` 标签像调试文本。
- 复杂背景上缺少稳定遮罩，1280x720 下最容易暴露问题。

## 2. 字体层级与文本预算

Slice 1 扩展了 ART-10R Skin Kit 中的字体和文本规则：

- 字体 token：`page_title`、`section_title`、`body`、`body_small`、`caption`、`button`、`key_prompt`、`hud`、`hud_small`。
- 文本预算：`short_summary()`、`budgeted_lines_text()`、`readable_section_text()`。
- 行高与边界：`font_line_height()`、`label_safe_padding()`、layout profile 中的 `text_safe_padding` 与 `panel_inner_padding`。
- 默认策略：主界面显示短标题、短状态、短标签；长解释放入 tooltip / 文档 / 后续详情页。

## 3. 主菜单修正

Slice 2 对主菜单做可读性返工：

- 压缩中部说明和底部公告。
- 强化左侧 hero / 角色展示区的遮罩和剪影层。
- 顶部小入口统一图标 token，避免大图标撑爆按钮。
- 右侧入口继续保留大按钮体量，减少周边说明干扰。
- 背景语义仍是程序化基地门厅近似，不是最终美术稿。

## 4. 出发探索修正

Slice 2 对出发探索做页面级降噪：

- 右侧摘要拆成摘要、配置、效果、风险四个短模块。
- 中间路线卡片只保留名称和状态。
- 左侧整备说明压缩为短状态，保留装备 / 消耗品槽。
- 顶部 tab 尺寸统一，底部“开始探索”强化为主行动焦点。
- 右侧装备区仍需最终素材支持，但 1280 下不再是连续长段落。

## 5. 长期系统修正

Slice 3 对长期系统做可读性返工：

- 增加 archive wall、profile mask、detail mask，强化档案室 / 图鉴墙语义。
- 左栏改为角色档案、记录、战绩短块。
- 中间卡片改为 marker、标题、状态 badge，不再承载长说明。
- 右栏拆为状态、说明、解锁、联动短模块。
- 仍保留现有数据源标题，最终内容文案和图标素材留到后续阶段。

## 6. HUD / Runtime UI 修正

Slice 3 和 Slice 4 对 HUD 做压缩：

- 左扫描器固定短图例，MiniMap 提示从长句改为短提示。
- 中央顶部房间说明走短摘要。
- 右侧收为威胁、事件、奖励块。
- bottom key bar 固定按钮宽度，`Space` 缩短为 `Spc`，降低拥挤。
- 未修改 `scenes/player/player.tscn`，通过 UI 层遮罩和“回收员”标签覆盖 `Player` 调试文本。
- 对中央黄色房间提示增加轻量暗化遮罩，降低其与顶部信息条的竞争。

## 7. 背景层与遮罩

ART-11R2 没有导入新素材，也没有把 Base 确定稿整屏图作为 runtime UI。背景层处理方式为：

- 主菜单：程序化基地门厅遮罩和 hero 区。
- 出发探索：控制台 / 整备区遮罩与摘要模块。
- 长期系统：档案墙、栏位遮罩和详情模块。
- HUD：扫描器、房间顶部、右侧状态块、玩家标签和房间提示遮罩。

遮罩目标是保障文字可读，不代表最终背景美术完成。

## 8. 截图 QA

最终截图位于 `docs/art/validation/art11r2/`：

| 分辨率 | 主菜单 | 出发探索 | 长期系统 | HUD |
| --- | --- | --- | --- | --- |
| 1280x720 | `art11r2_main_menu_1280x720.png` | `art11r2_deploy_prep_1280x720.png` | `art11r2_long_term_1280x720.png` | `art11r2_run_hud_1280x720.png` |
| 1600x900 | `art11r2_main_menu_1600x900.png` | `art11r2_deploy_prep_1600x900.png` | `art11r2_long_term_1600x900.png` | `art11r2_run_hud_1600x900.png` |
| 1920x1080 | `art11r2_main_menu_1920x1080.png` | `art11r2_deploy_prep_1920x1080.png` | `art11r2_long_term_1920x1080.png` | `art11r2_run_hud_1920x1080.png` |

1280x720 是最严口径。当前目标是无阻断级文字重叠、主要按钮不越界、主要文本不靠省略号维持布局。

## 8.1 Final Slice 交互态修复

Final Slice 实机复核时发现，进入 HUD 后触发搜索 / 交互状态时，legacy HUD 状态栏仍会把运行快照中的工程诊断字段直出到玩家界面，表现为 `Rule/Modifier`、`display_only`、`ContentPool`、`read_only`、`RoomPolicy`、`fast_return`、`SettlementTriggerPreview` 等工程语义和大块文字遮挡。

本轮追加了一个最小 UI 层 hotfix：

- 修改 `scripts/ui/hud/hud_view_model.gd`，把 legacy HUD 状态栏压缩为生命、背包、位置、房间、雷险、搜索状态等短玩家信息。
- 移除 legacy HUD 中面向接口诊断的 snapshot 拼接，不再把 run lifecycle、room policy、content pool、settlement trigger 等内部字段作为玩家常驻文案。
- 对 legacy HUD 最新记录和提示增加短文本预算与工程词替换，保留信息来源为公开 snapshot，不读取或修改 TruthMap / RunContext / CommandBus 语义。

补充验证截图：

- `final_self_check_run_hud_after_hotfix.png`
- `final_self_check_run_hud_interaction_after_hotfix.png`
- `final_self_check_run_hud_interaction_after_hotfix3.png`

交互态复核结论：阻断级工程词直出已移除；HUD 交互态仍不是最终美术皮肤，但不再出现大块接口诊断文案遮挡。

Hotfix 3 补充修复 `scripts/ui/shell/run_ui_view_model.gd` 的操作反馈出口：`command_result_text()` 不再把 `message_key`、命令 key 或未知 reason code 拼进玩家文案，未知阻断统一降级为短玩家语句。该修复只处理 UI / presentation 文案，不修改 run / command / save 语义。

## 9. 验证脚本

新增脚本：

```text
tools/validate_art11r2_ui_readability.ps1
```

脚本检查：

- ART11R2 文档存在。
- 12 张最终截图和 hotfix 交互态补充截图存在且非空。
- dirty 路径只属于 UI / presentation / docs / tools 或 generated side effects。
- `asset_manifest.csv`、core run / command / save 没有被纳入 ART-11R2 成果。
- 不存在 `expand_icon = true`。
- 不存在直接从 Base Art / Draw / Connection runtime 读取的硬编码路径。
- legacy HUD 不再包含旧的 run lifecycle / room policy / content pool / settlement trigger 诊断拼接。
- run UI 操作反馈不再把 `message_key` 或内部 reason code 作为玩家文案出口。
- 工程词直出风险以 warning 形式提示人工复核。

## 10. Generated Side Effects 策略

当前工作区仍有 Godot 运行产生的 side effects，例如：

- `project.godot`
- `asset_manifest.*.translation`
- `*.gd.uid`
- `.import` / `.godot`

这些文件不属于 ART-11R2 成果。执行框不清理、不 stage、不 commit；后续审查 / 验收框需继续隔离处理。

## 11. 暂缓内容

- 最终角色立绘、最终背景图、完整动画。
- 真正最终发布级视觉 polish。
- 新素材导入和 manifest-backed runtime 素材补齐。
- 完整长期系统玩法。
- 完整 inventory / loot 产品化细节。
- ART-12 视觉 QA 后续修正。

## 12. 后续进入 ART-12 条件

进入 ART-12 前应完成：

- ART-11R2 审查验收通过。
- 1280x720 下核心页面无阻断级文字重叠或主按钮越界。
- generated side effects 已由审查 / 验收框明确隔离。
- ART-12 范围明确为第二轮 polish、最终视觉 QA 修正或新素材补齐，不回退为系统底座重建。
