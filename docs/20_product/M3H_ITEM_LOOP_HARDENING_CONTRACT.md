# M3H Item Loop Hardening Contract

中文摘要：M3H 是 M3/M3R 后的边界修正切片，目标是收紧局内装备、结算放弃分支、收益命名和 metadata hygiene，不扩展完整仓库、装备强化、Objective / Reward / Pool 或 Rule Engine。

## Scope

M3H hardens the existing M3/M3R item loop:

- In-run acquired equipment remains an inventory item until extraction / settlement registration.
- Carry-in equipment selected from DeployPrep remains active for the current run.
- Carry-in consumables remain valid failure salvage candidates when unused.
- Abandon uses the real `settle_abandon` branch and is neither success nor normal failure.
- `black_coin`, `safe_yield`, and `long_term_gold` are reported with explicit semantics.
- Godot generated metadata is not part of this implementation commit.

## Equipment Registration Boundary

In-run acquired equipment must not be equippable immediately. The authoritative block reason is:

```text
equipment_requires_extraction_registration
```

The runtime flags are:

```text
carry_in_equipment
carry_in_consumable
registered_for_run
acquired_in_run
equip_allowed_now
```

Only equipment carried in through the run start configuration is registered for the current run and allowed to be equipped immediately.

## Settlement and Currency Boundary

Currency naming is explicit:

- `black_coin`: run black coin, converted on success or lost on failure / abandon.
- `safe_yield`: in-run safe yield, internally compatible with historical `gold_coin` fields.
- `long_term_gold`: meta progression currency written after settlement.

Abandon result semantics:

- `outcome = abandon`
- `settlement_outcome = abandon`
- `safe_yield_state = pending_undecided`
- `long_term_gold_gained = 0`
- no success warehouse extraction fields

## Non-Goals

M3H does not implement:

- complete warehouse management
- complete equipment strengthening
- full Objective / Reward / Pool
- complete Rule Engine
- new item content expansion
- gameplay runtime PASS
- manual playtest PASS
- Godot metadata / resource import changes
