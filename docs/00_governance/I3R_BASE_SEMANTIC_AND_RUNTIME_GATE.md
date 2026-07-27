# I3R Base 语义目录与运行时交叉账

文档状态：`ACTIVE / MACHINE-GOVERNED`

## 目的

I3 已完成“原始策划案”保真和美术素材字节级去重，但统一写成
`pending_verification / pending_review / not_admitted` 只能保护来源，不能说明：

- 一个 Base 对象究竟是什么；
- 运行时为何存在相同字节；
- 真实消费者在哪里；
- 已检查素材是否适合动态文字、输入设备和当前玩家界面。

I3R 不修改 `sources/base` 的原件、对象或 I3 生成清单，而在治理层补充四份账：

- `I3R_BASE_SEMANTIC_OBJECT_REGISTRY.csv`：1012 个唯一 Base 对象的媒体种类、语义族、
  alias、同名异 SHA 风险与运行时匹配；
- `I3R_BASE_RUNTIME_CROSSWALK.csv`：每条 Base/runtime 精确 SHA 匹配的来源、运行时
  key、消费者证据和裁决；
- `I3R_BASE_VISUAL_REVIEW_REGISTRY.csv`：逐资产、逐 SHA 的人工视觉复核与准入范围；
- `I3_RUNTIME_ASSET_PROMOTION_REGISTRY.csv`：只有明确从 Base 晋级的对象才进入该表，
  并绑定来源、两个 SHA、runtime key、consumer、视觉证据和 rollback。

## 关键区分

```text
Base canonical object = 保存同一组字节的代表路径
semantic family       = 当前可检索分类，不等于最终用途批准
exact runtime match   = 字节相同，不自动证明运行时由 Base 晋级
promotion             = 明确由 Base source 进入某个 runtime consumer
existing lineage      = 运行时在 I3 前已有独立阶段来源；交叉账只回填关系
visual review         = 检查裁切、语义、烘焙文字和消费者；不自动等于准入
```

同名不同 SHA 不覆盖；同 SHA 不同名称保留全部 alias。CSV、JSON、Markdown、HTML、
视频等非图像对象也按真实媒体种类记录，不再笼统描述为“美术图片”。

## 视觉复核裁决

75 条原待复核运行时匹配已经绑定联系表证据并逐项裁决：

| 裁决 | 数量 | 含义 |
| --- | ---: | --- |
| `visual_reviewed_existing_runtime` | 14 | 语义、裁切与现有真实消费者相符；不是新的 Base promotion |
| `visual_reviewed_staging_reference` | 35 | 图像本身可用，但只有映射或暂存证据；保留参考，不准入生产 |
| `visual_reviewed_restricted_baked_text` | 12 | 含玩家文字，无法继承像素字体/本地化；只作参考或回滚 |
| `visual_reviewed_restricted_input_glyph` | 13 | 烘焙键盘或方向图形；不能作为唯一的设备语义提示 |
| `visual_reviewed_semantic_mismatch` | 1 | `xuetiao_tianchong` 实际为齿轮图标；隔离至语义重新裁决 |

因此“待视觉复核”已归零，但只有 14 项被确认为既有消费者范围内可继续使用。
其余 61 项没有被象征性批准，也不得因为已经分类或已经进入仓库而自动接线。
特别是带“确认出发”“天赋”等烘焙文字的旧按钮，不能再与动态 Label 叠加。

## 其他交叉账裁决

| 状态 | 含义 |
| --- | --- |
| `approved_by_explicit_promotion_gate` | 显式 promotion 的身份、消费者与回滚字段通过机器门 |
| `independent_generated_lineage` | 运行时有内部生成谱系，与 Base 准入相互独立 |
| `existing_stage_evidence_backfilled` | 已有审计阶段证据；I3R 只回填精确 Base 匹配 |
| `existing_stage_evidence_visual_review_pending` | 新增/变化素材尚未复核；严格门会失败 |
| `quarantined_runtime_manifest` | 来源或许可未解决，不可视为已准入 |

## 复现

```powershell
python .\tools\i3r\build_base_governance_overlay.py `
  --repo-root (git rev-parse --show-toplevel) `
  --mode verify
```

需要重新生成当前治理 CSV 时：

```powershell
python .\tools\i3r\build_base_governance_overlay.py `
  --repo-root (git rev-parse --show-toplevel) `
  --mode write
```

复核联系表：

```powershell
python .\tools\i3r\build_base_visual_review_gallery.py `
  --repo-root (git rev-parse --show-toplevel) `
  --output .tmp\i3r\base_visual_review
```

联系表会输出 5 页、75 项及每种裁决计数。任何资产字节变化、清单身份变化或新增
待复核项都会使严格治理门失败。工具不得修改
`sources/base/原始策划案`、`sources/base/美术素材` 或 I3 import manifests。
