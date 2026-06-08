# T2-Pre Repo and Docs Assessment

## 时间
2026-06-08 15:16:46 +08:00

## 工作目录
- CodeX 当前工作目录：C:\Users\33682\Documents\Codex\2026-06-08\windows-text-t2-pre-base-docs
- Base Docs：D:\AGAME1\Base Docs
- 仓库缓存：D:\AGAME1\_repo_cache\Game_feature_editor_playable_prototype
- Godot 项目：D:\Godot\GraytailGodot
- Godot 可执行文件：D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe

## Base Docs 检查结果
- `D:\AGAME1\Base Docs` 存在。
- 发现文档类文件 1 个，可直接读取 1 个 txt。
- 未发现 docx / pdf 需要专用工具读取的文件。
- `未来规划策划案.txt` 明确包含 Godot 正式独立版定位、核心循环、UI / 小地图 / HUD、数值与难度、目录结构、开发优先级、规则迁移阶段。
- 未发现明确可用于资产合规迁移的素材授权说明或素材来源说明；文档中的“来源”主要是玩法、压力、奖励来源语境。

## Base Docs 读取到的文档
- `D:\AGAME1\Base Docs\未来规划策划案.txt`，33100 bytes，LastWriteTime=2026/6/8 14:15:43。

主要标题摘录：
- # 《灰尾回收 / 五四三二一》Godot 正式独立版未来策划案
- ## 1. 项目定位
- ## 2. 核心玩法循环
- ### 2.1 单局循环
- ### 2.2 长期循环
- ## 3. Godot 版本表现方向
- ### 3.1 美术风格
- ### 3.2 Godot 场景结构方向
- ## 4. Godot 工程架构规划
- ### 4.1 推荐目录结构
- ### 4.2 Autoload 全局系统
- #### GameKernel
- #### ContentDB
- #### SaveManager
- ### 4.3 Resource / JSON 数据化方向
- ## 5. 地图与难度体系
- ### 5.1 地图尺寸
- ### 5.2 撤离点数量
- ### 5.3 标准局建议配置
- ## 6. 撤离权系统
- ### 6.1 撤离点的核心定位
- ### 6.2 两阶段体验
- #### 阶段一：撤离点未发现
- #### 阶段二：撤离点已发现
- ### 6.3 撤离点扩展类型
- ## 7. 小地图与情报系统
- ### 7.1 基础规则
- ### 7.2 TruthMap 与 IntelMap
- ### 7.3 情报可靠性
- ### 7.4 标记系统

## 仓库拉取结果
- 目标目录原本不存在，已在允许目录内执行浅克隆。
- clone 结果：成功。
- 未执行 pull、reset、clean、commit、push。

## 仓库分支
- 当前分支：`feature/editor-playable-prototype`
- 最后提交：`7388bc0 Document editor playable prototype v2`
- `git status --short`：clean

## 仓库结构概览
- README.md: 文件, exists=true, files=1
- docs: 目录, exists=true, files=27
- scripts: 目录, exists=true, files=49
- scripts\systems: 目录, exists=true, files=28
- scripts\main.lua: 文件, exists=true, files=1
- assets: 目录, exists=true, files=402
- game_material: 目录, exists=true, files=8
- .project: 目录, exists=true, files=12
- UE\Graytail: 目录, exists=true, files=66

## Lua 原型状态判断
- Lua / UrhoX 原型仍是 Godot 独立版最重要的玩法参考，尤其是扫雷式情报、单局探索、撤离、背包、事件、战斗占位、协议压力、教程和 HUD / MiniMap 行为。
- `scripts/main.lua` 约 5699 行，承载主流程、菜单、CG、HUD、输入、GM 调试、结算等大量表现与流程粘合逻辑；迁移时应拆为 Godot domain + scene + UI，而不是逐行搬运。
- Minefield.lua: 993 行，地图生成、RNG、雷/情报/探索规则较完整。
- ExtractionRun.lua: 213 行，单局移动、Reveal、Flag、撤离判定适合作 Godot run domain 参考。
- RunInventory.lua: 861 行，局内收益、结算、安全/待结算资源逻辑较完整，但应规格迁移。
- Combat.lua: 449 行，战斗占位与怪物结算路径可作为行为规格，不宜逐行迁移。
- EventSystem.lua: 413 行，事件定义、选项状态与结果模型可转为 Godot Resource/JSON。
- Protocol.lua: 84 行，54321 压力系统轻量，适合优先迁移为独立 domain。
- MetaProgress.lua: 1438 行，局外成长很重，建议 Godot 核心闭环稳定后分阶段迁移。
- Tutorial.lua: 347 行，教程触发与弹窗规则可迁移为引导规格。
- HUD.lua / MiniMap.lua / MapOverlay.lua 分别约 916 / 377 / 436 行，是 UI 行为参考，不应照搬绘制实现。
- 适合作 Godot 迁移参考的系统：Minefield、ExtractionRun、RunInventory、Protocol、EventSystem、MiniMap、MapOverlay、HUD 的数据/行为契约。
- 只应作为行为规格、不应逐行迁移的文件：`scripts/main.lua`、HUD 绘制代码、UrhoX 输入/渲染适配、CG 播放、平台/工具相关 `.project` 与 `.cli` 内容。

