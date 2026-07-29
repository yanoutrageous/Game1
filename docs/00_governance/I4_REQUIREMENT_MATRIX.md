# I4 需求矩阵

文档状态：`ACTIVE`

生产质量标准：
`docs/20_product/I4_ENGINEERING_QUALITY_AND_ACCEPTANCE_STANDARD.md`

状态值：

- `NOT_STARTED`
- `BLOCKED`
- `FAIL`
- `IMPLEMENTING`
- `TARGETED_PASS`
- `VISUAL_CANDIDATE`
- `VISUAL_PASS`
- `PRODUCTION_PASS`
- `IMPLEMENTED_AND_VERIFIED`
- `REJECTED_WITH_EVIDENCE`
- `EXPLICITLY_DEFERRED`

| ID | 必须结果 | 当前状态 | 证明要求 |
| --- | --- | --- | --- |
| I4-R001 | I4 入口 commit/tree、远端、工具链、dirty 和 I3R 开放反馈可追溯 | `TARGETED_PASS` | 入口报告、台账、Git 证据；最终远端证据仍由 I4-R029 关闭 |
| I4-R002 | Base 治理验证跨 Windows/Linux 换行稳定，真实内容漂移仍失败 | `TARGETED_PASS` | 单元测试、overlay verify、exact-head |
| I4-R003 | debug/editor-only 测试场从设置主菜单入口进入 | `TARGETED_PASS` | 生产路由 runner、release 隐藏门 |
| I4-R004 | 测试场强制使用独立 `dev_sandbox` profile 并在退出后恢复 | `TARGETED_PASS` | 前后 profile/save hash |
| I4-R005 | 第一个写命令 taint 会话，tainted 会话不能写默认档结算 | `TARGETED_PASS` | 命令、结算、保存失败路径测试 |
| I4-R006 | 诊断面板分离只读状态与写命令并显示 profile/scenario/seed/save target | `VISUAL_CANDIDATE` | 定向 runner 已过；1280×720 真实原图已复核，12 组展开态仍待执行 |
| I4-R007 | 固定场景目录覆盖房型、战斗、满包、重复物品、终局和保存失败 | `TARGETED_PASS` | 六场景 manifest、内容普查与重复报告 |
| I4-R008 | 失败包包含完整复现身份和前后保存证据 | `TARGETED_PASS` | 失败注入与字段完整性 runner |
| I4-R009 | 携带卡使用 `− 已携带/持有 +` 且修改可撤销草稿 | `TARGETED_PASS` | Deploy 生产 runner |
| I4-R010 | N 件购买预检总价、生成 N 个不同实例、一次保存、失败全回滚 | `TARGETED_PASS` | 领域单元/集成/失败注入 |
| I4-R011 | 待售数量稳定映射精确可售实例并一次原子提交 | `TARGETED_PASS` | batch sale 集成、幂等/回滚 |
| I4-R012 | 同一物品卡一次只显示一种数量语义 | `VISUAL_CANDIDATE` | 投影测试与 Deploy 12 图复核 |
| I4-R013 | 普通卡只保留名称与类别/价格/数量两行，不显示玩家 T 码 | `VISUAL_CANDIDATE` | 文案扫描与 Deploy 12 图复核 |
| I4-R014 | 普通 Deploy 页为 310/12/310，地图页继续 198/424 | `TARGETED_PASS` | 几何合同与 Deploy 12 状态捕获 |
| I4-R015 | 详情与摘要可滚动且不再截断为四行 | `TARGETED_PASS` | 超长 fixture、稳定布局与滚动可达测试 |
| I4-R016 | 速览/携带/本局/目标内容严格按语义分栏 | `TARGETED_PASS` | model 投影测试 |
| I4-R017 | 金币只在交易上下文出现，动作区显示总价/收益/交易后余额 | `VISUAL_CANDIDATE` | Deploy 各页投影测试与 12 图复核 |
| I4-R018 | 快速出售支持全选可售/清空/一次确认 | `TARGETED_PASS` | 局外生产旅程 |
| I4-R019 | 局内重复可堆叠物品紧凑聚合，底层精确实例不变 | `TARGETED_PASS` | ledger/投影/截图测试 |
| I4-R020 | 使用/丢弃只消费一个确定实例，重量与结算按实例正确 | `TARGETED_PASS` | 使用/丢弃/成功/失败 runner |
| I4-R021 | 长期通知直达具体页/卡，打开模块不提前清未读 | `TARGETED_PASS` | 长期系统定向 runner 与生产旅程 |
| I4-R022 | Back 使用页面历史；筛选、滚动、选中状态可恢复 | `TARGETED_PASS` | 键鼠导航 runner；物理手柄仍属外部门 |
| I4-R023 | display/readable 字体角色分离；正文使用可读 CJK 与 AA | `VISUAL_CANDIDATE` | 字体策略/消费者测试与当前真实原图；完整矩阵待验 |
| I4-R024 | 品质、焦点和选中视觉通道分离且颜色有冗余 | `VISUAL_CANDIDATE` | 静态规则、定向 runner 与当前真实原图 |
| I4-R025 | 四分辨率×三 UI 比例无文字遮挡、裁切或不可达区域 | `IMPLEMENTING` | 自动几何已通过；12 组逐原图与动态输入尚未完成 |
| I4-R026 | 关键 runner 等待语义状态/信号，不依赖固定帧证明正确性 | `TARGETED_PASS` | 静态门为 `fixed_frame_helpers=0`，重复运行通过 |
| I4-R027 | 关键场景 10 连过（至少 3 个新进程），局外旅程 3 连过 | `TARGETED_PASS` | worktree 6×10 + 3×旅程已过；最终 exact-head 仍由 I4-R029 关闭 |
| I4-R028 | 旧档兼容，sandbox 前后默认档语义哈希一致 | `TARGETED_PASS` | save fixture、污染门与局外旅程 |
| I4-R029 | worktree/full、exact-head/full、远端 SHA 和最终审计一致 | `IMPLEMENTING` | `f950eef` exact-head/full 与 51 图已过；最终审计提交、push/远端 SHA 待关闭 |
| I4-R030 | 最终 diff 无未知 dirty 或未授权 Godot metadata | `TARGETED_PASS` | `f950eef` clean exact-head 静态门 `protected_dirty=0`；最终审计提交仍需同门复验 |
| I4-R031 | `I4-QA-FROZEN-1` 在任何新 PASS 前生效；每条门具备对象、前置、测量、阈值、根因、修复顺序、信息保护和复验范围 | `TARGETED_PASS` | 标准审计、文档链接、模糊词扫描与人工复核；治理测试 12/12 |
| I4-R032 | 当前生产内容普查覆盖主菜单/设置、Deploy、长期 6/25/58、局内、模态、结果和测试场，且每行有公开路径、fixture、layout class 和风险 | `TARGETED_PASS` | 156 行当前 registry/model 导出与逐行可达性报告 |
| I4-R033 | 视觉几何按 R/S/G/V/H/F/P 判定；文字/框体遮挡为零，失败必须分类根因并按无损顺序修复 | `VISUAL_CANDIDATE` | 几何/极值/失败注入已过；当前原图已复核，完整矩阵未关门 |
| I4-R034 | 页面/工作区/卡片/紧凑控件单边边框分别 ≤16/8/4/2 逻辑像素；同一内容簇最多两层完整框 | `VISUAL_CANDIDATE` | 样式门与当前真实原图通过；12 组矩阵待验 |
| I4-R035 | 所有玩家可见中文使用统一 readable CJK；display 只承载纯数字 HUD、键位和登记装饰，字号不低于 token 基准 | `VISUAL_CANDIDATE` | 字体消费者/实际角色测试通过；完整真实矩阵待验 |
| I4-R036 | Deploy 摘要满足精确语义与密度：速览首屏至少六项，单行 34–46 px、间距 4–8 px，内容不重复/错栏/删减 | `VISUAL_CANDIDATE` | model、信息库存、滚动与 Deploy 12 图已复核；动态全矩阵待验 |
| I4-R037 | 真实 Windows renderer 捕获 12 组矩阵；捕获成功仅为 `VISUAL_CANDIDATE`，逐原图复核后才能 `VISUAL_PASS` | `VISUAL_CANDIDATE` | Deploy 12 图与 1280 高风险状态已逐原图复核；非 Deploy 12 组未完成 |
| I4-R038 | 1280×720@100% 全量内容捕获；其余矩阵按已证明布局等价类和高风险状态覆盖，等价证明失败时扩为全量 | `IMPLEMENTING` | 156 行 census 已有；25 长期页与 14 高风险生产态已捕获，尚非 156 行全量 |
| I4-R039 | 测试场与生产 UI/theme/命令同源；诊断面板默认收起、展开 ≤28% 宽/75% 高且零关键遮挡、焦点精确归还 | `VISUAL_CANDIDATE` | 同源/焦点/输入定向门通过；1280 展开态实测约 24%×71%，12 组待验 |
| I4-R040 | 每个旧失败断言登记为仍权威、带替代门的已取代或有证据的无效；不得仅改预期使旧测试变绿 | `IMPLEMENTING` | 已登记地图承载层、字体角色、左下滚动阈值、长期 Back 四组替代；其余旧失败断言仍需逐项清点 |
| I4-R041 | 携带、购买、批售、出发、通知直达、Back 和局内物品管理满足冻结动作预算，无重复详情/确认链 | `TARGETED_PASS` | 解析输入动作日志与定向/生产旅程通过；动态玩家复核待阶段门 |
| I4-R042 | 任一当前反例重新打开受影响布局类；所有 `MUST` 失败清零后才允许生产/阶段 PASS | `IMPLEMENTING` | 反例台账、缺陷关闭记录、受影响复验范围 |
| I4-R043 | 折叠小地图与展开地图按 base/semantic/count/focus 固定层合成；子层零越格、图标与计数分配矩形零交集、背景 HUD 不穿透地图内容板 | `VISUAL_CANDIDATE` | z=0/20/30/40、clip 与分配矩形定向门通过；1280 原图已复核，完整 15×2×12 未完成 |
| I4-R044 | 每个生产静态阻挡具备稳定来源和当前可见对应物；碰撞足迹至少 90% 被登记视觉足迹覆盖，缺图/退场后零隐形碰撞 | `VISUAL_CANDIDATE` | descriptor、全房型、缺图/退场注入通过；当前 Normal/房型原图已复核 |
| I4-R045 | 右上协议标题/状态/压力条全部位于按真实边框 B 计算的安全区，极值压力和全部模态组合零内部遮挡、零错误命中 | `VISUAL_CANDIDATE` | 几何/模态配对定向门与当前原图通过；五等级×12 组待验 |
| I4-R046 | 左下物品簇按内容驱动高度；0/1/3 件无超过 8 px 的语义间空白，超过 3 件才启用三完整行滚动且 footer 可达 | `VISUAL_CANDIDATE` | 0/1/3/4/满包定向门通过；当前空包/有物原图已复核，12 组待验 |
| I4-R047 | 全物品表面使用冻结的 UE 借鉴色值映射和同一描述器；名称/细边/地面光束一致，焦点/失败不覆盖品质且自然语言/形状提供冗余 | `VISUAL_CANDIDATE` | 冻结色值/消费者/状态定向门与当前原图通过；完整 8×6 状态配对待验 |
| I4-R048 | 当前全部 item ID 在背包、库存、地面列表、世界掉落和结果解析同一非空 visual key/path；缺失纹理显示可见 fallback 并记录原因 | `VISUAL_CANDIDATE` | registry 全枚举、缺失注入与世界掉落真实捕获通过；完整矩阵待验 |
| I4-R049 | 本次局内补充以增量重审接入原 I4.5/I4.7，保留 I4-R001–R042 与既有反例结论，并冻结新的依赖顺序和复验范围 | `TARGETED_PASS` | 合同、标准、矩阵、台账、质量审计、runbook 交叉引用；治理测试 12/12 |

