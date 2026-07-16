# I0 本地工具链

本目录固定 I0 基线重构使用的项目内工具链。它不修改系统 `PATH`、注册表或证书库，也不在 `D:\AGAME1` 外写入文件。

## Godot 4.6.3

执行：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\i0\bootstrap_toolchain.ps1 `
  -WorkspaceRoot D:\AGAME1
```

固定结果：

- 版本：`4.6.3.stable.official.7d41c59c4`
- 安装目录：`D:\AGAME1\tools\runtimes\godot\4.6.3`
- 报告：`D:\AGAME1\reports\i0\I0.1_TOOLCHAIN_CURRENT.json`
- 隔离模式：安装目录内 `_sc_`，且 `TEMP`、`TMP`、`APPDATA`、`LOCALAPPDATA` 只在子进程生命周期内指向项目内 `process-env`

门禁顺序：

1. 只接受 lock 中的官方 GitHub release asset URL、字节数和 SHA-256。
2. ZIP 必须恰好包含两个根级可执行文件。
3. 两个可执行文件的字节数和 SHA-256 必须与 lock 一致。
4. Authenticode 类型、签名者证书和时间戳证书必须与 lock 一致。
5. `--version` 必须完全匹配固定版本输出。
6. 已存在安装也重新对照 lock 验证，不以同目录 manifest 作为信任锚。

当前机器的 Windows 证书库无法把 Certum 链构建到受信根，因此报告必须保持：

```text
result=PASS_WITH_RECORDED_LIMITATION
authenticode_result=CHAIN_UNTRUSTED_RECORDED
godot_signature_chain_trusted=false
```

这表示官方发布 API digest、本地 ZIP 和可执行文件字节均一致，且 PE 中存在固定的签名/时间戳证书元数据；不表示本机 Authenticode 信任链为 `Valid`。

`optional_python` 目前只记录候选版本与哈希，不是核心门禁，也不会由该脚本安装。

## I0.2 隔离特征化测试

修复前基线：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\i0\invoke_i0_tests.ps1 `
  -Profile baseline
```

修复后验收：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\i0\invoke_i0_tests.ps1 `
  -Profile remediated
```

推送或 PR 前的干净提交树验收：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\i0\invoke_i0_tests.ps1 `
  -Profile remediated `
  -SourceMode head
```

测试不会在活动 Godot 项目上运行。每次执行会在 `D:\AGAME1\tools\runtimes\.tmp\i0\<run-id>` 创建独立镜像、引擎硬链接、进程环境、日志和导入缓存，并把正式报告写到 `D:\AGAME1\reports\i0`。

`SourceMode=worktree` 保留原行为，用于验证当前受保护工作树；`SourceMode=head` 通过 run root 内的隔离 Git index 导出 `HEAD`，不修改活动 index、不注册额外 worktree，也不把原有 12 项 dirty 状态带入镜像。HEAD 文档编码门禁从活动 Git 仅读取指定提交的 `docs` 清单、从隔离镜像读取内容，并锁定提交号和 Git 状态。I0 push / PR 声明必须使用 `head` 报告。项目提交树保留 `config/features=PackedStringArray("4.0")`；受保护工作树中的 Godot 4.6 编辑器改写仍作为未裁决 metadata 保留，因此两种 source mode 使用不同的 feature declaration 白名单。

基线必须恰好出现以下四个 `EXPECTED_RED`：

```text
SAVE_ABANDON_COUNT
CSV_ASSET_MANIFEST_WIDTH
INPUT_REQUIRED_ACTIONS
DEBUG_SURFACE_TOGGLES
```

验证范围包括：

- 工具链 lock、EXE 大小/SHA-256 和精确 Godot 版本；
- 当前工作树到沙箱镜像的业务文件哈希一致性；
- 严格 UTF-8、RFC 4180 CSV、17 列/179 行资产清单契约；
- 新镜像内 editor import 与全局类缓存；
- 实测 `res://`、`user://`、日志及写探针全部位于 run root；
- 7 个现有 headless runner 的退出码、唯一 PASS 行、零 FAIL 行；
- 活动仓库的 HEAD、branch、status、stash、Git index、refs 和完整业务文件哈希集合前后不变。

当前 7 个 runner 均通过业务断言，但每个在 Godot 退出时报告相同的 ObjectDB/资源清理诊断。它们只按精确白名单降级为 `PASS_WITH_CLEANUP_DIAGNOSTIC`；其他 `WARNING`、`ERROR`、`SCRIPT ERROR`、`FATAL` 或 `CRASH` 仍会阻塞。基线总结果因此为 `PASS_WITH_EXPECTED_REDS_AND_NOTES`，不能表述成无注记 PASS。
