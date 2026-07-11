# Text Encoding Ledger

文档状态：I0 当前文本编码台账
最后更新：2026-07-11

## 审计结论

I0 严格 UTF-8 审计扫描活动仓库 368 个 Git 跟踪文档文本，确认 5 个文件在 I0 前已经发生字节损坏。损坏模式不是 GBK / GB18030，而是 UTF-8 三字节字符的第三字节被 `0x3F` 替换；Git 历史及 `D:\AGAME1` 冻结 / 镜像副本均无正常来源，因此不能声称可无损转码恢复。

## 原样保留的精确例外

严格门禁只允许以下“相对路径 + LF 规范化 SHA256”组合：

| Path | Normalized LF SHA256 | Lost character bytes | Decision |
| --- | --- | ---: | --- |
| `docs/00_governance/P2_EXECUTION_REPORT.md` | `339F5894B0073B8E01A0E9F29119974EE672C458D7EBF127D7408BC4FB4259C9` | 34 | 历史执行报告，原样保留 |
| `docs/20_product/PRODUCT_CONTRACT.md` | `A084706612E6B1C5939AEDFE7A34BF04F69F97B20EAB080971CFA30E48F6D88E` | 34 | P2 待确认草案，原样保留；不替代 I0 contract |
| `docs/30_engineering/adr/README.md` | `751CA1D949B5B0F234F4EE4C22D0D7B4FEDEF76092FB252502CFB76A6A60834D` | 3 | 原样保留；当前导航改由 `I0_INDEX.md` 承担 |
| `docs/30_engineering/architecture/README.md` | `EAE2C7A825C993427918D27E9B9242D800D1FB16424351C8F2604EFADC8A757E` | 2 | 原样保留；当前导航改由 `I0_INDEX.md` 承担 |
| `docs/90_archive/generated_reports/README.md` | `FE0F51B01FD0772EBC936341D0250264E9EF6A5EDB4513804E9F8E12790C0D65` | 2 | 原样保留；当前归档边界改由 `I0_INDEX.md` 承担 |

哈希改变、新增非法 UTF-8、目录通配例外或无法读取都必须失败。成功状态只能是 `PASS_WITH_RECORDED_LIMITATION`，不是“全部文档严格 UTF-8 PASS”。

## 有效替代索引

由于补丁工具会对无效 UTF-8 fail closed，I0 不以非审计写入覆盖损坏文件。以下 preimage 原样保留，并新增严格 UTF-8 的当前替代索引；这不是历史字节恢复：

| Preserved path | Preimage worktree SHA256 | Damaged characters | Current replacement |
| --- | --- | ---: | --- |
| `docs/30_engineering/adr/README.md` | `4AA87485ED74D06BBBCE016E6F29D1B5D9C20EA00EBF68652209EA13DA38E7CF` | 3 | `docs/30_engineering/adr/I0_INDEX.md` |
| `docs/30_engineering/architecture/README.md` | `A221B6D0D1B6B1DD52E5764A537A844CF1E7B24322D79D5F47D41E296ED21C6E` | 2 | `docs/30_engineering/architecture/I0_INDEX.md` |
| `docs/90_archive/generated_reports/README.md` | `B424010D4FCB56B09C44173A5B4237ED8949516062F0A6F8F0832B499222672B` | 2 | `docs/90_archive/generated_reports/I0_INDEX.md` |

## 门禁规则

- 只扫描活动仓库 `docs` 下 Git 跟踪和非忽略的新文件。
- 严格 UTF-8 解码；未知扩展名、文件缺失、重复 / 大小写碰撞、清单失败、路径逃逸或重解析点均 fail closed。
- `.png` / `.jpg` 是当前明确的图片类型；必须具有 PNG 或 JPEG magic。历史截图允许扩展名与实际 PNG/JPEG 编码不一致，但会计数，不允许伪装文本静默跳过。
- 脚本必须逐行核对本台账中的五组路径 + 规范化哈希，防止人类台账与机器例外漂移。
- 只读执行，前后 Git 状态必须一致。
- freeze、历史报告和临时镜像不随活动文件修复。
