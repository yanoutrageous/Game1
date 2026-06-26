# ART-08 Base Art staged assets 到 Godot manifest-backed runtime 接入

## 0. 文档定位

本文档记录 ART-08 从 Base Art staged runtime candidates 到 Godot runtime assets 的静态 manifest-backed 接入结果。它不是最终美术批准，不代表 UI / 场景已经接线，也不是 Godot 导入缓存或 `.import` 文件的授权。

本阶段只复制小批 PNG 到真实 Godot 项目 assets 目录，并追加 `data/assets/asset_manifest.csv`。未运行 Godot，未修改脚本、场景、`project.godot`、ContentDB、AssetCatalog 或 PresentationMapping。

## 1. 输入来源

- 输入来源固定为 `D:\AGAME1\Base Art\05_export_runtime_candidates\art07_first_batch`。
- 本阶段没有从 `D:\AGAME1\Draw` 直接导入，也没有修改 Draw。
- 本阶段没有修改 Base Art registry 或 Base Art 文件。
- ART-07 的 `08_visual_targets`、animation sources 和 sprite sheets 只作为后续参考，不进入本轮 runtime assets。

## 2. Import Scope

| category | count | target directories |
| --- | ---: | --- |
| item_consumable | 2 | res://assets/items/consumable |
| item_equipment | 2 | res://assets/items/equipment |
| item_recovered | 1 | res://assets/items/recovered |
| prop_art07 | 9 | res://assets/props/art07 |
| ui_deploy_button | 8 | res://assets/ui/deploy/buttons |
| ui_deploy_icon | 4 | res://assets/ui/deploy/icons |
| ui_deploy_panel | 3 | res://assets/ui/deploy/panels |
| ui_icon | 2 | res://assets/ui/icons |
| ui_key_prompt | 6 | res://assets/ui/key_prompt |
| ui_main_menu | 1 | res://assets/ui/main_menu |
| ui_panel | 1 | res://assets/ui/panels |

本轮计划接入并实际复制 39 个 PNG。所有目标路径位于 `Godot/GraytailGodot/assets/ui/...`、`Godot/GraytailGodot/assets/items/...` 或 `Godot/GraytailGodot/assets/props/art07/...`。

## 3. Manifest Update Summary

`asset_manifest.csv` 保持原 header 与字段顺序，只追加 39 行；没有删除、重排或改写既有行。新增记录统一使用 `source_status=staged_pending_review`，不声明 runtime wiring。

