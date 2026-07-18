# ART24 局内最终美术 UI 计划

状态：已完成；以交付提交成功推送为生效条件。本文件在任何完成验收之前已冻结范围、文件所有权与验收规则。

## 目标

以当前 Godot 代码、既有真实拾取接口和 ART21—ART23 的视觉语言为准，完成可独立审计、可供程序线程接入的局内美术资产包与 Godot 实机预览。目标画面保持：左侧扫描/状态栏、中央房间、右上紧凑协议牌、底部操作栏；放大地图全屏阻塞，背包和地面物品只覆盖中央游戏区域。

本阶段不伪造玩法语义、持久化、奖励结算或新的拾取规则。程序线程仍拥有生产交互文件；ART24 通过 `visual_key`、快照字段和表现事件预留接口。

## 复用与新制原则

- 复用：现有六类房间底图、宝箱、雷陷阱、异常核心、撤离装置、MiniMap/MapOverlay 图标、Noto Sans CJK 正文字体和已验证的黑铁/深木/暖金/青绿视觉语法。
- 新制：24 帧基础角色动作与 16 帧四方向战斗动作（共 40 帧）、8 帧铁背穴兽图集、8 类世界掉落图集、ART24 专用 HUD/协议/地图/背包/地面物品/结算状态框、拾取与风险反馈帧。
- 不直接挂载概念图；背景、演员、道具、UI、文字和 FX 分层。
- 每个复用项与新制项都登记来源、哈希、语义槽、状态、尺寸、锚点、层级、fallback 与 reduced-motion 结果。

## 固定流程

1. 计划：冻结 8 个一级模块、54 个二级状态、五档分辨率、动作观察和非声明边界。
2. 审计：核对当前代码、真实拾取接口、已有素材质量、程序线程脏文件和所有权冲突。
3. 执行：在独立 `art/art24-in-run-final-ui` 分支制作资产、接口契约、隔离 Godot 预览和矩阵捕获。
4. 首次完成审计：静态验证、资源哈希、透明度、分辨率矩阵、文本边界与动效帧检查。
5. 两轮优化：问题驱动；不得改变左栏/中央房间/右上协议/底栏/弹层层级的核心结构。
6. 最终验收：只使用预先冻结的 `ART24-ARTPACK-CU-FROZEN-1`，并用 Computer Use 在真实 Godot 窗口逐项检查。
7. Push：自动化、Computer Use、diff、污染守卫和声明边界全部通过后才提交并推送。

## 实现切片

- Slice 0：基线审计、重叠守卫、接口与验收冻结。
- Slice 1：1280×720 逻辑布局和五档缩放契约。
- Slice 2：六类房间复用、亮度/遮挡运行时分层和房间状态道具。
- Slice 3：角色 40 帧、怪物 8 帧、宝箱/陷阱/异常/撤离状态表现。
- Slice 4：HUD、协议 5→1、底栏、按键态、提示与风险反馈。
- Slice 5：放大地图、背包、tooltip、地面物品、替换预览和容量阻塞。
- Slice 6：世界掉落、生成/悬浮/拾取飞行/移除的美术闭环。
- Slice 7：教程、事件、暂停、撤离确认、成功/失败/放弃结算边界。
- Slice 8：全部状态/分辨率捕获、首次审计和两轮优化。
- Slice 9：Computer Use 全量验收、收尾审计、提交和 push。

## 文件所有权

ART24 可修改：

```text
docs/art/ART24_*
docs/art/validation/art24/**
docs/60_interfaces/connection/ART24_*
docs/validation/ART24_*
docs/handoff/HANDOFF_ART24_*
Godot/GraytailGodot/assets/art24/**
Godot/GraytailGodot/scripts/presentation/art24/**
Godot/GraytailGodot/tests/art24_*
tools/art24_*
tools/validate_art24_*
```

程序线程拥有且本分支禁止修改：

```text
Godot/GraytailGodot/scripts/core/run/run_scene.gd
Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd
Godot/GraytailGodot/scripts/ui/run_surface/run_surface_model.gd
Godot/GraytailGodot/scripts/ui/inventory/inventory_panel.gd
Godot/GraytailGodot/scripts/ui/ground_loot/ground_loot_panel.gd
Godot/GraytailGodot/scripts/ui/map_overlay/map_overlay_panel.gd
Godot/GraytailGodot/project.godot
Godot/GraytailGodot/data/assets/asset_manifest.csv
```

全局 manifest 只由后续整合切片合并；ART24 先交付独立 manifest fragment，避免与程序线程产生同文件冲突。

## 完成定义

本执行包完成必须同时满足：

- 8 个一级模块下 54 个二级状态全部可在真实 Godot 预览中到达。
- 五档分辨率 270 张矩阵图全部生成且无缺失。
- 资产契约、运行时报告、哈希、透明度、fallback、动作帧和重叠守卫全部 PASS。
- 首次审计后完成两轮可追溯优化，核心结构不变。
- `ART24-ARTPACK-CU-FROZEN-1` Computer Use 全量 PASS，并连续观察完整动效 60 秒。
- 未修改程序线程拥有的文件；未提交 `.godot`、`.import`、`.translation`、`.uid` 或 `project.godot` 副作用。

完成只声明“ART24 局内美术资产包、接口契约和隔离 Godot 预览可交付”。真实程序交互接入、自然玩法路线和完整 MVP 局内终验仍需后续整合，不由本分支伪造。
