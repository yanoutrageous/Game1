# 《灰尾回收 / 五四三二一》规则、效果、Modifier 与内容投放通用系统策划案

## 独立策划案

---

## 0. 文档定位

本案用于定义游戏中规则触发、效果执行、Modifier 修正、内容池选择、掉落池投放、生成池解析与日志输出的统一框架。

本案承接以下已确认系统：

1. 地图本体与生成规则；
2. 局内流程与状态流转规则；
3. 房间类型、标签与遭遇通用规则；
4. 局内背包、GroundLoot、黑币与结算接口；
5. 出发探索中的本局配置；
6. 资产、仓库、申领、结算报告与长期系统；
7. 标签系统、Policy 系统、State 系统与 RunResult 输出链路。

本案不讨论：

1. 具体装备数值；
2. 具体消耗品数值；
3. 具体怪物数值；
4. 具体事件文本；
5. 具体宝箱奖励表；
6. 具体掉落概率；
7. 具体商人价格；
8. 具体研究项目；
9. 具体高难委托数值；
10. 完整规则脚本语言；
11. 复杂动态经济系统；
12. AI Director 类大型动态投放系统。

本案目标是建立一套轻量、可扩展、可调试、可逐步迁移的通用规则框架，避免装备、消耗品、事件、房间、怪物、宝箱、研究、高难委托、掉落池各自维护一套独立逻辑。

---

## 1. 系统总定位

本系统统一回答以下问题：

```text
什么时候触发？
什么条件下生效？
当前上下文是什么？
作用目标是谁？
受哪些标签、Policy、State、Modifier 影响？
执行什么效果？
是否需要从池中选择内容？
生成什么局内结果？
结果如何写入 RunLog、MapMutationLog 和 RunResult？
```

本系统同时服务：

1. 装备被动效果；
2. 消耗品主动效果；
3. 事件结果；
4. 房间规则；
5. 怪物技能；
6. 战斗奖励；
7. 宝箱奖励；
8. 搜索收益；
9. 商人商品；
10. 回收终端目录；
11. 高难委托 Modifier；
12. 研究解锁影响；
13. 地图规则变化；
14. Encounter 生成；
15. 房间内容投放；
16. 掉落池和奖励池解析。

本系统不直接写入长期仓库、长期图鉴、长期研究、资历、收藏或成就领取结果。
所有长期写回必须继续通过：

```text
Rule / Effect / Pool
→ 本局状态变化
→ RunResult
→ 结算报告
→ 仓库 / 图鉴 / 研究 / 历史 / 资历 / 收藏等长期系统
```

---

## 2. 总体架构

本系统采用以下结构：

```text
共享规则层：Rule / Trigger / Condition / Context / Target / Tag / Policy
Modifier 层：统一修正规则
EffectResolver：负责状态变化
PoolResolver：负责内容选择
Result 层：统一输出局内结果
Log 层：记录触发、过滤、权重、结果和调试信息
```

即：

```text
Rule
→ Trigger
→ Condition
→ Context
→ TargetSelector
→ Modifier
→ Operation
→ EffectResolver / PoolResolver
→ RunDelta / PoolResult / LootResult / EncounterResult
→ RunLog / MapMutationLog / RunResult
```

### 2.1 共享层与分支层

Effect 和 Pool 共享：

1. Trigger；
2. Condition；
3. Context；
4. TargetSelector；
5. Tags；
6. Modifier；
7. Priority；
8. Log。

但二者输出职责不同：

```text
EffectResolver：负责执行状态变化。
PoolResolver：负责从内容池中选择内容。
```

示例：

```text
扫描消耗品：
Rule 触发 → EffectResolver 扫描房间 → 更新 ScanLayer。

宝箱开启：
Rule 触发 → PoolResolver 抽取宝箱奖励 → EffectResolver 生成 GroundLoot。

高难委托：
Rule 触发 → EffectResolver 应用 Modifier → 后续 PoolResolver 和 EffectResolver 均读取该 Modifier。
```

---

## 3. 核心设计原则

### 3.1 当前阶段只做轻量规则框架

当前版本只建立有限规则解析框架。

应支持：

1. 有限 Trigger；
2. 有限 Condition；
3. 有限 Effect Operation；
4. 有限 PoolResolver；
5. 有限 Modifier；
6. 可记录日志；
7. 可复现随机结果；
8. 可逐步扩展字段；
9. 可与现有工程 additive 接入。

当前不做：

1. 完整脚本系统；
2. 任意表达式语言；
3. 多层嵌套规则链；
4. 全局复杂 AI Director；
5. 复杂动态经济系统；
6. 完整概率保底系统；
7. 大规模旧内容强制迁移；
8. 玩家可见完整标签系统。

