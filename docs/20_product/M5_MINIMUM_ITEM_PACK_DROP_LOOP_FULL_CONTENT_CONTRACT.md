# M5 最小物品包与掉落闭环完整内容契约

中文摘要：M5 在 M1-M4S 可玩闭环基础上，把最小物品包、掉落、GroundLoot、背包、收益层、事件分支、Warehouse Lite / Codex Lite / DeployPrep 轻量接口补齐到可验证状态。本阶段不实现完整仓库经济、完整装备强化、完整 Objective / Reward / Pool、完整 Rule Engine 或正式美术导入。

## 阶段定位

M5 是 Minimum Item Pack & Drop Loop Full Content Implementation。阶段事实源来自用户提供的 M5 策划案与数值/文案策划案；仓库文档只记录工程契约，不复制 Base Docs 正文。

## 内容包范围

- 作业装备：旧背心、开刃器、回收袋、护目镜、信号针、绝缘套。
- 作业消耗品：压缩饼、急救贴、胶带卷、扫描针、镇静糖、稳定剂。
- 藏品：24 个 1-6 级普通藏品。
- 怪物专属掉落：旧齿轮组、断裂巡逻牌、过热驱动核、搬运机黑箱、异常指令片。
- 特殊物：祭坛残渣、旅商收据、调试回收箱等事件/测试边界物。
- unique：仅登记未来 gacha-only 概念，不进入普通搜索、宝箱、怪物、事件、祭坛掉落。

## 掉落与背包规则

- 搜索、宝箱、怪物、事件、祭坛、Debug 掉落默认进入 GroundLoot / RoomLootContainer。
- 拾取进入背包，受 weight / capacity 限制。
- 满包时可使用 replace_ground_item：丢出一个可腾出容量的低价值背包物，再拾取地面物。
- 丢弃后地面物可再次拾取；未拾取 GroundLoot 在结算时按 outcome 失去。
- 局内拾取装备不立即激活，必须撤离带回后登记；carry-in 装备才可在本局生效。
- 消耗品使用后从背包移除，并通过 RunRuleService / RunAssetLedger / transaction log 记录。

## 收益层

- run black coin：本局黑币，成功撤离时转为长期金币，失败/放弃时丢失。
- safe_yield：安全收益，成功/失败保留并在结算写入长期金币；放弃为 pending_undecided。
- long_term_gold：长期金币，只由结算结果写回，不由 UI 重算。

## 事件分支

- 旅商：支持出售背包物、高价值出售确认、治疗、情报购买及资源不足 disabled reason。
- 骰子：只使用本局黑币下注，不使用长期金币，不允许负债。
- 祭坛：支持 1-5 阶段 HP 递增消耗，HP 最低保留 1，不产出 unique。
- 陷阱：沿用现有机制反馈，不扩展为完整事件链。

## 轻量长期接口

- Warehouse Lite 显示仓库物品的分类、baseValue、weight、source/flavor/status，并可作为 DeployPrep carry-in 来源。
- Codex Lite 显示 discovered / undiscovered / source / rarity / category；unique 仅显示 locked future gacha-only。
- DeployPrep 提供最小 loadout、容量、profile / permit / protocol / talent hook 字段和 disabled reason。

## 非目标

M5 不实现完整仓库、完整装备强化、完整研究/图鉴/收藏/抽奖、完整 Objective / Reward / Pool、完整 Rule Engine、正式资源导入、SaveManager 重构或 UI 直接写存档。
