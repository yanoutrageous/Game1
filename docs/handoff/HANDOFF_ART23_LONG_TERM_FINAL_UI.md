# ART23 长期系统最终美术 UI 交接

## 交付状态

ART23 已完成 6 个一级模块、27 个二级页面、固定角色档案、家具式模块切换、档案室收起/展开、键盘焦点链和环境/角色动效。Computer Use 最终验收为 27/27 PASS，五档分辨率矩阵为 135/135 PASS。

## 打开与复验

- Godot 项目：`D:\AGAME1\active\Game1_art23\Godot\GraytailGodot\project.godot`
- 启动场景：`res://scenes/main/main.tscn`
- 主菜单入口：“长期系统”
- 总验证：`powershell -ExecutionPolicy Bypass -File tools/validate_art23_long_term_final_ui.ps1 -GodotPath D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe`
- 运行时契约：`res://tests/art23_long_term_runtime_runner.gd`
- 主线入口契约：`res://tests/art23_long_term_main_route_runner.gd`

## 可维护边界

- 内容定义集中在 `long_term_content_framework.gd`，一级/二级页签和卡片文案不应散落到场景节点。
- 版式尺寸集中在 `long_term_layout_contract.gd`；后续修改优先调整契约，不直接在运行时节点中堆叠魔法数。
- 视觉资源通过 `art23_long_term_asset_contract.gd` 和 `asset_manifest.csv` 解析；不要恢复对生成 sidecar 的依赖。
- 模块家具按加载组拆分，默认资源与六个模块家具分开；新增模块资产需同步 manifest、合同和解码预算报告。
- 正文使用 Noto Sans CJK SC Regular；FusionPixel 保留在短按钮、页签和短卡片标签。不得再次把整页正文改成像素字体。
- 研究与抽奖当前是诚实的只读/锁定表现；在程序系统真正提供数据和写入接口之前，不得用 UI 伪造解锁、抽取或保存成功。

## 证据索引

- 冻结标准：`docs/validation/ART23_LONG_TERM_FINAL_UI_ACCEPTANCE.md`
- 最终记录：`docs/validation/ART23_LONG_TERM_FINAL_UI_VALIDATION.md`
- 审计与两轮优化：`docs/art/validation/art23/ART23_INITIAL_AUDIT_AND_OPTIMIZATION.md`
- 动效审计：`docs/art/validation/art23/ART23_LONG_TERM_MOTION_AUDIT.md`
- 五档联系表：`docs/art/validation/art23/matrix_contact_sheets/`
- 原尺寸代表图：`docs/art/validation/art23/screenshots/final_representative/`
- 图像生成统一房间源：`docs/art/validation/art23/sources/long_term_room_unified_source.png`

## 已知非缺陷

- 当前页面显示真实可用投影或明确的“未发现/封存/未登记”状态，不包含尚未实现的完整长期玩法逻辑。
- 顶部研究、抽奖保持锁定语义但可进入只读说明页，这是当前代码事实对应的 MVP 美术状态。
- 联系表用于版式审计，不替代实际 Godot 交互和 Computer Use 验收。
