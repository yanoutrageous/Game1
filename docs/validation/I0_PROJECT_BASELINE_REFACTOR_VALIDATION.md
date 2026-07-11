# I0 Project Baseline Refactor Validation

文档状态：I0.7 最终验证记录
阶段状态：`CLOSED`
总体收口：`CLOSED_WITH_RECORDED_SAFETY_NONCONFORMANCE_AND_LIMITATIONS`
最后更新：2026-07-11

## 1. 中文摘要

I0.0–I0.7 的批准范围已经执行并收口：四个确认缺陷已修复，`RunScene` 的最小职责提取保持五组快照逐字一致，活动仓库已原子迁移，恢复后的最终隔离套件为 12/12，Git 与业务污染守卫通过。

I0 不能写成无条件 PASS。可见验收只覆盖主菜单、出发整备、局内 HUD 与 M / Q / G / T 关键 UI 响应；移动、撤离完成、结算和返回路线未观察。更重要的是，可见 Godot 启动在 `D:\AGAME1` 外新增 / 改写了两个 AppData 日志，并在工作区内改写了受保护业务文件。业务文件已从可信 preimage 精确恢复并复验，但已经发生的范围外写入不能撤销或改写，因此安全边界结论为 `NONCONFORMING_RECORDED`。

## 2. 阶段证据

| Phase | Status | Commit / evidence |
| --- | --- | --- |
| I0.0 freeze | PASS | `D:\AGAME1\_i0_freeze\I0.0_d4168a6111cfd30be28880301ded52be2d32f462` |
| I0.1 toolchain | PASS_WITH_RECORDED_LIMITATION | `b52150d`, `f797b7f`; `I0.1_TOOLCHAIN_CURRENT.json` |
| I0.2 characterization | PASS | `f3e9fa0`; isolated harness and pollution guards |
| I0.3 repairs | PASS_REMEDIATED_WITH_NOTES | `75e275b`; four confirmed red contracts remediated |
| I0.4 tests first | PASS | `ab86626`; five RunScene cases established before extraction |
| I0.4 extraction | PASS_WITH_NOTES | `de8c66f`; pre/post snapshots identical |
| I0.5 atomic relocation | PASS_WITH_FOLLOWUPS | `ba467dd`; move report and two repeat runs |
| I0.6 governance | PASS_WITH_RECORDED_LIMITATIONS | current docs, integrated encoding gate, external pointers |
| I0.7 final acceptance | CLOSED_WITH_RECORDED_SAFETY_NONCONFORMANCE_AND_LIMITATIONS | restored final suite, limited visible smoke, byte-level dirty recovery, handoff |

## 3. I0.0 冻结

冻结基线为 `d4168a6111cfd30be28880301ded52be2d32f462`。284 / 284 artifact hash、121 refs、index、stash、原始 12 个工作树文件和 isolated `git fsck` 均核对；bundle 可读取 174,628,791 字节，manifest SHA256 为 `8E6D...390A`。

冻结期间失败尝试留在 failed 证据目录；源仓库未因失败尝试发生变更。

## 4. I0.1 工具链

```text
version: 4.6.3.stable.official.7d41c59c4
archive_sha256: e39986a178d585ce7ac198fb8de6ea436366dc0cc00e594810c2e3e104c04b90
main_sha256: ef90e929ba1a6a4322860285d97f40f4aa349c90329a91b0e8b55b8df0f4cb00
console_sha256: 63b3b2208819714c9677fbfdd8217c5b7dee8ecf5f383502e826bc9e2227ff5a
```

签名者和时间戳存在；本机证书链为 untrusted root。因此工具链结论是 `PASS_WITH_RECORDED_LIMITATION / CHAIN_UNTRUSTED_RECORDED`，不是完整证书链 PASS。

## 5. I0.2 / I0.3 特征测试与缺陷修复

基线先确认四个 expected red：

