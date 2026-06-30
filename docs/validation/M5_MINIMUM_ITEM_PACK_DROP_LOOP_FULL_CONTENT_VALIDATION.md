# M5 最小物品包与掉落闭环完整内容验证

中文摘要：M5 验证覆盖静态 validator、Godot project-load/parser smoke、M5 headless runner、既有 M2/M3/M3R/M3H/G35-G39/M4S 回归，以及 Computer Use 可见流程。project-load/parser smoke 不等于 gameplay runtime PASS；未运行 manual long playtest 时不得声明 manual playtest PASS。

## 验证命令

```powershell
git diff --check
powershell -ExecutionPolicy Bypass -File tools/validate_m5_item_drop_loop_full_content.ps1
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --quit
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --script "D:\AGAME1\_repo_cache\Game1_work\tools\godot_m5_item_drop_loop_full_content_runner.gd"
```

## M5 runner 覆盖

- 6 件装备、6 件消耗品、24 件藏品、怪物专属掉落、unique locked concept。
- GroundLoot-first、满包 blocked、replace_ground_item、丢弃 / 拾取状态迁移。
- 镇静糖复合效果：HP 恢复与协议压力降低。
- 旅商出售、治疗、情报；骰子本局黑币下注；祭坛 1-5 阶段。
- 成功、失败、放弃结算：run black coin / safe_yield / long_term_gold 语义分离。

## 边界

- 未声明 gameplay runtime PASS。
- 未声明 manual playtest PASS。
- 未实现完整仓库经济、完整装备强化、完整 Objective / Reward / Pool、完整 Rule Engine。
- 未提交 project.godot、scene/resource、uid、translation、import metadata。
