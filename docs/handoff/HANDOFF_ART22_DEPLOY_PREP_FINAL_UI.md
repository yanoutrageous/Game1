# Handoff: ART22 出发探索最终美术 UI

状态：CLOSED / PASS

日期：2026-07-18

## 中文摘要

ART22 已完成真实出发探索页的场景式 UI：环境角色与两块竖直锁链导航、可收起大羊皮纸、
5 个一级页签和 34 个二级状态、悬挂四页摘要、指示牌操作、进行时取消边界，以及 8 帧角色
和 10 组环境动效。最终验收先冻结标准，再用 Computer Use 全量执行；失败均返工并从头复验。

## 分支与基线

```text
branch: art/art22-deploy-prep-final-ui
base: origin/integration/i0-art21-baseline
godot_project: <worktree>/Godot/GraytailGodot
design_canvas: 1280x720
```

## 主要入口

- UI：`Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd`
- 布局：`deploy_prep_layout_contract.gd`
- 卡片：`deploy_prep_card_view.gd`
- 资产契约：`scripts/presentation/art22_deploy_prep_asset_contract.gd`
- 运行时素材：`assets/ui/art22/deploy_prep/`
- 生成器：`tools/art22_build_deploy_prep_runtime.py`
- 验收标准：`docs/validation/ART22_DEPLOY_PREP_FINAL_UI_ACCEPTANCE.md`
- 验证原文：`docs/validation/ART22_DEPLOY_PREP_FINAL_UI_VALIDATION.md`

## 必须保留

- `main.tscn → RunScene → AppShell → DeployPrepShell` 的真实挂载。
- `AppShell.page_changed` 与 `RunScene.screen_state` 同步；否则 Esc / 返回语义会失真。
- `AssetCatalog` 的原图读取后备只在 `ResourceLoader` 不可用且文件真实存在时启用，并缓存纹理；
  仓库禁止提交 `.import`，删除该后备会使开发运行回退旧资产。
- 二级筛选切换时不重建筛选行；不可取消的 ButtonGroup 维持唯一选中。
- 长筛选按真实按钮边界最小滚动；不要恢复“hover 抢焦点”。
- 玩家可见说明必须依附卡片 / 摘要 / 状态底板，不恢复无底板原生 tooltip。
- 取消当前探索的真实确认在接口未接入时保持禁用。

## 接手验证

```powershell
$env:GODOT4_CONSOLE = '<Godot 4.6.3 console path>'
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools/validate_art22_deploy_prep_final_ui.ps1

powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools/i0/invoke_i0_tests.ps1 `
  -Profile remediated `
  -SourceMode head
```

## 当前边界

- ART22 不实现真实继续持久化、放弃结算、完整奖励或许可消耗。
- 长期系统仍不是最终美术交付；外观 / 时装只复用其既有路由。
- 用户要求先完成 MVP，再谈主线收敛；ART22 关闭不等于 MVP 完成。
- 后继阶段需重新命名、重新冻结验收标准，并继续“计划—审计—执行—完成审计—push”。
- I0 的 `PASS_WITH_NOTES`、历史安全不符合和有限人工覆盖仍必须继承。
