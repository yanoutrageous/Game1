# I4 执行台账

文档状态：`ACTIVE`

总契约：`docs/20_product/I4_PRODUCTION_INTERACTION_CONVERGENCE_CONTRACT.md`

质量标准：`docs/20_product/I4_ENGINEERING_QUALITY_AND_ACCEPTANCE_STANDARD.md`

入口：`4127bd27a05b75cb5e3071cf6dc87d9287f679a9` /
tree `e1455ffd8c7a754c63eb2141a47e41f8fe5cdf3a`

## 状态规则

每个切片按 `PRECHECK → IMPLEMENTING → TARGETED_PASS → PRODUCTION_PASS → ACCEPTED`
前进。自动 PASS、截图生成和单个 runner 均不能替代生产旅程与动态验收。

| Gate | 状态 | 当前事实 | 剩余门 |
| --- | --- | --- | --- |
| I4.0 | `TARGETED_PASS` | 入口治理提交 `62332f0`；Base overlay 已只归一化换行，真实字段漂移仍 fail closed | 最终 exact-head/full 才能关闭 |
| I4.1 | `TARGETED_PASS` | 检查点 `7af22f4` 已接 `dev_sandbox`、taint、设置入口、默认档哈希门和 release 隐藏定向门 | 生产旅程、重复和最终存档门 |
| I4.2 | `TARGETED_PASS / VISUAL_CANDIDATE` | 诊断身份、读写分区、确定性场景夹具、一次性保存失败注入与失败包已接入；clean/tainted × collapsed/expanded 已进入 12 组捕获 | 逐原图、动态焦点/停靠和物理输入门 |
| I4.3 | `TARGETED_PASS` | 检查点已接原子 N 件购买、精确实例携带/出售与失败回滚定向门 | 完整交易旅程、重复和旧档 |
| I4.4 | `TARGETED_PASS / VISUAL_CANDIDATE` | 两行卡、单一数量语义、310/12/310、地图 198/424、六项摘要、滚动、交易上下文金币；正确字体下 Deploy 12 组真实捕获通过 | 逐原图动态输入与玩家验收 |
| I4.5 | `TARGETED_PASS / VISUAL_CANDIDATE` | 精确实例使用/丢弃、紧凑聚合、稳定阻挡 descriptor、可见足迹、纹理 fallback、品质地面光束与全房型定向门通过并纳入全矩阵 | 逐原图和动态玩家验收 |
| I4.6 | `TARGETED_PASS / VISUAL_CANDIDATE` | 通知直达、显式已读、页面历史与状态恢复 runner 已过；6 模块/25 页面真实矩阵已逐图复核 | 物理手柄和动态玩家验收 |
| I4.7 | `TARGETED_PASS / VISUAL_CANDIDATE` | display/readable 排版语义均解析为 FusionPixel 主字体，Noto 仅缺字回退；16/8/4/2 边框、地图四层、协议安全区、内容驱动左下高度、统一品质色与纹理 resolver 已接入并完成 12 组机器捕获 | 1140 张逐原图与动态输入门 |
| I4.8 | `WORKTREE_AUTOMATION_PASS / EXTERNAL_GATES_BLOCKED` | post-audit worktree I1 full 104/104、I4 full、6×10+3、156×12=1872 单元/1140 PNG、旧断言 15/15 均通过 | 候选提交上的 exact-head/full 与 exact-head 矩阵、push/远端 SHA、C/E 存储收口；逐原图、物理手柄、功能听音、目标 GPU 长局与动态玩家验收仍待外部条件 |

## I4.0 入口审计记录

```text
remote_main=4127bd27a05b75cb5e3071cf6dc87d9287f679a9
local_entry=4127bd27a05b75cb5e3071cf6dc87d9287f679a9
ahead_behind=0/0
preexisting_dirty=project.godot line-ending materialization + 7 generated .translation files
preservation=stash "pre-i4 generated Godot metadata 2026-07-30"
entry_exact_head_attempt=FAIL
failure=I3R Base overlay byte comparison treated CRLF checkout as semantic drift
disposition=I4.0 cross-platform verifier repair; semantic field drift remains blocking
```

