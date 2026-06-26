# ART-10R Base 确定稿 UI 视觉返工

## 0. 文档定位

ART-10 是技术基线，确认了像素字体、manifest-backed UI asset、主菜单 / 出发探索 / 长期系统 / 运行态 HUD 的可运行页面基础。ART-10R 是基于 Base 确定稿与 M1/Lua demo 的视觉返工记录，不代表最终视觉 QA 完成，也不授权直接把 Base 确定稿整屏图作为 runtime UI 背景。

本轮只记录 presentation/UI 层返工、截图和静态验证；不修改玩法核心、run 规则、CommandBus、TruthMap、RunContext、save-profile 语义，不 commit / push。

## 1. 运行前现状观察

执行前已实际运行 `D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot`。项目能启动，能到主菜单，能进入出发探索，能显示长期系统 shell，也能进入运行态 HUD。

观察到的主要问题：

- 主菜单右侧入口仍像普通按钮列表，按钮体量、图标尺寸和 Base 确定稿差距明显。
- 出发探索页以文本卡片和纵向信息为主，缺少左侧视觉展示、中间卡片列表、右侧摘要与底部金色主按钮的产品结构。
- 长期系统 shell 仍偏技术预览文本，缺少左侧档案、中间图鉴网格、右侧详情的正式框架。
- HUD 已有左 / 中 / 右结构，但中央房间提示遮挡偏重，底部 key bar 图标尺度不稳定，运行截图中曾出现 `Dev Debug` 浮层。
- 多处 player-visible copy 中残留 preview/debug/draft/Legacy 风险，需要通过 Skin Kit sanitize 与页面级摘要显示降低风险。

## 2. Lua demo / M1 参考观察

已只读查看 `D:\AGAME1\Base Art\M1`，并从 `D:\AGAME1\Base Art\M1\Lua demo.mp4` 抽取关键帧到 `docs/art/validation/art10r/`。

M1/Lua 参考重点：

- 左侧是稳定的扫描器 / 状态栏，信息密度高但被面板边界约束。
- 中央房间视觉是主舞台，提示条应轻量浮在上方，不应大面积遮挡房间。
- 右侧协议 / 危险 / 事件状态采用窄栏显示，强调摘要，不直接倾倒完整调试文本。
- 底部 key bar 是横向分段控件，key prompt 图标必须受控。
- 弹窗 / 事件提示应作为结构化面板出现，而不是裸露 debug overlay。

## 3. Base 确定稿量尺规则

主菜单参考 `主菜单确定.png`：

- 大标题在左上，左侧保留角色 / 基地展示区。
- 右侧入口是大号纵向按钮栈，不是普通小按钮。
- 顶部小入口用于仓库、设置、退出等次级入口。
- 左下是公告框，底部是 key bar。

出发探索参考 `出发探索确定.png`：

- 顶部为横向主导航。
- 左侧是角色 / 地图氛围展示与携带槽。
- 中间是模式卡片列表和选中详情。
- 右侧是出发摘要、装备 / 消耗品 icon slot 和底部主按钮。
- 底部主按钮需要金色大按钮体量。

长期系统参考 `长期系统确定.png`：

- 顶部标题、返回入口和横向 tab。
- 左侧角色档案 / 记录摘要。
- 中间图鉴式卡片网格。
- 右侧大预览 / 详情面板。

## 4. Skin Kit 返工

`Godot/GraytailGodot/scripts/presentation/art10_ui_skin_kit.gd` 已扩展为 ART-10R Skin Kit：

- 字体 token：`title`、`page_title`、`main_button`、`tab`、`body`、`caption`、`numeric`、`key_prompt`。
- 组件函数：`make_frame_panel()`、`make_large_nav_button()`、`make_icon_slot()`、`make_card_frame()`、`make_selected_glow()`、`make_bottom_key_button()`。
- 尺寸控制：统一 icon token、button min size、panel padding、line spacing。
- 风险规避：`Button.expand_icon` 默认关闭，使用 `icon_max_width` 控制图标；Label 默认通过 token 控制行距，窄栏由页面级摘要与 clip 处理。

## 5. 主菜单返工结果

修改 `Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd`。

结果：

- 改为左侧基地 / 探索员展示区、右侧大号入口按钮栈、顶部小入口、公告框、底部 key bar。
- 主入口按钮使用 Skin Kit 大按钮，icon 不再 expand 放大。
- meta/debug 式摘要改为行动记录，不再直接展示 Debug 字样。
- 公告框和 key bar 分区独立，避免混入右侧 meta 信息。

仍存在差距：

- 当前仍复用 ART09 runtime 可用素材和几何展示，没有新增角色立绘或完整 Base 背景拆分素材。
- 右侧按钮已接近确定稿体量，但图标仍是 manifest-backed 临时低风险图标。

## 6. 出发探索返工结果

