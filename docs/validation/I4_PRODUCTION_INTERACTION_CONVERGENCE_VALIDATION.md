# I4 生产交互收敛与可复现验证

文档状态：`ACTIVE CANDIDATE / EXTERNAL ACCEPTANCE BLOCKED`

日期：2026-07-30

## 中文摘要

I4 已按冻结标准完成当前候选的 P1–P8 实现、worktree 自动预检、内容普查、重复运行和
代表性真实渲染复核。原 I4-R001–R042、用户 Deploy 反例和边框计划均保留；后续局内反馈
作为 I4-R043–R049 增量接入，没有覆盖此前要求。

当前结果只能称为：

```text
implementation=IMPLEMENTED_CANDIDATE
automation_worktree=PASS
visual=VISUAL_CANDIDATE
stage=I4 / ACTIVE
stage_acceptance=BLOCKED_EXTERNAL_DEVICE_AND_DYNAMIC_ACCEPTANCE
```

物理手柄、功能听音、目标 GPU 长局、动态玩家任务以及非 Deploy 全 12 组视觉矩阵没有
完成，不能由自动 runner、静态截图、exact-head 或 push 推断通过。

## 1. 验证对象与身份

```text
repo=resolved by git rev-parse --show-toplevel
branch=codex/i4-production-interaction-convergence
entry_commit=4127bd27a05b75cb5e3071cf6dc87d9287f679a9
entry_tree=e1455ffd8c7a754c63eb2141a47e41f8fe5cdf3a
implementation_checkpoint=7af22f44bacc6a5a78e136b35b2faea825b07df8
implementation_candidate=f950eefb000ab298344059dfa8afc125aa79ed8a
implementation_tree=c19957042fb5ebe424694716c6a7a0af72922024
final_audit_commit=PENDING_FINAL_AUDIT_COMMIT
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
| 字体/边框 | `TARGETED_PASS / VISUAL_CANDIDATE` | readable/display 分离、中文 AA、16/8/4/2、最多两层完整框 |

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
生产移动输入关闭。此结论只约束该真实状态，不能外推为 12 组全矩阵。

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
non_deploy_full_12_group_visual=NOT_RUN
```

没有物理手柄时无法验证真实手柄焦点/重复输入；检测到音频路由不等于人耳听音通过；
记录 GPU 和运行指标不等于满足尚未登记的目标设备/阈值。

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

本验证文档的回填将形成后续审计提交；所以上述报告是实现候选证据，不会被冒充为后续
最终 HEAD 证据。最终审计提交仍需重跑 clean exact-head/full。

## 7. 阶段审计

未关闭的 MUST：

1. I4-R025：非 Deploy 四分辨率×三 UI 比例全状态原图与动态输入；
2. I4-R029：实现候选 exact-head/full 已过；最终审计提交同门、push 和远端 SHA 待完成；
3. I4-R038：156 行内容的完整捕获/等价覆盖；
4. I4-R040：旧失败断言全量 disposition；
5. I4-R042：全部 MUST 与外部动态验收清零。

因此：

```text
stage_pass=NO
stage_close=NO
latest_closed_non_art_baseline=I2
push_allowed_for_active_candidate=YES
```

push 是活动候选交付证据，不会自动关闭 I4，也不会授权 I4 后续增量线或 ART22。
