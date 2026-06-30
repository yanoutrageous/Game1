# M4 Repository Sync Metadata Policy

文档状态：M4 metadata 策略裁决
适用范围：Godot generated metadata、ART15/17 准入、clean checkout 验证流程
最后更新：2026/06/30

本文件只定义 M4 的仓库同步和 metadata 处理口径，不替代具体 release gate，不声明 gameplay runtime PASS 或 manual playtest PASS。

## 1. Dirty 归属裁决

当前主工作区 dirty 归属如下：

| 类型 | 路径 / 范围 | 归属 | M4 处理策略 |
| --- | --- | --- | --- |
| ART/UI 真改动 | `Godot/GraytailGodot/scripts/presentation/art09_manifest_asset_mapping.gd`、`art10_ui_skin_kit.gd` | 真代码，不是 metadata | 不作为当前 main dirty 提交；应通过 ART15/17 分支完整准入。当前 main dirty 是临时/局部修补，且会覆盖 ART 分支更完整实现。 |
| Godot migration | `Godot/GraytailGodot/project.godot` | Godot 4.6.3 editor auto rewrite / migration candidate | 不混入 ART；若需要纳入，必须单独 metadata/project gate。当前 M4 默认不随 ART 提交。 |
| `.gd.uid` | `Godot/GraytailGodot/scripts/**/*.gd.uid` | Godot generated script UID metadata | 当前仓库已有 tracked uid，也存在 untracked uid。以 clean checkout 可验证为优先；不得提交 `.godot/` cache。是否纳入缺失 uid 需独立 metadata gate。 |
| `.translation` | `Godot/GraytailGodot/data/assets/asset_manifest.*.translation` | Godot generated translation metadata | 默认不纳入 ART / M4 工具提交。tracked dirty 应恢复，untracked generated 应精确删除，除非另有资源导入 gate 证明需要版本控制。 |
| `.godot/` | `Godot/GraytailGodot/.godot/` | editor/import cache | 必须 ignore，不入库。clean checkout parser 验证可先生成 cache，但不得提交。 |

## 2. project.godot 策略

`project.godot` 当前差异包含：

```text
config/features: 4.0 -> 4.6
animation compatibility setting
input event formatting rewrite
window/stretch/aspect 删除
renderer 行重排
```

裁决：

```text
不混入 ART15/17。
不作为 M4 docs/tools 提交的一部分。
若团队确认 Godot 4.6.3 migration 为当前项目事实，应另开 project metadata gate 单独提交，并验证窗口 / 输入 / renderer 行为。
```

## 3. .gd.uid 策略

事实：

```text
当前仓库已有 tracked .gd.uid。
当前主工作区还有多个 untracked .gd.uid，对应已存在的 .gd 脚本。
clean checkout 直接 project-load 可能缺少 .godot/global_script_class_cache.cfg，造成 class_name 解析失败。
```

裁决：

```text
.gd.uid 不等同于 .godot cache。
是否将缺失 .gd.uid 纳入版本控制，应以 clean checkout editor/import + project-load 验证为准。
M4 本轮不把 .gd.uid 与 ART 内容混合提交。
缺失 uid 若被证明是 clean checkout parser 的必要条件，应走独立 metadata gate。
```

## 4. .translation 策略

裁决：

```text
asset_manifest.*.translation 视为 Godot generated metadata。
当前没有证据证明它们是 ART15/17 或 M4 governance 所需的手写资产。
tracked dirty 不应提交；untracked generated translation 不应入库。
不得使用 git clean；只能按精确清单 restore / Remove-Item。
```

## 5. Clean Checkout Godot 验证流程

标准流程：

```text
1. 使用 clean main 或模拟 main+ART 的独立 worktree。
2. 先运行：
   D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe --headless --editor --path <project> --quit
3. 再运行：
   D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe --headless --path <project> --quit
4. 检查工作区 dirty。
5. `.godot/` 和 generated cache 不提交。
```

说明：

```text
普通 project-load 在 clean checkout 前可能因为没有 `.godot/global_script_class_cache.cfg` 而失败。
ObjectDB / resource leak warning 若 Godot 退出码为 0，可记录为 note，不应自动扩大为 gameplay failure。
该流程只证明 project-load / parser，不证明 gameplay runtime PASS 或 manual playtest PASS。
```

## 5.1 M4 实测验证结论

验证 worktree：

```text
D:\AGAME1\_repo_cache\Game1_m4_art_validation
base: main e9c17cb784aadba37c67c07a6a3716f0b75e38cb
merged: godot/art15-art17-visual-ui-cleanup 7d405ccc9f0ad656a62cadcf9c9e27096a4d5434
merge mode: fast-forward
```

结果：

```text
Godot --headless --editor --path <project> --quit: PASS / exit 0
Godot --headless --path <project> --quit: PASS / exit 0
普通 project-load 输出 ObjectDB/resource still in use warning，按 M4 规则记为 note。
```

验证后 generated dirty：

```text
tracked asset_manifest.*.translation modified
untracked asset_manifest.*.translation created
untracked scripts/**/*.gd.uid created
.godot cache generated but ignored
```

裁决：

```text
这些 dirty 是 Godot editor/import metadata，不属于 ART15/17 release content。
ART release gate 可记录这些 generated dirty，但不得提交它们。
若团队希望消除每次 import 后的 untracked .gd.uid，需要另开 metadata UID registration gate。
```

## 6. ART15/17 准入策略

```text
ART15/17 分支已通过 `docs(art): fix ART15 validation whitespace` 修复 markdown EOF whitespace。
ART15/17 分支不得夹带 project.godot / .translation / .uid / .import metadata。
ART15/17 验证应包含 ART15R layout、ART17 screen layering、G39 navigation boundary、M4 repository sync 和 Godot editor/import + project-load。
validate_art15_core_art_asset_pipeline.ps1 若作为纯 ART15 gate 不接受 combined ART15/17 的 run_scene/UI 改动，应记录为 legacy/pure-gate mismatch，不能用作单独放行证据。
```

## 7. 当前推荐下一步

```text
1. 用独立 worktree 模拟 main + ART。
2. 跑 M4 validation、ART validators、G39 validation、Godot editor/import + project-load。
3. 若通过，进入 ART release gate。
4. main 只能在 release gate 后 fast-forward，不由 M4 直接 push main。
```
