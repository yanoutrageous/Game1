# Godot Architecture Notes

最小架构原则：

- TruthMap 记录真实地图。
- IntelMap 记录玩家已知信息。
- MiniMap UI 只读 MiniMapViewModel。
- ContentDB 负责 asset_id / data_id 查询。
- CommandBus 负责玩家命令入口。
- RoomResolver 负责房间进入后的规则分发。
- 不要在 UI 脚本中直接修改核心状态。
- 不要在核心逻辑中硬编码图片、音频、字体路径。
