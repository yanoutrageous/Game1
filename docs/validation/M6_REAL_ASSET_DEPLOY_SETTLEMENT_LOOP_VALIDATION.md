# M6 真实资产、出勤与结算闭环验证

状态：PASS_WITH_CLEANUP_DIAGNOSTIC（2026-07-19）

## 中文摘要

本记录验证 M6 是否把真实仓库实例、玩家手动出勤、局内实例、终局消耗品清除、失败手动保全、放弃结算、幂等写回和历史记录连成同一条程序闭环。验证不把 ART24 作为基线，也不修改美术资源、场景、项目配置或 Godot 导入元数据。

## 自动化入口

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\validate_m6_real_asset_deploy_settlement_loop.ps1 `
  -RepoRoot E:\AGAME1 `
  -GodotExecutable E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
```

验证器包含：

- 静态契约与禁止修改面检查；
- Godot headless M6 runner；
- 全部非唯一实体物品的可执行来源检查；
- 初始库存、手动选择、2 件装备与 3 件消耗品上限、应急申领；
- 装备效果进入真实运行状态且只结算一次；
- 成功、失败、放弃三分支的货币、物品与消耗品规则；
- 失败确认前禁止局外提交；
- 结果幂等提交与最多一次历史写入。

## 声明边界

- headless runner 与 project-load smoke 不等于完整人工长时间游玩。
- 本阶段不声明完整仓库经济、研究、抽奖、保险、托运、强化或跨进程局内续玩完成。
- 美术侧可继续通过稳定显示键和既有布局契约替换表现；本阶段不把程序验收绑定到临时贴图尺寸。

## 最终运行记录

```text
M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP=PASS
ART22_DEPLOY_PREP_RUNTIME=PASS
M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP_VALIDATION=PASS
ART23_LONG_TERM_RUNTIME=PASS
G41_IN_RUN_CORE_GAMEPLAY_RUNTIME_VALIDATION=PASS
Godot headless editor/project-load smoke=PASS
git diff --check=PASS
```

M6 外部 runner 在断言完成并以退出码 0 结束后，Godot 报告 `ObjectDB instances leaked` 与 `15 resources still in use` 清理诊断；同类快速退出诊断也存在于旧的外部 runner。该诊断被保留为 `PASS_WITH_CLEANUP_DIAGNOSTIC`，不影响 M6 规则断言，但不得据此声明长期运行、性能或发布通过。
