# I4 可复现生产验证操作手册

文档状态：`ACTIVE / FOUNDATION`

## 1. 权威路径

```text
repo_root = git rev-parse --show-toplevel
godot_project = <repo_root>/Godot/GraytailGodot
i4_tools = <repo_root>/tools/i4
```

不得使用历史盘符选择仓库。Godot 路径必须来自参数、专用环境变量或已验证 PATH。

## 2. 标准循环

1. 记录 commit/tree、Godot 版本、profile、scenario 和 seed。
2. 重置 `dev_sandbox`，记录默认 profile 的语义哈希。
3. 从公开生产入口加载场景，不调用私有 UI 方法伪造状态。
4. 通过解析后的键鼠/手柄动作执行输入。
5. 等待领域状态、公开信号或可查询 UI 状态成立。
6. 保存状态快照、日志、截图和存档哈希。
7. 退出并重置 sandbox，再次校验默认 profile 哈希。

## 3. 禁止

- 用固定帧等待代替关键状态完成。
- 直接写玩家坐标、金币、实例、结果页或保存内容作为最终生产证据。
- 用静态截图生成成功宣称交互、手感或动态视觉通过。
- 在默认 profile 上执行修改状态的 debug 命令。
- 忽略单次偶发失败后只保留下一次通过结果。

## 4. 失败包

每个失败目录至少包含：

```text
identity.json
actions.json
state_before.json
state_after.json
save_before.json
save_after.json
focus_modal.json
runtime.log
failure.png
reproduce.ps1
```

`identity.json` 必须含 commit、tree、Godot 版本、scenario、seed、profile、
save target、输入索引和 runner 版本。

## 5. 重复门

- 定向关键场景连续 10 次，其中至少 3 次从新 Godot 进程启动。
- 完整局外生产旅程连续 3 次。
- 一旦中途失败，连续计数清零，并保留失败包。
- 状态一致性以领域/保存语义哈希为主；包含时间或动画相位的像素截图不要求逐字节相同。
