# HANDOFF — ART24 局内最终美术 UI

## 交付结论

ART24 已完成局内美术资产包、表现接口契约和隔离 Godot 预览。交付范围包括 8 个一级模块、54 个二级状态、五档响应式布局、角色/怪物/掉落动作资源、拾取反馈、地图/背包/地面物品弹层、覆盖层和结算表现。

本分支没有修改生产玩法脚本、`project.godot` 或全局 `asset_manifest.csv`。它不声明真实拾取命令、库存写入、持久化或自然玩法流程已经接线完成。

## 程序侧接入点

- 接口契约：`docs/60_interfaces/connection/ART24_RUN_PRESENTATION_INTERFACE_V1.md`
- 布局契约：`Godot/GraytailGodot/scripts/presentation/art24/art24_in_run_layout_contract.gd`
- 资产解析：`Godot/GraytailGodot/scripts/presentation/art24/art24_in_run_asset_contract.gd`
- 状态目录：`Godot/GraytailGodot/scripts/presentation/art24/art24_state_catalog.gd`
- 独立 manifest fragment：`Godot/GraytailGodot/assets/art24/contracts/art24_asset_manifest_fragment.csv`

程序侧只需提供只读 `RunPresentationSnapshot` 与表现事件；美术层通过 `visual_key` 解析资产。事件丢失后必须能由下一份完整快照恢复，表现事件不得充当玩法事实源。

## 资产根目录

```text
Godot/GraytailGodot/assets/art24/actors
Godot/GraytailGodot/assets/art24/items
Godot/GraytailGodot/assets/art24/fx
Godot/GraytailGodot/assets/art24/ui
Godot/GraytailGodot/assets/art24/contracts
```

- 新制运行时资产：142
- 合格复用资产：14
- 角色：24 帧基础动作 + 16 帧四方向战斗动作
- 铁背穴兽：8 帧
- 世界掉落：8 类
- 解码预算：27.16 MiB；最大分组 13.91 MiB

素材路径与表现状态均通过契约间接引用；后续替换 PNG 或调整锚点时优先修改 ART24 契约/fragment，不要求程序改写业务逻辑。

## 本地预览与验证

Godot 项目：`D:/AGAME1/active/Game1_art24/Godot/GraytailGodot/project.godot`

隔离预览入口：

```text
res://tests/art24_in_run_art_preview_runner.gd
```

预览中：左右方向键切换 54 个二级状态，PageUp/PageDown 切换 8 个一级模块。生产按键显示固定为 WASD、M/Tab、E、Q、G、Space/J、T、Esc。

静态门禁：

```powershell
python tools/validate_art24_in_run_final_ui.py --require-matrix
```

当前结果：`ART24_STATIC_VALIDATION=PASS assets=142 reused=14 states=54 decoded_mib=27.16 matrix=required`

## 验收证据

- 冻结标准：`docs/validation/ART24_IN_RUN_FINAL_UI_ACCEPTANCE.md`
- 最终 Computer Use：`docs/art/validation/art24/ART24_CU_FINAL_AUDIT.md`
- 两轮优化：`ART24_ROUND1_AUDIT.md`、`ART24_ROUND2_AUDIT.md`
- 分辨率矩阵：`ART24_FINAL_MATRIX_REPORT.md`
- 本地矩阵：五档共 270 张，保留在当前工作树但不提交 301.05 MiB 可再生 PNG。

## 整合边界

后续程序整合应单独执行并重新验收：

1. 将 manifest fragment 合并进全局 manifest，解决同时开发产生的键冲突。
2. 把生产快照字段映射到 V1 契约，不在美术层生成假库存或假奖励。
3. 接通真实拾取成功、容量阻塞、替换预览与物品移除事件。
4. 运行自然局内流程、保存/加载和错误恢复测试。
5. 再做一次 Computer Use 整合验收；ART24 本分支的 PASS 不能替代整合 PASS。
