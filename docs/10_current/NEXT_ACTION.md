# Next Action

文档状态：当前下一步建议
适用范围：DOC-GOV-001 完成后的审计复查与后续 gate
最后更新：2026/06/26

## 1. 推荐下一步

```text
1. 完成 DOC-GOV-001 执行框自检。
2. 由审计框复查 README、INDEX、current、validation index、stage index 和重复台账。
3. 审计确认后，再决定是否进入文档治理 Git gate。
4. G36 后续如需 release / merge gate，应另开工程 gate，不由 DOC-GOV-001 自动执行。
```

## 2. 本阶段不得自动推进

```text
1. 不 commit。
2. 不 push。
3. 不运行 Godot。
4. 不执行 manual playtest。
5. 不修改 Base Docs、Base Docs_Governance、Connection。
6. 不修改 Godot scripts/scenes/data/project.godot/.uid/.translation。
7. 不把 G36 验证摘要写成 gameplay runtime PASS 或 manual playtest PASS。
```

## 3. 审计框复查重点

```text
1. DOC_PLACEMENT_STANDARD.md 是否覆盖后续 CodeX 文档落位规则。
2. DUPLICATE_DOC_LEDGER.md 是否正确区分当前入口、历史证据、外部快照和外部原件。
3. docs/INDEX.md 是否停止长历史堆叠。
4. G30-G36 中文摘要是否只解释既有内容，没有新增玩法规则。
5. Base Docs_Governance 是否只被写成外部快照，不是当前事实源。
```
