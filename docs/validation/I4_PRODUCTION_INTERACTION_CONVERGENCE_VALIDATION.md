# I4 生产交互收敛与可复现验证

文档状态：`ACTIVE CANDIDATE / EXTERNAL ACCEPTANCE BLOCKED`

日期：2026-07-30

## 中文摘要

I4 已按冻结标准完成当前候选的 P1–P8 实现、post-audit worktree full、内容普查、重复
运行、旧断言全量处置和正确 FusionPixel 主字体下的 12 组全内容真实捕获。原
I4-R001–R042、用户 Deploy 反例和边框计划均保留；后续局内反馈作为 I4-R043–R049
增量接入，C/E 盘精确存储收口作为 R050 接入，没有覆盖此前要求。

当前结果只能称为：

```text
implementation=IMPLEMENTED_CANDIDATE
automation_worktree=PASS
visual=VISUAL_CANDIDATE
stage=I4 / ACTIVE
stage_acceptance=BLOCKED_EXTERNAL_DEVICE_AND_DYNAMIC_ACCEPTANCE
```

全 12 组的 1140 张原图已经生成，但逐原图人工 ledger、真实窗口动态玩家任务、物理手柄、
功能听音和目标 GPU 长局没有完成，不能由自动 runner、捕获清单、exact-head 或 push
推断通过。

## 1. 验证对象与身份

```text
repo=resolved by git rev-parse --show-toplevel
branch=codex/i4-production-interaction-convergence
entry_commit=4127bd27a05b75cb5e3071cf6dc87d9287f679a9
entry_tree=e1455ffd8c7a754c63eb2141a47e41f8fe5cdf3a
implementation_checkpoint=7af22f44bacc6a5a78e136b35b2faea825b07df8
implementation_candidate=f950eefb000ab298344059dfa8afc125aa79ed8a
implementation_tree=c19957042fb5ebe424694716c6a7a0af72922024
post_audit_base_head=0d4fe159fc86b1b63b4fc13771058313686cb43f
final_audit_commit=THIS_DOCUMENT_COMMIT / BOUND_BY_POST_COMMIT_EXACT_HEAD_REPORT
godot=4.6.3.stable.official.7d41c59c4
renderer=OpenGL 3.3 Compatibility
gpu=NVIDIA GeForce RTX 3060 Laptop GPU
os=Windows
locale=zh_CN
```

入口前已有的 Godot 生成 metadata 仍保存在
`stash@{0}: pre-i4 generated Godot metadata 2026-07-30`，未并入 I4。

## 2. 实施结果

| 范围 | 当前结果 | 主要验证 |
| --- | --- | --- |
| 隔离测试场 | `TARGETED_PASS / VISUAL_CANDIDATE` | 设置入口、`dev_sandbox`、默认档前后哈希、release 隐藏 |
| 诊断面板 | `TARGETED_PASS / VISUAL_CANDIDATE` | 身份横幅、CLEAN/TAINTED、读写分区、失败包、焦点、移动输入关闭 |
| 数量/交易 | `TARGETED_PASS` | N 件购买、精确实例携带/批售、一次保存、失败回滚 |
| Deploy | `TARGETED_PASS / VISUAL_CANDIDATE` | 两行卡、单一数量语义、310/12/310、六项摘要、滚动、上下文金币 |
| 局内物品 | `TARGETED_PASS / VISUAL_CANDIDATE` | 紧凑聚合、确定实例使用/丢弃、内容驱动 0/1/3/4/满包高度 |
| 地图 | `TARGETED_PASS / VISUAL_CANDIDATE` | base/semantic/count/focus z=0/20/30/40、clip、分配矩形 |
| 阻挡/纹理 | `TARGETED_PASS / VISUAL_CANDIDATE` | descriptor、可见足迹、Normal 零匿名障碍、缺图/退场、fallback |
| 品质 | `TARGETED_PASS / VISUAL_CANDIDATE` | 冻结 UE 借鉴色、同一描述器、名称/细边/世界光束及自然语言冗余 |
| 长期系统 | `TARGETED_PASS / VISUAL_CANDIDATE` | 通知直达、显式已读、真实 Back 历史、筛选/选择/滚动/焦点恢复 |
| 字体/边框 | `TARGETED_PASS / VISUAL_CANDIDATE` | display/readable 均为 FusionPixel 主字体、AA/subpixel 关闭、Noto 仅缺字回退、16/8/4/2、最多两层完整框 |

## 3. 自动与重复证据

统一 worktree 预检：