## 2026-07-30 视觉反例与标准重开

```text
evidence=external user production screenshot
sha256=1F85061F1C90B1E6B3F673F8519399B8094FD2499B0F4004DB9BCEBD4C3E0C51
surface=Deploy / warehouse / overview
previous_claim=automated layout targeted pass
corrected_status=VISUAL_FAIL
affected_classes=shared CJK font, deploy card, quantity stepper, deploy detail,
                 summary projection, summary row, border hierarchy
```

反例确认：

- 顶部页签、卡片、详情和摘要的中文字体不一致；
- 卡片数量器的框、符号、数量和卡片边界发生视觉冲突；
- 摘要仍呈现四个高 72 px 的单行大框，间距/留白过大；
- 摘要只暴露地图、难度、目标、容量，缺少装备、消耗品、剩余容量和可操作阻塞；
- 页面、工作区、卡片、步进器、摘要行出现多层完整粗框；
- 详情存在同义品质重复。

处置：

1. 撤回此前视觉 PASS 表述；机器门最多记为 `VISUAL_CANDIDATE`。
2. 冻结 `I4-QA-FROZEN-1`，在任何新 PASS 前执行。
3. 不只修仓库截图；共享字体、边框和布局组件按消费者扩大复验。
4. 旧 ART22/ART25 断言逐条分类，不得仅修改 expected。

## 2026-07-30 局内补充增量重审

本次重审不撤销、不降级、不替换 I4-R001–R042、Deploy 反例、边框计划或测试隔离要求；
只把用户新增的局内生产反馈映射到原 I4.5/I4.7，并新增 I4-R043–R049。

### 代码事实

| 表面/对象 | 当前实现事实 | 根因码 | 审计状态 |
| --- | --- | --- | --- |
| 折叠小地图 | `minimap_panel.gd::_add_marker_node` 将语义纹理四边各扩出 4 px；cell 未登记 `clip_contents`；相邻雷险标签再次覆盖全格 | `MAP-CELL-SPILL` / `MAP-SEMANTIC-STACK` | `FAIL` |
| 展开地图 | `map_overlay_panel.gd::_add_marker_node` 在有玩家纹理时仍保留 `P`，相邻雷险标签覆盖全格；子层没有固定局部 z/分配矩形 | `MAP-SEMANTIC-STACK` | `FAIL` |
| 展开地图与 HUD | 内容 host 为透明板，背景协议/房间仍可能通过格间与文字带竞争可读层；只有 0.70 dimmer | `MAP-MODAL-COMPETE` | `FAIL` |
| 房间中央阻挡 | `g41_room_runtime_view.gd::_obstacles_for_room` 仅按 Monster/Event/Normal 返回匿名 `Rect2`；生产 `_draw` 明确不显示这些矩形 | `WORLD-ANON-COLLISION` | `FAIL` |
| 阻挡退场/缺图 | `logical_obstacles` 没有 visual key、纹理解析或 visual footprint 门；无法证明视觉消失与碰撞同事务 | `WORLD-VISUAL-COLLISION-DESYNC` | `FAIL` |
| 世界掉落缺图 | `g41_interactable.gd::_apply_visual_state` 只判断 `ArtVisual` 节点是否存在；节点存在但 `texture=null` 时会错误隐藏占位物 | `ASSET-NODE-WITHOUT-TEXTURE` | `FAIL` |
| 左下物品簇 | `run_surface.gd` 使用 `backpack_panel_height=max(192, ...)` 和固定列表预留；空包仍保留完整 scroll/watermark 区 | `HUD-FIXED-EMPTY-BAND` | `FAIL` |
| 协议 | 当前布局按卡宽 18%/7% 推算文案区，没有按真实可见 B 导出 S，也没有极值/模态几何断言 | `HUD-PROTOCOL-SAFE-RECT` | `FAIL` |
| 品质 | Godot 当前色表与用户指定 UE 参考不一致；背包/库存/地面列表主要只显示局部色条，世界掉落光束固定为青色 | `RARITY-CHANNEL-OVERRIDE` | `FAIL` |

