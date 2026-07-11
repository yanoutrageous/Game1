# Engineering Docs Entry

文档状态：工程文档入口
适用范围：仓库工程文档与 Godot docs 证据索引
最后更新：2026/07/11（I0.6）

## 当前入口

| 路径 | 用途 |
| --- | --- |
| `docs/30_engineering/godot/GODOT_DOCS_REGISTRY.md` | Godot 内部 docs 只读注册 |
| `docs/30_engineering/architecture/I0_INDEX.md` | I0 当前架构文档入口；旧 README 为受登记的损坏历史证据 |
| `docs/30_engineering/adr/I0_INDEX.md` | I0 当前 ADR 预留入口；旧 README 为受登记的损坏历史证据 |

## I0 当前边界

```text
1. 仓库 docs 是当前文档治理入口。
2. Godot/GraytailGodot/docs 是工程历史 / 环境证据，不作为当前治理入口。
3. 当前工程执行只使用 I0 固定工具链和隔离验证入口；历史 Godot 路径不是执行指令。
4. 工程架构文档新增时应落位到 docs/30_engineering/architecture/ 或对应阶段 validation / handoff。
5. 两个旧 README 的不可逆 UTF-8 损坏保留在编码台账；当前导航使用严格 UTF-8 的 `I0_INDEX.md`。
```
