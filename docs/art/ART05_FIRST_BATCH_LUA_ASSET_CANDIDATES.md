# ART-05 首批 Lua 原型素材候选与 Base Art 入库准备

## 0. 文档定位

本文档是 R5 候选登记与 Base Art 入库准备文档，不是 Godot 导入授权，不是 manifest 修改，不是 runtime asset list，也不是复制图片或导入图片的指令。

本文档只记录从 Lua / UrhoX 原型仓库素材中只读扫描得到的首批可接入候选。所有候选均为 `source_status=pending_verification`、`review_status=pending_review`、`runtime_import_status=not_ready`，不得被视为 final、approved 或 runtime_ready。

## 1. R4 继承结论

R4 / ART-04 的桥接结论是：首批美术候选应优先服务 A / B 接口，暂不进入 Godot，暂不修改 manifest，暂不复制 Lua assets。当前 R5 只做候选登记和 Base Art registry 准备。

优先范围：

- A 类：RunScene / Room、Minimap / MapOverlay、Room prop、Player idle / facing。
- B 类：HUD / common UI、Item / Inventory / Reward 局部、resource icon。
- 暂缓：完整主菜单背景、完整 DeployPrep UI、完整 LongTerm UI、完整角色动画、完整 tileset、reward VFX、结算 / 历史最终缩略图、字体、音频、视频。

## 2. 首批候选范围

| 类别 | 数量 | 选择原因 | 接口等级 |
| --- | ---: | --- | --- |
| MiniMap / MapOverlay 小图标 | 14 | 小尺寸、低耦合、直接服务地图状态与 marker taxonomy | A |
| Room 背景小批试点 | 1 | 只选基础房间背景，先验证 room background 规格 | A |
| Room prop 小批试点 | 8 | 可服务宝箱、陷阱、事件、补给等竖切交互对象 | A |
| Player idle / facing | 4 | 只登记四向 idle，不进入完整角色动画 | A |
| common UI / resource icon | 8 | 服务 HUD / common UI 的通用图标与 UI 基础件 | B |
| 宝箱 / 撤离点 / 危险 / 事件 marker | 6 | 作为 room marker 与 minimap marker 的语义候选 | A |

候选总数：41。

## 3. 候选素材清单

