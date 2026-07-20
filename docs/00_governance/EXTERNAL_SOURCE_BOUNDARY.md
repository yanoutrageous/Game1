# External Planning And Handoff Source Boundary

文档状态：I1 当前外部来源治理规则。
最后更新：2026-07-20

本文件规定仓库如何引用外部策划、美术与 handoff 材料；不复制 source body，不授权 runtime import，也不把历史盘符当作当前机器事实。

## 历史登记与本机状态

G40 登记过以下根：

```text
D:\AGAME1\sources\docs
D:\AGAME1\sources\docs_governance
D:\AGAME1\sources\art
D:\AGAME1\sources\draw
D:\AGAME1\handoff\connection
```

它们在 2026-07-20 本机只读检查均不可用。更早的 Base Docs、Base Docs_Governance、Base Art、Draw 和 Connection 路径也只保留 legacy mapping。不得猜测新位置；需要时由用户显式提供，再更新 `SOURCE_REGISTRY.md`。

## 使用规则

1. 当前仓库事实来自动态解析的 worktree、当前代码、runtime evidence 和仓库 current docs。
2. Planning originals 只注册/引用，不复制或改写 source body。
3. Governance snapshot 是外部时间点参考，不替代当前仓库治理。
4. Base Art / Draw 只有经过来源、许可、hash、manifest、import 和 runtime key gate 才能成为 production asset。
5. Connection 是外部并行 handoff；默认只登记路径/hash，不进入 Git 或 Godot。
6. 外部路径不可用时记为 unavailable，不将旧缓存、相似目录或历史镜像自动认作同一来源。
7. hash registration 只证明字节身份，不等于内容批准、执行授权或验收。

## 当前读取顺序

1. 当前代码、`docs/10_current/`、I1 contract/validation/handoff。
2. `docs/00_governance/SOURCE_REGISTRY.md` 中明确可用的当前 external pointer。
3. 用户显式提供的外部来源，经路径/hash 登记后只读使用。
4. 历史 snapshot 只解释过去，不覆盖当前事实。

## 禁止反向推断

- 不从 UI 图片推断玩法、容量、碰撞或结算规则。
- 不从临时工程实现推断产品规则已批准。
- 不从 handoff 推断任务自动获权。
- 不从 pre-G40/G40 路径推断当前机器 canonical path。
- 不从 source registration 推断 runtime import 已通过。
