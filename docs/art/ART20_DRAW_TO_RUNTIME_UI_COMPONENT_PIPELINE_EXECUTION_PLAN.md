# ART-20 Draw 候选归并、Art staging、UI 切片管线、首批组件切图与核心界面替换执行计划

## 0. 文档定位

本文是 ART-20 的执行计划与边界说明。ART-20 的目标不是继续用坐标补丁修 UI，而是建立并验证以下链路：

```text
sources/draw 或 sources/art source candidate
  -> sources/art/ART-20 staging
  -> cut working / cut output
  -> Godot runtime asset
  -> asset_manifest.csv
  -> visual_key / UI 消费侧
  -> Computer Use 实机验收
```

本阶段不 commit / push，不 pull / reset / clean / stash，不删除、移动、重命名外部原始素材。

## 1. 当前治理依据

已读取的当前治理入口：

- `docs/README.md`
- `docs/INDEX.md`
- `docs/00_governance/DOC_PLACEMENT_STANDARD.md`
- `docs/00_governance/EXTERNAL_SOURCE_BOUNDARY.md`
- `docs/00_governance/DOC_GOV_003_STAGE_PROCESS_MINIMAL.md`

当前 canonical 外部素材源：

- `D:\AGAME1\sources\art`
- `D:\AGAME1\sources\draw`

旧路径只作为历史标签，不作为执行来源：

- `D:\AGAME1\Base Art`
- `D:\AGAME1\Draw`
- `D:\AGAME1\Connection`

## 2. ART-19 / ART-19R1 结论继承

ART-19 已被标记为未达成目标并关闭；ART-20 不直接继承 ART-19 的替换结果作为目标。

ART-19R1 提供的有效治理输入：

- `UI_COMPONENT_CUTTING_SPEC.csv`
- `NEXT_RUNTIME_IMPORT_BATCH_PLAN.csv`
- `ART19_IMPORTED_ASSET_REVIEW.csv`

关键事实：

- ART-19 已接入的 16 个素材大多来源可追溯且 hash 匹配。
- 风险不主要是“文件错导入”，而是语义过宽、命名不稳、跨页面复用和错位使用风险。
- `needs_source_selection`、`needs_visual_fit_review`、`reference_only` 不得直接进入 runtime import。
- Base / ART-13 / ART-14 / M1 参考图不能作为整屏 runtime UI 直接使用。

## 3. 参考优先级

ART-20 后续切片判断优先级：

1. 策划案决定功能和信息结构。
2. 用户手绘图决定区域比例和 UI 位置。
3. Base 确定稿决定美术质感、材质、边框、按钮、完成度方向。
4. TapTap / UE / Lua / M1 参考决定成熟 UI 层级、运行态反馈节奏和遮挡关系。
5. 当前 Godot 实现只作为待改基线，不作为目标。

已确认参考：

- `D:\AGAME1\sources\art\Base\主菜单示例.png`
- `D:\AGAME1\sources\art\Base\出发探索确定.png`
- `D:\AGAME1\sources\art\Base\长期系统确定.png`
- `D:\AGAME1\sources\art\M1\Lua demo.mp4`
- `D:\AGAME1\sources\art\M1\*.png`
- `docs/art/validation/art15/art15r_user_layout_reference_run_hud.jpg`
- `docs/art/validation/art15/art15r_user_layout_reference_deploy_long_term.jpg`

## 4. 旧工具链只读复核

旧工具目录：

```text
D:\A GAME\26.5.30 GameJam\tools
```

仅允许借鉴的算法概念：

- PIL crop / bbox。
- transparent crop / alpha bounds。
- magenta -> alpha。
- manual bbox override。
- source hash / duplicate hash。
- sprite sheet split。
- manifest / report 输出格式。

不得直接运行旧脚本，原因：