### 3.2 标签、Policy、Rule、State 边界

本系统沿用此前确认的四层结构：

```text
Type：对象是什么；
Tags：对象如何分类和匹配；
Policy：对象真实如何运作；
State：本局内对象现在处于什么状态；
Rule：在特定 Trigger 下按条件执行操作。
```

标签不替代 Policy 和 Rule。

例如：

```text
tags = ["repeat.repeatable"]
```

只能说明该对象属于“可重复类”，不能自动等于：

1. 可重复奖励；
2. 可重复掉落；
3. 可重复推进目标；
4. 可重复增加压力；
5. 可重复记录图鉴。

这些必须通过 Policy 或 Rule 明确。

### 3.3 Pool 只生成局内结果

PoolResolver 允许生成：

1. GroundLoot；
2. 局内背包物；
3. 待结算黑币；
4. Encounter；
5. RoomStateDelta；
6. EncounterStateDelta；
7. Modifier；
8. RunLog；
9. RunResult 中的本局结果字段。

PoolResolver 不允许直接写入：

1. 长期仓库；
2. 长期图鉴完整解锁；
3. 长期研究完成；
4. 长期资历增加；
5. 收藏解锁；
6. 成就领取；
7. 长期任务奖励领取。

### 3.4 Modifier 必须可追踪

每个 Modifier 必须记录：

1. 来源 source；
2. 作用范围 scope；
3. 持续时间 duration；
4. 优先级 priority；
5. 叠加规则 stack_policy；
6. 移除条件 remove_condition；
7. 影响对象 affected_targets；
8. 是否写入日志。

没有来源、范围和持续时间的 Modifier 不应进入正式配置。

---

## 4. RuleDef：统一规则对象

Rule 是本系统的核心配置单位。

一条 Rule 描述：

```text
在什么时机触发；
什么条件下生效；
从哪些上下文读取信息；
作用目标是谁；
执行哪些操作；
受哪些 Modifier 影响；
结果如何记录。
```

### 4.1 RuleDef 基础字段

建议字段：

```text
rule_id
rule_type
display_name
description
trigger
conditions
context_requirements
target_selector
operations
priority
stack_policy
source_type
source_id
duration
log_policy
debug_tags
future_hooks
```

### 4.2 rule_type

基础 rule_type：

```text
effect_rule
pool_rule
modifier_rule
reward_rule
map_rule
objective_rule
encounter_rule
settlement_rule
```

说明：

1. effect_rule：执行状态变化；
2. pool_rule：请求内容池；
3. modifier_rule：应用或移除 Modifier；
4. reward_rule：生成局内奖励；
5. map_rule：影响地图、房间、信息层或回传规则；
6. objective_rule：推进或检查目标；
7. encounter_rule：生成或处理 Encounter；
8. settlement_rule：只用于本局结果整理，不直接写长期系统。

### 4.3 source_type

source_type 用于记录规则来源。

可选来源：

```text
equipment
consumable
room
encounter
event
monster
research
objective
high_difficulty
map_rule
system
debug
```

示例：

```text
装备被动效果：source_type = equipment
消耗品主动效果：source_type = consumable
事件污染区：source_type = encounter
高难委托禁用回传：source_type = high_difficulty
研究提高藏品权重：source_type = research
```

---

## 5. Trigger：触发时机

Trigger 是 Rule 的入口。当前版本应建立有限 Trigger 字典。

### 5.1 本局阶段 Trigger

```text
run_start
run_success
run_fail
run_abandon
run_settlement
```

用途：

1. run_start：应用装备、研究、高难、地图规则等本局起始 Modifier；
2. run_success：成功撤离后整理本局结果；
3. run_fail：失败后整理本局结果；
4. run_abandon：放弃后整理本局结果；
5. run_settlement：进入结算报告前生成 RunResult 汇总。

### 5.2 地图 / 房间 Trigger

```text
room_enter
room_scan
room_search
room_interact
room_clear
room_return
room_polluted
room_locked
room_unlocked
```

用途：

1. room_enter：进入房间；
2. room_scan：扫描房间；
3. room_search：搜索房间；
4. room_interact：与房间内容交互；
5. room_clear：房间被清理；
6. room_return：回传 / 快速回访；
7. room_polluted：房间进入污染状态；
8. room_locked：房间被封锁；
9. room_unlocked：房间解除封锁。

### 5.3 Encounter Trigger

```text
encounter_start
encounter_complete
encounter_fail
encounter_repeat
```

用途：

