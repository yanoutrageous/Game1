# I3 Base 原始来源基线

本目录是用户在 I3 明确授权纳入仓库的原始策划与美术来源基线。它不是运行时
资源目录，也不改变 Godot、当前代码或产品契约的事实优先级。

## 目录

```text
sources/base/
├─ 原始策划案/       # sources.zip 中 sources/docs/ 的 25 份原件
├─ 美术素材/blobs/   # art/draw 成员按 SHA-256 唯一保存的内容对象
└─ manifests/        # 原件、别名、排除项与统计
```

## 保留与去重说明

- 原始策划案保持来源文件名和完整正文，默认保持源字节；不得删减、摘要替换或改名。
- 美术按内容 SHA-256 去重。一个 blob 可以对应多个原路径；所有路径均保留在
  `manifests/BASE_ART_ALIAS_MANIFEST.csv`，因此去重不丢来源身份。
- 每个 canonical/alias 行都说明来源层级、保留理由、许可、审核、运行时准入和消费者。
- `sources/draw/Art.zip` 是内容已在外层存在的内嵌重复压缩包，不再次保存；其
  archive 路径、hash 与排除理由仍保留在 `SOURCE_ARCHIVE_INVENTORY.csv`。
- `sources/docs_governance/` 是复制型历史治理快照，不是原始策划案；不重复导入正文，
  但全部成员身份仍在 archive inventory 中可追溯。
- `pending_review`、`pending_verification` 和 `not_admitted` 是真实状态。目录名包含
  `selected` 或 `game_ready` 不会自动升级这些状态。

## 运行时边界

Base 入库只证明来源保存与可追溯。任何图片进入 Godot production 前仍必须记录：

```text
source member + source SHA
derivative transform + output SHA
license/review decision
runtime path + manifest/runtime key
actual consumer
visual validation + rollback
```

缺少对应语义状态（例如开箱状态）的资源必须阻塞该状态的最终验收；不得用其他状态
贴图、色调或缩放伪装。

## 可复现导入

```powershell
python .\tools\i3\import_base_sources.py `
  --archive <workspace>\sources.zip `
  --repo-root (git rev-parse --show-toplevel) `
  --mode verify
```

导入脚本锁定 archive SHA，拒绝其他压缩包冒充本基线。`audit` 只计算计划，`import`
只创建缺失或字节一致的目标，`verify` 以原 archive 验证精确内容。提交态/CI 不依赖
工作区外压缩包，使用：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i3\validate_i3_base.ps1 `
  -RepoRoot (git rev-parse --show-toplevel)
```

该门从已提交 manifest 重新计算 25 份策划与 1012 个美术对象的 SHA，并验证 1407
成员、395 alias、处理状态和意外文件。