| candidate_id | category | source_path | lua_reference_hint | intended_use | interface_level | processing_needed | source_status | review_status | runtime_import_status | risk |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CAND-R5-MM-001 | MiniMap / MapOverlay | assets/Textures/generated/icons/32/00_wanjia_dingwei.png | scripts/ui/MiniMap.lua; scripts/ui/MapOverlay.lua | player position icon | A | verify size and contrast | pending_verification | pending_review | not_ready | source authorization pending |
| CAND-R5-MM-002 | MiniMap / MapOverlay | assets/Textures/generated/icons/32/01_weizhi_ge.png | scripts/ui/MiniMap.lua; scripts/ui/MapOverlay.lua | unknown cell icon | A | verify unknown-state readability | pending_verification | pending_review | not_ready | state semantics may change |
| CAND-R5-MM-003 | MiniMap / MapOverlay | assets/Textures/generated/icons/32/02_yitan_ge.png | scripts/ui/MiniMap.lua; scripts/ui/MapOverlay.lua | explored cell icon | A | verify grid clarity | pending_verification | pending_review | not_ready | small-size readability |
| CAND-R5-MM-004 | MiniMap / MapOverlay | assets/Textures/generated/icons/32/03_saomiao_ge.png | scripts/ui/MiniMap.lua; scripts/ui/MapOverlay.lua | scanned cell icon | A | verify scan-state contrast | pending_verification | pending_review | not_ready | state color overlap |
| CAND-R5-MM-005 | MiniMap / MapOverlay | assets/Textures/generated/icons/32/04_biaoji_qi.png | scripts/ui/MapOverlay.lua | manual marker flag | A | align marker taxonomy | pending_verification | pending_review | not_ready | marker taxonomy pending |
| CAND-R5-MM-006 | MiniMap / MapOverlay | assets/Textures/generated/icons/32/05_dici_xianjing_icon.png | scripts/systems/Minefield.lua | mine / trap marker | A | verify danger readability | pending_verification | pending_review | not_ready | overlaps danger marker |
| CAND-R5-MM-007 | MiniMap / MapOverlay | assets/Textures/generated/icons/32/06_guaiwu_icon.png | scripts/scenes/DungeonRoom.lua | monster room marker | A | verify enemy semantics | pending_verification | pending_review | not_ready | enemy taxonomy pending |
| CAND-R5-MM-008 | MiniMap / MapOverlay | assets/Textures/generated/icons/32/07_baoxiang_icon.png | scripts/scenes/DungeonRoom.lua | chest marker | A | verify chest state pair | pending_verification | pending_review | not_ready | open / closed state split pending |
| CAND-R5-MM-009 | MiniMap / MapOverlay | assets/Textures/generated/icons/32/08_cheli_icon.png | scripts/systems/ExtractionRun.lua | retreat marker | A | verify extraction semantics | pending_verification | pending_review | not_ready | exit vs retreat distinction |
| CAND-R5-MM-010 | MiniMap / MapOverlay | assets/Textures/generated/icons/32/09_chukou_icon.png | scripts/systems/ExtractionRun.lua | exit marker | A | verify exit semantics | pending_verification | pending_review | not_ready | exit vs retreat distinction |
| CAND-R5-MM-011 | MiniMap / MapOverlay | assets/Textures/generated/icons/32/10_yiqingli_icon.png | scripts/ui/MapOverlay.lua | cleared marker | A | verify cleared state | pending_verification | pending_review | not_ready | state may be folded into grid |
| CAND-R5-MM-012 | MiniMap / MapOverlay | assets/Textures/generated/icons/32/11_shuzi_1.png | scripts/ui/MapOverlay.lua | overlay number 1 | A | verify number style | pending_verification | pending_review | not_ready | number set incomplete |
| CAND-R5-MM-013 | MiniMap / MapOverlay | assets/Textures/generated/icons/32/12_shuzi_2.png | scripts/ui/MapOverlay.lua | overlay number 2 | A | verify number style | pending_verification | pending_review | not_ready | number set incomplete |
| CAND-R5-MM-014 | MiniMap / MapOverlay | assets/Textures/generated/icons/32/13_shuzi_3.png | scripts/ui/MapOverlay.lua | overlay number 3 | A | verify number style | pending_verification | pending_review | not_ready | number set incomplete |
| CAND-R5-RB-001 | Room background | assets/Textures/generated/rooms/fangjian_jichu_1024.png | scripts/scenes/DungeonRoom.lua | base room background | A | verify crop, safe area, target size | pending_verification | pending_review | not_ready | room role and framing pending |
| CAND-R5-RP-001 | Room prop | assets/Textures/generated/props/00_baoxiang_kai.png | scripts/scenes/DungeonRoom.lua | open chest prop | A | transparent background and anchor check | pending_verification | pending_review | not_ready | open / closed state consistency |
| CAND-R5-RP-002 | Room prop | assets/Textures/generated/props/03_baoxiang_guan.png | scripts/scenes/DungeonRoom.lua | closed chest prop | A | transparent background and anchor check | pending_verification | pending_review | not_ready | open / closed state consistency |
| CAND-R5-RP-003 | Room prop | assets/Textures/generated/props/05_yichang_hexin.png | scripts/systems/EventSystem.lua | event core prop | A | verify event taxonomy | pending_verification | pending_review | not_ready | event visuals may branch |
| CAND-R5-RP-004 | Room prop | assets/Textures/generated/props/06_dici_xianjing.png | scripts/systems/Minefield.lua | mine / trap prop | A | verify danger readability | pending_verification | pending_review | not_ready | trap state pending |
| CAND-R5-RP-005 | Room prop | assets/Textures/generated/props/08_saomiaoyi.png | scripts/ui/MapOverlay.lua | scanner prop | A | verify interactable state | pending_verification | pending_review | not_ready | interaction rules pending |
| CAND-R5-RP-006 | Room prop | assets/Textures/generated/props/09_jinbi_dui.png | scripts/systems/RunInventory.lua | coin pile prop | A | verify pickup / reward state | pending_verification | pending_review | not_ready | reward economy pending |
| CAND-R5-RP-007 | Room prop | assets/Textures/generated/props/10_yiliaobao.png | scripts/systems/RunInventory.lua | medkit prop | A | verify consumable semantic | pending_verification | pending_review | not_ready | item category pending |
| CAND-R5-RP-008 | Room prop | assets/Textures/generated/props/11_wuzi_xiang.png | scripts/scenes/DungeonRoom.lua | supply crate prop | A | verify prop role | pending_verification | pending_review | not_ready | role may overlap chest |
| CAND-R5-PL-001 | Player idle / facing | assets/Textures/generated/characters/huli/frames/00_front_idle.png | scripts/scenes/DungeonRoom.lua | player front idle | A | verify anchor and sprite size | pending_verification | pending_review | not_ready | character identity pending |
| CAND-R5-PL-002 | Player idle / facing | assets/Textures/generated/characters/huli/frames/01_back_idle.png | scripts/scenes/DungeonRoom.lua | player back idle | A | verify anchor and sprite size | pending_verification | pending_review | not_ready | character identity pending |
| CAND-R5-PL-003 | Player idle / facing | assets/Textures/generated/characters/huli/frames/02_left_idle.png | scripts/scenes/DungeonRoom.lua | player left idle | A | verify anchor and sprite size | pending_verification | pending_review | not_ready | character identity pending |
| CAND-R5-PL-004 | Player idle / facing | assets/Textures/generated/characters/huli/frames/03_right_idle.png | scripts/scenes/DungeonRoom.lua | player right idle | A | verify anchor and sprite size | pending_verification | pending_review | not_ready | character identity pending |
| CAND-R5-UI-001 | common UI / resource icon | assets/ui/common/ui_icon_account_gold.png | scripts/ui/HUD.lua | account gold icon | B | verify UI scale | pending_verification | pending_review | not_ready | economy icon naming pending |
| CAND-R5-UI-002 | common UI / resource icon | assets/ui/common/ui_button_blank_dark.png | scripts/ui/UITheme.lua | common dark button | B | verify button states | pending_verification | pending_review | not_ready | state variants incomplete |
| CAND-R5-UI-003 | common UI / resource icon | assets/ui/common/ui_bar_blank_dark.png | scripts/ui/HUD.lua | common dark bar | B | verify bar slicing | pending_verification | pending_review | not_ready | nine-slice policy pending |
| CAND-R5-UI-004 | common UI / resource icon | assets/ui/common/ui_panel_terminal_main.png | scripts/ui/UILayout.lua | terminal panel | B | verify panel slicing | pending_verification | pending_review | not_ready | final UI density pending |
| CAND-R5-UI-005 | common UI / resource icon | assets/ui/hud/ui_icon_backpack.png | scripts/ui/HUD.lua | backpack HUD icon | B | verify icon taxonomy | pending_verification | pending_review | not_ready | inventory interface pending |
| CAND-R5-UI-006 | common UI / resource icon | assets/ui/deploy/ui_icon_compass.png | scripts/ui/HUD.lua | compass / navigation icon | B | verify cross-screen reuse | pending_verification | pending_review | not_ready | deploy UI future contract |
| CAND-R5-UI-007 | common UI / resource icon | assets/Textures/generated/ui/icons/jinbi_icon.png | scripts/systems/RunInventory.lua | currency icon | B | verify resource key | pending_verification | pending_review | not_ready | resource taxonomy pending |
| CAND-R5-UI-008 | common UI / resource icon | assets/Textures/generated/ui/icons/xuetiao_tianchong.png | scripts/ui/HUD.lua | health / bar fill icon | B | verify HUD bar role | pending_verification | pending_review | not_ready | bar composition pending |
| CAND-R5-MK-001 | marker | assets/Textures/room_treasure.png | scripts/scenes/DungeonRoom.lua | treasure room marker | A | compare with minimap icon set | pending_verification | pending_review | not_ready | duplicate semantic with chest |
| CAND-R5-MK-002 | marker | assets/Textures/room_safe.png | scripts/scenes/DungeonRoom.lua | safe room marker | A | verify room category | pending_verification | pending_review | not_ready | room taxonomy pending |
| CAND-R5-MK-003 | marker | assets/Textures/room_monster.png | scripts/scenes/DungeonRoom.lua | monster room marker | A | verify enemy room semantic | pending_verification | pending_review | not_ready | enemy taxonomy pending |
| CAND-R5-MK-004 | marker | assets/Textures/room_exit.png | scripts/systems/ExtractionRun.lua | exit room marker | A | align exit / retreat distinction | pending_verification | pending_review | not_ready | semantics overlap |
| CAND-R5-MK-005 | marker | assets/Textures/room_event.png | scripts/systems/EventSystem.lua | event room marker | A | verify event taxonomy | pending_verification | pending_review | not_ready | event taxonomy pending |
| CAND-R5-MK-006 | marker | assets/Textures/room_danger.png | scripts/systems/Minefield.lua | danger room marker | A | align danger / mine distinction | pending_verification | pending_review | not_ready | semantics overlap |

