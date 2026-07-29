# Next Action

文档状态：I4 活动执行入口。

## 当前动作

原 P0–P9 计划继续保留，不因后续补充而删除；当前执行位置已推进到 P9：

1. `P0 / TARGETED_PASS`：I4-R043–R049 已无冲突接入 I4-R001–R042，治理测试 12/12。
2. `P1 / TARGETED_PASS`：隔离测试场、诊断身份、失败包、CLEAN/TAINTED 和默认档哈希门已接入。
3. `P2 / TARGETED_PASS`：数量/交易领域语义、精确实例和失败原子性定向门已通过。
4. `P3 / TARGETED_PASS`：readable/display 字体、16/8/4/2 边框、品质描述器、
   纹理 resolver 和地图四层已接入。
5. `P4 / TARGETED_PASS + VISUAL_CANDIDATE`：Deploy 步进器、详情、六项摘要、
   310/12/310 与地图 198/424 已复验。
6. `P5–P6 / TARGETED_PASS + VISUAL_CANDIDATE`：确定实例、阻挡来源/足迹、
   fallback、地面掉落 body/品质光束已复验。
7. `P7 / TARGETED_PASS + VISUAL_CANDIDATE`：通知直达、显式已读、Back 历史、
   6/25/58 内容和 25 页真实矩阵已复验。
8. `P8 / PARTIAL`：协议、左下密度、地图/模态和 1280 高风险状态已复验；非 Deploy
   四分辨率×三比例全状态和动态玩家输入仍未完成。
9. `P9 / CURRENT`：提交当前候选；执行 clean exact-head/full；完成阶段审计与 push/远端
   SHA。设备清点已完成，但物理手柄、功能听音、目标 GPU 长局和动态玩家验收保持外部阻塞。

当前允许交付的是“已实现且自动验证通过的活动候选”，不是 I4 阶段关闭。即使
exact-head/full 与 push 成功，也不得把外部门写成 PASS。

## 执行规则

- 每个切片先做当前生产消费者和领域权威审计，再修改。
- 只修改与当前切片直接相关的文件；不顺带增加内容或重写无关模块。
- 关键状态等待领域信号/查询，不使用固定帧数证明正确性。
- 所有 debug 写操作只在 sandbox；默认档前后语义哈希必须一致。
- 购买/出售/结算任一失败必须恢复交易前金币、实例和保存。
- 受保护 Godot 文件只有在对应 gate 登记后才允许修改/暂存。
- 未运行证据保持 `NOT_RUN`；静态截图不能替代动态玩家或真实设备。
- 遮挡按 R/S/G/V/H/F/P 和 0 可见像素交叠判定，不能只写“看起来有/没有遮挡”。
- 遮挡优先修正捕获、slice/inset、扩容、重排、换行和滚动；不得先删信息或缩到 token 下限以下。
- 共享边框修改必须复验全部消费者，不能只修仓库截图。
- 地图共享合成修改必须同时复验折叠/展开；品质/resolver 修改必须复验全部物品消费者。
- 碰撞修改必须导出来源描述器，并回归全房型、门、攻击裁切、地面物和结算。

## 停止并调查

- 默认档被调试修改。
- 交易出现部分成功或重复提交。
- 聚合后丢失精确实例身份。
- UI 成为领域或保存第二权威。
- 文本截断、遮挡或滚动不可达仍存在。
- 任一组件超过边框带宽/比例门，或同一内容簇出现三层完整框。
- 摘要首屏信息少于冻结的六项，或用大空框代替信息层级。
- 地图子层越格、图标/计数分配矩形相交，或背景 HUD 穿透展开地图内容板。
- 任一静态阻挡无法反查当前可见对应物，或贴图/对象退场后仍保留碰撞。
- 协议任一字形/压力条越出按真实 B 计算的 S，或左下语义间空白超过 8 px。
- 当前登记物品在任一消费者出现空纹理，或 focus/失败状态覆盖品质身份。
- 工作树出现来源未知的 scene/resource/project/import/translation 变化。

## 当前权威

- 契约：`docs/20_product/I4_PRODUCTION_INTERACTION_CONVERGENCE_CONTRACT.md`
- 质量标准：`docs/20_product/I4_ENGINEERING_QUALITY_AND_ACCEPTANCE_STANDARD.md`
- 台账：`docs/00_governance/I4_EXECUTION_LEDGER.md`
- 矩阵：`docs/00_governance/I4_REQUIREMENT_MATRIX.md`
- 验证入口：`docs/40_validation/VALIDATION_INDEX.md`
- 工具：`tools/i4/README.md`
