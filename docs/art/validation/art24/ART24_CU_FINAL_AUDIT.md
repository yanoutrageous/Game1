# ART24 Computer Use 最终验收

- 验收标准：`ART24-ARTPACK-CU-FROZEN-1`
- 验收对象：`art/art24-in-run-final-ui`
- 验收方式：Computer Use 操作真实 Godot ART24 预览；分辨率全帧由同一 Godot 矩阵捕获器生成，并在 Windows Photos 中适配显示后复核四边。
- 最终结果：`PASS`
- 静态门禁：`ART24_STATIC_VALIDATION=PASS assets=142 reused=14 states=54 decoded_mib=27.16 matrix=required`。
- 生效前提：提交中不得包含 Godot 导入副产物或程序所有权文件改动。

## 返工历史

1. 尝试 1 在 `room.chest.opening` 停止：开启帧与已开启帧区分不足。补充 6 帧开启光环后废弃整轮结果。
2. 尝试 2 在 `inventory.empty` 停止：空背包正文与容量摘要矛盾。统一背包、拾取阻塞与替换预览容量语义，并重新生成 270 张矩阵。
3. 尝试 3 从 `01/54` 重新开始，未沿用前两次的部分通过结果，完整通过。

## 54 个二级状态

- 记录：Computer Use 按 CSV 顺序逐次发送一次 `Right`，每次操作后重新读取窗口截图。
- 数量：54；唯一窗口标题：54；首项 `room.normal.idle`；末项 `motion.reduced`。
- 房间状态：normal、mine、chest、event、monster、exit 的状态、道具和反馈一致。
- 协议状态：等级 5 至 1 的标题、颜色、压力条与“安全 5 → 1 危险”方向一致。
- 地图状态：overview、cell_selected、marked、return_available 均可辨识。
- 背包状态：empty、populated、selected、full、tooltip 均可辨识；容量摘要与左栏一致。
- 地面拾取：spawn、hover、panel、selected、pickup、capacity_blocked、replace_preview 均可辨识；阻塞为 9/10 且需求 2 格，替换预览为 10/10。
- 覆盖层与结算：教程、事件、暂停、安全撤离、高风险撤离及成功/失败/中止结算均保持正确层级和危险色。

## 8 个一级模块跳转

Computer Use 从 `motion.reduced` 开始连续使用 `PageDown`，实际顺序为：

`room.normal.idle` → `protocol.level.5` → `map.overview` → `inventory.empty` → `loot.spawn` → `overlay.tutorial` → `result.success` → `motion.full`

八次跳转均保留预期背景、遮罩层级和固定模块，没有错页、空页或页签结构漂移。

## 60 秒动效

- 起点：真实 Godot 窗口 `motion.full`。
- 实际连续观察：68.410 秒。
- 结果：窗口未冻结、未跳页；角色呼吸/眨眼、扫描环、环境尘粒和掉落光柱持续变化，无闪屏或大图回退。
- 精简动效：切换 `motion.reduced` 后，循环尘粒和扫描动画收敛，关键静态结果仍可理解。

## 五档分辨率

| 逻辑分辨率 | 真实 Godot 窗口 | 同源原生全帧 | 结果 |
| --- | --- | --- | --- |
| 1280×720 | 已检查 | Photos 显示 `1280 × 720` | PASS |
| 1366×768 | 已检查 | Photos 显示 `1366 × 768` | PASS |
| 1600×900 | 已检查 | Photos 显示 `1600 × 900` | PASS |
| 1920×1080 | 已检查；窗口超出当前桌面可视宽度 | Photos 显示 `1920 × 1080` 并完整适配 | PASS |
| 2560×1440 | 已检查；窗口超出当前物理桌面 | Photos 显示 `2560 × 1440` 并完整适配 | PASS |

当前桌面无法完整容纳后两档实时窗口，因此没有把桌面裁切误判为游戏裁切；最终四边判断使用同一 Godot 捕获器生成的原生尺寸全帧。五档均可见左栏、中央场景、右上协议牌、底栏与至少 8 逻辑像素安全区，无黑边、溢出或非等比拉伸。

## 结论

在冻结标准范围内，ART24 的美术资产包、表现接口与隔离预览通过最终 Computer Use 验收。此结论不声明局内玩法程序已完成接线，也不替代程序侧拾取、持久化或自然流程验收。
