# Godot Environment Final Report

## 时间

2026-06-08 14:49:52 +08:00

## 工作目录

`D:\Godot`

## 项目目录

`D:\Godot\GraytailGodot`

## Godot 下载来源

- 官方 GitHub release: `https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/Godot_v4.6.3-stable_win64.exe.zip`
- 首次尝试的 Godot 官方下载入口: `https://downloads.godotengine.org/?flavor=stable&platform=windows.64&slug=win64.exe.zip&version=4.6.3`
- Godot 官方下载入口因 Windows 证书吊销服务器离线导致 `curl` TLS 检查失败，未生成下载文件。
- 官方 GitHub API latest tag 确认为 `4.6.3-stable`，匹配资产为 `Godot_v4.6.3-stable_win64.exe.zip`。

## Godot 下载文件

- 文件: `D:\Godot\Tools\Downloads\Godot_v4.6.3-stable_win64.exe.zip`
- 大小: `79844616` bytes
- 下载完成时间: `2026-06-08 14:45:28 +08:00`

## Godot 解压目录

`D:\Godot\Tools\Godot`

## Godot 可执行文件

- 编辑器: `D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64.exe`
- Console: `D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe`
- 选定验证目标: `D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe`

## Godot 签名检查

- `Godot_v4.6.3-stable_win64.exe`: `UnknownError`
- `Godot_v4.6.3-stable_win64_console.exe`: `UnknownError`
- 状态信息: `A certificate chain could not be built to a trusted root authority`
- 签名者: `CN=Prehensile Tales B.V., O=Prehensile Tales B.V., L=Uitgeest, S=Noord Holland, C=NL`
- 处理结论: 未达到 `Valid`，按安全边界停止运行 Godot。

## Godot 版本

- 文件名版本: `4.6.3-stable`
- 命令检测: 未执行。原因是 Godot 可执行文件 Authenticode 签名状态未达到 `Valid`。

## self-contained mode 状态

已创建: `D:\Godot\Tools\Godot\_sc_`

## Godot 默认生成内容说明

未运行 Godot，因此未生成 `D:\Godot\Tools\Godot\editor_data`、项目 `.godot` 缓存或导入缓存。

## C 盘默认修改说明

CodeX 未手工创建、编辑、移动或删除 C 盘内容。Windows、PowerShell、curl 或系统证书检查机制如自然产生少量默认缓存，本轮未手工检查或清理。

## project.godot 配置结果

已配置：

- 项目名: `GraytailGodot`
- 主场景: `res://scenes/main/main.tscn`
- 视口: `1280x720`
- Stretch mode: `canvas_items`
- Stretch aspect: `keep`
- 渲染方法: `gl_compatibility`
- 默认纹理过滤: nearest

## Autoload 配置结果

已配置：

- `GameKernel="*res://scripts/core/run/game_kernel.gd"`
- `ContentDB="*res://scripts/core/content/content_db.gd"`
- `SettingsManager="*res://scripts/core/settings/settings_manager.gd"`

## 输入映射配置结果

已配置：

- `move_up`: W / Up
- `move_down`: S / Down
- `move_left`: A / Left
- `move_right`: D / Right
- `interact`: E
- `attack`: Space / J
- `open_map`: Tab / M
- `flag_cell`: F
- `cancel`: Esc
- `pause`: Esc
- `debug_restart_run`: R

## 占位场景配置结果

已创建或确认：

- `scenes/main/main.tscn`
- `scenes/run/run_scene.tscn`
- `scenes/room/room_scene.tscn`
- `scenes/ui/hud/hud.tscn`
- `scenes/ui/minimap/minimap_panel.tscn`
- `scenes/ui/result/result_panel.tscn`
- `scenes/player/player.tscn`
- `scenes/interactables/chest_placeholder.tscn`
- `scenes/interactables/exit_beacon_placeholder.tscn`

## 核心脚本配置结果

已创建或更新：