```text
result=PASS
stage_acceptance=AUTOMATION_PREFLIGHT_ONLY
report=.tmp/i4_unified_worktree_preflight_final/evidence/i4_report.json
report_sha256=81741EAE3B23F75EB773BE4DD3EED355A72CFA49B8B3FF05D090370FF0E80F07
static=PASS
quality_tests=12/12
i4_runners=8
protected_dirty=0
fixed_frame_helpers=0
static_report_sha256=1FB11E1C062C7237089CB4EA6670123163FCB73DEFC6A8DEC431120BD16D3906
final_worktree_static=.tmp/i4_static_worktree_final/evidence/static_report.json
final_worktree_static_sha256=13D1EE13E79B21C76211F0CC7FEA1DD3C9CD49EAD2235311BC68FC17324278C1
```

内容普查：

```text
result=PASS
rows=156
deploy_tabs=5
deploy_filters=13
summary_variants=4
long_term_modules/pages/assets=6/25/58
room_types=6
debug_scenarios=6
wrapper_report_sha256=A9717A173F5EE13C09C35F4FF49E9126C32E440E40A8346B43F4B9720D70C3BA
```

完整 worktree 重复门：

```text
result=PASS
critical=6 runners x 10
critical_process_launches=60
journey=3/3
report=.tmp/i4_repetition_worktree_full_1/repetition_report.json
report_sha256=D7D5933EE5DBF6A7F9E8A3412CDE2D44DD1E0D7F1ED1270E57F85C2C70444C19
```

局外旅程退出时的 ObjectDB/资源清理诊断按 manifest 精确分类并保留；它们不是静默忽略，
也没有放宽 `SCRIPT ERROR`、业务 `ERROR`、`FATAL` 或 `CRASH`。

字体权威纠正后的 post-audit worktree 重新执行完整自动门：

```text
i1_full=PASS
i1_runners=104/104
i1_plain=61
i1_cleanup_diagnostic=43
i1_hard_failures=0
i1_duration_ms=1391740
i1_report=.tmp/i1/20260730T061143153Z_8dc91cd6/report.json
i1_report_sha256=DCC085791E5E165C3EE1791FFE693CA738598B875757098262A6D24C7FD62B2D
i4_full=PASS
i4_report=.tmp/i4/invoke/20260730T063525012Z/i4_report.json
i4_report_sha256=A7C479158C7B41B48E3A9171E12F86C3AAA70982A799B720E9DC6F45BDE9DDB8
i4_stage_acceptance=BLOCKED_EXTERNAL_DEVICE_AND_DYNAMIC_ACCEPTANCE
static=PASS quality=12/12 i4_runners=9 protected_dirty=0 fixed_frame_helpers=0
static_report=.tmp/i4/static/20260730T060908802Z/static_report.json
static_report_sha256=0FF49E056F7BD4036165666C23AB182F2FEF35E9BE6D072DF4E37B3DE4525584
legacy_assertions=PASS files=15/15 dispositions=38 superseded=19 invalid=0
legacy_report=.tmp/i4/legacy_assertions/20260730T084927894Z/legacy_assertion_audit.json
legacy_report_sha256=CA7047D5A0A62B42DF7F9E1664F6494337212F610EDAF444FD7DA5F62AB96E35
```

上述报告绑定 `0d4fe15` 基础上的未提交工作树；本文所在提交仍需在零源码修改条件下重跑
head 模式，并由报告中的 SHA 绑定，不能使用文档自指值代替。

## 4. 真实渲染与逐原图结果

已完成：

- Deploy 12 状态逐原图复核；
- 长期系统 25 页面逐原图复核；
- 生产 14 个高风险状态真实 Windows renderer 捕获；
- 测试场设置、测试局、展开诊断面板、地图、库存、宝箱、事件、战斗、雷区、出口、
  世界掉落、成功结果和保存失败结果均由生产 `main.tscn` 创建。

```text
production_capture=PASS
visual_status=VISUAL_CANDIDATE
images=14
manifest=.tmp/i4_capture_wrapper_probe2/evidence/capture_manifest.json
manifest_sha256=0AC09492F45028DDDE04EF22F49212F620F3B0863BA28DB486B43A1AE9204335
duplicate_semantic_hashes=0
worktree_unchanged=true
```

统一三类清单随后在同一 worktree 身份下重跑：

```text
unified_capture=PASS
profile=all
images=51
deploy=12
long_term=25
production=14
visual_status=VISUAL_CANDIDATE
manifest=.tmp/i4_real_render_worktree_all_final2/evidence/capture_manifest.json
manifest_sha256=42894CFFFAEDA529367941F5CA8EA1424EF4C89FD8EDFB69E0AF3CB9581D16F7
duplicate_semantic_hashes=0
worktree_unchanged=true
```

