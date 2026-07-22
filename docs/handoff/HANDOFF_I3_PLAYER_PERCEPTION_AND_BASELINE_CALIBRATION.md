# I3 Player Perception and Baseline Calibration Handoff

文档状态：`CLOSED / PASS_WITH_NOTES`（以提交后 exact-head full 和同一 HEAD push 为生效条件）
最后更新：2026-07-23

## 中文摘要

I3 已把 I2 后仍明显偏工程展示的部分校准为可由真实生产入口、真实输入和玩家信息复核的基线，同时将 `sources.zip` 中的原始策划案与美术来源按“完整保留身份、内容去重、默认不准入运行时”的规则纳入仓库。项目仍处于增量开发与既有内容修改并行阶段；I3.0–I3.7 是一个阶段的内部切片，不是以后可以跳过整体验证的独立授权。

full/worktree 已通过 75/75，报告为 `E:\AGAME1\.tmp\worktrees\i3\.tmp\i1\20260722T210300990Z_ed330093\report.json`，SHA256 为 `5E07C1FDA64391738ABAC8ABDFA2E71AFE398F88EF1C4DF0F567FECEF710D34D`。本文不能自指最终 commit；最终交付必须补充 exact HEAD/tree、full/head 报告与远端同 SHA 证明。任一外部门失败时，本文只代表 closeout candidate，不代表已关闭基线。

## 1. 交接结论

- Godot 是唯一生产实现权威；活动仓库由 `git rev-parse --show-toplevel` 解析。`E:\UE\Game` 仅是只读体验比较源，Lua/UE/旧 Godot/历史盘符不是当前实现。
- I3 没有回退 Deploy：地图与难度仍在“出发探索”同页双栏完成；没有改成“区域→难度”的分步选择。
- 局内实现现在以公开玩家信息解释地图、搜索、箱子、地面物、战斗撤离、特殊房和终局结果；自动靠近只负责展示，搜索/拾取/替换/结算仍走显式领域命令。
- Base 已作为来源基线入库：25 份“原始策划案”保持原名、完整信息和源字节；1,407 个美术来源成员按 SHA 去重为 1,012 个对象并保留 395 条 alias。Base 不自动成为 runtime asset。
- 最终结果是 `PASS_WITH_NOTES`，不是“最终美术/动画/音频/性能/发布全部完成”。所有延后项必须使用本文第 7 节的 owner 与重新开启门。

## 2. 已交付能力

### 局内与特殊房

- 5×5 玩家中心小地图；7/10/13 地图尺寸可读；展开地图选择与旗帜/快速返程确认分离；Esc/M/Q/右键/外点关闭并恢复焦点。
- 搜索→揭示→稳定展示→显式拾取；已开箱重访直接显示内容；地面掉落靠近自动展示但不自动拾取；满包替换使用真实输入和 ledger 命令。
- 快捷背包、背包、地面物、世界对象、替换和结果页使用同一物品描述；品质/类型使用玩家术语，不显示伪空格，滚动与底部居中负重可用。
- HUD 首动作、周围雷险与七类上下文操作按可执行性排序；工程 token 和重复说明已清理。键盘/手柄进入同一移动路径。
- 战斗覆盖入场、预备、命中、恢复、受击、死亡；接触出口不自动逃离，取消不收费，确认只执行一次。Event/Mine/Monster/Exit 只显示公开快照。
- 成功、失败、放弃与保存失败结果均解释原因、可带走、损失和持久化状态；保存重试复用同一快照并保持幂等。

### 局外与设置

- 主菜单使用门厅/洞口/基地下层空间锚点；进入洞口角色实际移动并播放登记帧，取消完整回滚；进入长期系统先播放 180 px 下沉再提交导航。
- Deploy 保持八个地图 ID、同页地图/难度双栏、常驻金币、真实仓库/申领操作，以及“速览/携带/本局/目标”摘要。
- 长期系统当前只诚实呈现 M7 三节点研究前置树，`talent_rules=0`；不能称为完整天赋系统。
- 设置 schema v2 已接入 0–100 主音量、v1 迁移、Master bus、apply/cancel/rollback/restart。未登记类别不得只加 UI 假实现。