- `scripts/core/run/game_kernel.gd`
- `scripts/core/run/run_context.gd`
- `scripts/core/map/truth_map.gd`
- `scripts/core/intel/intel_map.gd`
- `scripts/core/map/minefield_service.gd`
- `scripts/core/run/room_resolver.gd`
- `scripts/core/command/command_bus.gd`
- `scripts/core/content/content_db.gd`
- `scripts/core/settings/settings_manager.gd`
- `scripts/ui/minimap/minimap_view_model.gd`
- `scripts/ui/hud/hud_view_model.gd`
- `scripts/ui/minimap/minimap_panel.gd`
- `scripts/ui/hud/hud.gd`
- `scripts/ui/result/result_panel.gd`
- `scripts/gameplay/player/player_controller.gd`
- `scripts/gameplay/rooms/room_scene_controller.gd`
- `scripts/gameplay/interactables/chest_placeholder.gd`
- `scripts/gameplay/interactables/exit_beacon_placeholder.gd`

## 资产迁移准备文档

已创建：

- `docs/ASSET_IMPORT_RULES.md`
- `docs/ASSET_TRANSFER_T0_CHECKLIST.md`
- `docs/ASSET_ID_NAMING.md`
- `docs/GODOT_READY_FOR_ASSET_TRANSFER.md`

## 项目结构验证结果

`PROJECT_STRUCTURE_VALIDATION=PASS`

检查文件数: `33`

## Godot headless 验证结果

未执行。原因是 Authenticode 签名检查未达到 `Valid`，按安全边界不得运行 Godot。

## Git 状态

未初始化 Git 仓库。

## 阻塞项

Godot 可执行文件签名状态为 `UnknownError`，本机无法构建到受信任根的证书链。按本轮规则，不能继续运行 Godot，也就不能完成 `--version` 与 headless 项目加载验证。

## 是否可以进入资产迁移阶段

暂不可以，原因是 Godot 可执行文件签名无法确认，未能执行 Godot 版本检测和 headless 项目加载验证。

## 下一步资产迁移建议

先在不修改项目内容的前提下解决本机对 Godot 签名证书链的信任问题，随后重新执行：

- Godot 版本检测
- Godot headless 项目验证
- 首批小地图图标迁移前检查

---

# Godot Environment Final Verification Report

## 时间

2026-06-08 14:58:07 +08:00

## 工作目录

`D:\Godot`

## 项目目录

`D:\Godot\GraytailGodot`

## Godot ZIP 文件

`D:\Godot\Tools\Downloads\Godot_v4.6.3-stable_win64.exe.zip`

## Godot ZIP 本地 SHA256

`E39986A178D585CE7AC198FB8DE6EA436366DC0CC00E594810C2E3E104C04B90`

## 官方 SHA256 / digest 来源

官方 GitHub release metadata:

`https://api.github.com/repos/godotengine/godot-builds/releases/latest`

Exact asset:

`https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/Godot_v4.6.3-stable_win64.exe.zip`

## 官方 SHA256 / digest 值

`sha256:e39986a178d585ce7ac198fb8de6ea436366dc0cc00e594810c2e3e104c04b90`

## SHA256 是否匹配

匹配。

## ZIP 内容检查

ZIP 内仅包含：

- `Godot_v4.6.3-stable_win64.exe`
- `Godot_v4.6.3-stable_win64_console.exe`

未发现异常可执行文件、脚本、安装器或无关内容。

## Godot exe 路径

- `D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64.exe`
- `D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe`

## Authenticode 签名复核

`Godot_v4.6.3-stable_win64.exe`:

- Status: `UnknownError`
- StatusMessage: `A certificate chain could not be built to a trusted root authority`
- SignerCertificate.Subject: `CN=Prehensile Tales B.V., O=Prehensile Tales B.V., L=Uitgeest, S=Noord Holland, C=NL`
- SignerCertificate.Issuer: `CN=Certum Code Signing 2021 CA, O=Asseco Data Systems S.A., C=PL`
- SignerCertificate.Thumbprint: `AD7729D8BED913352F2F21347D3DF5376F17E109`
- TimeStamperCertificate.Subject: `CN=Certum Timestamp 2026, O=Asseco Data Systems S.A., C=PL`
- TimeStamperCertificate.Issuer: `CN=Certum Timestamping 2021 CA, O=Asseco Data Systems S.A., C=PL`
- TimeStamperCertificate.Thumbprint: `571468410CA85AF3424EF9164A513610F4D38D98`

