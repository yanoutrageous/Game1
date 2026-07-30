# Current State

文档状态：I4 活动阶段事实。

最后更新：2026-07-30

当前质量权威：
`docs/20_product/I4_ENGINEERING_QUALITY_AND_ACCEPTANCE_STANDARD.md`

```text
current_stage=I4 / ACTIVE / IMPLEMENTED_CANDIDATE / EXTERNAL_ACCEPTANCE_BLOCKED
entry_commit=4127bd27a05b75cb5e3071cf6dc87d9287f679a9
entry_tree=e1455ffd8c7a754c63eb2141a47e41f8fe5cdf3a
branch=codex/i4-production-interaction-convergence
remote_main_at_entry=4127bd27a05b75cb5e3071cf6dc87d9287f679a9
implementation_checkpoint=f950eefb000ab298344059dfa8afc125aa79ed8a
implementation_tree=c19957042fb5ebe424694716c6a7a0af72922024
post_audit_base_head=0d4fe159fc86b1b63b4fc13771058313686cb43f
post_audit_candidate=THIS_DOCUMENT_COMMIT / POST_COMMIT_EXACT_HEAD_BINDING_REQUIRED
godot=4.6.3.stable.official.7d41c59c4
```

## 当前判断

项目已经具备真实生产主菜单、Deploy、局内、结果、仓库交易和长期系统，但当前玩家
任务仍被页面覆盖导向、重复详情/确认、固定摘要、信息错栏和实例逐行显示拖长。
I4 不新增内容，而是把这些已有功能整理为可理解、可撤销、一次提交和可复现的闭环。

入口实现事实（已被 I4 检查点部分取代）：

- 普通 Deploy 工作区为左 248、间隔 12、右 372；地图为 198/424。
- 右侧摘要固定四行，超出内容被截断。
- 金币在 Deploy 所有页面常驻。
- 购买接口一次创建一个实例；批量出售已有原子实例集合接口。
- 携带和局内账本已经保留多个精确实例，允许在展示层安全聚合。
- display/readable 字体角色当前返回同一 FusionPixel 栈，并统一关闭 AA/subpixel。
- debug gate 和 RunScene 调试命令存在，但 `debug_used` 标记本身不能证明默认档零污染。
- 长期系统当前生产口径是 6 模块、25 页面、58 运行资产。

当前候选事实：

- `7af22f4` 已包含 sandbox/taint、设置测试场入口、诊断基础、原子 N 件购买、
  精确实例数量投影、Deploy 两行卡/310 分栏和局内重复物品聚合的定向实现。
- 当前 worktree 已按 P1–P8 完成长期通知/历史恢复、字体、摘要、数量器、地图四层、
  阻挡—可见物、协议安全区、左下内容驱动高度、品质色、纹理 resolver 和诊断面板候选实现。
- 用户于 2026-07-30 提供真实 Deploy 生产截图，证明此前自动布局门没有发现中文字体不一致、
  数量器视觉冲突、摘要大间距/信息不足、同义重复和多层宽边框。
- 该原始反例截图 SHA-256 为
  `1F85061F1C90B1E6B3F673F8519399B8094FD2499B0F4004DB9BCEBD4C3E0C51`；
  它仍保留为导致 I4.4/I4.7 重开的有效历史证据，不因后续修复被删除。
- `I4-QA-FROZEN-1` 已建立具体 R/S/G/V/H/F/P 遮挡判定、无损修复顺序、
  页面/工作区/卡片/紧凑控件 16/8/4/2 边框上限、内容普查、动作预算和真实渲染逐图门。
- 用户随后补充局内生产问题；增量重审没有删除此前要求，而是将地图层级、阻挡—可见物、
  协议安全区、左下密度、UE 借鉴品质色和地面物纹理接入原 I4.5/I4.7。
- 初始代码审计确认的地图越格/共中心、匿名阻挡、空纹理隐藏 fallback 和固定空包区，
  已分别由地图四层、稳定 obstacle descriptor、纹理非空判据和内容驱动高度处理；定向 runner
  已通过，当前 1280×720 真实原图已复核，因此只可标记为
  `TARGETED_PASS / VISUAL_CANDIDATE`。
- 自动 runner、截图生成和几何报告最多产生 `VISUAL_CANDIDATE`，不能再直接宣称视觉通过。
- 当前 post-audit worktree 静态门为 PASS：质量治理 12/12、I4 runner 9、受保护 dirty 0、
  fixed-frame helper 0、旧断言文件 15/15；关键场景 6×10 和局外旅程 3×3 已通过。
- 当前真实渲染已复核 Deploy 12 状态、长期系统 25 页面和 14 个生产高风险状态。捕获过程中
  实际发现并修复筛选页签越界、局内左轨过高、Codex 第八页签不可见、调试横幅/面板遮挡
  和宝箱捕获旧语义等待问题；这些发现说明真实原图门不能由静态几何替代。
- 实现候选 `f950eef` 的 clean exact-head/full 和 exact-head 51 图清单保持历史有效；
  随后的 post-audit 工作树补齐了确定性测试场夹具、一次性保存失败注入、诊断布局、
  全内容矩阵和旧断言处置，并纠正了错误的 Noto 正文主字体实验。