上述代码事实可以证明对应合同尚未满足，但不能代替当前候选的真实截图和动态复核。用户的
直接生产观察登记为 `VISUAL_FAIL / exact failure bbox pending fresh capture`；后续必须从
本 worktree/候选提交生成新鲜原图，不得拿历史 gallery 当关闭证据。

### 计划重排

```text
P0  增量重审冻结：保留旧要求，接入 R043-R049
P1  I4.1/I4.2：隔离测试场、诊断身份、失败包
P2  I4.3：数量/交易领域语义
P3  I4.7A：共享 FusionPixel 字体权威、边框、品质描述器、纹理 resolver、地图格层级
P4  I4.4：Deploy 信息/数量/摘要
P5  I4.5A：局内聚合与确定实例
P6  I4.5B：阻挡来源、纹理 fallback、世界掉落
P7  I4.6：长期导航/状态
P8  I4.7B/C：协议、左下密度、地图/模态、全状态/12 组收敛
P9  I4.8：生产旅程、重复、设备、worktree/full、exact-head、审计、push
```

P3 修改共享消费者后，P4–P8 必须使用同一版本复验；P6 修改局内物体/碰撞后必须回归
攻击裁切、门、全房型和结算。任何后续步骤不能覆盖 P0–P2 或既有 Deploy FAIL。

```text
P0_status=TARGETED_PASS
governance_test=12/12 PASS
production_implementation=FAIL / NOT_RUN by requirement
next=P1/P2 regression, then P3 shared visual foundation
```

上段是增量重审当时的冻结快照，作为“先审计、后实现”的历史证据保留；不得用后续结果
反写成当时已经通过。其后已按 P1→P8 执行，当前候选结果如下。

## 2026-07-30 P1–P8 实施与复验记录

| 切片 | 已实施内容 | 当前证据状态 | 未关闭边界 |
| --- | --- | --- | --- |
| P1 / I4.1–I4.2 | 设置内隔离测试场、`dev_sandbox`、CLEAN/TAINTED 横幅、读写分区、失败包、默认档语义哈希门；展开诊断面板约 24%×71%，焦点归面板且停用移动输入 | `TARGETED_PASS / VISUAL_CANDIDATE` | 12 组展开态、物理手柄 |
| P2 / I4.3 | N 件购买、精确实例携带/批售、单次提交、失败回滚；卡片只投影当前操作数量 | `TARGETED_PASS` | 动态玩家体验 |
| P3 / I4.7A | readable/display 排版语义共享 FusionPixel 主字体、16/8/4/2 边框预算、统一品质描述器、纹理 resolver、地图 base/semantic/count/focus 四层 | `TARGETED_PASS` | 全矩阵视觉 |
| P4 / I4.4 | Deploy 两行卡、`− 数量 +`、310/12/310、地图 198/424、六项摘要、上下文金币、详情/摘要滚动 | `TARGETED_PASS / VISUAL_CANDIDATE` | 非 Deploy 全矩阵动态复核 |
| P5 / I4.5A | 局内同模板聚合；使用/丢弃只消费确定实例；重量、结算和失败路径保持实例权威 | `TARGETED_PASS` | 动态玩家体验 |
| P6 / I4.5B | 阻挡 descriptor 与可见足迹同源；Normal 零匿名障碍；缺图/退场清碰撞；地面掉落 body、fallback、品质光束 | `TARGETED_PASS / VISUAL_CANDIDATE` | 全房型×全矩阵 |
| P7 / I4.6 | 通知直达详情、显式已读、真实页面历史、筛选/选择/滚动/焦点恢复；二级页签按宽度动态容纳 8 项 | `TARGETED_PASS / VISUAL_CANDIDATE` | 物理手柄、玩家动态复核 |
| P8 / I4.7B/C | 协议真实安全区、左下 0/1/3/4/满包内容驱动高度、地图层级/模态配对、生产高风险捕获 | `TARGETED_PASS / VISUAL_CANDIDATE` | 四分辨率×三比例全状态 |

