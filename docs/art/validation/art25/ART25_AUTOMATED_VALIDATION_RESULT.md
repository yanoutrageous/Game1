# ART25 自动化验收结果

- 日期：2026-07-20
- 分支：`art/art25-m7-content-inrun-completion`
- 基线：`2e59401fa58a400892d2fcb719e7f3bf0c22709b`
- 冻结标准：`ART25-FINAL-CU-FROZEN-1`
- 结论：自动化保护集通过；最终完成状态仍取决于冻结标准下的 Computer Use 生产态验收。

## 1. 增量内容与资产治理

`python tools/validate_art25_content_and_ui.py`

- `ART25_CONTENT_UI=PASS`
- 运行资产：107 张 PNG，哈希、尺寸、alpha、解码量、visual key、manifest 路径逐项通过。
- 出发页增量：0.721 MiB，小于 0.75 MiB 上限。
- 长期页增量：0.993 MiB，小于 1.25 MiB 上限。
- 内容覆盖：8 张地图、6 个委托、10 个商店条目、42 个物品，以及长期任务、成就、研究、角色、收藏、规则、事件和怪物内容。
- 工作树中没有待提交的 `.import`、`.uid`、`.translation` 副作用文件。

## 2. 生产运行回归

以下命令均使用 `Godot_v4.6.3-stable_win64_console.exe --headless --path Godot/GraytailGodot --script ...`，退出码均为 0：

- `art22_deploy_prep_runtime_runner.gd`：PASS，5 个一级页签、34 个二级状态、4 个摘要页、展开/收起/探索中/取消确认、8 帧角色、10 条环境动效。
- `art22_deploy_prep_main_route_runner.gd`：PASS，`main.tscn` 主菜单到真实出发页路由有效。
- `art23_long_term_runtime_runner.gd`：PASS，6 个一级模块、27 个二级页面、8 帧角色、OPEN/CLOSED/OPENING/CLOSING/SWITCHING 状态有效。
- `art23_long_term_main_route_runner.gd`：PASS，`main.tscn` 主菜单到真实长期页路由有效。
- `art24_in_run_runtime_runner.gd`：PASS，8 个一级模块、61 个二级状态、33 个必须视觉键有效。
- `g41_in_run_core_gameplay_runtime_runner.gd`：PASS，30/60/144Hz 与 hitch 调度、4 类怪物和 G41 v1 视觉契约通过。
- `m7_content_runtime_runner.gd`：PASS，8 张地图、每图 100 个种子、事务和进度回归通过。
- `m7_meta_ui_runtime_runner.gd`：PASS，长期页、出发刷新、售卖确认和地图事实通过。

主路由/锚点探针退出时仍会报告历史性的 Godot `ObjectDB instances leaked at exit` 警告；断言和进程退出码为 0，且本阶段没有增加持久节点或循环加载路径。该警告作为非阻断技术债保留，不伪装成已解决。

## 3. 局内几何与交互状态

- `art24_map_overlay_scene_probe.tscn`：PASS，5 分辨率，overview/selected，控件位于面板内，M 可关闭。
- `art24_inventory_panel_layout_probe.tscn`：PASS，5 分辨率，左栏和底部热键栏均保留。
- `art24_result_panel_scene_probe.tscn`：PASS，5 分辨率，成功、失败空态、待选、已选、容量阻断、失败完成和放弃共 7 类状态。
- `art24_run_surface_layout_probe.gd`：PASS，底栏皮肤和按钮属于 action root。
- `art24_world_context_popup_layout_probe.gd`：PASS，关闭箱和地面物悬浮窗不覆盖目标。
- `art24_context_anchor_integration_probe.gd`：PASS，560 逻辑房间缩放、UI 不随房间缩放、锚点避让有效。

替换物品的当前生产链路是：

`G41WorldContextPopup.replace_requested` → `G41RoomRuntimeView.context_action_requested("replace")` → `RunScene._on_world_context_action_requested` → `replace_ground_item`。

这与“地面实体先出现，靠近后显示悬浮窗，再从悬浮窗操作”的已确认产品逻辑一致。

## 4. 五分辨率全矩阵

使用三个真实 OpenGL 矩阵捕获器串行渲染；捕获器不能加 `--headless`，否则 Godot dummy renderer 没有可读取帧缓冲。完整机械证据写到仓库外 `D:/AGAME1/validation_temp/art25_matrix_serial`，避免把 610 张大图提交到 Git。

| 系统 | 1280×720 | 1366×768 | 1600×900 | 1920×1080 | 2560×1440 | 合计 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| ART22 | 34 | 34 | 34 | 34 | 34 | 170 |
| ART23 | 27 | 27 | 27 | 27 | 27 | 135 |
| ART24 | 61 | 61 | 61 | 61 | 61 | 305 |
| 总计 | 122 | 122 | 122 | 122 | 122 | 610 |

610 张文件均成功解码、零空文件、像素尺寸与目标分辨率一致。ART22/23 各组状态哈希全部唯一。ART24 每组有 59 个唯一哈希；两个重复对符合状态定义：

- `loot_context_hidden_after_leave` 与 `loot_floor_visible` 都是“地面物仍在、悬浮窗不显示”的稳定画面。
- `room_chest_reopened` 与 `room_chest_container_open` 都是“箱子处于已打开稳定态”的画面。

## 5. 旧阶段封存验证器的客观解释

以下旧脚本不能直接作为 ART25 分支的总门禁，但它们暴露的实际运行保护集已由上文逐项补跑：

- `validate_art24_in_run_final_ui.py` 写死旧分支 `art/art24r2-g41-m6-combat-ui`，并要求 `project.godot` 与全局 manifest 零差异；ART25 的受控清屏色和 `ui.art25.*` manifest 增量必然触发旧护栏。
- `validate_m6_real_asset_deploy_settlement_loop.ps1` 内部 M6 与 ART22 运行测试均 PASS，但包装器因 `project.godot` 有 ART25 受控增量而返回 FAIL。
- `validate_art24r1_ue_gameplay_ui.ps1` 仍寻找已经废弃的 `replace_item_requested` 直连；当前生产代码已迁移到上文的世界悬浮窗链路，相关世界悬浮窗、锚点、G41 与 ART24 运行测试全部 PASS。
- `validate_art23_long_term_final_ui.ps1` 在归档报告的 `ui.art23.long_term.decoration.rail` source hash 处失败；实际运行图哈希为 manifest 声明的 `3bfa0c1b...3512`，且该文件相对 ART25 基线无 diff。ART23 真实主路由、27 页运行测试和 135 张五分辨率矩阵全部 PASS，因此不篡改历史归档哈希来制造绿色结果。

## 6. 自动化阶段结论

代码、资产、页面状态、五分辨率和现有 M6/M7/G41 保护集没有发现阻断性回归。历史验证器中的三类 FAIL 均可追溯到旧分支/旧哈希/旧信号名护栏，而非当前生产功能缺失。最终是否完成只能由同一冻结标准下的 Computer Use 生产态审计决定。
