# HANDOFF M5 最小物品包与掉落闭环完整内容

中文摘要：M5 交付最小物品包和掉落闭环的完整可验证实现。下一步建议进入 M6 前先由审计确认 M5 runner、可见验证和文档边界，再决定是否扩展到更完整的仓库、Objective / Reward / Pool 或长期系统。

## 已完成

- M5 item catalog：装备、消耗品、藏品、怪物专属掉落、special、unique locked concept。
- GroundLoot-first：搜索、宝箱、怪物、事件、祭坛、Debug 掉落仍优先落地面。
- Backpack loop：拾取、丢弃、重新拾取、满包 blocked、replace_ground_item。
- Consumable use：消耗品使用经 CommandBus / RunRuleService / RunAssetLedger。
- Event loop：旅商、骰子、祭坛分支补齐到 M5 最小规则。
- Settlement loop：成功 / 失败 / 放弃区分 run black coin、safe_yield、long_term_gold。
- Lite consumers：Warehouse Lite / Codex Lite / DeployPrep 接收 M5 内容字段。

## 未实现

- 完整仓库经济。
- 完整装备强化 / 装备系统。
- 完整 Objective / Reward / Pool。
- 完整 Rule Engine。
- 完整长期系统 / 研究 / 图鉴 / 收藏 / 抽奖。
- 正式美术资源导入。

## 下一步建议

M6 可在审计通过后选择一个窄切片：要么继续物品体验 UI / Warehouse Lite 强化，要么进入 Objective / Reward / Pool 的真实最小接口。不要在未完成 M5 audit gate 前扩大系统。