真实捕获过程中发现并修复的候选缺陷继续保留在审计链中：

1. Deploy 125%/150% 筛选页签会越界；改为可聚焦自动滚动并增加 overflow 判据。
2. 局内左侧外轨道占满高度；改为随当前物品内容收敛。
3. 长期 Codex 第八个二级页签不可见；改为按可用宽度动态拟合。
4. 调试横幅侵入协议、初版面板超过 75% 高；横幅固定为
   `R=(288,6,720,62)`，协议从 x=1060 起，间隔 52 px；面板最终约
   `R=(949,108,306,508)`，即 23.9% 宽、70.6% 高，与协议和底栏交集均为 0。
5. 生产捕获仍等待旧宝箱 loot 模态；当前生产权威已改为世界内宝箱上下文，替代门同时验证
   `searched=true`、`opened_once=true`、上下文种类和非空物品集合。

```text
unified_worktree_preflight=PASS
unified_report=.tmp/i4_unified_worktree_preflight_final/evidence/i4_report.json
unified_report_sha256=81741EAE3B23F75EB773BE4DD3EED355A72CFA49B8B3FF05D090370FF0E80F07
static=PASS quality=12/12 i4_runners=8 protected_dirty=0 fixed_frame_helpers=0
final_worktree_static=.tmp/i4_static_worktree_final/evidence/static_report.json
final_worktree_static_sha256=13D1EE13E79B21C76211F0CC7FEA1DD3C9CD49EAD2235311BC68FC17324278C1
content_census=PASS rows=156 deploy_tabs=5 deploy_filters=13 summaries=4
               long_term=6/25/58 room_types=6 scenarios=6
worktree_repetition=PASS critical=6x10 journey=3/3
worktree_repetition_sha256=D7D5933EE5DBF6A7F9E8A3412CDE2D44DD1E0D7F1ED1270E57F85C2C70444C19
production_capture=PASS images=14 visual_status=VISUAL_CANDIDATE
production_manifest_sha256=0AC09492F45028DDDE04EF22F49212F620F3B0863BA28DB486B43A1AE9204335
unified_capture=PASS profile=all images=51 visual_status=VISUAL_CANDIDATE
unified_capture_manifest=.tmp/i4_real_render_worktree_all_final2/evidence/capture_manifest.json
unified_capture_sha256=42894CFFFAEDA529367941F5CA8EA1424EF4C89FD8EDFB69E0AF3CB9581D16F7
long_term_capture=25 pages manually reviewed at 1280x720
deploy_capture=12 states manually reviewed
device_probe=PASS controller=BLOCKED_NOT_RUN
audio=ROUTE_DETECTED_NOT_FUNCTIONALLY_ACCEPTED
gpu=MEASURED_NOT_ACCEPTED
```

首个候选提交后的 clean exact-head 证据：

```text
candidate=f950eefb000ab298344059dfa8afc125aa79ed8a
tree=c19957042fb5ebe424694716c6a7a0af72922024
exact_head_full=PASS
stage_acceptance=BLOCKED_EXTERNAL_DEVICE_AND_DYNAMIC_ACCEPTANCE
report=.tmp/i4_exact_head_full_f950eef/evidence/i4_report.json
report_sha256=DAFE502175D30034C210AA664769770AB74420AF42FB1B45BE98F4E15F079E56
static_sha256=C708B0BCC09A436BD23218CC832AF8DEF16E7D7945C2F3987F135E09A9BC8F56
census_sha256=CC31EB553CB0BE106AD93DB75A1C8E653A60D648A06499C3689E84F23E8FBF04
repetition=PASS critical=6x10 process_launches=60 unique_pid_values=58 journey=3/3
repetition_sha256=5B7805C7BC472CE89E6D2807A9B44E177BA0E91FFBC7D3CB141FC92004C79471
device_sha256=48335E1DB9FB931FCE87F670EBFE4D6CA55A9A4B0B76E7BF699773E87A3C312F
exact_head_capture=PASS images=51 visual_status=VISUAL_CANDIDATE
exact_head_capture_manifest=.tmp/i4_exact_head_render_f950eef/evidence/capture_manifest.json
exact_head_capture_sha256=981126BEFFC89311986262EB78A036DE054911DE2869982BD0F99B49F5F8800E
push=NOT_RUN
```

