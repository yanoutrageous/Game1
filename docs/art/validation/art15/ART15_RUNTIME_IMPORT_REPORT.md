# ART-15 Slice 2 Runtime Import Report

## 0. 定位

本文档记录 ART-15 Slice 2 的 P0 runtime 小批导入结果。本 Slice 只导入低风险反馈 / 结算标题牌素材并更新 `asset_manifest.csv`，不修改 UI / presentation 代码，不运行 Godot，不 commit / push。

## 1. 导入原则

- 只选择 Slice 1 判定为低风险、可见变化明确、未在 runtime 中重复存在的候选。
- 每个导入文件先检查目标路径不存在，再复制。
- 复制后逐项计算 SHA256，确认 source 与 staged runtime 文件一致。
- 新增 manifest 行保持 `internal_staged` / `staged_pending_review`，不标 `approved`、`final` 或 `runtime_ready`。
- 源目录 `Draw` 与旧 GameJam Draw 只读，不修改、不移动、不重命名。

## 2. 新增 PNG

| asset_id | source_path | godot_path | size | source_sha256 | staged_sha256 | status |
| --- | --- | --- | --- | --- | --- | --- |
| `ui.feedback.bar.dark` | `D:\AGAME1\Draw\30_game_ready\ui_summary_bar\ui_bar_blank_dark.png` | `res://assets/ui/feedback/ui_bar_blank_dark.png` | 418x71 | `DDE95EBD216C273230DE0E2776F445AE97D38B4C370FC2C4765AC24CFC468558` | `DDE95EBD216C273230DE0E2776F445AE97D38B4C370FC2C4765AC24CFC468558` | copied |
| `ui.feedback.bar.red` | `D:\A GAME\26.5.30 GameJam\Draw\20_processed\ui_summary_bar\ui_bar_blank_red.png` | `res://assets/ui/feedback/ui_bar_blank_red.png` | 418x71 | `9BCB1E8E1C1B03E453F668B839ED44A85C61B702E04A1EE8348FB4B90163A22E` | `9BCB1E8E1C1B03E453F668B839ED44A85C61B702E04A1EE8348FB4B90163A22E` | copied |
| `ui.feedback.event_prompt` | `D:\A GAME\26.5.30 GameJam\Draw\20_processed\ui_summary_bar\ui_bar_event_prompt.png` | `res://assets/ui/feedback/ui_bar_event_prompt.png` | 454x162 | `8906431A8F3615D15F824594CECE0BEC3AA9070CEB534885D614D8673C1FF958` | `8906431A8F3615D15F824594CECE0BEC3AA9070CEB534885D614D8673C1FF958` | copied |
| `ui.result.title.extract_confirm` | `D:\AGAME1\Draw\30_game_ready\ui_title_plate\ui_title_extract_confirm.png` | `res://assets/ui/result/ui_title_extract_confirm.png` | 243x150 | `2565A06EE73395F5A5793E7BC3E1B60D67BA6C05952AE81343AB4914F332F6C7` | `2565A06EE73395F5A5793E7BC3E1B60D67BA6C05952AE81343AB4914F332F6C7` | copied |
| `ui.result.title.extraction_success` | `D:\AGAME1\Draw\30_game_ready\ui_title_plate\ui_title_extraction_success.png` | `res://assets/ui/result/ui_title_extraction_success.png` | 260x147 | `1ABBA3B9687D6B5EE553CD201FF6D24C2868A8463AC9AACACBE3DD13815A3951` | `1ABBA3B9687D6B5EE553CD201FF6D24C2868A8463AC9AACACBE3DD13815A3951` | copied |
| `ui.result.title.signal_lost` | `D:\AGAME1\Draw\30_game_ready\ui_title_plate\ui_title_signal_lost.png` | `res://assets/ui/result/ui_title_signal_lost.png` | 240x150 | `05346CDB918B7956130B95532F5B98EC86E9A4FEE792E36176AC5BCC50F67643` | `05346CDB918B7956130B95532F5B98EC86E9A4FEE792E36176AC5BCC50F67643` | copied |

## 3. Manifest 更新

| metric | value |
| --- | ---: |
| manifest rows before Slice 2 | 79 |
| manifest rows added | 6 |
| expected manifest rows after Slice 2 | 85 |
| duplicated new asset_id | 0 |
| missing new godot_path | 0 |

新增分类：
- `ui_feedback`：feedback bar / event prompt。
- `ui_result`：result title plate。

新增状态：
- `source_status=staged_pending_review`
- `license_status=internal_staged`
- `replacement_needed=true`

## 4. 未导入项

| candidate | reason |
| --- | --- |
| `ui_scrollbar\ui_scrollbar_vertical.png` | 对核心视觉变化优先级较低，defer |
| 角色 walk frames / sheets | 需要 sprite animation mapping，避免 Slice 2 扩大 blast radius |
| Base 确定稿 / M1 / ART-13 截图 | reference_only，不导入 |
| `debug_detected_boxes.png` | debug 检测图，禁止导入 |
| `Art.zip` | 本阶段禁止解压 |

## 5. 后续 Slice 3 接线建议

- `ui.feedback.bar.dark`：HUD neutral feedback、Inventory/GroundLoot neutral command result fallback。
- `ui.feedback.bar.red`：capacity blocked、warning、danger feedback fallback。
- `ui.feedback.event_prompt`：search result、event choice prompt、room interaction prompt。
- `ui.result.title.extract_confirm`：extract confirmation modal title plate。
- `ui.result.title.extraction_success`：settlement success banner。
- `ui.result.title.signal_lost`：failed / signal lost result banner。

## 6. 自检结论

Slice 2 导入完成后应满足：
- 新增 PNG 数量：6。
- manifest 新增行数：6。
- 新增 `asset_id` 唯一。
- 新增 `godot_path` 文件存在。
- 没有外部 runtime hardcode。
- 未修改 core/run、core/command、core/save。