- 正确字体下 I1 full 为 104/104 PASS，I4 full 自动门为 PASS，阶段接受仍明确返回
  `BLOCKED_EXTERNAL_DEVICE_AND_DYNAMIC_ACCEPTANCE`。
- 当前 156 行 census 已对 4 分辨率×3 UI 比例形成 1872 个逐行覆盖单元和 1140 张真实
  Windows renderer 原图；清单为 `CAPTURE_COMPLETE / VISUAL_CANDIDATE`。这些原图尚未逐张
  人工签收，不能写成 `VISUAL_PASS`。
- 入口以来 15 个被修改的既有测试文件已完成精确文件集/哈希审计：38 条 disposition、
  19 条 `SUPERSEDED_WITH_REPLACEMENT`、0 条 `INVALID_WITH_EVIDENCE`。
- 首次最终候选 `fafbbff` 的 I1 exact-head 为 103/104：满包替换真实旅程、PASS marker 和
  退出码均成功，但清理诊断偶发为 19 resources，违反冻结的 18-resource 精确合同。失败报告
  SHA-256 `5DAA2B783FF93147998A42D5A830CDA7C07B8FEC35BD36A510E370B408D173FC`
  已保留；没有把期望放宽为 18/19。主场景释放后的纯清理退栈等待由 2 次提交增至 4 次，
  修改后 3 个全新进程均业务 PASS 且精确回到 18；本文所在候选仍须全量 head 复验。
- 本文所在提交是最终候选对象；其 SHA 不在文档内自指硬编码，须在零源码修改条件下由
  post-commit exact-head/full、exact-head 全矩阵、push 和远端 SHA 绑定。

## I4 当前进度

| Gate | 状态 |
| --- | --- |
| I4.0 计划审计与入口冻结 | `TARGETED_PASS` |
| I4.1 正式档隔离与测试场 | `TARGETED_PASS` |
| I4.2 诊断与可复现场景 | `TARGETED_PASS` |
| I4.3 数量与原子交易 | `TARGETED_PASS` |
| I4.4 Deploy 交互 | `TARGETED_PASS / VISUAL_CANDIDATE` |
| I4.5 局内聚合、阻挡与地面物 | `TARGETED_PASS / VISUAL_CANDIDATE` |
| I4.6 长期导航 | `TARGETED_PASS / VISUAL_CANDIDATE` |
| I4.7 字体、边框、地图/HUD 与输入表现 | `TARGETED_PASS / VISUAL_CANDIDATE` |
| I4.8 终验与交付 | `WORKTREE_AUTOMATION_PASS / EXTERNAL_GATES_BLOCKED` |

## 入口审计事实

- 本地与远端 `main` 在入口时均为 `4127bd2`，ahead/behind 为 0/0。
- 入口前已有 `project.godot` 换行物化和 7 个 Godot 生成 `.translation` 修改；
  已保存到 stash `pre-i4 generated Godot metadata 2026-07-30`，未并入 I4。
- 首次 I3R exact-head/full 在 Base overlay 前置门失败。
- 失败根因是 Windows `core.autocrlf=true` 将三份 CSV 物化为 CRLF，而生成器输出 LF；
  文本行完全一致。
- I4.0 已修改验证器，只归一化 CRLF/LF；真实字段变化仍产生 `OVERLAY_DRIFT`，
  并新增单元测试。

## 历史边界

I3R 的机器矩阵和静态复核仍是历史有效证据，但用户通过实际生产截图提出的字体、
遮挡、信息层级、数量交互和操作链问题证明外部体验门未通过。I4 明确接管这些开放项。

I2 仍是最新已经生效的闭合非美术基线；I4 关闭和远端证明完成前不得提升这一权威。
ART21 仍是项目级最新闭合美术阶段。

## 当前未完成

- 对本文所在提交重跑 clean `exact-head/full` 与 exact-head 全内容矩阵，再 push 并核对
  远端 SHA。
- 对当前 1140 张原尺寸 PNG 建立逐图人工 ledger，并完成真实窗口动态输入复核；自动捕获、
  coverage 与几何 PASS 不能替代该门。
- 在接入物理手柄后执行导航/焦点门；当前设备枚举为 0 个手柄，状态必须保持
  `BLOCKED_NOT_RUN`。
- 由人实际听取关键音频、在目标 GPU 上执行长局性能验收，并完成动态玩家任务验收；
  当前只能记录 `ROUTE_DETECTED_NOT_FUNCTIONALLY_ACCEPTED` 和 `MEASURED_NOT_ACCEPTED`。
- I4-R050 第一轮精确清理已释放 E 盘 19,342,217,216 字节：裁剪 I1 可重建 cache/worktree、
  删除错误字体矩阵，并只删除 8 个被最终矩阵取代的旧矩阵 PNG；JSON/日志、正确矩阵
  1140 PNG、最终/失败证据、来源、用户档、stash、CAS 与恢复证明均保留。C 盘仅审计且
  零删除，避免误删用户截图和活动 Codex 内核文件；最终 exact-head 形成后仍须末轮复量。
- 上述外部门未关闭前，I4 保持 ACTIVE；I2 仍是最新生效的闭合非美术基线。