1. encounter_start：遭遇开始；
2. encounter_complete：遭遇完成；
3. encounter_fail：遭遇失败；
4. encounter_repeat：重复交互或重复触发。

### 5.4 战斗 Trigger

```text
combat_start
combat_victory
combat_defeat
combat_escape
monster_defeated
```

用途：

1. combat_start：战斗开始；
2. combat_victory：战斗胜利；
3. combat_defeat：战斗失败；
4. combat_escape：战斗撤退或逃离；
5. monster_defeated：单个怪物被击败。

### 5.5 物品 Trigger

```text
item_use
item_pickup
item_drop
item_consume
item_sell
item_equip
item_unequip
```

用途：

1. item_use：使用消耗品；
2. item_pickup：拾取物品；
3. item_drop：主动丢弃物品；
4. item_consume：物品被消耗；
5. item_sell：在合法功能区出售；
6. item_equip：装备；
7. item_unequip：卸下装备。

### 5.6 内容池 / 掉落池 Trigger

```text
chest_open
loot_generate
loot_pickup
search_reward_generate
monster_drop_generate
shop_refresh
encounter_generate
room_content_generate
```

用途：

1. chest_open：开启宝箱；
2. loot_generate：通用掉落生成；
3. loot_pickup：拾取掉落；
4. search_reward_generate：搜索收益生成；
5. monster_drop_generate：怪物掉落生成；
6. shop_refresh：商人或回收终端内容刷新；
7. encounter_generate：遭遇生成；
8. room_content_generate：房间内容生成。

### 5.7 目标 / 记录 Trigger

```text
objective_accept
objective_progress
objective_complete
objective_fail
codex_discover
research_condition_met
```

用途：

1. objective_accept：接取目标；
2. objective_progress：目标推进；
3. objective_complete：目标完成；
4. objective_fail：目标失败；
5. codex_discover：图鉴发现；
6. research_condition_met：研究条件满足。

---

## 6. Condition：条件判断

Condition 用于判断 Rule 是否生效。

Condition 只负责判断，不执行结果。

### 6.1 地图条件

```text
map_type_is
map_has_tag
run_difficulty_at_least
run_difficulty_below
seed_exists
```

### 6.2 房间条件

```text
room_type_is
room_has_tag
room_state_is
room_state_not
room_policy_is
room_is_current
room_is_adjacent
room_is_unknown
room_is_scanned
room_is_explored
room_is_cleared
room_has_ground_loot
room_in_polluted_area
```

### 6.3 Encounter 条件

```text
encounter_type_is
encounter_has_tag
encounter_state_is
encounter_policy_is
encounter_completed
encounter_not_completed
```

### 6.4 物品条件

```text
item_type_is
item_has_tag
item_state_is
player_has_item
player_has_equipment
item_is_in_backpack
item_is_ground_loot
item_is_sellable
item_is_droppable
item_is_objective_related
```

### 6.5 玩家 / 背包条件

```text
backpack_has_space
backpack_is_full
black_coin_at_least
player_has_modifier
player_not_has_modifier
```

### 6.6 目标 / 研究条件

```text
objective_active
objective_has_tag
objective_state_is
research_unlocked
research_condition_met
codex_discovered
```

### 6.7 Modifier 条件

```text
modifier_active
modifier_not_active
modifier_source_is
modifier_scope_is
pressure_level_at_least
pressure_level_below
```

### 6.8 示例

宝箱掉落规则条件：

```text
room_type_is("treasure")
room_state_not("opened")
```

扫描消耗品条件：

```text
item_has_tag("effect.scan")
target_room_is_unknown
current_context_is("map")
```

高难奖励修正规则条件：

```text
modifier_active("high_risk_reward_up")
room_has_tag("reward.item_source")
```

---

## 7. Context：规则解析上下文

Context 是规则执行时读取的环境快照。
Rule、EffectResolver、PoolResolver 都从 Context 读取数据，避免直接耦合多个系统。

### 7.1 RunContext

```text
run_id
seed
map_id
map_type
difficulty
selected_objectives
active_modifiers
pressure_state
current_step
result_state
```

### 7.2 MapContext

```text
truth_map_ref
known_map_ref
scan_layer_ref
mark_map_ref
info_reliability_layer_ref
map_mutation_log_ref
```

### 7.3 RoomContext

```text
current_room_id
room_type
room_tags
room_state
room_policies
ground_loot_state
info_reliability_state
```

### 7.4 EncounterContext

```text
encounter_id
encounter_type
encounter_tags
encounter_state
encounter_policies
repeat_state
```

### 7.5 PlayerContext