该证据绑定 `f950eef`；本台账回填会形成后续审计提交，因此最终 HEAD 仍必须重新执行
exact-head/full。不得把上段 SHA 直接贴到后续 HEAD。

上述 `PASS` 都有明确限定词；当前没有任何记录把它们合并推导为 `PRODUCTION_PASS` 或
`ACCEPTED`。P9 必须先完成候选提交、exact-head/full 和 push；即使这些机器门通过，
外部设备与动态玩家门仍会阻止 I4 阶段关闭。

## 2026-07-30 post-audit 字体纠正、全矩阵与旧断言收口

### 字体权威纠正

阶段自动巡检恢复后发现，未提交候选一度把 Noto Sans CJK 设为 Label/Button/正文主字体，
只让 FusionPixel 承担数字；这与运行资产 manifest、I3R 当前合同和 I4-R023/R035 冲突。
因此：

```text
wrong_font_matrix=.tmp/i4/census_matrix/20260730T055045676Z
disposition=INVALID_WRONG_FONT_AUTHORITY
process_disposition=only the exact validation process tree was stopped
user_editor=preserved
proof_use=FORBIDDEN
```

当前实现将 display/readable 继续作为字号、行高和密度语义，但两者均以 FusionPixel 为
base font，关闭 AA/subpixel；Noto 只在 FusionPixel 确实缺字时显式回退。直接加载 Noto
的局内预览消费者也已改为共享玩家字体。恢复后重新运行字体、布局、ART22、局内、长期和
完整 worktree full，不沿用错误字体证据。

```text
font_fixture=.tmp/i4/font_fix/20260730/fusionpixel_surface.png
font_fixture_sha256=DC82DB4442E471A2CC5894611D406F0E9F28CDEB229C3824EF7F04088B561372
font_fixture_boundary=real Windows renderer / representative only
i3r_font_raster=PASS primary=FusionPixel fallback=Noto
i3r_font_surface_coverage=PASS controls=347 tooltips=75 settings_popups=8
i4_font_role_raster=PASS primary=FusionPixel fallback=Noto aa=pixel
```

### 当前工作树机器证据

```text
base_head=0d4fe159fc86b1b63b4fc13771058313686cb43f
i1_full=PASS runners=104/104 plain=61 cleanup_diagnostic=43 hard_failures=0
i1_report=.tmp/i1/20260730T061143153Z_8dc91cd6/report.json
i1_report_sha256=DCC085791E5E165C3EE1791FFE693CA738598B875757098262A6D24C7FD62B2D
i1_duration_ms=1391740
i4_full=PASS
i4_stage_acceptance=BLOCKED_EXTERNAL_DEVICE_AND_DYNAMIC_ACCEPTANCE
i4_report=.tmp/i4/invoke/20260730T063525012Z/i4_report.json
i4_report_sha256=A7C479158C7B41B48E3A9171E12F86C3AAA70982A799B720E9DC6F45BDE9DDB8
static=PASS quality=12/12 i4_runners=9 protected_dirty=0 fixed_frame_helpers=0
static_report=.tmp/i4/static/20260730T060908802Z/static_report.json
static_report_sha256=0FF49E056F7BD4036165666C23AB182F2FEF35E9BE6D072DF4E37B3DE4525584
legacy_assertion_audit=PASS files=15/15 dispositions=38 superseded=19 invalid=0
legacy_report=.tmp/i4/legacy_assertions/20260730T084927894Z/legacy_assertion_audit.json
legacy_report_sha256=CA7047D5A0A62B42DF7F9E1664F6494337212F610EDAF444FD7DA5F62AB96E35
```

正确字体全内容矩阵采用比最低覆盖策略更强的每行 × 每矩阵组合全覆盖：