1. `SAVE_ABANDON_COUNT`
2. `CSV_ASSET_MANIFEST_WIDTH`
3. `INPUT_REQUIRED_ACTIONS`
4. `DEBUG_SURFACE_TOGGLES`

修复后 `I0.2_20260711T031319734Z_2e1235d4.json` 为 `PASS_WITH_NOTES / PASS_REMEDIATED_WITH_NOTES`，7 / 7 当时运行器通过、0 blocking、14 个退出清理提示。修复没有改变 179 个资产 ID 的数量和顺序。

## 6. I0.4 RunScene 行为等价

提取前 `RunScene` 1,768 行；提取后 1,668 行，新 seeder 108 行。五个案例覆盖：

| Case | Revealed | Scanned | Flagged | Debug floor / inventory |
| --- | ---: | ---: | ---: | ---: |
| contract | 1 | 0 | 0 | 0 / 0 |
| no_flags | 1 | 0 | 0 | 0 / 0 |
| modal | 1 | 0 | 0 | 2 / 0 |
| full_map | 100 | 0 | 1 | 0 / 0 |
| sparse_map | 5 | 3 | 1 | 0 / 0 |

所有案例 `save_files_created=[]`。pre `ea1c2445` 与 post `27031993` 快照逐字差异为 0。modal 的两个命令最终都进入 floor 而非 backpack 是既有内容语义债，I0.4 只保持行为，不擅自修正。

## 7. I0.5 原子迁移

```text
source: D:\AGAME1\_repo_cache\Game1_work
target: D:\AGAME1\active\Game1_work
primitive: System.IO.Directory.Move
copy_delete_fallback: false
files: 8,135
directories: 577
bytes: 486,706,028
tree_fingerprint_sha256: 20F83ADCCB072B6AC258F86042E8DF71298D7096CD945524FB78F7A5131C4C51
```

文件 / 目录 / 字节 / 指纹、根 ACL、属性、HEAD、branch、status、index、stash、refs 和 fsck 前后相同。当前旧路径不存在，新路径存在，目标树 reparse count 为 0。

MOVE JSON 没有把 `target-before-absent`、所有 preflight reparse / filesystem 类型等前置检查逐项序列化；这些由迁移前记录和独立只读终审补强。此项是证据完整性限制，不影响已核对的原子移动结果。

迁移后两次报告：

| Report | SHA256 | Result |
| --- | --- | --- |
| `I0.2_20260711T044908553Z_9d24aba9.json` | `A22CFE4E6262497681FE1E6FFD63363A1DA1C13A0527ED958CCDC175A442246D` | 12/12, 0 blocking, 24 cleanup, pollution PASS |
| `I0.2_20260711T045314232Z_7792d2cf.json` | `A24A046C561BA1987A26350D8B3994B9BDC922F22F0917D9283BFFA43EDABE7B` | 12/12, 0 blocking, 24 cleanup, pollution PASS |

两次的 runner ID / status、static checks、business SHA `9175B56...` 和五个 I04 snapshot 全部一致。

ART-13 exit 0、28 warning。ART-14 exit 1、5 error，其中 `run_surface.gd` 被按 unexpected dirty 与 script dirty 双计，另外是两张既存截图和 `tools/__pycache__`；均来自 I0 前状态，不是迁移回归。

## 8. 原始脏状态保护

所有记录的高风险门前后、测试报告取样点与阶段收口点 staged count 均为 0；本地提交使用过精确暂存，但原始 12 项从未被混合暂存。stash 始终为 `a608462968d7913a5bf63c376c186fe1df89d2db`。原始 12 项：

```text
Godot/GraytailGodot/data/assets/asset_manifest.category.translation
Godot/GraytailGodot/data/assets/asset_manifest.import.translation
Godot/GraytailGodot/data/assets/asset_manifest.license.translation
Godot/GraytailGodot/data/assets/asset_manifest.linked.translation
Godot/GraytailGodot/data/assets/asset_manifest.note.translation
Godot/GraytailGodot/data/assets/asset_manifest.replacement.translation
Godot/GraytailGodot/data/assets/asset_manifest.usage.translation
Godot/GraytailGodot/project.godot
Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd
docs/art/validation/art21r2/screenshots/slice6/godot_result_zujian3_modal_controls_pass29_smoke.png
docs/art/validation/art21r2/screenshots/slice6/godot_result_zujian3_modal_sections_pass31_smoke.png
tools/__pycache__/
```