修改 `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd`。

结果：

- 由纵向文本 shell 改为顶部横向导航、左侧探索整备、中间路线 / 目标卡片、右侧出发摘要与 slot、底部金色开始探索按钮。
- 装备 / 药剂 / 工具 / 武器 / 护具 / 补给 / 钥匙均以 icon slot 方式占位。
- 保留原 `DeployPrepModel`、`DeployConfig` 和出发 intent，不改出发规则。
- 长文本被压缩为面板摘要，避免覆盖 slot 与底部按钮。

仍存在差距：

- 出发页的地图、角色氛围和物品 icon 仍是 runtime 可用占位素材，不是最终视觉。
- 部分模型字段仍包含 preview/read_only 等底层状态，当前通过 Skin Kit 和页面摘要弱化。

## 7. 长期系统 shell 返工结果

修改 `Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd`。

结果：

- 改为顶部 tab、左侧角色档案、中央内容卡片网格、右侧详情面板。
- 卡片网格展示任务、成就、委托等模块卡位，不实现进度、奖励或解锁逻辑。
- 右侧说明改为详情摘要、边界摘要和接口 / 美术槽摘要。
- 保留长期系统 preview 数据作为展示源，不写长期系统状态。

仍存在差距：

- 右侧详情仍是文本占位，没有最终图鉴卡面和预览图。
- 左侧档案仍缺角色视觉素材与真实成长数据。

## 8. 运行态 HUD 返工结果

修改 `Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd`。

结果：

- 参考 M1/Lua 的左侧扫描器、中央房间、右侧协议 / 遭遇、底部 key bar 结构。
- 中央房间提示面板缩小，降低对房间画面的遮挡。
- 底部 key prompt icon 改为受控尺寸，避免 `expand_icon` 放大。
- UI 层通过 z-index 遮盖 core/run 中 dev debug toggle 的玩家可见风险，不修改 debug gate 或命令语义。

仍存在差距：

- `Dev Debug` 按钮来源在 `scripts/core/run/run_scene.gd`，该路径属于本轮禁止修改的 core/run；本轮未改其语义，只在 UI 层降低可见风险。
- 右侧状态文案仍来自现有 ViewModel/snapshot，后续应继续做玩家可读 copy 映射。

## 9. 截图 / 可视验收结果

最终截图：

- `docs/art/validation/art10r/art10r_main_menu.png`
- `docs/art/validation/art10r/art10r_deploy_prep.png`
- `docs/art/validation/art10r/art10r_long_term.png`
- `docs/art/validation/art10r/art10r_run_hud.png`

运行前现状截图：

- `docs/art/validation/art10r/art10r_current_main_menu.png`
- `docs/art/validation/art10r/art10r_current_deploy_prep.png`
- `docs/art/validation/art10r/art10r_current_long_term.png`
- `docs/art/validation/art10r/art10r_current_run_hud.png`

M1/Lua demo 参考帧：

- `docs/art/validation/art10r/m1_lua_demo_frame_01.png`
- `docs/art/validation/art10r/m1_lua_demo_frame_02.png`
- `docs/art/validation/art10r/m1_lua_demo_frame_03.png`
- `docs/art/validation/art10r/m1_lua_demo_frame_04.png`
- `docs/art/validation/art10r/m1_lua_demo_frame_05.png`

可视结论：

- 四屏均可由 Godot 项目捕获。
- 主菜单、出发探索、长期系统已具备 Base 确定稿的主要构图关系。
- HUD 已接近 M1/Lua 的左中右与底部 key bar 结构。
- 仍有视觉 polish 空间，特别是最终素材、卡面图标、中文 copy 精修和部分面板内密度控制。

## 10. 暂缓内容

- 不实现完整长期系统玩法。
- 不新增大规模图片或生成新图。
- 不直接把三张 Base 确定稿整屏图作为 runtime UI。
- 不修改 gameplay core / run rules / save-profile / command authority。
- 不修改 TruthMap / RunContext / CommandBus 语义。
- 不修改 Connection、Draw、Base Art 原始素材。
- 不做最终视觉 QA polish、完整动画、完整长期系统内容。

## 11. 后续进入 ART-11 条件

ART-11 才进入第二轮 polish / 视觉 QA 修正 / 新素材补齐。

进入 ART-11 前建议完成：

- 审查框确认 ART-10R 允许范围、截图和 static validation。
- 明确哪些 Base Art / Draw 素材可进入 manifest-backed runtime 小批导入。
- 为主菜单角色展示、出发页卡片缩略图、长期系统卡面提供 intended_asset_id / visual_key。
- 明确玩家可见 copy 映射，减少 preview/debug/read_only 等模型状态外泄。
- 确认是否允许在后续阶段处理 `scripts/core/run/run_scene.gd` 的 dev debug toggle 可见性。
