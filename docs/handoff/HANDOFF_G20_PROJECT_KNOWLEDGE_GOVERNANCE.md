# Handoff G20 项目知识治理

## 当前状态

- 仓库：`D:\AGAME1\_repo_cache\Game1_work`
- 当前分支：`main`
- G20 源分支：`godot/g20-project-knowledge-governance`
- G20-R4B closeout 写入前分支 HEAD：`82e2b1c6bec8311a144b42dd69950e4bfd500d9c`
- G20-R4B closeout commit / first main merge baseline：`ae689b7464fd6ea81a763110cd89813abcfb6665`
- `main` 已通过 fast-forward 首次合并到 `ae689b7464fd6ea81a763110cd89813abcfb6665`
- G20 已合并 `main`。
- G20 final 已执行。
- 本轮 post-merge docs commit hash：pending until commit。
- G21 尚未启动。

## G20 产物概览

- G20-R3a：入库授权的 Base Docs Markdown / TXT 文本设计源副本；Base Docs 原件未修改。
- G20-R3b：完成 source of truth policy、source registry、document lifecycle、naming conventions、execution environment、design source index 等治理地图。
- G20-R3c：完成 G10-G19 stage summaries、stage summary index、route analysis、ROADMAP_G20_PLUS、system boundary map、stage dependency map。
- G20-R3d1：完成 branch inventory、commit milestone map、validation status matrix；已记录 G20-R3d1 `493a5649ea114609abbf28bc07d3e25582fca7ae` 与 G20-R3d2 `ef30741902f0cf9e9984e20de3ceef696b30523a`。
- G20-R3d2：完成 decision log、glossary、temporary / deprecated inventory。
- G20-R4A：只读验收通过，blocker 修复提交为 `82e2b1c6bec8311a144b42dd69950e4bfd500d9c`。
- G20-R4B：docs-only closeout；更新 validation、handoff、current status、index、milestone 和当前导航文档。

## 验证与边界

- G20 是 docs-only 项目知识治理阶段。
- G20 未运行 Godot。
- G20 不声明 Godot parser smoke PASS。
- G20 不声明 full gameplay runtime PASS。
- G20 不声明 manual playtest PASS。
- G20 未修改业务代码。
- G20 未修改 Godot project / scene / resource / uid / translation。
- G20 未修改 Base Docs 原件。
- PNG 仍未入库，仅登记为 `external_reference` / `pending_user_authorization`。

## 后续决策

G20 final 已完成 fast-forward merge main 与 post-merge docs calibration。最终 docs commit hash 在本轮提交后由执行输出确认；本文不预写 hash。

G21 尚未启动。后续 G21 候选方向为 Asset Contract Foundation，但必须单独审计、计划、执行、验收，不能由 G20-R4B 自动承接。

## 安全规则

- 继续保留 `PATCH_MODE=AGAME1_ROOT` 执行安全规则；使用 `apply_patch` 时目标路径必须以 `_repo_cache/Game1_work/` 开头。
- 保护性 stash 不得触碰：`stash@{0}: On main: pre-sync generated dirty before aligning to G15 encounter branch on computer two`。
- Base Docs 原件不得修改、移动、删除、覆盖、重命名。
- 错误外部 Godot 路径 `D:\AGAME1\Godot\GraytailGodot` 不得触碰。
- 不得触碰 `D:\AGAME1\Base Docs`、`D:\AGAME1\Godot`、`D:\AGAME1\_repo_cache\Game_feature_editor_playable_prototype`、`D:\AGAME1\_codex_reports`、旧 UE/Game.git、`lua-prototype-main`、父级目录、兄弟目录、用户目录、系统目录或全局配置目录。
