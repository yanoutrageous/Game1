# S1 Interface Contracts

## Core Rule Interfaces

- `RunContext`: `reset_demo_run`, `is_inside`, `get_current_pos`, `get_status_snapshot`.
- `TruthMap`: `setup_demo_map`, `get_room_type`, `set_room_type`, `is_mine`, `get_adjacent_mine_count`, `is_inside`.
- `IntelMap`: `setup`, `reveal_cell`, `flag_cell`, `is_revealed`, `get_cell_info`, `get_all_cells`.
- `MinefieldService`: `count_adjacent_mines`, `get_neighbors_8`.
- `CommandBus`: `bind_context`, `start_demo_run`, `move_by`, `flag_current_cell`, `interact`, `extract`, `restart_run`.
- `RoomResolver`: `enter_room`, `interact_current_room`.
- `MiniMapViewModel`: `build_from_intel`.
- `HUDViewModel`: `build_status`.

## S1 Runtime Contract

- `Main.tscn` enters `RunScene.tscn` directly.
- `RunScene` creates a fixed 7x7 demo run with Spawn, Mine, Chest, Event, Monster, Exit, and Normal rooms.
- UI receives `HUDViewModel` and `MiniMapViewModel`; UI does not read `TruthMap` directly.
- Player input and debug buttons call `CommandBus`.
- Result output appears only after extract or run failure.

## Input Contract

- Move: `W`, `A`, `S`, `D`, arrow keys.
- Interact: `E`.
- Flag: `F`.
- Open map placeholder: `Tab` or `M`.
- Restart run: `R`.

## Placeholder Asset Contract

- `ContentDB.get_asset_ref(asset_id)` returns a texture only when a manifest row points to an existing Godot resource.
- `ContentDB.has_asset(asset_id)` is true only for existing loadable assets.
- `ContentDB.get_placeholder_label(asset_id)` provides a safe text label when an icon asset is absent.
- Unknown placeholder assets remain `license_status=unknown`, `replacement_needed=true`, and are internal only until replaced.