I0 变更必须与上述用户状态分开暂存和提交。

## 9. I0.6 文档与编码治理

- 当前权威路径已切换到 `D:\AGAME1\active\Game1_work`。
- G40 和更早的 validation / handoff / project_governance 保留为时间点证据。
- D 根六个当前 / external pointer 记录在 `D:\AGAME1\reports\i0\I0.6_CURRENT_POINTERS.json`。
- 25 个 Godot docs registry path 已切换；25 / 25 hash 当前匹配。
- 兼容 G40 的路径扫描为 `PASS_WITH_NOTES`：162 个已分类历史 / legacy mapping 命中，`unknown_count=0`；拓扑验证仍为 `PASS_WITH_NOTES` 且 warning count 0。
- 文档清单严格门得到 `PASS_WITH_RECORDED_LIMITATION`：804 项中 376 个文本严格扫描、428 个已知图片 magic 验证，恰好 5 个路径 + 规范化哈希历史异常，0 个未知或新增异常，台账契约匹配且 Git 状态不变。340 张历史截图使用 `.png` 扩展名但具有 JPEG magic；门禁未做完整图片解码，它们只被计数为证据格式债，不当作文本或运行时资产错误。
- 三个损坏导航 README 不做非审计覆盖；有效导航改由严格 UTF-8 的 `I0_INDEX.md` companion 承担。
- 编码门已接入 `invoke_i0_tests.ps1` 的 `allCasesPass` 和 JSON 总报告。集成正向报告为 12/12、0 blocking、24 cleanup、encoding limitation 1、pollution PASS。
- 集成负向 canary 使用临时未知 `.bin` 文档，主套件在任何 mirror / Godot runner 前以 `Document encoding gate failed` 退出；0 runner，污染守卫仍 PASS。canary 随后由创建者删除，未留在工作树。

## 10. 安全偏差与不符合记录

### 10.1 I0.4 历史偏差

I0.4 的一次 clean-clone 历史 G37 验证中，旧验证器绕过 I0 工具链选择了 `D:\Godot\Tools\...` 的 Godot，并挂起。相关命令行指向 I0 clean clone 的进程全部终止，复核剩余数为 0。

只读审计在已检查的 `C:\Users\33682\AppData\Roaming\Godot\app_userdata\GraytailGodot` 范围内确认 logs 写入，未见该事件窗口的 save / profile 变化；这不能推出整个外部文件系统没有其他写入。后续处置没有删除或修改已发现的范围外日志，也没有修改 `D:\Godot` 内文件。

纠正措施：之后的 headless 自动化只允许通过 I0 harness、项目本地固定二进制和 `D:\AGAME1` 内隔离 APPDATA / `user://`。

### 10.2 I0.7 可见启动不符合项

I0.7 使用 `D:\AGAME1\tools\runtimes\godot\4.6.3` 的固定二进制做可见编辑器 / 游戏烟测。虽然编辑器数据写入了工作区内的 self-contained 目录，游戏日志仍写入：

```text
C:\Users\33682\AppData\Roaming\Godot\app_userdata\GraytailGodot\logs\godot2026-07-11T14.24.49.log
created / written UTC: 2026-07-11 06:24:49
bytes: 12,238
sha256: 73C4D9BC9E5DC1B32F63D30703192AA5D7313B5C03166DD3FE445B20806DD7A2

C:\Users\33682\AppData\Roaming\Godot\app_userdata\GraytailGodot\logs\godot.log
last written UTC: 2026-07-11 06:24:50
bytes: 262
sha256 after run: 4B4304849DA42A212A647937193A2005EEF936EF25EBBAC9FD8BAD582C86713F
```

