# ART-15 Slice 4 核心页面视觉替换报告

## 0. 文档定位

本文记录 ART-15 Slice 4 的核心页面 manifest-backed 视觉替换结果。

本切片目标是让已有 runtime asset 与 Slice 2 新导入素材在核心界面中产生可见变化，而不是继续只做素材登记或文档说明。本切片不做完整视觉 polish，不做最终截图验收，不实现新玩法。

## 1. 修改范围

| file | 变更摘要 |
| --- | --- |
| `Godot/GraytailGodot/scripts/presentation/art09_manifest_asset_mapping.gd` | 新增通用 `panel_ref()`，把 `ui.panel.terminal_main`、HUD panel、bottom bar、warning bar 等现有 runtime asset 暴露为 manifest-backed panel visual_key |
| `Godot/GraytailGodot/scripts/presentation/presentation_mapping.gd` | 新增 `panel_ref()` presentation 包装 |
| `Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd` | 主菜单公告框和行动记录框加入 manifest-backed 纹理层 |
| `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd` | 出发探索页修正 art09 refs 字典回退，开始探索按钮加入 manifest-backed 纹理底层 |
| `Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd` | 长期系统三栏加入 terminal / protocol panel 纹理层，减少纯程序化色块 |
| `Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd` | HUD 命令反馈条已使用 feedback visual_key，并按 accepted / warning 状态切换 |
| `Godot/GraytailGodot/scripts/ui/ground_loot/ground_loot_panel.gd` | GroundLoot 物品按钮复用 Inventory item icon visual_key |
| `Godot/GraytailGodot/scripts/ui/result/result_panel.gd` | Result 面板按 outcome 显示 manifest-backed 标题牌 |

## 2. 核心界面替换结果

### 主菜单

- 已继续使用 `ui.main_menu.background.no_text` 作为主菜单背景层。
- 公告框新增 `ui.feedback.event_prompt` 纹理层。
- 行动记录框新增 `ui.panel.terminal_main` 纹理层。
- 入口按钮继续通过 `main_menu_entry_icon_ref()` 使用 manifest-backed deploy icons / key prompt。

主菜单不再只依赖程序化 panel 和 ColorRect 表达公告 / 行动记录层级。

### 出发探索

- 修正 `_art09_asset_refs()`：当配置中的 `art09_asset_refs` 仍是旧字符串结构或缺少 `buttons` / `panels` 字典时，回退到 `Art09ManifestAssetMapping.deploy_prep_asset_refs()`。
- `Art09DeployMainPanel`、`Art09DeploySummaryPanel`、tab icons、card icons、开始 / 继续 / 放弃按钮 icons 均可从 manifest-backed 字典解析。
- 开始探索主按钮新增 `ui.deploy.button.confirm_deploy_large` 纹理底层，强化主行动视觉焦点。

这个修正解决了“配置存在 art09_asset_refs 字段，但 UI 实际拿不到 asset_ref 字典”的代码事实问题。

### 长期系统

- 角色档案栏新增 `ui.panel.terminal_main` 纹理层。
- 中间图鉴 / 收藏网格新增 `ui.panel.terminal_main` 纹理层。
- 右侧详情栏新增 `ui.hud.panel.protocol` 纹理层。

长期系统仍是 shell / preview 数据，但视觉承载从纯色块推进到 manifest-backed runtime panel 组合。

### HUD / MiniMap / MapOverlay

- MiniMap / MapOverlay 已有 manifest-backed icon 消费：cell marker 从 view model 的 `asset_id` 获取 `ContentDB` texture。
- HUD 命令反馈新增 `ui.feedback.bar.dark` / `ui.feedback.bar.red` 状态贴图。
- RunSurface bottom key bar 继续使用 `key_prompt_ref()` 解析 key prompt icon。

本切片没有修改地图规则或 TruthMap，只增强 UI 显示层。

### Inventory / GroundLoot

- Inventory 已有 item icon visual_key 消费。
- GroundLoot 已补齐同样的 item icon visual_key 消费。
- 地面物品与背包物品现在共用 item icon fallback 逻辑。

### Result / Settlement

- Result 面板新增标题牌图层：
  - `ui.result.title.extract_confirm`
  - `ui.result.title.extraction_success`
  - `ui.result.title.signal_lost`
- 状态来自 snapshot outcome / settlement outcome，只用于选择 UI 展示图，不修改结算逻辑。

## 3. manifest-backed asset 使用摘要

| asset_id | 当前用途 |
| --- | --- |
| `ui.panel.terminal_main` | 主菜单行动记录、长期系统档案 / 网格纹理 |
| `ui.hud.panel.protocol` | 长期系统详情栏、feedback/result fallback |
| `ui.feedback.event_prompt` | 主菜单公告框、event/search/reward feedback |
| `ui.feedback.bar.dark` | HUD 默认命令反馈条 |
| `ui.feedback.bar.red` | HUD 阻断 / warning 命令反馈条 |
| `ui.deploy.button.confirm_deploy_large` | 出发探索主按钮纹理底层 |
| `ui.result.title.extract_confirm` | Result 撤离确认标题牌 |
| `ui.result.title.extraction_success` | Result 成功标题牌 |
| `ui.result.title.signal_lost` | Result 失败 / 放弃标题牌 |

## 4. 边界确认

- 未修改 Base Art / Draw / Connection。
- 未从 Base Art / Draw runtime 读取图片。
- 未修改 `core/run`、`core/command`、`core/save` 已跟踪代码。
- 未修改 TruthMap / RunContext / CommandBus 语义。
- 未把素材状态改为 approved / final / runtime_ready。
- 未 commit / push。

## 5. 静态自检

- `git diff --check`：通过，仅有 CRLF warning。
- 外部路径硬编码扫描：未发现 Base Art / Draw / `D:\AGAME1` runtime hardcode。
- 新增 panel refs 对应的 manifest asset_id：均唯一且 `godot_path` 文件存在。
- Godot headless 启动：退出码 0，未暴露脚本解析错误；退出阶段仍有 Godot 资源释放 warning，归入后续运行验证观察项。

## 6. 暂缓内容

- Slice 5：hover / selected / blocked / reward / pickup / panel open-close 等最小动效与反馈。
- Slice 6：Computer Use 多分辨率截图，确认上述替换在真实画面中是否足够可见。
- 更高质量页面背景、角色立绘、完整 Result / Settlement 视觉 polish 仍需后续阶段。

## 7. Slice 4 结论

Slice 4 已完成核心页面的首轮 manifest-backed 视觉替换：

- 主菜单、出发探索、长期系统、HUD、Inventory / GroundLoot、Result 均有真实 runtime asset 接入点。
- 出发探索修复了配置 art09 refs 与 UI 消费格式不匹配的问题。
- 长期系统从纯程序化色块推进到使用已登记 runtime panel 纹理。

后续应进入 Slice 5：最小动效与交互反馈。
