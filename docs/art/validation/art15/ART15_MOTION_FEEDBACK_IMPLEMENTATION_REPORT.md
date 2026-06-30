# ART-15 Slice 5 最小动效与反馈实现报告

## 0. 文档定位

本文记录 ART-15 Slice 5 的最小动效与交互反馈实现。

本切片只处理 UI / presentation 层反馈，不修改 gameplay core、run rules、CommandBus、TruthMap、RunContext 或 save 语义。

## 1. 修改文件

| file | 变更 |
| --- | --- |
| `Godot/GraytailGodot/scripts/presentation/art10_ui_skin_kit.gd` | 新增 reduce-motion 检测、motion fallback 表、统一 feedback pulse 与 panel open helper |
| `Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd` | HUD 命令反馈使用统一 feedback pulse；accepted / warning 状态分别处理 |
| `Godot/GraytailGodot/scripts/ui/inventory/inventory_panel.gd` | 背包打开使用 panel open；使用 / 丢弃结果使用统一 feedback pulse |
| `Godot/GraytailGodot/scripts/ui/ground_loot/ground_loot_panel.gd` | 地面回收物打开使用 panel open；拾取 / 容量阻断结果使用统一 feedback pulse |
| `Godot/GraytailGodot/scripts/ui/result/result_panel.gd` | Result 面板淡入改为 Skin Kit 统一 panel open helper |

## 2. animation_key / fallback

新增最小 motion fallback 表：

| animation_key | fallback |
| --- | --- |
| `feedback_pulse` | `static_state_tint` |
| `panel_open` | `instant_visible` |
| `pickup_feedback` | `static_state_tint` |
| `capacity_blocked` | `warning_tint` |
| `reward_feedback` | `accent_tint` |

`Art10UISkinKit.animation_fallback_key()` 用于读取 fallback。`reduce_motion_enabled()` 在存在项目设置时读取 reduce-motion 配置，否则默认关闭减动。

## 3. 已实现反馈

### HUD 命令反馈

- accepted / ok：使用 `ready` pulse。
- rejected / blocked：使用 `warning` pulse。
- HUD 命令反馈底图继续使用 Slice 3 / Slice 4 的 manifest-backed `feedback_bar_ref()`。
- 不显示内部 command / reason code。

### Inventory

- 背包打开时使用 `panel_open`。
- 使用 / 丢弃命令结果使用 `feedback_pulse`。
- accepted 使用 `ready`，失败 / 容量阻断使用 `warning`。

### GroundLoot

- 地面回收物面板打开时使用 `panel_open`。
- 拾取命令结果使用 `feedback_pulse`。
- 容量不足、操作失败等结果使用 `warning`。

### Result / Settlement

- Result 面板打开改为统一 `panel_open`。
- Result 标题牌仍由 Slice 3 的 `result_title_ref()` 提供 manifest-backed 视觉状态。

## 4. reduce motion 策略

- 默认 motion：短时 alpha / modulate tween。
- reduce motion 开启时：不播放 tween，直接显示静态 tint 或可见状态。
- 本策略优先保证状态辨识，不把动画作为唯一反馈渠道。

## 5. 暂缓内容

- MiniMap selected / danger 的更明显脉冲。
- MapOverlay cell selected 动效。
- reward count-up。
- item pickup transfer path。
- panel close 动效。
- 更完整的 hover / selected / disabled 动效矩阵。

以上内容需要 Computer Use 截图和实际交互路径确认后再扩展，避免在未验证画面密度前增加干扰。

## 6. 静态自检

- `git diff --check`：通过，仅有 CRLF warning。
- 外部路径硬编码扫描：未发现 Base Art / Draw / `D:\AGAME1` runtime hardcode。
- 禁止 core 路径检查：`core/run`、`core/command`、`core/save` 无已跟踪代码 diff。
- Godot headless 启动：退出码 0，未暴露脚本解析错误；退出阶段仍有 Godot 资源释放 warning。

## 7. Slice 5 结论

Slice 5 已完成最小动效与反馈底座：

- 统一 motion helper 已进入 Skin Kit。
- HUD、Inventory、GroundLoot、Result 已接入最小反馈。
- reduce-motion fallback 已显式登记。

后续应进入 Slice 6：Computer Use 最终验收、截图、验证脚本与 ART-15 总文档。
