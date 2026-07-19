# ART24R2 局内素材选择与 UE 敌人导入门禁

文档状态：执行中静态门禁记录
检索日期：2026-07-19
适用阶段：ART24R2 局内美术返工

## 1. 固定检索顺序

每个局内新增视觉项必须依次检查：

1. 当前 Godot 工程与 `data/assets/asset_manifest.csv`。
2. `D:\AGAME1\sources\art`、`D:\AGAME1\sources\draw\30_game_ready`，必要时扩展到 `sources\draw` 已处理目录和清单。
3. 同项目 UE 原型 `D:\AGAME1\external\ue_prototype`。
4. 只有前三层没有语义与质量均合格的候选时才允许新制。

候选必须同时比较文件语义、像素颗粒、轮廓、视角、角色比例、帧覆盖、透明边缘、运行尺寸与状态接口。文件名命中本身不等于可复用。

## 2. 本次检索事实与纠正

- Godot 导入区在本次导入前只有房间怪物背景和小地图怪物图标，没有 slime、bat、drone 的正式本体动作组。
- 项目素材库存在局内 UI、房间、道具和地图图标，但没有这三类敌人本体动作组。
- UE 原型存在可直接审计的 128×128 透明 PNG：史莱姆本体/扑击、蝙蝠四帧待机/两帧攻击、无人机四帧悬停/三帧蓄力，以及三类怪物各五帧死亡碎裂、蝙蝠弹丸和无人机激光素材。
- UE 原型还存在与 `screenshot_gameplay.png` 对应的局内 HUD 骨架：左侧面板、协议牌、底部栏、生命/战力/资源状态图标、背包图标与风险标签；Godot 和项目素材库没有同一组完整素材。
- 对应规格文档为 `docs/monster-art-spec-slime.md` 与 `docs/monster-art-spec-bat-drone.md`。
- 因最初检索误用了 worktree 内不存在的相对 `sources` 路径，先前“无适配素材”的结论不完整；本记录以重新检查后的事实为准。

## 3. 客观采用结论

运行时以 UE 现有帧作为默认怪物；本轮新生成的高细节 slime、bat、drone 不作为基础怪物，但保留为可选视觉变体，理由如下：

- UE 帧与当前主角共享更接近的粗像素颗粒、黑色轮廓和 128×128 画布，缩放后角色关系更稳定。
- UE 帧已经覆盖当前 G41 的 idle、warning/aim、active/fire 与 defeated 主状态，且包含真实远程攻击配套素材。
- 新生成候选的细节密度、轮廓体量和材质复杂度明显高于当前主角，在房间内缩放后会产生“敌人与主角不属于同一套游戏”的观感。
- 采用 UE 帧更接近用户指定的局内基准，并减少重复制作和后续替换成本。

新生成的三个色键源图保留在 `docs/art/validation/art24/sources`，清理后的动作组保留在各敌人目录。运行时仅在快照显式提供非默认 `visual_variant` 时解析这些高细节帧；默认快照继续使用 UE 基础帧。视觉变体只改变贴图、尺寸与动作表现，不得暗中修改 G41 的生命、伤害、速度或掉落规则。

## 4. 导入边界

- 只读来源仓库：`D:\AGAME1\external\ue_prototype`。
- 来源提交：`de4ece1163505d9fe08e31cd0dbe10477909f963`。
- 目标：`res://assets/art24/actors/{slime,bat,drone}/ue_*.png` 与 `res://assets/art24/fx/ue_*.png`。
- 共复制 36 个 PNG；复制后逐文件 SHA256 对比结果为 `HASH_MISMATCH=0`。
- HUD 目标：`res://assets/art24/ui/ue/*.png`；共复制 13 个 PNG，逐文件 SHA256 对比结果为 `HASH_MISMATCH=0`。
- 不复制 `.meta`、`.uasset`、`.import`、`.uid`、`.translation`、scene、resource、配置或工程文件。
- `art24_runtime_asset_report.csv` 和 `art24_asset_manifest_fragment.csv` 必须逐项记录目标哈希、UE 来源相对路径、来源提交与 `art24_ue_audited_import` 状态。

## 5. 运行绑定

- `Art24EnemyVisualCatalog` 统一解析三类敌人的状态与帧，不允许各房间脚本直接猜测文件路径。
- `visual_variant=base` 使用 UE 基础帧；非默认值使用已生成的高细节动作组，为废铁寄生史莱姆、精英蝠或重装无人机等后续数据变体预留接口。
- 史莱姆：本体待机、蓄力、扑击、五帧碎裂；小史莱姆使用独立 UE 本体并复用史莱姆攻击/碎裂节奏。
- 蝙蝠：四帧振翅循环、蓄力、发射、五帧碎裂。
- 无人机：四帧悬停循环、两帧蓄力、发射、五帧碎裂。
- 受击色闪、飞行浮动和阴影属于可维护的运行时表现，不为它们重复制作静态贴图。

## 6. 门禁结论

本门禁只证明检索优先级、来源、复制边界和运行绑定符合要求，不代表最终视觉通过。角色比例、动作节奏、战斗可读性和与 HUD/房间的整体关系仍须在两轮优化后，按预先冻结的标准通过生产路径 Computer Use 验收。