`Godot_v4.6.3-stable_win64_console.exe`:

- Status: `UnknownError`
- StatusMessage: `A certificate chain could not be built to a trusted root authority`
- SignerCertificate.Subject: `CN=Prehensile Tales B.V., O=Prehensile Tales B.V., L=Uitgeest, S=Noord Holland, C=NL`
- SignerCertificate.Issuer: `CN=Certum Code Signing 2021 CA, O=Asseco Data Systems S.A., C=PL`
- SignerCertificate.Thumbprint: `AD7729D8BED913352F2F21347D3DF5376F17E109`
- TimeStamperCertificate.Subject: `CN=Certum Timestamp 2026, O=Asseco Data Systems S.A., C=PL`
- TimeStamperCertificate.Issuer: `CN=Certum Timestamping 2021 CA, O=Asseco Data Systems S.A., C=PL`
- TimeStamperCertificate.Thumbprint: `571468410CA85AF3424EF9164A513610F4D38D98`

## Authenticode 状态解释

本机仍无法建立到受信任根的证书链，因此 Authenticode 状态为 `UnknownError`。未出现 `HashMismatch`、`NotSigned`、`NotTrustedPublisher` 等高风险状态；ZIP 官方 digest 与本地 SHA256 完全匹配，签名主体为 `Prehensile Tales B.V.`。

## 是否允许在 UnknownError 下继续运行

允许。T1B 多重验证准入 A-H 全部满足：

- 官方 release 来源匹配。
- exact asset 文件名匹配。
- SHA256 匹配官方 digest。
- ZIP 内 exe 文件名符合 Godot Windows 标准版命名。
- 签名主体为 `Prehensile Tales B.V.`。
- 签名状态未显示恶意篡改、`HashMismatch`、`NotSigned` 或 `NotTrustedPublisher`。
- `_sc_` self-contained 标记存在。
- Godot 文件全部位于 `D:\Godot\Tools\Godot\`。

## self-contained mode 状态

已存在：`D:\Godot\Tools\Godot\_sc_`

## Godot 版本检测

命令：

`D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe --version`

结果：

`4.6.3.stable.official.7d41c59c4`

## Godot headless 项目验证

命令：

`D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\Godot\GraytailGodot --quit`

最终结果：

- Exit code: `0`
- 输出: `Godot Engine v4.6.3.stable.official.7d41c59c4 - https://godotengine.org`
- 未出现脚本解析错误。

编辑器侧补充验证：

`--headless --editor --path D:\Godot\GraytailGodot --quit`

- Exit code: `0`
- 完成首次文件扫描、全局类注册和 `asset_manifest.csv` 导入。
- 输出末尾出现 Godot 内部 `optimized_translation.cpp` 的翻译表相关错误。该错误未导致退出失败，也未指向项目脚本或资产阻塞。

本轮首次 headless 验证曾暴露 `game_kernel.gd` 对 `RunContext` / `CommandBus` 的 Autoload 阶段类型解析问题，已做最小项目内修正并复测通过。

## Godot 默认生成内容说明

Godot 自然生成：

- `D:\Godot\Tools\Godot\editor_data\`
- `D:\Godot\GraytailGodot\.godot\`
- `D:\Godot\GraytailGodot\data\assets\asset_manifest.csv.import`

未手工修改这些生成内容。

## C 盘默认修改说明

CodeX 未手工创建、编辑、移动或删除 C 盘内容。Windows、PowerShell 网络请求、GitHub TLS 访问、证书状态检查或 Godot 程序如自然产生少量默认 C 盘缓存，本轮未手工检查或清理。

## 项目结构验证结果

`PROJECT_STRUCTURE_VALIDATION=PASS`

检查文件数：`33`

## Git 状态

未初始化 Git 仓库。

## 阻塞项

无阻塞项。Authenticode `UnknownError` 已通过官方 digest、ZIP 内容、签名主体和路径边界复核准入。

## 是否可以进入资产迁移阶段

可以。

## 下一步资产迁移建议

进入第一批资产迁移：先迁移小地图图标。每个资产必须先登记 `data/assets/asset_manifest.csv`，确认授权状态和 Godot 目标路径后再导入，不进行全量资产目录复制。
