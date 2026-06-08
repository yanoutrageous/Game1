# Asset Import Rules

- 资产先登记再导入。
- 禁止直接把整个 Lua assets 目录全量复制进 Godot。
- 禁止导入未知授权字体、音乐、音效、视频。
- 小地图图标优先。
- 玩家占位图优先。
- 房间 Tile / 背景其次。
- UI 面板和按钮其次。
- 音效最后。
- 每个资产必须写入 `data/assets/asset_manifest.csv`。