### 架构与性能边界

- `RunStateMachine`、`RunAssetLedger`、`RunRuntimeController`/meta adapter、`SaveAdapter` 的既有领域权威继续继承；UI、动画、tooltip 和 capture 不得写领域状态。
- `RuntimeModalLayoutModel` 只承担纯布局计算；modal 栈、焦点、命令和路由仍由 `RunScene` 持有。
- 热路径 actor/texture/capability 已缓存，projectile 使用专用同步。五轮 60 Hz 测量中 projectile15 关键分位在 5% 内、enemy5 改善，但 enemy1 有小幅回退；不得外推为目标 GPU/FPS 或全面性能提升。

## 3. 必须继承的权威与不变量

1. 展示自动化不等于领域自动化：proximity 可自动显示，不得自动搜索、拾取、替换、出售、结算或保存。
2. 地图选择只更新详情；旗帜、快速返程、战斗撤离、Exit、放弃和 salvage 必须经过各自显式确认，取消为零领域命令。
3. 同一 terminal `result_id` 不得重复提交；保存 retry 必须使用同一 finalized snapshot，失败回滚不能伪称成功。
4. `KnownMap`、公开 room snapshot 和 presentation mapping 是玩家信息边界；不得让 UI 读取隐藏房间/敌人状态或工程 token。
5. reduced-motion 必须保持静态可理解状态；新增动画、皮肤或骨骼方案必须同时提供替换、回滚、性能和人工动态门。
6. Base 原始策划案必须继续使用目录名“原始策划案”，保留文件原名与完整信息；工程摘要只能引用，不能替换原件。
7. Base 美术的 `pending_review` / `pending_verification` / `not_admitted` 是真实状态。没有 source/license/hash/derivative/runtime key/consumer/视觉验证链，不得复制到 production。

## 4. 证据入口

| 用途 | 入口 |
| --- | --- |
| 阶段契约 | `docs/20_product/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_CONTRACT.md` |
| 切片与门 | `docs/00_governance/I3_SLICE_GATE_LEDGER.md` |
| 用户反馈处置 | `docs/00_governance/I3_USER_FEEDBACK_DISPOSITION_MATRIX.md` |
| Base 保留/去重 | `docs/00_governance/I3_BASE_RETENTION_AND_DEDUP_AUDIT.md` |
| 原始策划案关系 | `docs/70_sources/base_docs/I3_ORIGINAL_PLANNING_RELATIONSHIP_REGISTRY.md` |
| Base 操作说明 | `sources/base/README.md` |
| 完整验证记录 | `docs/validation/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_VALIDATION.md` |
| 生产证据 | `E:\AGAME1\.tmp\i3_evidence\i3_7_headless_*` 与 `i3_7_rendered_*`（六个 production 目录、47 PNG；不含 `i3_7_cleanup_probe`） |
| 最终 worktree 报告 | `E:\AGAME1\.tmp\worktrees\i3\.tmp\i1\20260722T210300990Z_ed330093\report.json` |

最终 worktree manifest SHA256：`7A85382E1B2DBDC4B1260720369D9C8FC8448DD01E125873060F58907B6589C9`。业务快照为 2,220 files，fingerprint 为 `ED5E6A08A3569470C00F241E265B544E2BBA6766844924D32CC83277E3D0F545`。

## 5. 最短复核顺序

本机观测到的 Godot 路径如下；跨机器仍必须使用 runner 的解析和 identity check，不得把盘符写成项目权威。

```powershell
$repo = git rev-parse --show-toplevel
$godot = 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
Set-Location $repo
```

### 5.1 Base

