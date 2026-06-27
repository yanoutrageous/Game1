# ART-12 Draw / Base Art Diff

文档状态：ART-12 validation evidence
生成时间：2026-06-27

## 0. 定位

本文档记录 `D:\AGAME1\Draw`、旧 GameJam `Draw` 与 `D:\AGAME1\Base Art` 的只读对账结果。目标是避免重复来源登记，并明确哪些内容只作为 lineage reference。

## 1. Draw 与 old Draw 镜像关系

| 项 | Draw | old Draw | 结果 |
| --- | ---: | ---: | --- |
| 总文件 | 998 | 998 | 一致 |
| `.png` | 969 | 969 | 一致 |
| `.json` | 19 | 19 | 一致 |
| `.md` | 8 | 8 | 一致 |
| `.html` | 1 | 1 | 一致 |
| `.zip` | 1 | 1 | 一致 |
| 相对路径 + 文件大小差异 | 0 | 0 | 一致 |

结论：ART-12 将 old Draw 视为 Draw 的历史镜像 / 迁移副本，不作为独立资产来源重复登记。后续若需要严谨 hash 对账，可另起阶段补 SHA256；本阶段不读取或写入素材内容。

## 2. Draw _manifest 关键信息

`asset_manifest.json` 指向的原始 draw_dir 是 `D:\A GAME\26.5.30 GameJam\Draw`，说明当前 `D:\AGAME1\Draw` 更像迁移后的工作路径。当前两者内容一致，因此来源口径采用：

```text
primary observed source: D:\AGAME1\Draw
historical lineage source: D:\A GAME\26.5.30 GameJam\Draw
```

`selected_assets.md` 记录：

- selected assets：54
- copied to `20_processed`：54
- copied to `30_game_ready`：27
- A assets copied to both `20_processed` and `30_game_ready`
- B assets copied only to `20_processed`
- C / D assets not copied

`duplicates.md` 记录：

- duplicate group：50
- 每组均要求 visually verify before discarding anything
- ART-12 不执行 discard / delete / move

## 3. Base Art 与 Draw 的对应关系

当前 `Base Art` 中与 Draw 对应的核心 staging 层：

| Base Art 层 | 文件数 | 来源判断 |
| --- | ---: | --- |
| `03_selected/draw_30_game_ready` | 52 | Draw `30_game_ready` 已选 source_selected |
| `05_export_runtime_candidates/art07_first_batch` | 52 | 首批 runtime candidate staging |
| `06_animation_sources/art07_character_candidates` | 48 | 角色帧 source |
| `07_sprite_sheets/art07_character_candidates` | 4 | 角色 sprite sheet source |

当前 `Base Art\08_visual_targets\ui_mockups` 有 10 个 reference_only 文件，来自 `Base` 的确定稿 / 示例图，不进入 runtime candidates。

## 4. 只能作为 lineage reference 的内容

- `D:\A GAME\26.5.30 GameJam\Draw`：作为旧路径 lineage，不作为独立来源。
- `D:\AGAME1\Draw\_manifest` 中的绝对 old Draw 路径：作为历史记录，不反推当前执行路径。
- `Base Art\Base` 三张确定稿及示例图：作为排版和风格 reference，不作为整屏 runtime UI。
- `Base Art\M1\Lua demo.mp4` 和 M1 图片：作为 HUD / key prompt / room structure reference，不作为 runtime 资产。
- duplicate group：只作为复核线索，不授权删除。

## 5. 可进入下一步 source_candidate 的内容

| 来源 | 推荐用途 | 备注 |
| --- | --- | --- |
| `Base Art\05_export_runtime_candidates\art07_first_batch\ui_key_prompt` | key prompt / bottom key bar | 已有 Godot manifest 记录，后续重点是视觉一致性和接线复核 |
| `Base Art\05_export_runtime_candidates\art07_first_batch\ui_deploy_*` | deploy prep panels / buttons / icons | 部分已导入，仍需产品化规格和 fallback policy |
| `Base Art\05_export_runtime_candidates\art07_first_batch\props` | HUD / room prop / loot visual | 已部分进入 manifest，可作为 ART-13 小批接线候选 |
| `Base Art\06_animation_sources` | 角色展示 / hero silhouette source | 需先确认角色展示策略，不直接全量导入 |
| `Base Art\07_sprite_sheets` | player / character sprite sheet candidate | 需先确认 animation_key 和 frame spec |
| `Draw\30_game_ready\rooms` | room background source candidate | 需 crop / review，当前不直接导入 |

## 6. 暂缓内容

- Draw `10_working/candidates` 全量候选。
- Draw duplicate 清理。
- old Draw 独立登记。
- debug_detected_boxes 相关文件进入 runtime。
- 整屏 UI mockup runtime 导入。
- 角色完整动画 runtime 导入。

## 7. 自检

- 未修改 Draw。
- 未修改 old Draw。
- 未修改 Base Art。
- 未执行 quarantine。
- 未导入 Godot。
- 未写 Base Art registry。