```text
current_room_id
available_actions
locked_actions
active_status
```

### 7.6 InventoryContext

```text
backpack_used
backpack_limit
items_in_backpack
equipped_items
consumables_available
black_coin_pending
ground_loot_visible
```

### 7.7 ObjectiveContext

```text
active_objectives
objective_states
objective_tags
objective_related_items
```

### 7.8 ResearchContext

```text
unlocked_research
active_research_modifiers
research_conditions_met
```

### 7.9 ModifierContext

```text
active_modifiers
modifier_sources
modifier_priority
modifier_duration
modifier_stack_state
```

### 7.10 SettlementContext

```text
run_result_preview
success_policy
fail_policy
abandon_policy
item_settlement_policy
black_coin_settlement_policy
```

---

## 8. TargetSelector：作用目标

TargetSelector 负责选择规则作用对象。

### 8.1 通用目标

```text
self
current_room
current_encounter
player
player_backpack
ground_loot_current_room
selected_item
selected_pool
```

### 8.2 房间目标

```text
adjacent_rooms
adjacent_unknown_rooms
adjacent_explored_rooms
random_unknown_room
random_explored_room
all_rooms_with_tag
evacuation_room
objective_target_room
```

### 8.3 内容目标

```text
current_monster
selected_monster
selected_loot_pool
selected_encounter_pool
selected_shop_pool
objective_target
```

### 8.4 失败处理

每个 TargetSelector 必须定义无合法目标时如何处理：

```text
fail
do_nothing
fallback_to_current_room
fallback_to_random_valid_room
refund_cost
show_invalid_target
```

示例：

扫描道具：

```text
target_selector = adjacent_unknown_rooms
no_valid_target = show_invalid_target
```

空降道具：

```text
target_selector = random_unknown_room
no_valid_target = refund_cost
```

宝箱奖励：

```text
target_selector = ground_loot_current_room
no_valid_target = fail
```

---

## 9. Operation：统一操作类型

Rule 的 operations 可以包含 Effect 操作、Pool 请求、Modifier 操作、日志操作等。

### 9.1 基础 Operation

```text
apply_effect
request_pool
modify_pool_weight
spawn_loot
spawn_encounter
add_black_coin
consume_item
drop_item_to_ground
change_room_state
change_encounter_state
apply_modifier
remove_modifier
update_objective
record_codex_discovery
write_run_log
write_map_mutation
trigger_failure
trigger_evacuation
```

### 9.2 Operation 执行顺序

一条 Rule 可以执行多个 Operation。
建议执行顺序为：

```text
校验条件
→ 选择目标
→ 消耗成本
→ 请求 Pool
→ 应用 Effect
→ 生成结果
→ 更新状态
→ 写入日志
```

示例：宝箱开启

```text
trigger = chest_open
operations:
  - request_pool("treasure_loot_pool")
  - spawn_loot(result_to_ground_loot)
  - change_room_state("opened")
  - change_room_state("depleted")
  - write_run_log
```

示例：事件污染区

```text
trigger = room_interact
operations:
  - apply_modifier("info_unreliable_area")
  - change_info_reliability("unreliable")
  - write_map_mutation
  - write_run_log
```

---

## 10. EffectResolver

EffectResolver 负责执行状态变化。

### 10.1 Effect Operation 字典

当前版本建议支持：

```text
scan_room
reveal_room_info
change_info_reliability
add_pressure
reduce_pressure
apply_pollution
clear_pollution
lock_room
unlock_room
change_room_state
change_encounter_state
add_black_coin
consume_item
add_item_to_backpack
drop_item_to_ground
spawn_ground_loot
force_move_player
enable_evacuation
disable_return
enable_return
update_objective
record_codex_discovery
apply_modifier
remove_modifier
trigger_failure
trigger_evacuation
write_run_log
write_map_mutation
```

### 10.2 Effect 输出

EffectResolver 输出：

```text
EffectResult
RunDelta
MapDelta
RoomStateDelta
EncounterStateDelta
InventoryDelta
ObjectiveDelta
PressureDelta
CodexDelta
MapMutation
RunLogEntry
```

### 10.3 Effect 边界

EffectResolver 允许改变本局状态：

1. 房间状态；
2. Encounter 状态；
3. 地图信息层；
4. 扫描层；
5. 污染区；
6. 回传规则；
7. 玩家局内背包；
8. GroundLoot；
9. 黑币待结算收益；
10. 本局目标状态；
11. 图鉴临时发现；
12. RunLog。

EffectResolver 不允许直接改变：