阶段审计随后发现一次尚未完成的矩阵错误地把 Noto 设为正文主字体。该运行目录
`.tmp/i4/census_matrix/20260730T055045676Z` 登记为
`INVALID_WRONG_FONT_AUTHORITY`，不得作为证据。恢复 FusionPixel-primary、
Noto-fallback-only 后，从头完成全内容矩阵：

```text
census_matrix=PASS
rows=156
matrix_cases=12
row_case_cells=1872
images=1140
capture_status=CAPTURE_COMPLETE
visual_status=VISUAL_CANDIDATE
manifest=.tmp/i4/census_matrix/20260730T064617178Z/capture_manifest.json
manifest_sha256=00FFB0BFF1B308953FEA92D6611060F8314A450BDAE14F5E1F53F7E89DB6C293
worktree_unchanged=true
```

`1872` 是逐 census 行/矩阵组合的覆盖单元；`1140` 是多个行共享同一真实渲染状态后的
唯一原图数，映射由 coverage sidecar 绑定。自动清单验证尺寸、哈希、身份、几何和进程
结果，因此只能产生 `VISUAL_CANDIDATE`；当前没有 1140 张逐图人工 PASS 记录。

真实捕获发现并修复：

| 缺陷 | 判定 | 修复后实际 |
| --- | --- | --- |
| Deploy 125%/150% 筛选越界 | 焦点项 V 越出可见 host | 自动滚动到焦点项，overflow 判据通过 |
| 局内左轨整列过高 | 内容簇 F 远大于实际行内容 | 轨道随 0/1/3/4/满包内容高度收敛 |
| Codex 第八二级页签不可见 | 第八项 V 不在 viewport | 8 项按可用宽度动态拟合 |
| 调试横幅侵入协议 | 横幅 V 与协议 S 竞争 | 横幅 `R=(288,6,720,62)`，协议 x=1060，间隔 52 px |
| 初版调试面板过高 | 面板高约 76%，超过 75% | 最终约 `R=(949,108,306,508)`，23.9%×70.6% |
| 宝箱捕获等待旧模态 | 测试权威滞后于世界内上下文 | 等待 `searched/opened_once/chest/non-empty items` |

最终 1280×720 调试面板与右上协议、底部动作栏矩形交集均为 0；焦点位于面板内，
生产移动输入关闭。随后 12 组捕获机器门完成，但该几何事实仍不能外推为逐图人工或动态
输入 PASS。

## 5. 外部设备与动态边界

```text
device_inventory=PASS
joypads=0
controller=BLOCKED_NOT_RUN
audio_route=WASAPI Default
audio=ROUTE_DETECTED_NOT_FUNCTIONALLY_ACCEPTED
gpu=NVIDIA GeForce RTX 3060 Laptop GPU
gpu_status=MEASURED_NOT_ACCEPTED
dynamic_player=NOT_RUN
full_12_group_capture=CAPTURE_COMPLETE
full_12_group_visual=VISUAL_CANDIDATE
manual_original_ledger=NOT_RUN
```

没有物理手柄时无法验证真实手柄焦点/重复输入；检测到音频路由不等于人耳听音通过；
记录 GPU 和运行指标不等于满足尚未登记的目标设备/阈值。

### 5.1 R050 第一轮存储收口

第一轮仅按精确目标清单删除可重建验证产物，没有修改 Git 工作树或停止用户 Godot 编辑器：

```text
i1_temp_views_freed=1099808768
i1_duplicate_worktrees_freed=8652681216
i1_rebuildable_head_worktrees_freed=1545773056
invalid_wrong_font_matrix_freed=434622464
superseded_matrix_png_freed=7609331712
total_operation_deltas=19342217216
C_deleted_targets=0
C_free_before=18827001856
C_free_after_audit=18823122944
E_free_before=47882948608
E_free_after_cleanup_peak=67225149440
E_net_increase_during_window=19342200832
concurrent_activity_delta=16384
```

八个旧矩阵只删除共 5,430 张 PNG，JSON、census 和日志仍在；错误字体目录
`20260730T055045676Z` 已删除。正确字体目录 `20260730T064617178Z` 复核为
156 行、1872 单元、1140 PNG，manifest SHA-256 仍为
`00FFB0BFF1B308953FEA92D6611060F8314A450BDAE14F5E1F53F7E89DB6C293`。最终 I1/I4
报告、失败反例、字体证据、stash 和编辑器 PID 62788 均存在。C 盘候选不是用户输入就是
活动内核文件，或不能证明属于本任务，因此没有冒险删除。最终 exact-head 产物生成后还须
复量一次；R050 此时仍为 `IMPLEMENTING`。