外部 `sources.zip` 可用时，先验证 archive 与导入关系；提交态/CI 使用仓库独立门：

```powershell
python .\tools\i3\import_base_sources.py `
  --archive "$repo\sources.zip" --repo-root $repo --mode verify

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i3\validate_i3_base.ps1 -RepoRoot $repo
```

预期分别出现：

```text
I3_BASE_IMPORT_VERIFY=PASS files=1041 planning=25 art_members=1407 art_unique=1012 aliases=395
I3_BASE_COMMITTED_VERIFY=PASS files=1041 planning=25 art_members=1407 art_unique=1012 aliases=395
```

### 5.2 I3 定向运行时

```powershell
$tests = @(
  'i3_map_local_context_interaction_runner.gd',
  'i2_world_interaction_runtime_runner.gd',
  'i3_hud_item_input_character_runner.gd',
  'i3_runtime_modal_layout_model_runner.gd',
  'i3_combat_special_result_runtime_runner.gd',
  'i3_long_term_player_contract_runner.gd'
)
foreach ($test in $tests) {
  & $godot --headless --path "$repo\Godot\GraytailGodot" --script "res://tests/$test"
  if ($LASTEXITCODE -ne 0) { throw "$test failed: $LASTEXITCODE" }
}
```

生产旅程由 manifest 中三个 `I3_PRODUCTION_*` runner 从 `main.tscn` 驱动；全量门会复核真实输入、结果分支、满包替换及其精确 cleanup 契约。不要用私开 UI、坐标写入或伪 ViewModel 替代它们。

### 5.3 工作树与提交态

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 -Profile quick -SourceMode worktree -GodotExe $godot
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 -Profile ui -SourceMode worktree -GodotExe $godot
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 -Profile full -SourceMode worktree -GodotExe $godot
```

提交获批内容后，必须从 clean worktree 对 exact HEAD 重新运行：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 -Profile full -SourceMode head -GodotExe $godot

$localHead = git rev-parse HEAD
git push <approved-remote> HEAD:<approved-branch>
$remoteHead = git ls-remote <approved-remote> "refs/heads/<approved-branch>" |
  ForEach-Object { ($_ -split "`t")[0] }