- 旧脚本绑定旧 `Draw` 目录和旧 `_manifest` / processed / candidates 输出。
- 旧脚本包含生成、刷新、写 manifest 和候选目录的行为。
- 旧输出目录不等于 ART-20 当前 staging / cut output。
- ART-20 必须以 `D:\AGAME1\sources\art\ART-20` 为新的工作区，不能反向污染旧素材池。

## 5. 切片计划

### Slice 0：环境 / dirty / 旧工具链 / ART19 反例复核

完成：

- git root / branch / HEAD / status / stash 自检。
- 当前 dirty 分类。
- 读取治理文档、ART19R1 输出和参考资料。
- 用真实 Godot + Computer Use 捕获当前主菜单、出发探索、长期系统、Run HUD、MapOverlay baseline。
- 只读复核旧工具链。
- 输出本计划和 Slice 0 报告。

### Slice 1：Draw 候选准入 + Art staging 归并

目标：

- 基于 ART19R1 P0 计划选择可准入候选。
- 复制到 `D:\AGAME1\sources\art\ART-20\01_staging_from_draw`。
- 输出 staging manifest。

禁止：

- 修改 `sources/draw`。
- staging reference_only / unresolved / full-screen reference。
- 写 Godot 或 manifest。

### Slice 2：安全切片工具 dry-run

目标：

- 新增 dry-run 默认的 `tools/art20_cut_ui_assets.py`。
- 只输出 dry-run plan，不生成 PNG。

工具能力：

- transparent bbox。
- manual crop rect。
- fixed output size。
- nine-slice metadata。
- alpha check。
- source hash check。
- output path preview。
- no overwrite unless explicit flag。

### Slice 3：P0 组件真实切片 + 质量清单

目标：

- 只对审计批准的 P0 staging source 输出真实切片。
- 输出到 `D:\AGAME1\sources\art\ART-20\03_cut_output`。
- 输出 cut manifest 和 component gallery。

禁止：

- Godot import。
- manifest 修改。
- UI 代码修改。

### Slice 4：manifest / visual_key 接入 + component gallery

目标：

- 仅导入 `cut_status=ready_for_runtime_import` 的组件。
- 复制到 `Godot/GraytailGodot/assets/ui/art20`。
- 更新 `asset_manifest.csv` 和 manifest-backed mapping。

禁止：

- 导入 unresolved / wrong usage risk / reference_only。
- 直接 runtime 读取外部 source path。

### Slice 5：四核心界面替换

目标：

- 主菜单、出发探索、长期系统、Run HUD、MapOverlay 消费 ART20 组件。
- 覆盖 inventory / ground_loot / result 可用组件。
- 用 Computer Use 捕获核心页面截图。

Run HUD 硬约束：

- 左栏约 20%-25%。
- 左栏之外基本都是游戏画面。
- 右上角协议 / 压力只是小状态卡。
- 主信息栏和快捷键栏是 overlay，不切走主画面。
- MapOverlay 是临时 overlay。

### Slice 6：最终验收文档与总验证

目标：

- 输出总文档、validation 证据和 `tools/validate_art20_ui_asset_pipeline.ps1`。
- 验证 source -> staging -> cut -> runtime -> manifest -> visual_key -> UI 消费链路闭合。
- 用 Computer Use 对比 Base / Lua / 手绘 / ART19 错误替换截图和 ART20 当前截图。

## 6. 停止条件

必须停止并请求审计：

- dirty / staged 状态无法解释。
- 审计未授权进入下一 slice。
- 需要修改 `core/run` 语义。
- 需要修改 `core/command` 或 `core/save`。
- 需要删除、移动、重命名原始素材。
- 需要直接 runtime 读取 `sources/art` 或 `sources/draw`。
- 需要把整屏参考图当 runtime UI。
- 视觉截图明显不符合目标，即使脚本通过。

## 7. 审计规则

每个 Slice 完成后必须自检并向“美术调整-审计”框请求审计，要求使用 `5.5xHigh / 5.5超高`。

未经审计授权，不进入下一 Slice。