## 6. Clean exact-head 证据

`f950eefb000ab298344059dfa8afc125aa79ed8a` 在完全 clean 工作树上执行：

```text
exact_head_full=PASS
stage_acceptance=BLOCKED_EXTERNAL_DEVICE_AND_DYNAMIC_ACCEPTANCE
report=.tmp/i4_exact_head_full_f950eef/evidence/i4_report.json
report_sha256=DAFE502175D30034C210AA664769770AB74420AF42FB1B45BE98F4E15F079E56
static=PASS quality=12/12 i4_runners=8 protected_dirty=0 fixed_frame_helpers=0
static_sha256=C708B0BCC09A436BD23218CC832AF8DEF16E7D7945C2F3987F135E09A9BC8F56
census=PASS rows=156
census_sha256=CC31EB553CB0BE106AD93DB75A1C8E653A60D648A06499C3689E84F23E8FBF04
repetition=PASS critical=6x10 process_launches=60 unique_pid_values=58 journey=3/3
repetition_sha256=5B7805C7BC472CE89E6D2807A9B44E177BA0E91FFBC7D3CB141FC92004C79471
device=PASS joypads=0 controller=BLOCKED_NOT_RUN
device_sha256=48335E1DB9FB931FCE87F670EBFE4D6CA55A9A4B0B76E7BF699773E87A3C312F
```

同一提交的真实 renderer：

```text
exact_head_capture=PASS
profile=all
images=51
visual_status=VISUAL_CANDIDATE
manifest=.tmp/i4_exact_head_render_f950eef/evidence/capture_manifest.json
manifest_sha256=981126BEFFC89311986262EB78A036DE054911DE2869982BD0F99B49F5F8800E
duplicate_semantic_hashes=0
worktree_unchanged=true
```

上述报告只绑定历史实现候选，不会被冒充为本文所在提交的最终 HEAD 证据。本文所在提交
仍须在零源码修改条件下重跑 clean exact-head/full，并由报告中的 commit/tree 精确绑定。

### 6.1 首次最终候选的 I1 exact-head 反例

```text
candidate=fafbbffc47b16cc15dfaa4a4a093aa348c956a6e
report=.tmp/i1/20260730T082506569Z_79c39a2e/report.json
report_sha256=5DAA2B783FF93147998A42D5A830CDA7C07B8FEC35BD36A510E370B408D173FC
result=FAIL runners=103/104
failed_runner=I3_PRODUCTION_FULL_BAG_REPLACEMENT
business_result=PASS exit_code=0 inputs=204
cleanup_expected=18 resources
cleanup_actual=19 resources
```

这不是玩法替换失败，而是可复现清理合同失败。相同镜像后续 1 次 verbose、2 次非 verbose
全新进程均为业务 PASS/18，说明 19 是退出时序反例；失败报告仍保留，不能被后续 PASS
覆盖。处置没有改 manifest expected，而是在证据写完、主场景释放后将协程退栈等待 2→4；
修改后 3 个全新工作树进程均完整走真实满包旅程并以业务 PASS/精确 18 退出。最终候选仍须
重新跑完整 I1/I4 `SourceMode=head`，不能把 3 次定向结果外推为 full PASS。

## 7. 阶段审计

未关闭的 MUST：

1. I4-R025：156 行 × 12 组机器捕获已经完成，但 1140 张原图逐图人工复核和动态输入仍未完成；
2. I4-R029：实现候选 exact-head/full 已过；最终审计提交的 exact-head/full、
   exact-head 12 组矩阵、push 和远端 SHA 待完成；
3. I4-R042：物理手柄、功能听音、目标 GPU 长局、动态玩家验收和全部 MUST 清零仍未完成；
4. I4-R050：C/E 盘精确存储收口已启动，须登记精确删除目标、保留项、回收字节、清理前后
   可用空间，并在最终 exact-head 证据形成后完成最后一轮复量。

I4-R038 已由更强的 156 行 × 12 组全覆盖机器证据满足；I4-R040 已由 15/15 既有测试文件、
38 条 disposition、19 条带替代门的 superseded 和 0 invalid 的审计满足。两项都不能反向
提升 I4-R025 的人工视觉或动态输入状态。

因此：

```text
stage_pass=NO
stage_close=NO
latest_closed_non_art_baseline=I2
push_allowed_for_active_candidate=YES
```

push 是活动候选交付证据，不会自动关闭 I4，也不会授权 I4 后续增量线或 ART22。