## 4. Base Art registry 写入摘要

本轮向以下 registry 追加 R5 pending 候选记录：

- `D:\AGAME1\Base Art\_registry\source_registry.csv`
- `D:\AGAME1\Base Art\_registry\review_status.csv`

写入性质：

- 仅追加 R5 候选行，不重排、不覆盖、不删除既有行。
- 未复制图片。
- 未移动图片。
- 未修改图片。
- 未导入 Godot。
- 未修改 manifest。
- 未写入 runtime asset list。

所有候选均保持：

- `source_status=pending_verification`
- `review_status=pending_review`
- `runtime_import_status=not_ready`

## 5. 暂缓素材

- 视频：不纳入 R5，美术、授权与 runtime pipeline 均未进入本阶段。
- 音频：不纳入 R5，避免混入非美术图片候选流程。
- 字体：涉及授权、渲染和多语言覆盖，暂缓。
- 完整主菜单背景：属于 C 类 / future contract，不服务首批 A / B 接口。
- 完整出发探索 UI：DeployPrep 结构仍需后续收敛。
- 完整长期系统 UI：LongTerm 仍以 future contract 为主。
- 完整角色动画：R5 只登记四向 idle，不登记完整 walk / combat / VFX。
- 完整 tileset：R5 只登记基础 room background 和关键 prop，不登记完整 tileset。
- reward VFX：表现复杂且接口收益不稳定，暂缓。
- 结算 / 历史最终缩略图：Settlement / History 仍需 snapshot 口径确认。

## 6. R6 进入条件

进入 R6 前必须满足：

- 授权 / source 状态清楚，不再停留在 `pending_verification`。
- 候选通过 review，不再停留在 `pending_review`。
- 明确允许复制到 Base Art staging。
- 规格确认，包括尺寸、透明背景、裁切、安全边界、锚点和状态枚举。
- 仍不得直接导入 Godot。
- 仍不得修改 manifest。
- 仍不得修改 scripts / scenes。
- 仍不得把 `assets`、`Base Docs`、`Connection` 或 Lua 原型路径直接写入 runtime 消费路径。

