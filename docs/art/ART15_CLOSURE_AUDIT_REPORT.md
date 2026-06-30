# ART-15 收口审计报告

## 0. 报告定位

本报告记录 ART-15 / ART-15R / ART-15R2 / ART-15R3 的阶段收口审计结论。

ART-15 原目标是完成核心美术资产生产、manifest-backed runtime 接入、核心界面视觉替换与截图验证。实际执行过程中，阶段产出了资源接入和多轮界面验证证据，但未稳定达成预期视觉目标。

本报告不是 ART-15 通过验收证明，不是 commit / push 授权，也不是继续在 ART-15 内追加返修的执行计划。

## 1. 审计边界

- 是否修改 Draw：否。
- 是否修改 Base Art：否。
- 是否修改 Connection：否。
- 是否运行 Godot：审计阶段曾使用真实 Godot 项目进行 Computer Use 复核。
- 是否 commit / push：否。
- 是否操作 stash：否。
- 是否清理 generated side effects：否。

## 2. 当前仓库状态摘要

审计时仓库状态：

- git root：`D:/AGAME1/_repo_cache/Game1_work`
- 当前分支：`main`
- 当前 HEAD：`3f4e98b38974ceb8d4b1278b4168e3614289d58c`
- 最新提交：`3f4e98b docs(art): add ART-14 resource layering spec`
- 保护性 stash：存在，未操作。

当前工作区包含 ART-15 系列成果、验证截图、文档、脚本，以及 Godot generated side effects。工作区不 clean，不适合直接整体提交。

## 3. ART-15 已完成内容

ART-15 系列已完成以下探索和产物：

- 梳理 Base Art、Draw、旧 GameJam Draw 与 Godot runtime PNG 的匹配关系。
- 新增少量 UI runtime PNG，并追加 `asset_manifest.csv`。
- 接入部分 manifest-backed visual key / asset_id。
- 对主菜单、出发探索、长期系统、HUD、MapOverlay、Inventory、GroundLoot、Result 等界面做过可视替换尝试。
- 生成 ART-15、ART-15R、ART-15R2、ART-15R3 多轮截图证据。
- 生成验证脚本：
  - `tools/validate_art15_core_art_asset_pipeline.ps1`
  - `tools/validate_art15r_visual_layer_layout.ps1`
- 生成阶段文档：
  - `docs/art/ART15_CORE_ART_ASSET_PRODUCTION_AND_VISUAL_REPLACEMENT.md`
  - `docs/art/ART15R_VISUAL_LAYER_AND_LAYOUT_REWORK.md`

## 4. 主要未达标原因

ART-15 未能作为最终视觉阶段关闭，原因不是单一素材缺失或单个坐标错误，而是 UI 架构层面的职责耦合。

核心问题包括：

- UI shell 同时承担页面布局、图层管理、文案处理、状态解释和组件创建。
- `run_surface.gd` 同时处理局内房间背景、HUD、右上状态卡、交互提示、底部快捷键、MapOverlay slot 和旧 HUD 兼容。
- 主菜单、出发探索、长期系统也存在类似 shell 过重问题。
- `run_scene.gd` 与 UI 装配边界需要重新明确；当前审计未发现其忽略 CRLF 后有实质内容 diff，但它仍是运行态 UI 装配的关键边界。
- MapOverlay 仍表现为 overlay 逻辑与主游戏画面混杂。
- 局内 HUD 的主信息、快捷键栏、对象提示、右上状态卡之间缺少稳定 layer root。
- 继续靠 Rect2、透明度、z_index 和局部遮罩补丁，无法稳定达到目标视觉。

## 5. 视觉审计结论

ART-15 系列相较最初状态有可见变化，但仍不满足用户目标稿和手绘布局的最终口径。

已改善：

- 出发探索逐步接近左角色、中路线、右摘要/装备、底部主按钮结构。
- 长期系统逐步接近左角色、中收藏墙、右档案模块结构。
- 局内 HUD 已从三栏式结构转向左侧状态栏、中央/右侧主画面、右上状态卡、底部快捷键结构。
- MapOverlay 相比早期全屏强遮挡有所减轻。

仍未达标：

- HUD layer root 仍不稳定。
- 主信息浮层、快捷键栏、对象提示与 overlay 的职责仍未完全分离。
- 部分截图中仍可见文本裁切、底部拥挤、遮罩压画面等问题。
- 主菜单、出发探索、长期系统距离 Base 确定稿仍有明显美术完成度差距。
- 当前改动更像多轮局部修补，而不是稳定的 UI contract 落地。

## 6. 提交与收口判断

ART-15 不建议继续在当前阶段追加修补。

原因：

- 阶段目标已经从“素材接入与视觉替换”滑向“核心 UI 架构解耦”。
- 当前工作区 dirty 范围较大，包含 ART-15 系列成果与 generated side effects，提交边界复杂。
- 继续在 ART-15 内修补会扩大工程风险，并可能继续产生重复返工。

因此：

- ART-15 不作为通过验收阶段提交。
- ART-15 不继续追加 ART-15R4 补丁式执行。
- ART-15 的价值保留为资源接入试验、截图证据、问题定位和 ART-16 输入。

## 7. ART-16 接续建议

建议下一阶段定义为：

```text
ART-16：核心 UI 职责解耦与四界面重排
```

核心路线：

```text
先解耦职责边界，再按职责建立图层结构，最后基于图层结构重排实际视觉。
```

建议覆盖：

- 主菜单。
- 出发探索。
- 长期系统。
- 局内 HUD。

建议先建立统一 UI contract：

- page layout regions。
- layer roots。
- overlay / modal 规则。
- text budget。
- presentation model 边界。
- screenshot QA 口径。

运行态重点：

- `run_scene.gd` 只做 UI 装配、signal 转发和 presentation model 传递，不承载视觉布局。
- `run_surface.gd` 重建 layer roots：
  - game viewport root
  - left HUD root
  - top-right status root
  - bottom floating info root
  - bottom action root
  - overlay root
  - modal root
- MapOverlay 不再默认全屏暗罩。
- 主信息栏作为游戏画面下方浮层，而不是横跨底部的固定说明条。

禁止范围：

- 不改 run rules。
- 不改 command execution 语义。
- 不改 save/profile。
- 不改 reward / combat / extract 规则。
- 不改 room generation。
- 不把 Base Art / Draw 作为 runtime 直读路径。

## 8. 停止点

ART-15 到此收口。

- 本报告已记录 ART-15 未达最终目标的原因。
- 执行框已被通知停止继续追加 ART-15 返修。
- 后续应以 ART-16 新阶段重新规划和执行。
- 本报告本身未 commit / push。
