# I4 Validation Tools

本目录承载 I4 生产交互收敛与可复现验证入口。

当前阶段：`ACTIVE / IMPLEMENTED_CANDIDATE / EXTERNAL_GATES_OPEN`

规范性质量标准：
`docs/20_product/I4_ENGINEERING_QUALITY_AND_ACCEPTANCE_STANDARD.md`

计划入口：

- `invoke_i4.ps1`：统一 `governance/preflight/full` 与 `worktree/head` 调度；
- `validate_i4_static.ps1`：合同、注册、受保护文件、固定帧等待与文案静态门；
- Godot targeted runners：sandbox、交易、Deploy、局内、长期、字体/布局；
- production journey：从真实 `main.tscn` 执行解析输入；
- repetition runner：关键场景 10 连过和局外旅程 3 连过；
- failure bundle：保存身份、动作、状态、存档、焦点、日志和截图。
- content census：导出当前页面/状态/fixture/layout class/risk flags，不能用历史固定数量替代。
- geometry report：采集 R/S/G/V/H/F/P、字体、边框带宽/层级和滚动可达性。
- `capture_i4_real_render.ps1`：真实 Windows renderer 捕获 Deploy 4×3、长期 25 页和
  I4 高风险生产状态；捕获成功只标 `VISUAL_CANDIDATE`。
- manual visual ledger：逐原图记录规则、实际结果、失败矩形、根因和复验范围。
- legacy assertion disposition：旧断言只能保留权威、带替代门取代或有证据无效。
- map composition report：折叠/展开地图的 base/semantic/count/focus 层、clip 和越格像素。
- obstacle correspondence report：全房型 obstacle 来源、视觉足迹、纹理状态和通行扫描。
- HUD density report：协议 B/S/G/V/H 与左下 0/1/3/4/满包内容高度。
- item presentation census：全 item ID 的跨消费者 visual key/path、品质色和 fallback。

统一自动门：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i4\invoke_i4.ps1 `
  -Profile full `
  -SourceMode worktree `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

真实渲染候选：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i4\capture_i4_real_render.ps1 `
  -Profile all `
  -SourceMode worktree `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

`full` 自动门即使全部成功，也会把阶段接受状态保持为
`BLOCKED_EXTERNAL_DEVICE_AND_DYNAMIC_ACCEPTANCE`；实体手柄、实际音频听检、GPU 接受目标和
动态玩家签收不能由脚本推断。

静态工具不得输出 `VISUAL_PASS`。只有真实 renderer 原图完成逐张复核并且零开放 `MUST`
失败时，视觉台账才能提升该候选。

当前可执行的标准治理测试：

```powershell
python -m unittest tools.i4.tests.test_i4_quality_standard
```

它只验证标准身份、关键阈值、需求编号和跨文档接入，不证明任何生产页面通过。