这些文件没有被删除、恢复或再次修改。同期未发现 save / profile 写入。该事件违反“不得修改 `D:\AGAME1` 外文件”的执行边界，所以本验证不能使用 `PASS_WITH_RECORDED_DEVIATION` 弱化为一般提示；必须保留 `SAFETY_NONCONFORMANCE`。

可见启动还在项目内触及 Godot 生成物，并改变 8 个业务指纹路径：2 个受保护 tracked 文件、5 个 ignored translation 和 1 个新增 ignored UID。恢复动作仅发生在 `D:\AGAME1` 内：

- `project.godot` 恢复到启动前 post-I0 preimage：7,535 bytes / `CD7C9662E78D0B2EBBB660CD238E1C8E47E9D11D50020F98A811CDD186DE3D46`。
- `asset_manifest.note.translation` 从 I0.0 dirty raw 恢复：25,897 bytes / `1C23005E798EA61F0768616218E0CDFD617B3A81CAD3B5DC2215969EE76B3A40`。
- `presentation`、`source`、`state`、`theme`、`variant` 五个 ignored translation 从五组独立早期镜像一致的 preimage 恢复。
- 可见启动新增的 `scripts/core/run/art21r2_run_smoke_seeder.gd.uid` 已删除，恢复其启动前“不存在”状态。
- 原始 12 个 status 路径成员全部保留；其中 11 / 12 与 I0.0 dirty raw 字节相同。`project.godot` 因 I0.3 合法加入 Q / G / T InputMap，不能与 I0.0 raw 相同；它已恢复到可见启动前的 post-I0 preimage `CD7C9662E78D0B2EBBB660CD238E1C8E47E9D11D50020F98A811CDD186DE3D46`。5 个 ignored translation 也匹配 I0.5 prehash。

七个 `.godot` editor / import cache 内容变化与若干相同内容的 mtime 变化没有伪装成业务不变；它们是被主套件明确排除的本地生成缓存。`D:\AGAME1\tools\runtimes\godot\4.6.3\editor_data` 新增 769 个文件、33 个目录、4,990,377 bytes，全部位于允许的工作区内并保留。以后在当前安全约束下，不再授权直接可见启动，除非先有能实证隔离游戏日志的启动门。

## 11. 当前报告哈希

| File | SHA256 |
| --- | --- |
| `I0.1_TOOLCHAIN_CURRENT.json` | `2F63AA63A4B090B29D6151B8B33020CA31FCBC0B3AAD3F75C4BA4B7F6DF74840` |
| `I0.2_20260711T031319734Z_2e1235d4.json` | `DC05C221A0B07E615ECD27059A34B3C114AC6E555A7023A04D32753531F92C32` |
| `I0.2_20260711T040100675Z_ea1c2445.json` | `DC61D334FAA4F8138DE454498B0D90E75847F088DA19A88F4F9256132AE25E5C` |
| `I0.2_20260711T041436105Z_27031993.json` | `8EC236020712FAB61181B08CC5BA7BEDFFECB75FBDA1AC0420F9E4F474089299` |
| `I0.5_20260711T044519237Z_15fb88fe_MOVE.json` | `D0C52F3FFBDE27B51AF8FB2A70EC181F5E24A781FAFADD264A4CE19C54528D16` |
| `I0.6_CURRENT_POINTERS.json` | `3FC62C3B06DF5B437B771E9D3AC6062496CF4F20339A31F40A677CC2797721F9` |
| `I0.2_20260711T060154836Z_3f271a48.json` | `4FE5B1AA0F0F4FB793EC7E751F7550365281A860155290A5C1E4D7BDF4BFFF54` |
| `I0.2_20260711T060307627Z_2827a9c2.json` | `9EEE3B857A0DBBEA961DA35BDA1F29B66BF48BB18FB3F84135DEE0BD79F2E111` |
| `I0.2_20260711T064535471Z_5b55f8c8.json` | `6868337E7E51DB03BA083725914165D6D7456F017252823C866939CF4B98782F` |