if ($localHead -ne $remoteHead) { throw 'remote HEAD mismatch' }
```

只有 full/head 75/75、blocking 0、pollution PASS，且远端与本地 SHA 相同，I3 才正式关闭。不得在 exact-head 通过后再修改文件并沿用旧报告。

## 6. 玩家操作复核

| 场景 | 应观察到的行为 |
| --- | --- |
| 主菜单转场 | “出发探索”使角色走入洞口；“长期系统”使场景下移。取消或失败恢复原位置/帧/透明度/焦点，不提前提交导航。 |
| Deploy | 地图与难度在同页双栏选择；金币常驻；仓库/申领是实际数据与操作。不存在区域→难度回退页。 |
| 地图 | M/Q 打开或切换，移动焦点只刷新大字号详情；单独确认旗帜/快速返程。Esc、M/Q、右键或面板外点击关闭。 |
| 箱子/地面物 | 首次搜索后显示真实内容，已开箱重访直接显示；靠近地面物自动显示候选，但拾取必须显式确认。 |
| 背包/满包 | 无伪空位；详情与品质一致；可滚动。满包时选替换项才改变 ledger，取消不变。 |
| 战斗撤离 | 接触边界不离开；明确意图后先显示收益/遗留/目标，取消零收费，确认只执行一次。 |
| Exit/结果 | Exit 靠近显示未结算摘要；成功/失败/放弃说明原因、带走和损失。保存失败重试同一快照，不能重复奖励。 |
| 设置 | Apply 写入主音量并应用 Master bus；Cancel/返回回滚未提交值；重启恢复已提交值。 |
| 长期系统 | 当前显示 M7 研究前置树；不得把三节点展示解释为完整天赋规则。 |

## 7. 明确未完成项与重新开启门

| 项目 | owner | 必须补齐的门 |
| --- | --- | --- |
| 最终跨页视觉与动态审美 | UI 美术/产品 UX | 统一 StyleBox/token/层级、动态原机复核、分辨率与 reduced-motion |
| 角色最终动画、时装、骨骼生成 | 角色表现/资产管线 | 真实 rig/素材、替换夹具、性能、回滚、动态人工验收 |
| 批量/快捷售卖 | 经济/产品 | 价格、选择、确认、原子性、幂等和保存失败回滚 |
| 真正天赋树 | 成长系统产品 | 点数、成本、依赖、效果、重置/返还和持久化权威 |
| 新设置分类 | 产品/平台 | schema/adapter/migration/事务/玩家文案与设备验证 |
| Mine 音频/震动及全设备输入 UX | 音频/UX QA | 键鼠/手柄、焦点、DPI、reduced-motion、音频和震动设备门 |
| enemy1 残差与绝对战斗性能 | 性能/战斗体验 | 目标 GPU/FPS、同机可见帧、长局、设备矩阵和玩家感知 |
| 退出清理分类（production 为 18-resource 子集） | Runtime/QA | 逐 runner 找到所有权链并把 manifest 登记的 66 条 diagnostics 降到 0 |
| Base runtime 使用 | 资产治理/法务/美术 | source/license/review/derivative/hash/runtime key/consumer/视觉验证 |
| CI/export/release | 发布工程 | 独立 CI full、export/package/install/smoke 与远端制品证明 |

## 8. Base、UE 与受保护边界

- `sources/base/原始策划案/` 的 25 份原件不得改名、删减或由摘要替换；格式统一必须证明信息等价。策划案是来源，不是当前实现完成证明。
- 美术 blob 去重只合并相同字节，不能删除 alias、来源层级或保留理由。内嵌 archive 和复制型历史治理快照可不重复保存字节，但必须保留 inventory 身份与排除理由。
- 不得将 UE `.uasset`、UE 架构、固定像素布局或未知许可素材复制到 Godot。借鉴 UE 时必须先写明“体验更好”的原因，再选择 Godot 可维护的表达方式。
- 不得把 Base `selected/game_ready` 目录名当成审核结果，也不得把 committed verifier 当成 push 或许可证明。
- 不得修改 `project.godot`、scene/resource、`.uid`、translation 或 import metadata，除非新任务明确授权并通过相应 gate。

## 9. 回滚与后续授权

I3 的进入基线为 `09aaafe283aa2e4c2f30708c5f88b89ebf7753eb`。最终 I3 commit SHA 由外部收口报告给出，不在本文预写。若需要回滚，先确认故障范围和最终交付 commit，再使用可审查的 scoped `git revert <i3-delivery-commit>`；不得使用 `git reset --hard`、覆盖用户工作或删除 Base 来源身份来制造“干净”结果。回滚后至少重跑 Base committed verify、相关定向 runner 以及 full/head。

I3 关闭只授权继承本文明确列出的基线。新功能、ART22/后续美术阶段、真实天赋、批量售卖、新设置、运行时 Base 资产、发布或任何超出矩阵的内容，都必须取得新的用户/治理授权并重新声明 allowed/protected paths、产品契约、性能边界和玩家验收门。

## 10. 最终交付清单

- [ ] 记录最终 exact HEAD 与 tree；worktree clean。
- [ ] exact-head full 75/75；记录 run/report SHA/manifest SHA/business fingerprint/cleanup/blocking/pollution。
- [ ] 推送获批远端分支；`git ls-remote` 与本地 HEAD 完全相同。
- [ ] 最终回复明确列出 `PASS_WITH_NOTES` 残余，不把 Base、审美、性能、CI/export/release 写成完成。

任何一项未完成，本交接状态都是 `CLOSEOUT CANDIDATE / NOT CLOSED`。