1. 长期仓库；
2. 长期图鉴完整状态；
3. 长期研究完成状态；
4. 资历等级；
5. 收藏展示；
6. 长期任务奖励领取。

---

## 11. PoolResolver

PoolResolver 负责从池中选择内容。

### 11.1 Pool 类型

当前版本建议实现：

```text
LootPool
SearchPool
EncounterPool
ShopPool
ModifierPool
```

后续预留：

```text
RoomPool
RewardPool
MonsterPool
EventPool
ObjectivePool
ResearchPool
BossPool
MapRulePool
GachaPool
```

### 11.2 当前实现 Pool

LootPool：

```text
宝箱奖励
怪物掉落
事件奖励
特殊掉落
```

SearchPool：

```text
普通房搜索收益
特殊搜索收益
黑币搜索结果
```

EncounterPool：

```text
基础事件
基础怪物遭遇
基础宝箱遭遇
基础撤离遭遇
```

ShopPool：

```text
商人商品
回收终端目录
基础交易内容
```

ModifierPool：

```text
高难基础 Modifier
地图规则基础 Modifier
事件结果 Modifier
```

### 11.3 PoolDef 字段

```text
pool_id
pool_type
tags
allowed_contexts
required_conditions
blocked_conditions
entries
weight_rules
modifier_hooks
fallback_policy
limit_policy
debug_note
```

### 11.4 PoolEntry 字段

```text
entry_id
entry_type
entry_tags
base_weight
conditions
min_difficulty
max_difficulty
unique_policy
repeat_policy
limit_per_run
limit_per_room
limit_per_pool
result_type
result_payload
```

### 11.5 PoolResolver 流程

```text
1. 接收 pool_request
2. 读取 Context
3. 找到目标 PoolDef
4. 过滤不满足条件的 Entry
5. 应用标签筛选
6. 应用基础权重
7. 应用 Modifier 权重修正
8. 检查唯一、次数、重复规则
9. 抽取结果
10. 生成 PoolResult
11. 交给 EffectResolver 或对应系统执行
12. 写入 RunLog
```

### 11.6 PoolResult

PoolResult 应记录：

```text
pool_id
request_source
context_snapshot_id
candidate_entries
filtered_entries
filter_reasons
applied_modifiers
final_weights
selected_entry_id
roll_seed
roll_value
result_payload
```

---

## 12. Fallback Policy

所有 Pool 必须有 fallback。
禁止出现“池为空导致流程断裂”。

### 12.1 默认 fallback

LootPool 为空：

```text
给少量黑币或生成 empty_loot_result
```

SearchPool 为空：

```text
返回 empty_search_result
```

EncounterPool 为空：

```text
返回 empty_encounter 或基础普通事件
```

ShopPool 为空：

```text
显示无可交易内容
```

ModifierPool 为空：

```text
不应用 Modifier
```

MonsterPool 为空：

```text
给低阶默认怪或跳过遭遇
```

RoomContentPool 为空：

```text
按普通房处理
```

### 12.2 fallback 记录

Fallback 也必须写入日志：

```text
pool_id
fallback_reason
fallback_result
context_snapshot
```

---

## 13. Modifier 系统

Modifier 是统一修正系统，可同时影响 EffectResolver 和 PoolResolver。

### 13.1 Modifier 来源

Modifier 可以来自：

```text
equipment
consumable
event
room
encounter
map_rule
research
high_difficulty
monster
pollution
system
```

### 13.2 ModifierDef 字段

```text
modifier_id
modifier_type
source_type
source_id
tags
scope
duration
priority
stack_policy
conditions
affected_targets
effect_modifiers
pool_modifiers
policy_modifiers
log_policy
remove_condition
```

### 13.3 scope

```text
global_run
map_area
room
encounter
player
item
pool
objective
```

### 13.4 duration

```text
instant
until_room_exit
until_encounter_end
until_run_end
fixed_steps
permanent_in_run
conditional
```

### 13.5 priority

priority 用于解决冲突。
优先级较高的 Modifier 可覆盖较低 Modifier。

冲突示例：

```text
研究允许回传强化；
高难委托禁止污染区回传；
事件临时封锁当前房间。
```

需要通过 priority 判断最终结果。

### 13.6 stack_policy

默认叠加规则：

```text
同源唯一：同一个 source 的同类 Modifier 默认不重复叠加；
不同源可叠加：装备、研究、事件、高难可按规则叠加；
冲突时按 priority 处理；
未声明 stack_policy 的 Modifier 默认 replace 或 highest_only；
不允许默认无限叠加。
```

可选 stack_policy：

```text
none
replace
stack_add
stack_multiply
highest_only
lowest_only
unique_source_only
```

