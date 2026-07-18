# ART24 Run Presentation Interface V1

## 中文摘要

本接口只连接程序语义快照与美术表现。它不新增玩法命令、不决定奖励、不修改库存、不写入持久化。程序侧提供稳定语义字段和事件；美术侧通过 `visual_key` 解析素材与状态。

## RunPresentationSnapshot

| field | type | required | purpose |
| --- | --- | --- | --- |
| `viewport_profile` | StringName | yes | 逻辑分辨率/缩放档 |
| `gameplay_rect` | Rect2 | yes | 中央游戏区，背包/地面物品弹层必须以此居中 |
| `room_type` | StringName | yes | normal/mine/chest/event/monster/exit |
| `room_visual_state` | StringName | yes | 房型内部表现态 |
| `player_facing` | StringName | yes | down/left/right/up |
| `player_motion_state` | StringName | yes | idle/walk/hit/interact/attack；美术内部再映射 windup/swing/impact/recover |
| `hp_state` | Dictionary | yes | current/max/severity，只读 |
| `protocol_level` | int | yes | 5 最安全，1 最危险 |
| `action_states` | Array[Dictionary] | yes | 真实可用/禁用/按下状态 |
| `inventory_summary` | Dictionary | yes | 容量、计数、摘要，不含写操作 |
| `ground_loot_items` | Array[Dictionary] | yes | 当前房间地面物品快照 |
| `active_modal` | StringName | yes | none/map/inventory/ground_loot/event/pause/extract/result |
| `reduce_motion` | bool | yes | 静态 fallback 开关 |

## GroundLootVisualItem

```text
instance_id: String
item_id: StringName
icon_key: StringName
category: StringName
rarity: StringName
quantity: int
visual_state: StringName
```

`instance_id` 只用于命令关联，不得显示给玩家。`icon_key` 必须能解析到 fallback；新物品不允许要求重画整屏。

## 表现事件

```text
room_entered
player_moved
player_interacted
player_hurt
combat_started
combat_attack
combat_resolved
protocol_changed
loot_spawned
loot_removed
pickup_success
pickup_blocked
inventory_dropped
modal_opened
modal_closed
```

事件只触发表现，不是事实源。丢事件后，下一份完整快照必须能恢复正确静态状态。

## 版本与兼容

- V1 字段只能向后兼容地追加；删除、改名或改语义需要 V2。
- 未识别的房型、物品和事件必须回退到 `visual.art24.fallback.*`，不得报错或显示内部代码。
- 美术资产换路径只更新契约/manifest fragment，不要求程序修改。
