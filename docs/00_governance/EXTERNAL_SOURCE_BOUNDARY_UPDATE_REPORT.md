# External Source Boundary Update Report

> 历史冻结说明（2026-07-26）：本文记录 2026-06-23 当时机器上的
> `D:\AGAME1` 布局，仅作为执行历史保留；其中“当前”措辞不得再解释为本机路径权威。
> 现行仓库、Godot 与文档入口必须从活动工作树动态解析，Base Docs / Connection
> 旧路径只按来源登记使用，具体边界以 `AGENTS.md`、
> `docs/00_governance/SOURCE_REGISTRY.md` 和
> `docs/70_sources/base_docs/BASE_DOCS_SOURCE_REGISTRY.md` 为准。

文档状态：执行记录
适用范围：Base Docs 归档来源与 Connection 并行交接边界校准
执行日期：2026/06/23

## 1. 执行摘要

本轮将仓库当前治理口径校准为：

```text
1. D:\AGAME1\Base Docs 是当前归档后的外部只读策划事实来源之一。
2. 旧文件名或路径不保证仍是唯一有效路径，应按主题、相近名称、更新时间和文档状态重新定位。
3. Base Docs 外部变化视为用户已完成的策划整理，不作为异常、blocker 或回滚对象。
4. 未获新授权，不刷新或新增 Base Docs 仓库副本。
5. D:\AGAME1\Connection 是外部并行交接区，不进入 Git，不作为 Godot 资源导入。
6. 仓库对 Connection 只保留路径、更新时间、观测哈希和使用边界，不保留内容镜像。
```

本轮不改变玩法规则、产品方向、工程实现状态或阶段验收结论。

## 2. Base Docs 处理

```text
外部文件数：25
文本文件：15
UI / 问题图片：10
外部文件修改：0
外部文件移动：0
外部文件删除：0
外部文件复制/刷新：0
```

仓库中既有 15 个文本和 10 个图片副本，是此前阶段在当时授权下形成的历史导入或冻结快照。本轮未刷新、未补齐、未覆盖，统一标记为不自动同步且不替代当前外部原件。

## 3. Connection 处理

```text
外部文件数：10
外部文件修改：0
外部文件移动：0
外部文件删除：0
仓库内容镜像移除：9
移除后仓库 Connection 内容镜像：0
```

移除的 9 个仓库镜像在删除前均与外部源文件 SHA256 一致。外部 `D:\AGAME1\Connection` 未被触碰。

## 4. 当前登记入口

| 用途 | 路径 |
| --- | --- |
| 外部来源总边界 | `docs/00_governance/EXTERNAL_SOURCE_BOUNDARY.md` |
| 来源总表 | `docs/00_governance/SOURCE_REGISTRY.md` |
| Base Docs 登记 | `docs/70_sources/base_docs/BASE_DOCS_SOURCE_REGISTRY.md` |
| UI 图片登记 | `docs/70_sources/ui_reference/UI_REFERENCE_REGISTRY.md` |
| Connection 登记 | `docs/60_interfaces/connection/CONNECTION_SOURCE_REGISTRY.md` |

## 5. 自检结果

```text
Base Docs 文本注册行：15
Base Docs 文本缺失：0
Base Docs 文本哈希不一致：0
UI 图片注册行：10
UI 图片缺失：0
UI 图片哈希不一致：0
Connection 注册行：10
Connection 文件缺失：0
Connection 哈希不一致：0
Connection 仓库镜像文件：0
Connection 外部文件在全仓的同内容副本：0
Base Docs 冻结文本快照：15
Base Docs 冻结文本哈希不一致：0
Base Docs 冻结图片快照：10
Base Docs 冻结图片哈希不一致：0
当前治理必需文件缺失：0
UTF-8 replacement character：0
```

## 6. 安全结果

```text
工程代码修改：否
Godot 场景/脚本/资源/配置修改：否
Godot 运行：否
Git 命令：否
commit/push：否
Base Docs 写入：否
Connection 写入：否
玩法规则变化：否
```

## 7. 待复查重点

```text
1. Base Docs 既有历史导入/冻结快照是否被清楚限制为历史证据。
2. 当前策划读取是否明确优先核对外部归档结果。
3. Connection 是否已完全改为外部路径/哈希登记且无内容镜像。
4. 历史 P2/G20 报告是否仍被正确保留为当时事实，而未被改写。
```
