# Audit Scope

文档状态：I1 当前审计范围。
最后更新：2026-07-21

## 已纳入

- 由 `git rev-parse --show-toplevel` 解析的活动仓库、Godot 工程、当前文档和注册表。
- Git branch / HEAD / origin / index / refs / stash / worktree / dirty / staged / untracked。
- 当前代码的命令、状态、刷新、保存、终局提交、UI、动画、资源和项目元数据边界。
- I1 static、preflight/quick/core/ui/full、worktree/head、报告、marker、diagnostic 和污染守卫。
- production `main.tscn` 的九状态 × 三分辨率预览生成与人工图片复核。
- ART25 来源、许可、hash、manifest、确定性与 production runtime key。
- 当前入口、来源、Godot docs registry、重复/生命周期/编码与阶段索引。
- 本机 Godot 4.6.3 路径、版本、大小与 SHA-256；跨机器解析规则另行核对。

## 历史证据使用

- I1 是最新闭合非美术基线，ART21 是项目级最新闭合美术阶段；I0 保留为其前序冻结基线。
- ART23 是较晚页面/UI 验收证据切片；ART24R2 是 24/61 失败封存。
- G41/M6/M7 与更早 runner/validation 可用于回归，但当前实现和 I1 结果优先。
- 历史 `D:\AGAME1` source/report/worktree 路径只证明当时机器布局；本机 external source pack 当前不可用。

## 明确未声称完成

- 退出 Godot 进程后的 active-run 检查点恢复和迁移。
- 完整仓库经济、装备深度、Boss/精英、更深内容、抽奖/唯一物/实际外观。
- 完整人工长时间游玩、最终视觉/音频、鼠标/手柄/动画手感。
- 除 combat refresh 微基准外的通用性能、设备/输入矩阵。
- GitHub Actions full、导出、发布或 release gate；已成功的 Actions quick 只证明 quick profile。
- 对所有历史文档、branch 或 external source pack 的破坏性清理。

## 证据等级

当前代码与可运行/可见证据优先于对话或历史摘要。worktree runner、committed HEAD、capture、人审、performance、CI 和 release 各自只能证明其明确范围。I1 以提交态 full/head 39/39、Git 交付与远端 quick 成功关闭为 `PASS_WITH_NOTES`；其排除项不因阶段关闭而转为已完成。
