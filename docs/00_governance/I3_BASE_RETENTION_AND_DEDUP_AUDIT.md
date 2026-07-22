# I3 Base 保留、去重与运行时边界审计

文档状态：I3.0/I3.6 当前审计记录
最后更新：2026-07-23

## 结论

`sources.zip` 不应原样解压进仓库。I3 采用“策划原件逐文件保留 + 美术内容寻址
去重 + 全路径 alias + 独立 runtime admission”的 Base 基线：

```text
archive members: 1626 / 314060767 bytes
原始策划案: 25 / 728214 bytes / 原名与源字节完整
art + draw members: 1407 / 256510309 bytes
unique art content objects: 1012 / 177253870 bytes
exact duplicate aliases: 395
deduplicated art bytes: 79256439
repository Base total: 179095285 bytes（`sources/base/` 物理内容，含清单与说明）
```

这解决的是“同一字节多处复制”和“来源不可追溯”，不是通过删掉阶段材料伪造整洁。
被折叠路径仍可从 manifest 找到 canonical object；不同字节即使名称相近也保留，等待
语义和版本裁决。

## 原始策划案

- `sources/docs/` 25 份全部保留，因为它们分别承载版本、假设、修正、扩展或历史
  上下文；不得用当前工程摘要代替。
- 文件名、正文与 SHA 保持来源字节，不做标题反斜杠、伪引用、固定盘符或换行清理。
  这些问题在关系表中说明，修正只能产生独立的工程契约，不能改写原件。
- v0.1/v0.2、早期数值/M5、长期系统三份文档通过关系表组合读取，而不是只保留
  日期最新的一份。
- 逐文件保留理由和当前用途见
  `docs/70_sources/base_docs/I3_ORIGINAL_PLANNING_RELATIONSHIP_REGISTRY.md`。

## 美术内容保留分布

| 来源层 | member | canonical bytes | 处理理由 |
| --- | ---: | ---: | --- |
| `draw_root` | 24 | 41527358 | 原始合图、页面底图与参考入口；唯一内容保留 |
| `Base` | 10 | 14636047 | 用户确定图/示例图；作为视觉参考，不定义玩法 |
| `M1` | 7 | 46287403 | Lua 捕获视频与截图；保留体验参考，非源码 |
| `00_raw` | 4 | 0 | 四项字节都被更优 canonical 路径代表；原路径保留 alias |
| `10_working` | 552 | 17426276 | 多数为唯一工作帧/角色帧；不能因“工作层”批量删除 |
| `20_processed` | 191 | 23206864 | 多数为唯一处理结果；保留变换结果但不自动晋级 |
| `30_game_ready` | 151 | 2104172 | 大量与较早路径同字节，按 SHA 折叠；目录名不代表审核通过 |
| `03_selected` | 52 | 0 | 52 项全部由其他 canonical object 表示；只保留 alias |
| `05_export_runtime_candidates` | 52 | 0 | 与 `03_selected` 52/52 精确相同；不保存第二套字节 |
| `08_visual_targets` | 10 | 0 | 与 `Base` 10/10 精确相同；保留语义 alias |
| `stage_output` | 222 | 21174986 | 117 个唯一阶段结果保留，其余 105 个折叠为 alias |
| 其他 art/draw metadata | 132 | 10890764 | manifest、HTML、JSON、CSV 等用于重建谱系；仍不等于审核通过 |

canonical 的选择只影响“哪个原路径用作该 SHA 的标签”，不改变 blob 内容。优先使用
较少衍生、可读性较好的来源标签；若同一字节只有一个路径，则无论位于 working 或
stage 目录都保留，避免根本性素材再次丢失。

## 重复组

| exact group size | canonical groups |
| ---: | ---: |
| 1 | 820 |
| 2 | 84 |
| 3 | 68 |
| 4 | 13 |
| 5 | 14 |
| 6 | 3 |
| 7 | 6 |
| 8 | 3 |
| 9 | 1 |

精确重复只按 SHA 折叠，不按文件名、目录或肉眼相似判断。ART21R2 中“不同语义 ID
却同一像素”的文件因此仍只存一份字节，但 alias 会保留这些语义冲突，等待运行时
消费者裁决。

## 明确排除

| 范围 | 处理 | 原因 |
| --- | --- | --- |
| `sources/draw/Art.zip` | 不再次保存 archive bytes | 23 张内嵌图均在外层有相同内容；保留 archive member SHA 和排除记录 |
| `sources/docs_governance/` | 不复制正文 | 192 个复制型历史治理/旧仓库快照，不是用户要求的原始策划案或美术原件 |
| `sources.zip` | `.gitignore` 明确忽略 | Base 可由锁定 SHA 的 importer 重建；提交 archive 会恢复整包重复 |

排除不等于遗忘。全部 1626 member 的路径、SHA、字节、分类、处理和原因保存在
`sources/base/manifests/SOURCE_ARCHIVE_INVENTORY.csv`。

## 运行时晋级

当前 1012 个 Base art object 的共同状态是：

```text
authority=base_source_evidence_only
license_status=pending_verification
review_status=pending_review
runtime_admission=not_admitted
consumer=none_until_separate_runtime_gate
```

只有逐项补齐来源许可、语义、变换、输出 SHA、runtime path/key、真实 consumer、
视觉验证与回滚后才能晋级。开箱图等已存在于运行时但早先为 pending 的对象也必须
通过单独 I3 切片重新验证，不能因本次 Base 入库批量翻转状态。

## 可复现验证

```powershell
python .\tools\i3\import_base_sources.py `
  --archive <workspace>\sources.zip `
  --repo-root (git rev-parse --show-toplevel) `
  --mode verify
```

期望 marker：

```text
I3_BASE_IMPORT_VERIFY=PASS files=1041 planning=25 art_members=1407 art_unique=1012 aliases=395
```

validator 同时拒绝 archive SHA 漂移、原件缺失/字节变化、blob 变化和生成区意外文件。