## UE 迁移状态判断
- UE 当前更像实训 / 编辑器可玩原型线，不是 Godot 独立线的资产迁移依据。
- 仓库 README 与 `docs/editor-playable-prototype-v2.md` 均显示 UE 工程在 `UE/Graytail`，当前分支为 `feature/editor-playable-prototype`，V2 是 C++ only 的 Editor console playable prototype。
- 值得 Godot 借鉴的架构边界：RunContext、TruthMap / IntelMap、CommandProcessor、RoomResolver、ContentRegistry、EventBus、QueryFacade、MiniMapViewModel、DebugSubsystem。
- UE 内容不应直接迁移到 Godot：`.uproject`、C++ / Build.cs、UE Config、UMG / Blueprint / DataAsset 规划、UE 验证命令、未来 `.uasset` 或 UE Content 资产。
- Godot 应借鉴“规则内核、命令边界、查询门面、ViewModel 投影”，但用 GDScript / Resource / Scene / Control 实现。

## Godot 工程状态判断
- project.godot: 文件, exists=true
- assets\ui\icons\minimap: 缺失, exists=false
- data\assets\asset_manifest.csv: 文件, exists=true
- docs\ASSET_IMPORT_RULES.md: 文件, exists=true
- docs\ASSET_TRANSFER_T0_CHECKLIST.md: 文件, exists=true
- docs\ASSET_ID_NAMING.md: 文件, exists=true
- docs\GODOT_READY_FOR_ASSET_TRANSFER.md: 文件, exists=true
- `data/assets/asset_manifest.csv` 可读取，当前记录约 5 行。
- `assets` 目录存在但当前扫描到 0 个文件；`assets/ui/icons/minimap/` 缺失，下一轮若正式迁移需在允许范围内创建。
- 资产导入规则、T0 检查表、命名规则、Ready 文档均存在。
- Godot 目录 Git 状态：未初始化 Git 仓库。

## 资产目录统计
- 扫描范围：`assets/`、`game_material/`、`.project/`。
- 图片数量：199
- 音频数量：1
- 字体数量：1
- 视频数量：6
- UI 图标数量估计：115
- 地图 / Tile / 房间素材数量估计：19
- 宣传 / 截图 / 视频素材数量估计：45
- 未知授权素材数量估计：207
- 重点候选目录：`assets/Textures/generated/icons/32`、`assets/Textures/generated/icons/64`、`assets/ui/common`、`assets/ui/deploy`、`assets/ui/hud`。

## 第一批推荐迁移资产类别
- P0：`assets/Textures/generated/icons/32` 下的小地图 / 房间类型 / 数字图标，适合落到 `res://assets/ui/icons/minimap/`。
- P0 候选包括：玩家定位、未知格、已探索格、扫描格、旗标、雷/陷阱、怪物、宝箱、撤离、出口、已清理、数字 1/2/3。
- P1：`assets/Textures/generated/icons/64` 的高分辨率备用版本。
- P1：基础 UI 小图标，如金币、背包、绷带、护甲、指南针。
- P1/P2：玩家占位图和小尺寸房间占位图，需等小地图图标链路验证后再处理。

## 禁止迁移资产类别
- 本轮禁止复制任何真实资产到 Godot。
- 下一轮仍不建议迁移：视频、宣传图、截图、大背景、字体、音乐、未知授权音效、`.cli` 工具、UE 工程资产、UE Content / UMG / Blueprint / DataAsset 内容。
- 不得全量复制 `assets/`、`game_material/`、`.project/`。

## 授权风险
- 仓库内真实媒体资源缺少明确授权文件或素材来源总表。
- 部分 generated character manifest 记录了本地绘制源路径，但不能等同于商用授权说明。
- Base Docs 未给出可直接迁移的素材授权清单。
- 候选 CSV 中所有候选均标记 `license_status=unknown`、`replacement_needed=true`。
- 正式复制前必须由人工确认授权，或改用可确认授权的替代资源。

## Godot 迁移优先级建议
- P0：先迁移已确认授权的小地图 / 房间类型图标，建立 `asset_manifest.csv` 登记、Godot 导入、命名和验证闭环。
- P1：补齐 64px 备用图标与基础 UI 图标。
- P2：玩家占位图、房间占位图、Tile / 房间表现资源。
- P3：音频、字体、视频、宣传素材、大背景，一律等授权与导入策略明确后再评估。

## 是否可以进入正式资产迁移
条件允许，但不能直接复制当前未知授权候选。建议下一轮进入正式资产迁移时只处理“已人工确认授权”的 P0 小地图 / 房间类型图标；若授权仍未确认，则下一轮应改为生成或替换可用占位图，而不是复制仓库真实资产。

## 下一轮建议任务
- 明确确认 P0 候选图标授权状态，或指定替代素材策略。
- 只迁移 `assets/Textures/generated/icons/32` 中已确认的 14 个小地图 / 房间图标。
- 在 Godot 内创建必要目标目录，禁止删除、禁止覆盖、禁止全量复制。
- 更新 `data/assets/asset_manifest.csv`，使用小写点号 asset_id 与小写蛇形文件名。
- 使用 Godot headless import 验证，并记录 `git status --short`。
