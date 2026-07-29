# I4 Validation Tools

本目录承载 I4 生产交互收敛与可复现验证入口。

当前阶段：`ACTIVE / FOUNDATION`

计划入口：

- `invoke_i4.ps1`：统一 profile/source mode 调度；
- `validate_i4_static.ps1`：合同、注册、受保护文件、固定帧等待与文案静态门；
- Godot targeted runners：sandbox、交易、Deploy、局内、长期、字体/布局；
- production journey：从真实 `main.tscn` 执行解析输入；
- repetition runner：关键场景 10 连过和局外旅程 3 连过；
- failure bundle：保存身份、动作、状态、存档、焦点、日志和截图。

任何入口未实现前保持 `NOT_RUN`，不得用本 README 推断通过。
