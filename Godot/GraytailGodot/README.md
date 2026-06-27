# GraytailGodot

这是《灰尾回收 / 五四三二一》的 Godot 工程入口。

本 README 只说明 Godot 工程边界；当前仓库文档治理入口不在这里，而在：

```text
../../docs/README.md
../../docs/INDEX.md
../../docs/00_governance/DOC_PLACEMENT_STANDARD.md
```

## 当前工程口径

- Godot 工程保存运行骨架、脚本、场景、资源、验证所需项目文件。
- `Godot/GraytailGodot/docs` 保留工程历史和环境证据。
- 当前阶段治理文档、来源注册、重复台账和阶段索引应写入仓库 `docs`，不要写入本目录。
- 当前文档入口承认 G38 / G37S / G37 已存在于仓库文档；G36 是较早工程证据。
- DOC-GOV-002 不修改 Godot 工程代码、场景、资源、data、`project.godot`、`.uid`、`.translation` 或 import metadata。

## 禁止误用

```text
1. 不把 Godot docs 当作文档治理主入口。
2. 不从 Godot 临时实现反推策划定案。
3. 不把 project.godot、.uid、.translation 或导入 metadata 当作文档治理对象。
4. 不在未授权阶段运行 Godot 或执行 manual playtest。
5. 不把 parser/headless smoke 写成 gameplay runtime PASS 或 manual playtest PASS。
```

后续资产、场景、脚本和 metadata 的变更必须经过单独工程 gate。