| asset_id | category | godot_path | needs_semantic_review |
| --- | --- | --- | --- |
| item.consumable.medkit | item_consumable | res://assets/items/consumable/item_consumable_medkit.png | no |
| item.consumable.syringe | item_consumable | res://assets/items/consumable/item_consumable_syringe.png | no |
| item.equipment.flashlight | item_equipment | res://assets/items/equipment/item_equipment_flashlight.png | no |
| item.equipment.goggles | item_equipment | res://assets/items/equipment/item_equipment_goggles.png | no |
| item.recovered.ore | item_recovered | res://assets/items/recovered/item_recovered_ore.png | no |
| prop.art07.00_baoxiang_kai | prop_art07 | res://assets/props/art07/00_baoxiang_kai.png | yes |
| prop.art07.01_cheli_zhuangzhi_an | prop_art07 | res://assets/props/art07/01_cheli_zhuangzhi_an.png | yes |
| prop.art07.02_cheli_zhuangzhi_liang | prop_art07 | res://assets/props/art07/02_cheli_zhuangzhi_liang.png | yes |
| prop.art07.04_shangren_tai | prop_art07 | res://assets/props/art07/04_shangren_tai.png | yes |
| prop.art07.05_yichang_hexin | prop_art07 | res://assets/props/art07/05_yichang_hexin.png | yes |
| prop.art07.07_lingjian_dui | prop_art07 | res://assets/props/art07/07_lingjian_dui.png | yes |
| prop.art07.08_saomiaoyi | prop_art07 | res://assets/props/art07/08_saomiaoyi.png | yes |
| prop.art07.10_yiliaobao | prop_art07 | res://assets/props/art07/10_yiliaobao.png | yes |
| prop.art07.11_wuzi_xiang | prop_art07 | res://assets/props/art07/11_wuzi_xiang.png | yes |
| ui.deploy.button.back_main | ui_deploy_button | res://assets/ui/deploy/buttons/ui_button_back_main.png | no |
| ui.deploy.button.confirm_deploy_large | ui_deploy_button | res://assets/ui/deploy/buttons/ui_button_confirm_deploy_large.png | no |
| ui.deploy.button.key_or_arrow_small_button | ui_deploy_button | res://assets/ui/deploy/buttons/ui_key_or_arrow_small_button.png | no |
| ui.deploy.button.nav_loadout | ui_deploy_button | res://assets/ui/deploy/buttons/ui_button_nav_loadout.png | no |
| ui.deploy.button.nav_recovery | ui_deploy_button | res://assets/ui/deploy/buttons/ui_button_nav_recovery.png | no |
| ui.deploy.button.nav_requisition | ui_deploy_button | res://assets/ui/deploy/buttons/ui_button_nav_requisition.png | no |
| ui.deploy.button.nav_talent_selected | ui_deploy_button | res://assets/ui/deploy/buttons/ui_button_nav_talent_selected.png | no |
| ui.deploy.button.nav_warehouse | ui_deploy_button | res://assets/ui/deploy/buttons/ui_button_nav_warehouse.png | no |
| ui.deploy.icon.armor | ui_deploy_icon | res://assets/ui/deploy/icons/ui_icon_armor.png | no |
| ui.deploy.icon.backpack | ui_deploy_icon | res://assets/ui/deploy/icons/ui_icon_backpack.png | no |
| ui.deploy.icon.bandage | ui_deploy_icon | res://assets/ui/deploy/icons/ui_icon_bandage.png | no |
| ui.deploy.icon.compass | ui_deploy_icon | res://assets/ui/deploy/icons/ui_icon_compass.png | no |
| ui.deploy.panel.deploy_main_blank | ui_deploy_panel | res://assets/ui/deploy/panels/ui_panel_deploy_main_blank.png | no |
| ui.deploy.panel.deploy_summary_blank | ui_deploy_panel | res://assets/ui/deploy/panels/ui_panel_deploy_summary_blank.png | no |
| ui.deploy.panel.frame_highlight | ui_deploy_panel | res://assets/ui/deploy/panels/ui_frame_highlight.png | no |
| ui.icon.jinbi_icon | ui_icon | res://assets/ui/icons/jinbi_icon.png | yes |
| ui.icon.xuetiao_tianchong | ui_icon | res://assets/ui/icons/xuetiao_tianchong.png | yes |
| ui.key_prompt.e | ui_key_prompt | res://assets/ui/key_prompt/ui_key_e.png | no |
| ui.key_prompt.esc | ui_key_prompt | res://assets/ui/key_prompt/ui_key_esc.png | no |
| ui.key_prompt.f | ui_key_prompt | res://assets/ui/key_prompt/ui_key_f.png | no |
| ui.key_prompt.m | ui_key_prompt | res://assets/ui/key_prompt/ui_key_m.png | no |
| ui.key_prompt.q | ui_key_prompt | res://assets/ui/key_prompt/ui_key_q.png | no |
| ui.key_prompt.t | ui_key_prompt | res://assets/ui/key_prompt/ui_key_t.png | no |
| ui.main_menu.background.no_text | ui_main_menu | res://assets/ui/main_menu/main_menu_bg_no_text.png | no |
| ui.panel.terminal_main | ui_panel | res://assets/ui/panels/ui_panel_terminal_main.png | yes |

## 4. Deferred Content

- `map_icon`：暂缓，等待 minimap / room icon 语义和既有资产去重确认。
- `map_tile_icon`：暂缓，等待 minimap tile 状态枚举与现有 manifest 对齐。
- 已知重复 / 暂缓 hash 文件：`props/03_baoxiang_guan.png`、`props/06_dici_xianjing.png`、`props/09_jinbi_dui.png`、`ui_button_blank/ui_button_blank_dark.png`。
- `Base Art\08_visual_targets`：整屏视觉稿只保留为 reference_only，不进入 runtime assets。
- `06_animation_sources` 与 `07_sprite_sheets`：角色动画源和 sprite sheet 不进入本轮 runtime candidates。
- Direct Draw import：仍禁止；后续接入必须继续经过 Base Art staging。

