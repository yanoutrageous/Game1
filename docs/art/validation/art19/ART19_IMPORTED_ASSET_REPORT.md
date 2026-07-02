# ART-19 Imported Asset Report

## 0. 导入边界

- 修改外部 `sources/art`：否。
- 修改外部 `sources/draw`：否。
- 直接 runtime 读取外部 source：否。
- 新增 runtime PNG：是，位于 `Godot/GraytailGodot/assets/ui/art19/**`。
- 修改 `asset_manifest.csv`：是，仅追加 `ui.art19.*` 首批 UI 素材行。

## 1. 新增 Runtime PNG

| runtime path | source path | sha256 |
| --- | --- | --- |
| `Godot/GraytailGodot/assets/ui/art19/panels/terminal_main.png` | `sources/draw/30_game_ready/ui_panel/ui_panel_terminal_main.png` | `4BB57AC94C797BE82FD9B03B1EB708D87E3FE6CD014AF898A059486DCA6EACBC` |
| `Godot/GraytailGodot/assets/ui/art19/panels/deploy_main_blank.png` | `sources/draw/30_game_ready/ui_deploy_panel/ui_panel_deploy_main_blank.png` | `222F475C981FA20063686E3BA1C203A46E04B9B2DBE6C6CDD1C4B5827E9EF525` |
| `Godot/GraytailGodot/assets/ui/art19/panels/deploy_summary_blank.png` | `sources/draw/30_game_ready/ui_deploy_panel/ui_panel_deploy_summary_blank.png` | `6893538A28D34001C2FFBF52DE811139936CAD2F24954A0588238A67DAEDFE75` |
| `Godot/GraytailGodot/assets/ui/art19/panels/frame_highlight.png` | `sources/draw/30_game_ready/ui_deploy_panel/ui_frame_highlight.png` | `6A7B4D2BBC7A87236B11F52BEAA8568477428D86A288D987949EC11F1B5DD95D` |
| `Godot/GraytailGodot/assets/ui/art19/buttons/button_blank_dark.png` | `sources/draw/30_game_ready/ui_button_blank/ui_button_blank_dark.png` | `99DCED078AC8D2DBE127689D8005715F2878185B14884355BCBC4F471FD06A1C` |
| `Godot/GraytailGodot/assets/ui/art19/buttons/button_confirm_deploy_large.png` | `sources/draw/30_game_ready/ui_deploy_button/ui_button_confirm_deploy_large.png` | `E245F3D25671EAB9C11A437933FB7C8A8D79F5F2129962273AEDBB6A3E2D7873` |
| `Godot/GraytailGodot/assets/ui/art19/buttons/button_nav_talent_selected.png` | `sources/draw/30_game_ready/ui_deploy_button/ui_button_nav_talent_selected.png` | `E051CF0398847504F69B14E18C65430F81CD9FA50DF712352E85BA169D25BBA0` |
| `Godot/GraytailGodot/assets/ui/art19/bars/summary_bar_dark.png` | `sources/draw/30_game_ready/ui_summary_bar/ui_bar_blank_dark.png` | `DDE95EBD216C273230DE0E2776F445AE97D38B4C370FC2C4765AC24CFC468558` |
| `Godot/GraytailGodot/assets/ui/art19/bars/scrollbar_vertical.png` | `sources/draw/30_game_ready/ui_scrollbar/ui_scrollbar_vertical.png` | `6F4CEBABB51384A31E306D57475A6AD1EE2E5F02179844C55B66C4798A9A7906` |
| `Godot/GraytailGodot/assets/ui/art19/map64/player_marker_64.png` | `sources/draw/30_game_ready/icons/64/00_wanjia_dingwei.png` | `8C9E5FEF07B3727023AB6B382DA488AF2E5B8F43C565B22D5CE425C70575F836` |
| `Godot/GraytailGodot/assets/ui/art19/map64/unknown_cell_64.png` | `sources/draw/30_game_ready/icons/64/01_weizhi_ge.png` | `80CD787F8E0E0B306712A7B58C83100481C710B380D5EC38D2BB14517661566A` |
| `Godot/GraytailGodot/assets/ui/art19/map64/explored_cell_64.png` | `sources/draw/30_game_ready/icons/64/02_yitan_ge.png` | `3869461FBEF3CDEB66F16FA874610306C0E9E0C836E523022B33E526A743DD6B` |
| `Godot/GraytailGodot/assets/ui/art19/map64/scanned_cell_64.png` | `sources/draw/30_game_ready/icons/64/03_saomiao_ge.png` | `53ED5AFB260BA5ED3603F27C7D697CB71D44C79B68FF105BBEBED70D9752CB32` |
| `Godot/GraytailGodot/assets/ui/art19/map64/mine_icon_64.png` | `sources/draw/30_game_ready/icons/64/05_dici_xianjing_icon.png` | `F76605DFA2FA2B691DE2255FD9849C47C7198C4172A974C42A7DD6BD9A638A8F` |
| `Godot/GraytailGodot/assets/ui/art19/map64/chest_icon_64.png` | `sources/draw/30_game_ready/icons/64/07_baoxiang_icon.png` | `57D63A7C4CB7CAB747DC7C18F99AFC8EBD5D2C885712EAD7774553ECEB16EAF5` |
| `Godot/GraytailGodot/assets/ui/art19/map64/exit_icon_64.png` | `sources/draw/30_game_ready/icons/64/09_chukou_icon.png` | `19D5A2AEA1E8354E702B2A1741DA815389372414DDEFF99313FACA230310F7F9` |

## 2. Manifest

新增 asset_id 范围：

```text
ui.art19.panel.*
ui.art19.button.*
ui.art19.bar.*
ui.art19.scrollbar.*
ui.art19.map64.*
```

manifest 快检结果：

```text
DuplicateAssetIds: none
MissingPaths: none
Art19Rows: 16
```

## 3. 说明

本轮没有导入整屏 Base 确定稿。首批导入素材是可复用 UI 组件和 MapOverlay marker，用于让四核心界面出现真实 UI PNG 组件变化。
