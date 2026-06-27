# 灰尾回收 / 五四三二一

仓库名：`Game1`。

本仓库当前以 Godot 工程与仓库内文档为主。仓库根 README 只负责说明入口和边界，不作为完整策划案、验证结论或玩法规则来源。

## 当前阅读入口

优先阅读：

```text
docs/README.md
docs/INDEX.md
docs/10_current/CURRENT_STATE.md
docs/10_current/NEXT_ACTION.md
docs/10_current/CAPABILITY_MATRIX.yaml
```

当前文档治理规则来源：

```text
docs/00_governance/DOC_PLACEMENT_STANDARD.md
docs/00_governance/DUPLICATE_DOC_LEDGER.md
docs/00_governance/SOURCE_REGISTRY.md
```

`docs/game-design.md` 和 `docs/dev-plan.md` 保留为早期历史材料，不再作为当前唯一核心文档。

## 当前阶段口径

当前仓库文档入口收口到 G38 / G37S / G37 与 DOC-GOV-002：

- G38：Runtime Architecture Consolidation Finalization，release gate pending。
- G37S：Runtime Authority Validation / Handoff Supplement。
- G37：Runtime Authority / RunFlow Execution Consolidation，release gate pending。
- G36：较早 runtime architecture / save profile foundation 工程证据。
- DOC-GOV-001：已完成 / historical 文档治理阶段。
- DOC-GOV-002：当前仓库 docs 入口、索引、README 与历史层归属治理。

上述工程阶段不声明 gameplay runtime PASS，也不声明 manual playtest PASS。DOC-GOV-002 不新增玩法规则。

## 写入边界

允许写入的当前文档主入口在：

```text
D:\AGAME1\_repo_cache\Game1_work\docs
```

不要从本 README 推导权限去修改：

```text
D:\AGAME1\Base Docs
D:\AGAME1\Base Docs_Governance
D:\AGAME1\Base Art
D:\AGAME1\Connection
Godot 场景、资源、导入 metadata、project.godot、脚本
```

Godot 工程入口见：

```text
Godot/GraytailGodot/README.md
```
