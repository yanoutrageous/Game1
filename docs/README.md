# Game1 Docs

本目录是当前仓库文档入口。I0 以前的阶段文档和 I0 / ART21 的原始
validation、handoff、closeout 都保留为历史证据，不被当前摘要改写。

## 第一读取顺序

1. `docs/README.md`
2. `docs/INDEX.md`
3. `docs/10_current/CURRENT_STATE.md`
4. `docs/10_current/CAPABILITY_MATRIX.yaml`
5. `docs/10_current/NEXT_ACTION.md`

## 目录职责

| 目录 | 职责 |
| --- | --- |
| `00_governance/` | 当前治理、路径、来源、生命周期和编码规则 |
| `10_current/` | 当前事实、能力、下一步和未完成系统 |
| `20_product/` | 产品与阶段契约 |
| `30_engineering/` | 工程索引、架构与 ADR |
| `40_validation/` | 当前验证索引 |
| `50_stages/` | active / closed 阶段索引 |
| `validation/` | 阶段验证原文 |
| `handoff/` | 阶段交接原文 |
| `art/` | 美术阶段契约、审计、关闭和证据 |
| `60_interfaces/`、`70_sources/` | 外部协作和来源登记 |
| `90_archive/` | 历史与旧入口说明 |

## 当前基线

- 最新非美术阶段：I0。
- 最新美术阶段：ART21 主菜单场景全量重构。
- 当前整合验证：`docs/validation/I0_ART21_BASELINE_INTEGRATION_VALIDATION.md`。
- 当前没有已授权的后续阶段。

## 规则

- 当前路径由 `git rev-parse --show-toplevel` 解析，不绑定盘符。
- 历史文档中的绝对路径保持时间点证据属性。
- 新长期文档按 `docs/00_governance/DOC_PLACEMENT_STANDARD.md` 落位。
- 完成声明必须与实际运行的自动化、人工或发布证据范围一致。
