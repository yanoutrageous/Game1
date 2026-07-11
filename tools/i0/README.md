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