## 5. Static Validation Results

- 新增 PNG 文件存在性：通过，39 / 39。
- source / target SHA256 一致性：通过，39 / 39。
- 新增 asset_id 唯一性：通过。
- 新增 godot_path 唯一性：通过。
- 新增 godot_path 文件存在性：通过。
- `.import` / `.uid` / translation 副产物：不作为本轮产物；若外部监听生成，已从本轮允许状态中排除。

| asset_id | source_sha256 | staged_sha256 | hash_match |
| --- | --- | --- | --- |
| item.consumable.medkit | EC58BAE34F8CBD3612E8B9DC2326285126BA1CC34BD20246CF1BB78AC7AABB90 | EC58BAE34F8CBD3612E8B9DC2326285126BA1CC34BD20246CF1BB78AC7AABB90 | yes |
| item.consumable.syringe | 1D103D257DFA58ADF097BE31493DC94906836857DF6431B6D42065EA61FCDB45 | 1D103D257DFA58ADF097BE31493DC94906836857DF6431B6D42065EA61FCDB45 | yes |
| item.equipment.flashlight | 339826ACF7CEB1736B2A3D4B172022B0CD1ACE084AC49FEAA2DF65D5793C4A35 | 339826ACF7CEB1736B2A3D4B172022B0CD1ACE084AC49FEAA2DF65D5793C4A35 | yes |
| item.equipment.goggles | 24462587E2902253A8383BE61EDFA1EC3118A0FE4F1610840FD165309B80A335 | 24462587E2902253A8383BE61EDFA1EC3118A0FE4F1610840FD165309B80A335 | yes |
| item.recovered.ore | 78860D8DC692B4D2A4F6B1F985AF885F34B478B315B121C849EA5BDACD85D574 | 78860D8DC692B4D2A4F6B1F985AF885F34B478B315B121C849EA5BDACD85D574 | yes |
| prop.art07.00_baoxiang_kai | 3A4D3445312B5611B7F9FA9066FBE7FB666C48A074579BE7D303003CC9C0180A | 3A4D3445312B5611B7F9FA9066FBE7FB666C48A074579BE7D303003CC9C0180A | yes |
| prop.art07.01_cheli_zhuangzhi_an | FCE7959AE7A20F51707DC29AA16BD35448C26B1E11BE16A4B966E90B2E018F2A | FCE7959AE7A20F51707DC29AA16BD35448C26B1E11BE16A4B966E90B2E018F2A | yes |
| prop.art07.02_cheli_zhuangzhi_liang | 50B4239F76BF654686972C1D6D238F8481B29F7EAA6E0A99E3EBF1E1949146B2 | 50B4239F76BF654686972C1D6D238F8481B29F7EAA6E0A99E3EBF1E1949146B2 | yes |
| prop.art07.04_shangren_tai | 56C00AFD49CA374A53C9DC81A7E81883BD97CB0A995747C0108FD45D9B86C07F | 56C00AFD49CA374A53C9DC81A7E81883BD97CB0A995747C0108FD45D9B86C07F | yes |
| prop.art07.05_yichang_hexin | 1AF589B83403E204126CA1F7402158ACC183FB47CEC733B5FE75285505092908 | 1AF589B83403E204126CA1F7402158ACC183FB47CEC733B5FE75285505092908 | yes |
| prop.art07.07_lingjian_dui | 609C73CDDC5300809CF78E8E341DF5F077916CC8983BC0847FBFC9006AB9B6A6 | 609C73CDDC5300809CF78E8E341DF5F077916CC8983BC0847FBFC9006AB9B6A6 | yes |
| prop.art07.08_saomiaoyi | CFA8A370608EFB8C9BCCB747F143D06C45ECF19BC67AFB5A76E2F303047F3810 | CFA8A370608EFB8C9BCCB747F143D06C45ECF19BC67AFB5A76E2F303047F3810 | yes |
| prop.art07.10_yiliaobao | 7CF0D291EAA59A94FCA3B321443B98D281FBDB33A1302C8B75E3AD0606F08D63 | 7CF0D291EAA59A94FCA3B321443B98D281FBDB33A1302C8B75E3AD0606F08D63 | yes |
| prop.art07.11_wuzi_xiang | 6D2CF9DC683B69DF9CB9F428A764CB47F966987DFF426C27F8E8AAD72886BDDC | 6D2CF9DC683B69DF9CB9F428A764CB47F966987DFF426C27F8E8AAD72886BDDC | yes |
| ui.deploy.button.back_main | 5426CBCF75284BDE97B98A0E1677C9E78F349DCC6C78224F8E6441343BD0A3E2 | 5426CBCF75284BDE97B98A0E1677C9E78F349DCC6C78224F8E6441343BD0A3E2 | yes |
| ui.deploy.button.confirm_deploy_large | E245F3D25671EAB9C11A437933FB7C8A8D79F5F2129962273AEDBB6A3E2D7873 | E245F3D25671EAB9C11A437933FB7C8A8D79F5F2129962273AEDBB6A3E2D7873 | yes |
| ui.deploy.button.key_or_arrow_small_button | 8A70EF18582AA3D98BD6CA8E32D3790F2F169EA3F0EE43ACACC23F5A89471497 | 8A70EF18582AA3D98BD6CA8E32D3790F2F169EA3F0EE43ACACC23F5A89471497 | yes |
| ui.deploy.button.nav_loadout | 55B1B40BBC90B97A1C8FD6F0DAB23476EBCDB0E741748844A8D63F1670E0B74B | 55B1B40BBC90B97A1C8FD6F0DAB23476EBCDB0E741748844A8D63F1670E0B74B | yes |
| ui.deploy.button.nav_recovery | 578B1A0498EB34C117F45D78DE7A47DBFA604D2705B953E46940F4317302F02A | 578B1A0498EB34C117F45D78DE7A47DBFA604D2705B953E46940F4317302F02A | yes |
| ui.deploy.button.nav_requisition | 7C55CD1AE2789842C4D079A7B618E84A165AD72267612A3B8642037B3C1A4C8B | 7C55CD1AE2789842C4D079A7B618E84A165AD72267612A3B8642037B3C1A4C8B | yes |
| ui.deploy.button.nav_talent_selected | E051CF0398847504F69B14E18C65430F81CD9FA50DF712352E85BA169D25BBA0 | E051CF0398847504F69B14E18C65430F81CD9FA50DF712352E85BA169D25BBA0 | yes |
| ui.deploy.button.nav_warehouse | 28EAA56504E1F7EA3136BE8AD7478357E03C4E6C28AEB27D67C011CCE416951E | 28EAA56504E1F7EA3136BE8AD7478357E03C4E6C28AEB27D67C011CCE416951E | yes |
| ui.deploy.icon.armor | 29F71E2E65B31F0D3C1F0B6775482351C4837148E4D1773FAC4CB35127DC58F4 | 29F71E2E65B31F0D3C1F0B6775482351C4837148E4D1773FAC4CB35127DC58F4 | yes |
| ui.deploy.icon.backpack | B247A2ABA7509D1797376B95136A2D7155D13CC8470EE7233ACF450EFA5A7413 | B247A2ABA7509D1797376B95136A2D7155D13CC8470EE7233ACF450EFA5A7413 | yes |
| ui.deploy.icon.bandage | 8E5B26EB543E59A1B7D09BCDCC74803D1674BA4D3487C7FB10EE131FA5C18FE9 | 8E5B26EB543E59A1B7D09BCDCC74803D1674BA4D3487C7FB10EE131FA5C18FE9 | yes |
| ui.deploy.icon.compass | 016D4065BFBE7CA6406816F6BBA786C31F9D8CC2EACDD637A5257B822582E285 | 016D4065BFBE7CA6406816F6BBA786C31F9D8CC2EACDD637A5257B822582E285 | yes |
| ui.deploy.panel.deploy_main_blank | 222F475C981FA20063686E3BA1C203A46E04B9B2DBE6C6CDD1C4B5827E9EF525 | 222F475C981FA20063686E3BA1C203A46E04B9B2DBE6C6CDD1C4B5827E9EF525 | yes |
| ui.deploy.panel.deploy_summary_blank | 6893538A28D34001C2FFBF52DE811139936CAD2F24954A0588238A67DAEDFE75 | 6893538A28D34001C2FFBF52DE811139936CAD2F24954A0588238A67DAEDFE75 | yes |
| ui.deploy.panel.frame_highlight | 6A7B4D2BBC7A87236B11F52BEAA8568477428D86A288D987949EC11F1B5DD95D | 6A7B4D2BBC7A87236B11F52BEAA8568477428D86A288D987949EC11F1B5DD95D | yes |
| ui.icon.jinbi_icon | E6ED6B95506EF88CB28E54E4256737D5BEC22396F1B47B9863029E145962D08E | E6ED6B95506EF88CB28E54E4256737D5BEC22396F1B47B9863029E145962D08E | yes |
| ui.icon.xuetiao_tianchong | 2B1F1E10F40A7E125C8A056C9F03CA089CC7666587A6B803FA9354E9336AB3E8 | 2B1F1E10F40A7E125C8A056C9F03CA089CC7666587A6B803FA9354E9336AB3E8 | yes |
| ui.key_prompt.e | 819C31BC1070AC5C9832EEA32605584BC6D835ED952A40371AEC308F2379455A | 819C31BC1070AC5C9832EEA32605584BC6D835ED952A40371AEC308F2379455A | yes |
| ui.key_prompt.esc | 9A9A580FE1A1FB7268A905FA1E04B12576048D1D963CBB02F097E41B821E4EAB | 9A9A580FE1A1FB7268A905FA1E04B12576048D1D963CBB02F097E41B821E4EAB | yes |
| ui.key_prompt.f | EC188529DC43CB042E9EAFF489FBDFDD4B300B046B066FC666D2C4878DF98D87 | EC188529DC43CB042E9EAFF489FBDFDD4B300B046B066FC666D2C4878DF98D87 | yes |
| ui.key_prompt.m | 18E737B8021ED01216132B95494A0CB7D83D71D006CC3C87AA83B103140F1FCD | 18E737B8021ED01216132B95494A0CB7D83D71D006CC3C87AA83B103140F1FCD | yes |
| ui.key_prompt.q | 099706289B700AEBAF7B6B679E26B2D7D8414FD624B2C7673378629582A79682 | 099706289B700AEBAF7B6B679E26B2D7D8414FD624B2C7673378629582A79682 | yes |
| ui.key_prompt.t | 49AC601D40A4E14B5F76E5906F573C444C0A6D36EACA013B60B1B74C81DD3D47 | 49AC601D40A4E14B5F76E5906F573C444C0A6D36EACA013B60B1B74C81DD3D47 | yes |
| ui.main_menu.background.no_text | AC521358BBEFB53300C41E9B562D0610C707948DE891650B34CD037D572E4313 | AC521358BBEFB53300C41E9B562D0610C707948DE891650B34CD037D572E4313 | yes |
| ui.panel.terminal_main | 4BB57AC94C797BE82FD9B03B1EB708D87E3FE6CD014AF898A059486DCA6EACBC | 4BB57AC94C797BE82FD9B03B1EB708D87E3FE6CD014AF898A059486DCA6EACBC | yes |

## 6. Follow-up Hookup Conditions

ART-08 只完成静态 manifest-backed 小批导入准备。后续若要在 deploy UI、main menu、items 或 props 中实际显示这些图，必须在单独阶段完成 PresentationMapping / UI / ViewModel / fallback policy 接线与验收。

进入后续接线阶段前，仍需完成：命名审查、visual_key / intended_asset_id 确认、UI 尺寸规格确认、fallback 规则确认，以及是否需要替换现有占位资产的判断。
