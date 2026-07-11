# Known Unfinished Systems

文档状态：I0 当前未完成系统清单
最后更新：2026-07-11

本文件阻止工程 foundation、preview 或局部 runner PASS 被误写成完整产品能力。

| 系统 | 当前事实 | 建议后续门 |
| --- | --- | --- |
| 可见启动安全隔离 | I0 已关闭，但可见 Godot 曾写入范围外 AppData logs | 在任何新可见运行前建立并验证日志隔离门 |
| 完整人工游玩 | I0.7 仅观察 main menu → deploy prep → run HUD 与 M / Q / G / T；移动、撤离、结算、返回未覆盖 | 安全启动门之后的独立 manual regression stage |
| `RunScene` 职责 | I0.4 后仍有 1,668 行 | 每次只迁移一个有特征测试的职责 |
| active-run persistence | save/profile 边界存在，完整往返、恢复和迁移不足 | persistence stage |
| Complete LongTerm | shell / preview / partial foundation | long-term product stage |
| Objective / Reward / Pool | contract / preview foundation，不是完整闭环 | MVP progression stage |
| Complete Rule Engine / content | schema、adapter 和基础执行存在，内容与完整策略不足 | rule runtime/content stage |
| Complete Warehouse economy | lite / display / loadout 基础，不是完整经济 | warehouse/economy stage |
| Final art productization | ART21R2 为 visual partial | independent visual acceptance gate |
| Cleanup diagnostics | 每轮 24 条 ObjectDB/resource 退出提示 | lifecycle diagnostic stage |
| CI / release gate | 未建立为当前能力 | CI then export/release gate |
| Performance / device matrix | 无权威性能、分辨率和输入设备矩阵 | performance/compatibility stage |
| 用户原始 dirty 归属 | 12 项状态被保护，未清理或提交 | separate user decision |

自动化 runner 通过只能证明它覆盖的契约；不能替代内容完成、人工游玩、最终视觉或发布验收。
