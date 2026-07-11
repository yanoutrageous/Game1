# I0 Project Baseline Refactor Contract

文档状态：已批准、执行中；I0.0–I0.6 完成，I0.7 待验收
阶段：I0（独立基准阶段，不归入 G / ART / M / P 线路）
批准时间：2026-07-11

## 1. 阶段目的

I0 用可复现证据重新确定 Game1 / GraytailGodot 的项目事实，修复确认缺陷，降低最集中的结构风险，并建立后续所有线路共同使用的仓库、工具链、测试和文档基准。

I0 不以增加玩法内容为目标。它改善工程可信度，不把结构修正解释为产品完成度提升。

## 2. Scope Check

```text
Scope: valid_stage
Risk: high
Action: split, audit, execute by gated phase
Claim check: governance / defect repair / architecture baseline only
```

I0 同时改变了冻结恢复能力、工具链、自动化验证、运行时契约、核心脚本职责、活动仓库位置和当前事实入口，满足独立阶段条件。

## 3. 已批准范围

| 阶段 | 目标 | 主要证据 |
| --- | --- | --- |
| I0.0 | 冻结原始 Git、文件、脏状态、refs 与 stash | `D:\AGAME1\_i0_freeze\I0.0_d4168a6111cfd30be28880301ded52be2d32f462` |
| I0.1 | 固定项目本地 Godot 4.6.3 工具链 | `D:\AGAME1\reports\i0\I0.1_TOOLCHAIN_CURRENT.json` |
| I0.2 | 建立隔离特征测试、路径防护和污染守卫 | `tools/i0/` 与 I0.2 JSON 报告 |
| I0.3 | 修复四个已确认的基线缺陷 | 保存字段、CSV、InputMap、调试面板契约 |
| I0.4 | 对 `RunScene` 做最小、有行为快照保护的职责提取 | ART21R2 smoke seeder 与五组快照 |
| I0.5 | 同卷原子迁移活动仓库并重绑定路径 | I0.5 MOVE 报告与双次迁移后测试 |
| I0.6 | 修正当前文档、分支、路径、安全与交接治理 | 当前入口、验证记录、编码审计 |
| I0.7 | 执行自动化、可见和人工验收，关闭 I0 | 最终验证与 handoff |

## 4. 允许与禁止

允许：

- 只在 `D:\AGAME1` 内读取、创建或修改 I0 所需内容。
- 在独立 I0 分支进行可审计的本地提交。
- 使用 `D:\AGAME1` 内固定的 Godot 和隔离的测试目录。
- 在特征测试保护下实施最小结构修正。

禁止：

- 修改或删除 `D:\AGAME1` 外的文件。
- 删除、覆盖或清理用户原有脏状态、stash、历史 refs 或冻结证据。
- `reset --hard`、`clean`、历史重写、force push、未经授权的 push / merge。
- 用批量路径替换改写历史 validation、handoff、freeze 或报告中的时间点证据。
- 把自动化 PASS 扩大为未执行的手工游玩、最终视觉或发布 PASS。

## 5. 停止条件

- 路径越过 `D:\AGAME1`，或出现未知重解析点。
- 源、目标、Git 身份、stash、refs 或原始 12 项脏状态不能精确解释。
- 测试产生业务文件或 Git 污染。
- 重构前后行为快照不一致。
- 可见运行结果与自动化结论冲突。

## 6. I0 验收标准

1. 冻结包可独立校验，且原始状态可追溯。
2. 工具链版本、二进制哈希、来源和签名限制均有记录。
3. 四个确认缺陷由先红后绿的契约验证覆盖。
4. `RunScene` 提取前后五组快照逐字一致。
5. 活动仓库位于 `D:\AGAME1\active\Game1_work`，旧活动路径不存在。
6. 两次迁移后全套验证一致，Git / 业务污染守卫通过。
7. 当前文档不再把 G40 时间点事实当作当前事实。
8. 最终自动化和可见验收被分别记录；未执行的验证不得声称通过。
9. 原始用户脏状态和保护性 stash 保持不变。

## 7. 非目标

- 完整 LongTerm、Objective / Reward / Pool、规则引擎、仓库经济或内容库。
- 最终美术产品化、全分辨率视觉 QA 或发布打包。
- 大规模重写 `RunScene`、更换引擎或重建全部架构。
- 远端分支整理、main 合并、发布或 CI 平台接入。