```text
census_rows=156
matrix_cases=12
row_case_cells=1872
png_images=1140
capture_status=CAPTURE_COMPLETE
visual_status=VISUAL_CANDIDATE
manifest=.tmp/i4/census_matrix/20260730T064617178Z/capture_manifest.json
manifest_sha256=00FFB0BFF1B308953FEA92D6611060F8314A450BDAE14F5E1F53F7E89DB6C293
worktree_unchanged=true
```

`1140` 是去除同一渲染状态对多个 census 行复用后的原图数，`1872` 是
156×12 的逐行覆盖单元数；coverage sidecar 绑定两种口径。捕获成功只将 R025/R037/R038
推进为 `VISUAL_CANDIDATE`，没有完成 1140 张逐原图记录或动态玩家签收。

### 首次最终候选 exact-head 反例与修复

`fafbbffc47b16cc15dfaa4a4a093aa348c956a6e` 的首次 I1 `full/head` 必须保留为失败反例：

```text
report=.tmp/i1/20260730T082506569Z_79c39a2e/report.json
report_sha256=5DAA2B783FF93147998A42D5A830CDA7C07B8FEC35BD36A510E370B408D173FC
runners=103/104
failed_runner=I3_PRODUCTION_FULL_BAG_REPLACEMENT
business_exit_code=0
business_marker=PASS
business_inputs=204
expected_cleanup=18 resources
actual_cleanup=19 resources
```

没有把 manifest 放宽为 18/19，也没有用下一次通过覆盖失败。相同 exact-head 镜像的 1 次
verbose 与 2 次全新非 verbose 进程均回到业务 PASS/18，证明 19 不是稳定新基线而是退出
时序反例。修复仅将父生产旅程在证据写入、`main.free()` 之后的协程退栈等待从 2 次渲染提交
增至 4 次；不参与 gameplay 状态或输入正确性判断。修改后的工作树再以 3 个全新进程执行
完整满包旅程，三次均为退出码 0、业务 PASS 和精确 18-resource 诊断。旧断言审计因此增加
一条 `STILL_AUTHORITATIVE`，保持 15 个文件、38 条 disposition、19 superseded、0 invalid。
最终结论仍只能由新候选完整 exact-head/full 给出。

### C/E 盘收口门

用户补充要求将 C/E 盘不必要的大体积内容整理为阶段收口任务，登记为 I4-R050。执行顺序为：

1. 候选提交与最终 exact-head 报告、矩阵、失败反例绑定；
2. 清点每个目标绝对路径、大小、可重建性和保留理由；
3. 优先使用 I1 已有归档/校验/事务裁剪工具；
4. 只删除被最终证据取代的镜像、缓存、中断/错误字体重复产物；
5. 保留用户存档、命名 stash、原始来源、失败唯一证据、最终报告/日志/原图和恢复证明；
6. 复量 C/E 盘并记录实际回收字节与可恢复性。

在 exact-head 证据形成前，I4-R050 保持 `IMPLEMENTING`，不得提前清除仍可能成为最终证据的目录。

#### R050 第一轮精确清理回执

2026-07-30 在不修改 Git 工作树、不停止 Godot 编辑器 PID 62788 的条件下完成第一轮清理。
删除均为永久删除，但目标可由治理脚本或验证重跑重建：

| 精确处置 | 删除对象 | 实际释放字节 |
| --- | --- | ---: |
| I1 临时内容裁剪 | 18 个 run 的 50 项 `process_env`、engine hardlink view、`.godot` cache；18 份报告保留 | 1,099,808,768 |
| I1 重复 worktree | 8 个有同 HEAD/指纹保留替代的 `worktree` | 8,652,681,216 |
| I1 可重建 HEAD worktree | `20260729T225847900Z_ec12a2d6/worktree`、`20260729T231120093Z_65888032/worktree` | 1,545,773,056 |
| 错误字体矩阵 | `census_matrix/20260730T055045676Z` 全目录，处置为 `INVALID_WRONG_FONT_AUTHORITY` | 434,622,464 |
| 被最终矩阵取代的旧 PNG | 8 个旧矩阵中的 5,430 张 PNG；JSON、census、日志保留 | 7,609,331,712 |
| **合计** | 可重建验证产物 | **19,342,217,216** |

