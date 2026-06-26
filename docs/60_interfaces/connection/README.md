# Connection Interface Sources

文档状态：外部接口来源入口
适用范围：Connection 并行交接资料的只读路径登记
最后更新：2026/06/26

当前来源注册表：

```text
docs/60_interfaces/connection/CONNECTION_SOURCE_REGISTRY.md
```

当前外部交接根目录：

```text
D:\AGAME1\Connection
```

仓库不保存 Connection 内容镜像。Connection 原始文件保持外部并行更新，只能只读访问，不得写入、清理、回滚、移动、覆盖，不得进入 Git，不得作为 Godot 资源导入。

Program / Art 内容不得直接写成策划定案、工程实现任务、验收结论或权限依据。

## DOC-GOV-001 规则

```text
1. Connection 不参与仓库去重。
2. Connection 不作为当前仓库事实源。
3. Connection 内容不得复制入库、提交 Git 或导入 Godot。
4. 仓库只维护路径、来源和边界说明。
```
