# Next Action

文档状态：当前下一步建议
适用范围：DOC-GOV-002 完成后的审计复查、Git gate 和下一策划主题准备
最后更新：2026/06/27

## 1. 推荐下一步

```text
1. 完成 DOC-GOV-002 执行框自检。
2. 由审计框复查 README、INDEX、current、validation index、stage index、重复台账和新增目录 README。
3. 审计确认后，再决定是否进入 DOC-GOV-002 docs-only Git gate。
4. G38 / G37S / G37 后续 release / merge gate 必须另开工程 gate，不由 DOC-GOV-002 自动执行。
5. 下一策划主题准备时，先读取 docs/README.md、docs/INDEX.md 和 docs/00_governance/DOC_PLACEMENT_STANDARD.md。
```

## 2. 本阶段不得自动推进

```text
1. 不 commit。
2. 不 push。
3. 不 stage。
4. 不运行 Godot。
5. 不执行 manual playtest。
6. 不修改 Base Docs、Base Docs_Governance、Connection、Base Art。
7. 不修改 Godot scripts/scenes/data/project.godot/.uid/.translation/import metadata。
8. 不把 G38 / G37S / G37 / G36 验证摘要写成 gameplay runtime PASS 或 manual playtest PASS。
```

## 3. 审计框复查重点

```text
1. DOC-GOV-001 是否已经降级为 completed / historical。
2. DOC-GOV-002 是否是当前文档治理阶段。
3. G38 / G37S / G37 是否只按现有文档证据索引，未扩大为 main 已完成。
4. validation index 是否只说明验证范围，没有扩大验证结论。
5. 根目录旧文件是否只登记状态，没有移动、删除或批量改写。
6. 新增目录 README 是否只说明职责和边界。
```