### 13.7 Modifier 影响对象

Modifier 可影响：

1. Effect 是否生效；
2. Effect 数值；
3. Effect 目标数量；
4. Pool 选择；
5. Pool 权重；
6. Pool entry 是否可用；
7. 房间搜索规则；
8. 回传规则；
9. Encounter 重复规则；
10. 压力变化；
11. 信息可信度；
12. 撤离条件；
13. 掉落数量；
14. 稀有度权重；
15. 黑币获得量。

### 13.8 Modifier 示例

高难奖励提升：

```text
modifier_id = high_risk_reward_up
source_type = high_difficulty
scope = global_run
duration = until_run_end
pool_modifiers:
  entries_with_tag("rarity.rare") weight +20%
effect_modifiers:
  pressure_gain +1
```

研究藏品倾向：

```text
modifier_id = relic_research_minor
source_type = research
scope = global_run
duration = until_run_end
pool_modifiers:
  entries_with_tag("reward.collection_source") weight +10%
```

污染区信息失真：

```text
modifier_id = polluted_info_unreliable
source_type = event
scope = map_area
duration = conditional
policy_modifiers:
  info_reliability = unreliable
log_policy = write_map_mutation
```

---

## 14. 重复触发与防刷规则

全局原则：

```text
可重复交互 ≠ 可重复奖励
可重复奖励 ≠ 可重复掉落
可重复触发 ≠ 可重复推进目标
可重复查看 ≠ 可重复记录图鉴
```

### 14.1 需要拆分的 Policy

```text
repeat_interaction_policy
repeat_reward_policy
repeat_progress_policy
repeat_loot_policy
repeat_pressure_policy
```

### 14.2 默认规则

宝箱：

```text
repeat_interaction_policy = once
repeat_reward_policy = once
repeat_loot_policy = once
```

普通搜索：

```text
search_policy = search_once
repeat_reward_policy = once
```

怪物掉落：

```text
repeat_loot_policy = once_per_monster_defeat
```

商人 / 回收终端：

```text
repeat_interaction_policy = repeatable
repeat_reward_policy = transaction_based
```

规则房：

```text
repeat_interaction_policy = repeatable
repeat_reward_policy = none
repeat_progress_policy = once_or_none
```

赌博 / 风险事件：

```text
repeat_interaction_policy = repeatable
repeat_reward_policy = cost_based
repeat_pressure_policy = by_encounter
```

### 14.3 目标 / 图鉴防刷

同一事件同一局内默认只推进一次目标或图鉴，除非目标或事件明确声明可重复计数。

---

## 15. 随机、确定性与可复现

所有池解析结果必须可记录、可复现、可调试。

### 15.1 必须记录

```text
pool_id
触发来源
上下文快照
候选 entry
过滤掉的 entry
过滤原因
应用的 Modifier
基础权重
最终权重
抽取结果
seed / roll
结果 payload
```

### 15.2 Active Run 存档

必须保存：

```text
active_modifiers
modifier_duration
modifier_stack_state
pool_results_already_generated
unique_entry_used_state
ground_loot
room_state
encounter_state
run_log
map_mutation_log
random_seed_state 或 deterministic roll record
```

避免：

1. 读档后宝箱重复抽取；
2. 怪物掉落重复生成；
3. 事件奖励消失；
4. Modifier 丢失；
5. 污染区状态不一致；
6. 目标进度重复推进。

---

## 16. 玩家可见规则变化

凡是影响玩家判断的信息变化，都必须有玩家可读提示。

必须提示的变化包括：

```text
信息不可信
雷数污染
回传被禁止
撤离条件变化
搜索规则变化
房间被封锁
强制移动
压力规则变化
显著掉落规则变化
```

特别规则：

1. 信息不可信必须写入 InfoReliabilityLayer；
2. 地图规则变化必须写入 MapMutationLog；
3. 禁止回传、封锁、污染等状态应在地图或房间详情中可读；
4. 不能只在后台悄悄改变核心判断条件。

---

## 17. 标签与池解析关系

标签用于筛选、匹配、调试和内容组织。
标签不直接替代 Policy。

### 17.1 Pool 中标签用途

Pool 可使用标签进行：

1. allowed_tags 筛选；
2. blocked_tags 排除；
3. required_tags 条件；
4. weight_rules 加权；
5. modifier_hooks 匹配。

示例：

```text
宝箱池允许 reward.item_source；
高难 modifier 提高 rarity.rare 权重；
研究 modifier 提高 reward.collection_source 权重。
```

### 17.2 标签不直接决定行为

例如：

```text
tags = ["repeat.repeatable"]
```

