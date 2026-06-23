# AGAME1 Unified Docs Index

文档状态：P2 统一入口
适用范围：仓库 `docs` 根目录的当前入口、归属和阅读顺序
最后更新：2026/06/23

本文件是 P2 文档治理后的仓库文档统一入口。它不新增玩法规则，不替代验证记录，不把外部来源材料写成定案。

## 1. 当前必读入口

新对话或审计复查优先读取以下 5 个文件：

1. `docs/INDEX.md`
2. `docs/10_current/CURRENT_STATE.md`
3. `docs/10_current/NEXT_ACTION.md`
4. `docs/10_current/CAPABILITY_MATRIX.yaml`
5. `docs/00_governance/SOURCE_REGISTRY.md`

旧的 `PROJECT_BASELINE.md`、`ENGINEERING_STATUS.md`、`NEXT_HANDOFF.md`、`DOCS_INDEX.md` 保留为扩展证据和历史状态材料，不再作为第一轮必须通读入口。

## 2. 阶段边界

```text
P2 = 策划文档统一整理与仓库文档同步执行。
G25 = UI Structure Stabilization & Playable Route Recovery，已作为工程阶段关闭。
G26 = 后续产品 / 原型阶段占位，未被 P2 占用。
```

P2 只处理文档治理，不执行工程实现，不运行 Godot，不提交或 push。

## 3. 目录归属

| 目录 | 定位 |
| --- | --- |
| `00_governance/` | 文档治理、来源注册、生命周期、待确认事项、声明台账 |
| `10_current/` | 当前状态、下一步、能力矩阵 |
| `20_product/` | 产品契约草案和待确认产品边界 |
| `30_engineering/` | 工程文档入口与 Godot docs 只读注册 |
| `40_validation/` | 验证证据索引 |
| `50_stages/` | 阶段索引；历史阶段保留证据价值 |
| `60_interfaces/` | Connection 外部只读交接登记与接口说明；不保存内容镜像 |
| `70_sources/` | Base Docs、UI 图片等外部来源登记与此前获授权的冻结历史快照 |
| `90_archive/` | 历史、生成报告、旧体系归档说明 |

既有 `handoff/`、`validation/`、`stage_summaries/`、`route_analysis/`、`project_governance/`、`design_sources/` 不删除；P2 通过新入口和索引统一引用。

## 4. 使用规则

```text
1. 当前事实先看 10_current。
2. 来源归属先看 00_governance/SOURCE_REGISTRY.md。
3. Base Docs 是当前归档后的外部只读策划事实来源之一；读取前应按当前目录和相近文件名重新定位。
4. UI 图片只作为确定图、示例图、问题截图或未知图登记。
5. 未确认内容不得写成最终规则。
6. Connection 是外部并行交接区，不得进入 Git 或作为 Godot 资源导入。
7. 外部来源完整边界见 `docs/00_governance/EXTERNAL_SOURCE_BOUNDARY.md`。
```
