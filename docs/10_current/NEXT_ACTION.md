# Next Action

文档状态：当前下一步
最后更新：2026-07-11（I0.6）

## 已授权的下一步

完成 I0.6 后进入 I0.7，并按以下顺序关闭独立基准阶段：

1. 对文档路径、严格 UTF-8、Git 状态、冻结证据和安全边界做最终静态审计。
2. 从新活动路径再次运行完整 remediated I0 套件。
3. 使用项目本地 Godot 做可见启动与关键 UI 路由烟测，记录实际可见结果。
4. 按最小人工检查表验证启动、出发、局内、地图、背包 / 地面拾取、撤离 / 结算和返回路由。
5. 如实区分自动化 PASS、可见 PASS、人工 PASS 与未覆盖项。
6. 定稿 I0 validation / handoff，更新 active / closed stage index，并提交本地关闭记录。

## 当前停止条件

- 出现未知 Git / 业务文件污染。
- 原始 12 项脏状态、stash、refs 或冻结证据发生不可解释变化。
- Godot 执行源不是 `D:\AGAME1\tools\runtimes\godot\4.6.3`。
- 可见结果与自动化结论冲突。
- 需要修改或删除 `D:\AGAME1` 外文件。

## I0 后

I0 不自动启动后续线路。下一阶段应由用户单独授权，并引用 `I0_BASELINE_ASSESSMENT.md` 中的优先级：先 release / CI 基础与 persistence 可靠性，再继续可证明的 `RunScene` 拆分和 MVP 内容闭环。
