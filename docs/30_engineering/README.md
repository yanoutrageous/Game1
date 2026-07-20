# Engineering Docs Entry

文档状态：I1 当前工程文档入口。
最后更新：2026-07-21

## 当前入口

| 路径 | 用途 |
| --- | --- |
| `docs/30_engineering/architecture/I1_ARCHITECTURE_BASELINE.md` | 当前运行权威、命令、状态、刷新与保存边界 |
| `docs/30_engineering/godot/I1_DEVELOPMENT_PREVIEW_VALIDATION_RUNBOOK.md` | 开发、预览、验证和证据操作手册 |
| `docs/30_engineering/godot/GODOT_DOCS_REGISTRY.md` | Godot 内部历史/工程 docs 只读注册 |
| `docs/30_engineering/architecture/I0_INDEX.md` | I0 冻结架构入口；不覆盖 I1 |
| `docs/30_engineering/adr/I0_INDEX.md` | I0 ADR 历史入口 |

## 当前边界

```text
1. 仓库 docs 是当前治理与工程导航入口。
2. Godot/GraytailGodot/docs 是工程历史/环境证据，不是当前阶段治理入口。
3. 当前执行以 tools/i1 和锁定 Godot 身份为准；固定盘符只可作本机示例或历史证据。
4. 架构新增直接落位 docs/30_engineering/architecture/；操作说明落位 docs/30_engineering/godot/。
5. 已登记的损坏历史 README 不做无审计重写；有效 companion/index 继续承担导航。
6. I1 已按提交态 full/head 证据关闭；后续变更不得用 implementation-present 或 worktree PASS 替代对应验收。
```

## 工程修改最低要求

- 先定位数据/行为权威，再修改消费者。
- 新 runner 注册到 I1 manifest 或明确登记 `EXCLUDED_NON_SLICE`。
- 普通改动 quick；core/UI 改动追加对应 profile；提交后 full/head。
- 战斗刷新微基准不外推为通用性能。
- Godot metadata 和资源来源必须通过专门 gate。
