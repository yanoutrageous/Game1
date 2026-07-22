# Known Unfinished Systems

文档状态：I2 关闭后的当前未完成系统清单。
最后更新：2026-07-21

本文件阻止 foundation、preview、schema、runner、capture 或局部 PASS 被扩写为完整产品能力。下列项目是 I1/I2 的保留边界和后续候选，不重新打开已关闭的 I1 或 I2。

| 系统 | 当前事实 | 后续门 |
| --- | --- | --- |
| `RunScene` 职责 | 仍是大型协调器；I1 已提取若干边界但未完成拆分 | 一次一个有特征测试的职责提取；以所有权和回归门而非行数判断 |
| active-run persistence | 当前进程内 continue 可用；退出 Godot 后恢复未实现 | schema/migration/crash/idempotency stage |
| 完整人工游玩 / 整合 UX | I2 有局部动态、focus、Esc、保存失败与 production capture；跨页面键鼠/手柄、长文本/DPI 和长局玩家体验仍未整体验收 | 独立长局、多终局、返回/恢复、设备与输入 regression |
| 角色动画、时装与移动手感 | I2 有表现端口、缺失回退、四姿态与 reduced-motion 门；最终动画方案、真实时装素材和动态手感未验收 | approved art/animation pipeline + replacement fixture + visible/performance gate |
| 空间转场与跨页最终视觉 | I2 有安全路由/回退、文字/锚点和局部 layer 边界；洞口/下层连续空间及最终跨页风格未验收 | UX prototype + navigation failure + approved art + dynamic visual gate |
| 玩家死亡表现 | 无独立 death bitmap；当前使用已有帧/姿态表达 | approved art asset + runtime + visible gate |
| 完整仓库经济 / 批售 | 手动出勤、单件交易和写回可用；整理、堆叠、扩容、保险、寄售、批量出售等未完成 | warehouse/economy contract: price, confirmation, atomicity, idempotency, save rollback |
| 真实天赋树 | I2 已将任务/成就迁至任务档案；点数、成本、依赖、节点效果、重置/返还与持久化权威未定义 | progression/talent product and persistence contract |
| 装备深度 | 基础效果可用；强化、耐久、随机词条、完整被动和平衡未完成 | equipment/content/balance contract |
| 内容量 | M7 首轮内容可用；Boss、精英、更深事件、奖励池与长期内容不足 | content runtime + persistence + UI gate |
| 抽奖/唯一物/外观 | UI 或锁定状态存在；真实获取、消费和实际外观未闭环 | product rule and acquisition gate |
| Save future evolution | I1 保护未来 schema 不被降级；真正的未来 migration 尚未实现 | versioned migration tests |
| Cleanup diagnostics | full 中 22 个 runner 共保留 44 条已分类 shutdown cleanup diagnostic；blocking diagnostic 为 0 | lifecycle diagnostic stage |
| 历史 validator 漂移 | G35/G36 与 M3/M3H/M3R/M5 独立 wrapper 含旧模块位置、旧语义或 blanket metadata 规则，不是 I1 当前入口 | 需要复用时单独校准；当前使用 I1 manifest + `I1_PROJECT_METADATA` |
| 战斗房绝对性能与通用性能 | I2 已有真实 1/3/5 敌人和弹丸 workload、同机 A/B/A 测量；该数据不证明绝对 FPS 改善，GPU/设备/长局仍未验收 | frame/memory/long-run/device/GPU workload and visible-drop gate |
| CI | GitHub Actions quick run `29760789712` 已成功；full、导出与 release 仍无远端证明 | 为目标 profile/平台建立独立 Actions 与 artifact gate |
| 导出 / 发布 | 未建立为当前能力 | target export, package, smoke, release gate |
| 最终美术 / 音频 | I1 改善 UI、动画与资源治理；不构成最终验收 | independent visual/audio acceptance |

自动化 runner 只证明其覆盖的契约；预览生成只证明图像被写出；二者都不能替代人工、最终视觉、通用性能或发布验收。
