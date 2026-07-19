# ART24R2 物品素材导入门禁

文档状态：执行中静态门禁记录
适用阶段：ART24R2 局内美术返工

## 1. 来源与边界

- 当前运行事实源仍为活动 worktree 中的 Godot 工程。
- 素材检索固定遵循“当前 Godot 清单 → 项目素材库 → UE 原型 → 确认缺失后新制”的顺序；不得因已有临时图或新制图而跳过更高优先级候选。
- 本次物品缺口在当前 Godot 与项目素材库没有完整覆盖后，才从用户明确提供的同项目 UE 原型仓库读取现有美术素材；UE 不作为运行与验收标准。
- 只读来源仓库：`D:\AGAME1\external\ue_prototype`。
- 来源提交：`de4ece1163505d9fe08e31cd0dbe10477909f963`，导入前工作区为空。
- 目标仅限 `Godot/GraytailGodot/assets/items/recovered`、`Godot/GraytailGodot/assets/items/loadout` 和已有 `asset_manifest.csv`。
- 不复制 `.meta`、`.import`、`.uid`、`.translation`、scene、resource 或 `project.godot`。
- ART08 已存在且哈希一致的 medkit、syringe、flashlight、goggles、ore 不重复复制。
- ART08 已存在的 `props/art07/00_baoxiang_kai.png` 经本阶段语义复审后复用为箱体打开态；它与 `chest_closed.png` 成对，不再保持“待语义确认”。

## 2. 导入清单

| source relative path | target Godot path | SHA256 |
| --- | --- | --- |
| `assets/item_recovered/anomaly_core_shard.png` | `res://assets/items/recovered/anomaly_core_shard.png` | `FE1155FA3444D6F8EA163C94C9B349ED975B108A7A67D76F77C26D064C36C09B` |
| `assets/item_recovered/blackbox_tag.png` | `res://assets/items/recovered/blackbox_tag.png` | `4E812BB7E508FD639E4EA2A85ECCB190ED4F1F88A7FB2BFABF6DCE17A112FB8C` |
| `assets/item_recovered/broken_copper_wire.png` | `res://assets/items/recovered/broken_copper_wire.png` | `566FA6F94FFA732C18D28BB8421F59836A162A2B95775E5EE29A383E339AA01D` |
| `assets/item_recovered/broken_terminal.png` | `res://assets/items/recovered/broken_terminal.png` | `DC92C2E968D3DEB1B34EEAEC61D43936A5073281EFF6123E56027C9694FA406A` |
| `assets/item_recovered/damaged_circuit.png` | `res://assets/items/recovered/damaged_circuit.png` | `62038A5F4804C2425F6A36D8A896BD3B54B21C26DA21F2574FCC27800CB25629` |
| `assets/item_recovered/data_disk.png` | `res://assets/items/recovered/data_disk.png` | `CB6AED7523604487F4BF0996717ADFF837567A6646724C790263500E93758A91` |
| `assets/item_recovered/dead_battery.png` | `res://assets/items/recovered/dead_battery.png` | `8417A54C0A58B0814978E088193DF0A4951CF211C44250F664114AF343DE4710` |
| `assets/item_recovered/dim_capacitor.png` | `res://assets/items/recovered/dim_capacitor.png` | `4EF0282C693119C35A9172AB102BBA7B91B3C4898A6419A1941A590759681A6E` |
| `assets/item_recovered/fluorescent_shard.png` | `res://assets/items/recovered/fluorescent_shard.png` | `668EA1BA56C8522755B42702A9DBA008950DD8B79C6663790DD5581F6ED7492B` |
| `assets/item_recovered/old_gauge.png` | `res://assets/items/recovered/old_gauge.png` | `781495E1C6F010CBC2D2264857C393615F6401E86E879F52A51B0EF3E1BE8EB7` |
| `assets/item_recovered/old_gear.png` | `res://assets/items/recovered/old_gear.png` | `64239B785C08F26D576E279200883C2ACE3E100BBAD05832218E6FF4C0866C66` |
| `assets/item_recovered/sealed_core_shard.png` | `res://assets/items/recovered/sealed_core_shard.png` | `CF91E3E978C6B82C50E3C8D0810B3C606A357A322CA9306CCDFCE9D238DFF751` |
| `assets/item_recovered/static_lens.png` | `res://assets/items/recovered/static_lens.png` | `8404EDE553934F9B4D9E2CC7ACC2EC3CD7144DDF0B000062BF366F1D70FE2445` |
| `assets/item_recovered/whisper_wick.png` | `res://assets/items/recovered/whisper_wick.png` | `5AD4FC921DEE9C81718305C057B997CB18E917D519DF8002BE02B1717CA074F1` |
| `assets/item_loadout/anomaly_fang.png` | `res://assets/items/loadout/anomaly_fang.png` | `380CBE877F3BFB1B5F907EC07261FD0A62B302A160446FF9741CE1929CA2C676` |
| `assets/item_loadout/company_badge.png` | `res://assets/items/loadout/company_badge.png` | `3CCE8B5F1C4C0BD85607DC7AFAFEE04882D154161D28892E991A727009CCF1BC` |
| `assets/item_loadout/lockdown_crystal.png` | `res://assets/items/loadout/lockdown_crystal.png` | `5895BDA965EA7CC83C73F8AB07C6F209BE79B65314EAF0F66E1ABE5436FAC31D` |
| `assets/item_loadout/lucky_coin.png` | `res://assets/items/loadout/lucky_coin.png` | `05A856D3B74EB7D433A65ACEDB036BAC195605A49AFB727FA5529C9BA21CAE3A` |
| `assets/item_loadout/overload_parts_box.png` | `res://assets/items/loadout/overload_parts_box.png` | `8781C5B14FF29765A647CF428074DF15FB3CC74EB507436277725F65AFD8481D` |
| `assets/item_loadout/salvage_magnet.png` | `res://assets/items/loadout/salvage_magnet.png` | `6D8694D2957A2E2860C15FD3BAC601C95C45434E1F2CC0730895D9F940E62334` |

## 3. 使用规则

- 物品 ID 到图标的绑定必须集中在 ART24 item visual catalog，世界实体、靠近悬浮窗、背包和结算不得各写一套猜测逻辑。
- 物品存在显式语义映射时优先使用显式图标；未覆盖条目只能按类型使用已声明 fallback。
- 后续新增物品或替换图标前，必须先复查 `D:\AGAME1\sources\art`、`D:\AGAME1\sources\draw\30_game_ready` 及其清单，再按需检查 UE；检索路径、候选、采用/拒绝理由与哈希必须进入对应门禁记录。
- 本门禁只证明来源、文件一致性与允许进入运行时，不等于最终视觉验收通过。
- 最终通过仍以冻结验收标准后的生产流程 Computer Use 结果为准。