## 2026-07-30 当前候选证据快照

状态回填遵守以下边界：

- `TARGETED_PASS` 只说明对应自动/定向门通过，不等于玩家体验、设备或阶段通过；
- `VISUAL_CANDIDATE` 说明真实 Windows renderer 已产图且当前代表图完成逐原图复核，仍不等于
  12 组全矩阵或动态玩家验收；
- I4-R025、R029、R038、R040、R042 仍未关闭，因此 I4 保持 `ACTIVE`。

```text
original_deploy_counterexample_sha256=1F85061F1C90B1E6B3F673F8519399B8094FD2499B0F4004DB9BCEBD4C3E0C51
original_deploy_counterexample_disposition=VISUAL_FAIL / PRESERVED_HISTORY
worktree_preflight=PASS
report=.tmp/i4_unified_worktree_preflight_final/evidence/i4_report.json
report_sha256=81741EAE3B23F75EB773BE4DD3EED355A72CFA49B8B3FF05D090370FF0E80F07
static=PASS quality=12/12 i4_runners=8 protected_dirty=0 fixed_frame_helpers=0
static_sha256=1FB11E1C062C7237089CB4EA6670123163FCB73DEFC6A8DEC431120BD16D3906
final_worktree_static_sha256=13D1EE13E79B21C76211F0CC7FEA1DD3C9CD49EAD2235311BC68FC17324278C1
content_census=PASS rows=156 deploy=5/13 long_term=6/25/58 rooms=6 scenarios=6
content_census_sha256=A9717A173F5EE13C09C35F4FF49E9126C32E440E40A8346B43F4B9720D70C3BA
worktree_repetition_full=PASS critical=6x10 journey=3/3
worktree_repetition_sha256=D7D5933EE5DBF6A7F9E8A3412CDE2D44DD1E0D7F1ED1270E57F85C2C70444C19
production_real_render=PASS images=14 visual_status=VISUAL_CANDIDATE
production_manifest=.tmp/i4_capture_wrapper_probe2/evidence/capture_manifest.json
production_manifest_sha256=0AC09492F45028DDDE04EF22F49212F620F3B0863BA28DB486B43A1AE9204335
unified_real_render=PASS profile=all images=51 visual_status=VISUAL_CANDIDATE
unified_real_render_manifest=.tmp/i4_real_render_worktree_all_final2/evidence/capture_manifest.json
unified_real_render_sha256=42894CFFFAEDA529367941F5CA8EA1424EF4C89FD8EDFB69E0AF3CB9581D16F7
device_inventory=PASS controller=BLOCKED_NOT_RUN
audio=ROUTE_DETECTED_NOT_FUNCTIONALLY_ACCEPTED
gpu=MEASURED_NOT_ACCEPTED
exact_head_candidate=f950eefb000ab298344059dfa8afc125aa79ed8a
exact_head_full=PASS
exact_head_report=.tmp/i4_exact_head_full_f950eef/evidence/i4_report.json
exact_head_report_sha256=DAFE502175D30034C210AA664769770AB74420AF42FB1B45BE98F4E15F079E56
exact_head_static_sha256=C708B0BCC09A436BD23218CC832AF8DEF16E7D7945C2F3987F135E09A9BC8F56
exact_head_census_sha256=CC31EB553CB0BE106AD93DB75A1C8E653A60D648A06499C3689E84F23E8FBF04
exact_head_repetition_sha256=5B7805C7BC472CE89E6D2807A9B44E177BA0E91FFBC7D3CB141FC92004C79471
exact_head_device_sha256=48335E1DB9FB931FCE87F670EBFE4D6CA55A9A4B0B76E7BF699773E87A3C312F
exact_head_render=PASS images=51 visual_status=VISUAL_CANDIDATE
exact_head_render_sha256=981126BEFFC89311986262EB78A036DE054911DE2869982BD0F99B49F5F8800E
push=NOT_RUN
stage_acceptance=BLOCKED_EXTERNAL_DEVICE_AND_DYNAMIC_ACCEPTANCE
```