I1 重复 worktree 的精确“删除 → 保留替代”关系为：

```text
20260729T214157456Z_e2ebff54 -> 20260729T214207436Z_623c4083
20260729T225512339Z_ef7a22e1 -> 20260729T225847900Z_ec12a2d6
20260730T031029409Z_7e10aba5 -> 20260730T041815676Z_63c4241a
20260730T031217515Z_2864f3d0 -> 20260730T041815676Z_63c4241a
20260730T051346959Z_99a34985 -> 20260730T053925008Z_f3c9b2a9
20260730T051640586Z_306181ff -> 20260730T053925008Z_f3c9b2a9
20260730T060921618Z_5d48d844 -> 20260730T061143153Z_8dc91cd6
20260730T063539611Z_3328f6df -> 20260730T061143153Z_8dc91cd6
```

旧 PNG 的精确矩阵目录为：
`20260730T001445118Z`、`20260730T001806216Z`、`20260730T002115473Z`、
`20260730T003958672Z`、`20260730T005053679Z`、`20260730T011118835Z`、
`20260730T012645178Z`、`20260730T021502999Z`。

```text
C_free_before=18827001856
C_free_after_audit=18823122944
C_deleted_targets=0
E_free_before=47882948608
E_free_after_cleanup_peak=67225149440
E_net_increase_during_window=19342200832
E_sum_of_operation_deltas=19342217216
concurrent_activity_delta=16384
```

C 盘只完成审计：用户提供的剪贴板原图必须保留，活动 Codex/Node 内核文件被占用，其余候选
不能证明属于本任务，因此零删除。正确字体最终矩阵
`census_matrix/20260730T064617178Z` 仍为 156 行、1872 单元、1140 PNG，manifest SHA-256
`00FFB0BFF1B308953FEA92D6611060F8314A450BDAE14F5E1F53F7E89DB6C293`；I1/I4 最终报告、
失败反例、字体证据、stash 与编辑器均复核存在。最终 exact-head 产物形成后仍须执行末轮复量，
所以 R050 暂不提升为关闭。

### 旧断言处置：展开地图图标承载层

```text
assertion=tests/i3_map_local_context_interaction_runner.gd::Button.icon distinct
old_authority=I3 expanded-map semantic distinction
disposition=SUPERSEDED_WITH_REPLACEMENT
reason=I4-R043 requires semantic/count/focus to occupy separate clipped child layers;
       keeping semantic art in Button.icon cannot expose or verify those local layers
replacement=SemanticMarker TextureRect exists, both textures resolve, and the Monster/Mine
            textures remain distinct; I4 map-layer gate additionally verifies clip, z order
            and semantic/count allocated-rect intersection == 0
scope_change=render carrier only; Monster/Mine distinction remains authoritative
```

### 旧断言处置：中文字体角色与左下滚动阈值

