# Engineering Docs Entry

文档状态：工程文档入口
适用范围：仓库工程文档与 Godot docs 证据索引
最后更新：2026/06/26

## 当前入口

| 路径 | 用途 |
| --- | --- |
| `docs/30_engineering/godot/GODOT_DOCS_REGISTRY.md` | Godot 内部 docs 只读注册 |
| `docs/30_engineering/architecture/README.md` | 架构文档入口 |
| `docs/30_engineering/adr/README.md` | ADR 预留入口 |

## DOC-GOV-001 边界

```text
1. 仓库 docs 是当前文档治理入口。
2. Godot/GraytailGodot/docs 是工程历史 / 环境证据，不作为当前治理入口。
3. DOC-GOV-001 不修改工程代码、Godot 场景、脚本、资源、导入文件、.uid、.translation 或 project.godot。
4. 工程架构文档新增时应落位到 docs/30_engineering/architecture/ 或对应阶段 validation / handoff。
```