不能自动让对象重复奖励。
必须通过：

```text
repeat_reward_policy = repeatable
```

或明确 Rule 来决定。

---

## 18. 与各系统的关系

### 18.1 与装备系统

装备可以提供：

1. run_start 触发的被动 Modifier；
2. 特定 Trigger 下的效果；
3. 对 Pool 的权重修正；
4. 对扫描、压力、背包、搜索、战斗等系统的轻量影响。

装备不应直接修改长期仓库或长期系统。

### 18.2 与消耗品系统

消耗品通常通过 item_use 触发 Rule。

可执行：

1. 扫描；
2. 揭示信息；
3. 减压；
4. 强制移动；
5. 解锁或影响撤离；
6. 临时 Modifier；
7. 生成或改变 GroundLoot；
8. 消耗自身。

### 18.3 与事件系统

事件可以执行：

1. Effect；
2. Pool 请求；
3. Modifier 应用；
4. MapMutation；
5. ObjectiveDelta；
6. RunLog。

事件结果必须写入日志。

### 18.4 与怪物 / 战斗系统

战斗胜利可触发：

1. combat_victory；
2. monster_drop_generate；
3. ObjectiveDelta；
4. CodexDelta；
5. RoomStateDelta；
6. GroundLoot 生成。

怪物掉落不直接入仓。

### 18.5 与宝箱系统

宝箱开启触发 chest_open。

默认流程：

```text
检查宝箱未开启
→ 请求 LootPool
→ 生成 GroundLoot
→ 房间状态 opened / depleted
→ 写入 RunLog
```

### 18.6 与目标系统

目标可监听 Rule 输出的 ObjectiveDelta。

Pool、Effect、Modifier 不直接完成长期目标奖励领取。
目标最终完成状态在结算报告中确认。

### 18.7 与研究系统

研究可在 run_start 应用 Modifier。

研究可以影响：

1. 信息展示；
2. 掉落池权重；
3. 特定标签物品出现倾向；
4. 目标 / 图鉴 / 事件的解释信息。

研究不应直接在局内完成长期奖励发放。

### 18.8 与结算系统

结算报告读取 RunResult。

Rule / Effect / Pool 输出的本局结果包括：

1. 背包物；
2. GroundLoot；
3. 黑币；
4. 掉落记录；
5. 事件记录；
6. 目标状态；
7. 图鉴发现；
8. 研究条件变化；
9. 压力变化；
10. MapMutationLog。

结算报告决定最终写回。

---

## 19. 典型案例

### 19.1 扫描消耗品

```text
source_type = consumable
trigger = item_use
conditions:
  - item_has_tag("effect.scan")
  - current_context_is("map")
target_selector = adjacent_unknown_rooms
operations:
  - scan_room
  - consume_item
  - write_run_log
```

结果：

```text
更新 ScanLayer
消耗物品
不触发房间
不增加压力
写入 RunLog
```

### 19.2 宝箱掉落

```text
source_type = room
trigger = chest_open
conditions:
  - room_type_is("treasure")
  - room_state_not("opened")
target_selector = current_room
operations:
  - request_pool("treasure_loot_pool")
  - spawn_ground_loot
  - change_room_state("opened")
  - change_room_state("depleted")
  - write_run_log
```

### 19.3 怪物掉落

```text
trigger = combat_victory
conditions:
  - encounter_has_tag("function.combat")
target_selector = current_room
operations:
  - request_pool("monster_drop_pool")
  - spawn_ground_loot
  - change_room_state("cleared")
  - update_objective
  - record_codex_discovery
  - write_run_log
```

### 19.4 污染区事件

```text
trigger = room_interact
source_type = encounter
conditions:
  - encounter_has_tag("risk.pollution")
target_selector = nearby_rooms
operations:
  - apply_modifier("info_unreliable_area")
  - change_info_reliability("unreliable")
  - write_map_mutation
  - write_run_log
```

### 19.5 研究影响掉落池

```text
trigger = run_start
source_type = research
conditions:
  - research_unlocked("relic_research_01")
operations:
  - apply_modifier("relic_drop_minor_up")
```

Modifier：

```text
pool_modifiers:
  entries_with_tag("reward.collection_source") weight +10%
```

### 19.6 高难委托

```text
trigger = run_start
source_type = high_difficulty
operations:
  - apply_modifier("return_disabled_in_polluted_rooms")
  - apply_modifier("rare_reward_weight_up")
  - apply_modifier("pressure_gain_up")
```

后续：

1. 回传检查读取 return modifier；
2. 宝箱掉落读取 pool modifier；
3. 探索未知房读取 pressure modifier。

