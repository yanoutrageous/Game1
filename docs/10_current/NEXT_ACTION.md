# Next Action

文档状态：I4 活动执行入口。

## 当前动作

完成 I4.0 后按依赖顺序推进：

1. 建立 `dev_sandbox` profile、taint 防线和默认档语义哈希门。
2. 将设置中的 debug/editor-only 测试场接入真实 `RunScene`。
3. 整理局内诊断面板、确定性场景目录和失败证据包。
4. 实现原子 N 件购买、实例级出售映射和统一数量草稿。
5. 重构 Deploy 卡片、普通页 310/310、滚动详情/摘要和交易上下文。
6. 接通局内聚合、长期导航和字体/输入表现。
7. 运行定向、重复生产、视觉/设备、worktree 和 exact-head 门。
8. 完成阶段审计、提交、push，并验证远端 SHA。

## 执行规则

- 每个切片先做当前生产消费者和领域权威审计，再修改。
- 只修改与当前切片直接相关的文件；不顺带增加内容或重写无关模块。
- 关键状态等待领域信号/查询，不使用固定帧数证明正确性。
- 所有 debug 写操作只在 sandbox；默认档前后语义哈希必须一致。
- 购买/出售/结算任一失败必须恢复交易前金币、实例和保存。
- 受保护 Godot 文件只有在对应 gate 登记后才允许修改/暂存。
- 未运行证据保持 `NOT_RUN`；静态截图不能替代动态玩家或真实设备。

## 停止并调查

- 默认档被调试修改。
- 交易出现部分成功或重复提交。
- 聚合后丢失精确实例身份。
- UI 成为领域或保存第二权威。
- 文本截断、遮挡或滚动不可达仍存在。
- 工作树出现来源未知的 scene/resource/project/import/translation 变化。

## 当前权威

- 契约：`docs/20_product/I4_PRODUCTION_INTERACTION_CONVERGENCE_CONTRACT.md`
- 台账：`docs/00_governance/I4_EXECUTION_LEDGER.md`
- 矩阵：`docs/00_governance/I4_REQUIREMENT_MATRIX.md`
- 验证入口：`docs/40_validation/VALIDATION_INDEX.md`
- 工具：`tools/i4/README.md`