```text
assertion=tests/i3r_ui_composition_contract_runner.gd::title/button/status use display font
old_authority=I3R single FusionPixel-primary player UI stack
disposition=SUPERSEDED_WITH_REPLACEMENT
reason=I4-R023/I4-R035 keep readable/display as layout semantics but do not authorize
       either role to replace the project's FusionPixel visual identity
replacement=I4_FONT_ROLE_RASTER plus the revised I3R composition/raster runners verify
            both semantic FontVariation stacks are FusionPixel-primary, AA/subpixel are
            disabled, Noto remains missing-glyph fallback only, and all theme consumers
            resolve the governed stack
scope_change=semantic token mapping only; FusionPixel primary identity, token sizes,
             explicit fallback, manifest hash and system fallback prohibition remain
             authoritative

assertion=tests/i3_hud_item_input_character_runner.gd::quick bag always SCROLL_MODE_AUTO
old_authority=I3 quick-bag items remain reachable through a scroll container
disposition=SUPERSEDED_WITH_REPLACEMENT
reason=I4-R046 forbids a fixed scroll reservation for 0-3 rows and enables scrolling
       only above three complete rows
replacement=the revised I3 HUD runner asserts one aggregated row has scrolling disabled;
            I2_RUN_INFORMATION_SURFACE and I4_IN_RUN_VISUAL_PHYSICS verify 0/1/3/4/full
            content-driven height, the >3 threshold and end reachability
scope_change=scroll activation threshold only; all real items and focus actions remain
             reachable and the exact instance ledger remains authoritative

assertion=tests/i3r_out_of_run_production_journey_runner.gd::three staged Esc
old_authority=I3R LongTerm had no player page-history stack, so record -> secondary ->
              primary -> main was always exactly three cancel presses
disposition=SUPERSEDED_WITH_REPLACEMENT
reason=I4-R021/I4-R022 require Back to restore every actually visited page, filter,
       selected card, scroll and focus state before leaving LongTerm; the production
       journey visits task -> talent -> profile default -> history and therefore owns
       three authoritative page-history entries
replacement=the revised production journey asserts depth 3, one-entry consumption and
            exact profile/talent/task restoration before a fourth cancel returns to main;
            I4_LONG_TERM_NAVIGATION separately verifies one-action notification-detail
            return with card/filter/scroll/focus restoration
scope_change=only the number and meaning of Back steps after multiple real page visits;
             staged focus handling and eventual main-menu return remain authoritative
```

### 治理断言处置：R036 从反例 FAIL 推进到候选

```text
assertion=tools/i4/tests/test_i4_quality_standard.py::R036 must currently be FAIL
old_authority=冻结标准建立时必须阻止在没有新鲜实现/原图的情况下抹去用户 Deploy 反例
disposition=SUPERSEDED_WITH_REPLACEMENT
reason=P3/P4 已实施，Deploy 12 状态真实 Windows 原图已逐图复核；继续强制当前行写 FAIL
       会把历史反例状态和当前候选证据混为一体
replacement=治理测试要求 R036 只能推进到 VISUAL_CANDIDATE；原截图 SHA 必须继续存在；
            R025/R038 只能随真实捕获推进到 VISUAL_CANDIDATE，R040 只有完整处置审计后才能
            推进到 TARGETED_PASS，R042 必须保持 IMPLEMENTING；R029 只有在登记 exact-head
            证据后才能从 NOT_STARTED 推进到 IMPLEMENTING，push/远端 SHA 前不得继续提升；
            R030 必须以 clean/protected-dirty 证据为 TARGETED_PASS
scope_change=只更新当前候选状态；原反例、全矩阵/动态验收和阶段关闭边界均不放宽
```

## UE 非权威参考记录

用户允许在需要时只读参考 `E:\UE`，但明确禁止照搬。2026-07-30 已只读检查：

- `E:\UE\Game\UE\Graytail\Graytail.uproject`；
- `E:\UE\graytail-final-running.png`；
- Deploy 主/摘要空面板资产及历史适配文档。
- `E:\UE\Game\UE\Graytail\Source\Graytail\UI\GT_UIStyle.h` 的 common/rare/epic/
  legendary/mythic 色值；
- `E:\UE\Game\scripts\main.lua` 的 uncommon 色值。

仅保留一个可迁移原则：高装饰边框集中在页面/主要面板，内部列表应降低为薄描边或分隔线。
另只借用色值 `#D0D8E0/#78DCAA/#5FA5FF/#BE78FF/#FFC346/#FA5F55` 作为 I4 Godot
品质色映射。UE 的 1536×864 基准、模块结构、资产尺寸、旧数据、输入和实现不属于 Godot
当前权威，不进入内容普查或 PASS 证据。

## 证据登记规则

每项证据必须记录：

- commit/tree；
- source mode；
- Godot 版本；
- profile/scenario/seed；
- 输入类型与输入序列；
- 保存 profile 与前后语义哈希；
- 报告/截图/日志路径；
- 自动、静态人工、动态人工、设备和性能边界。

未执行项目保持 `NOT_RUN`，不得根据相邻门推断通过。