---

## 20. 当前版本实现范围

### 20.1 当前应实现

```text
RuleDef 基础结构
Trigger 字典基础版
Condition 字典基础版
Context 快照
TargetSelector 基础版
Effect Operation 基础版
PoolDef / PoolEntry
PoolResolver 基础流程
ModifierDef 基础结构
Fallback Policy
RunLog 记录
PoolResult 记录
GroundLoot 输出
RunResult 汇总
调试显示
```

### 20.2 当前 Effect Operation 范围

```text
scan_room
reveal_room_info
change_room_state
change_encounter_state
spawn_ground_loot
add_black_coin
consume_item
drop_item_to_ground
add_pressure
reduce_pressure
apply_modifier
remove_modifier
update_objective
record_codex_discovery
write_run_log
write_map_mutation
trigger_failure
trigger_evacuation
```

### 20.3 当前 Pool 范围

```text
LootPool
SearchPool
EncounterPool
ShopPool
ModifierPool
```

### 20.4 当前暂不实现

```text
复杂表达式语言
任意脚本规则
多层嵌套 Rule
复杂概率保底系统
复杂动态经济系统
AI Director
完整跨局规则引擎
完整玩家可见标签系统
复杂多阶段事件链
```

---

## 21. 调试工具需求

本系统必须具备调试能力。

至少显示：

```text
当前 Trigger
命中的 Rule
未命中的 Rule
失败 Condition
当前 Context
当前 active Modifier
Pool 候选 Entry
过滤掉的 Entry
权重修正前后
最终抽取结果
Effect 输出 Delta
RunLog
MapMutationLog
```

调试工具应支持：

```text
手动触发 Trigger
手动添加 Modifier
手动移除 Modifier
手动请求 Pool
固定 seed 测试掉落
导出规则解析日志
批量模拟掉落池
批量模拟 Encounter 池
批量模拟地图生成池
```

---

## 22. 最低验收标准

当前阶段最低验收标准：

1. 能定义 RuleDef；
2. 能按 Trigger 找到候选 Rule；
3. 能根据 Condition 判断 Rule 是否生效；
4. 能构建 Context 快照；
5. 能通过 TargetSelector 找到合法目标；
6. 能执行基础 Effect Operation；
7. 能请求 Pool；
8. 能过滤 PoolEntry；
9. 能应用基础权重；
10. 能应用 Modifier 权重修正；
11. 能生成 PoolResult；
12. 能生成 GroundLoot；
13. 能应用 Modifier；
14. 能按 duration 移除 Modifier；
15. 能防止同源 Modifier 无限叠加；
16. 能处理 Pool fallback；
17. 能记录随机结果；
18. 能写入 RunLog；
19. 能写入 MapMutationLog；
20. 能输出 RunResult 需要的本局变化；
21. Pool 不直接写长期系统；
22. 标签不替代 Policy；
23. 影响玩家判断的规则变化可被 UI 或调试层读取。

---

## 23. 后续扩展范围

后续可扩展：

1. 更复杂 Condition；
2. 更复杂 TargetSelector；
3. 多段 Rule 链；
4. 条件 Encounter；
5. 连锁事件；
6. 多阶段事件；
7. BossPool；
8. ObjectivePool；
9. ResearchPool；
10. GachaPool；
11. 复杂掉落保底；
12. 动态经济调控；
13. AI Director；
14. 跨局长期 Modifier；
15. 玩家可见规则词条系统；
16. 高级标签驱动研究和目标系统。

---

## 24. 总结

本案确立以下核心规则：

1. 效果系统、Modifier 系统、内容池、掉落池、生成池共享 Rule / Trigger / Condition / Context / Target / Tag / Modifier 底层逻辑；
2. EffectResolver 负责状态变化；
3. PoolResolver 负责内容选择；
4. Modifier 同时可以影响 Effect 和 Pool；
5. 标签用于分类、筛选、匹配、调试和内容组织；
6. Policy 和 Rule 决定真实行为；
7. Pool 只生成局内结果，不直接写长期系统；
8. 所有结果先进入本局状态，再由 RunResult 交给结算报告；
9. 当前版本只实现轻量规则框架，不做完整规则引擎；
10. Pool 必须有 fallback；
11. 随机结果必须可记录、可复现、可调试；
12. Modifier 必须记录来源、作用范围、持续时间、优先级、叠加规则和移除条件；
13. 影响玩家判断的规则变化必须有玩家可读提示；
14. 本系统完成后，装备、消耗品、事件、宝箱、怪物、研究、高难委托和内容池都可以接入同一套底层框架。