## 12. I0.7 恢复后自动化验收

```text
report: D:\AGAME1\reports\i0\I0.2_20260711T064535471Z_5b55f8c8.json
report_sha256: 6868337E7E51DB03BA083725914165D6D7456F017252823C866939CF4B98782F
validated_implementation_head: d34f869e85993704ca4091b26f9e40a39795c860
overall: PASS_WITH_NOTES
characterization: PASS_REMEDIATED_WITH_NOTES
runners: 12/12
blocking_diagnostics: 0
cleanup_diagnostics: 24
document_encoding: PASS_WITH_RECORDED_LIMITATION
pollution_guard: PASS
git_before_after_unchanged: true
business_before_after_unchanged: true
business_file_count: 656
business_fingerprint: A344034211ACD8299E1FE3F1CDED47A80D58815B4D77D9E6B312A4A0569D0928
protected_status_membership: 12/12
frozen_dirty_raw_byte_identical: 11/12
project_godot_post_i0_preimage_sha256: CD7C9662E78D0B2EBBB660CD238E1C8E47E9D11D50020F98A811CDD186DE3D46
staged_count: 0
stash: a608462968d7913a5bf63c376c186fe1df89d2db
```

closeout 文档落位后另行运行严格编码门：805 inventory、377 文本、428 图片 magic、5 个精确历史例外、0 error、Git 状态不变。该门验证最终文档树；上方 12-runner 报告明确验证 `d34f869...` implementation head，不声称运行于尚未产生的 closeout 文档提交。

06:30 报告（business fingerprint `BEAE62B8...`）和 06:40 报告（business fingerprint `58A09982...`）是发现污染与分层恢复过程的中间证据，不作为最终 implementation acceptance。06:45 报告从完整 A+B 恢复后的状态开始，并证明该状态在隔离套件内保持稳定。

## 13. 可见 / 人工观察矩阵

| 项目 | 结果 | 证据边界 |
| --- | --- | --- |
| 项目内 Godot 4.6.3 导入 `main.tscn` | OBSERVED | 真实可见编辑器窗口；无持久化截图 |
| 主菜单 | OBSERVED | 菜单与“出发探索 / 整备出发”入口可见 |
| 出发整备 | OBSERVED | 地图 / 目标与确认开始探索界面可见 |
| 局内 HUD | OBSERVED | 小地图、角色、底部操作栏与状态框可见 |
| M 地图 | OBSERVED | 区域地图覆盖层打开 |
| Q 背包 | OBSERVED | 回收背包面板打开 |
| G 地面回收 | OBSERVED | 地面回收物面板打开 |
| T 任务提示 | OBSERVED_WITH_NOTES | 底部任务提示发生可见响应 |
| 基础移动 | NOT_OBSERVED | 单次 W / Up 未观察到位移；不声明失败或通过 |
| 撤离完成 / 结算 / 返回 | NOT_RUN | 安全不符合项确认后停止继续可见运行 |
| 完整人工游玩 | NOT_CLAIMED | 本轮只是有限可见烟测 |
| 最终视觉 / 性能 / 发布 / CI | NOT_RUN | 非 I0 验收范围 |

## 14. 最终声明

- I0 阶段按批准范围关闭；不存在已授权的后续 active stage。
- 实现与隔离自动化结论为 `PASS_WITH_NOTES`，不是纯 PASS。
- 可见关键路由为 `PASS_WITH_NOTES / LIMITED_COVERAGE`，不是完整 manual playtest PASS。
- 安全边界为 `NONCONFORMING_RECORDED`；业务恢复不抹除范围外日志写入事实。
- 因此 I0 总体只能记为 `CLOSED_WITH_RECORDED_SAFETY_NONCONFORMANCE_AND_LIMITATIONS`。
