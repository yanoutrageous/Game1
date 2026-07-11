# Handoff I0 Project Baseline Refactor

文档状态：I0 最终交接
阶段状态：`CLOSED`
总体收口：`CLOSED_WITH_RECORDED_SAFETY_NONCONFORMANCE_AND_LIMITATIONS`
关闭日期：2026-07-11

## 1. 基线身份

```text
workspace_root: D:\AGAME1
active_repo: D:\AGAME1\active\Game1_work
godot_project: D:\AGAME1\active\Game1_work\Godot\GraytailGodot
branch: i0/project-baseline-refactor
source_head: d4168a6111cfd30be28880301ded52be2d32f462
code_and_path_baseline_head: ba467dd2afdfd517ce798b9d674742891face4b7
validated_implementation_head: d34f869e85993704ca4091b26f9e40a39795c860
toolchain: Godot 4.6.3.stable.official.7d41c59c4
upstream: none
authorized_next_stage: none
```

## 2. 已交付

- I0.0：冻结原始 Git、refs、stash、index、12 项 dirty raw 和可恢复 bundle。
- I0.1：把版本与 SHA 锁定的 Godot 4.6.3 安装到 `D:\AGAME1\tools\runtimes\godot\4.6.3`。
- I0.2：建立 fail-closed 路径防护、隔离镜像、用户目录隔离、污染守卫和统一报告。
- I0.3：修复 `abandon_count`、RFC4180 CSV、Q / G / T InputMap、DebugGate 四个确认缺陷。
- I0.4：先建立五组行为快照，再把 ART21R2 播种职责从 `RunScene` 提取到独立 seeder；快照逐字一致。
- I0.5：同卷原子迁移活动仓库到 `D:\AGAME1\active\Game1_work`，不使用 copy-delete fallback。
- I0.6：重建当前事实、评估、编码、阶段、验证和路径治理；历史证据不被批量改写。
- I0.7：完成恢复后的最终隔离套件、有限可见烟测、字节级污染恢复、安全审计和交接。

## 3. 最终自动化证据

```text
report: D:\AGAME1\reports\i0\I0.2_20260711T064535471Z_5b55f8c8.json
sha256: 6868337E7E51DB03BA083725914165D6D7456F017252823C866939CF4B98782F
overall: PASS_WITH_NOTES
characterization: PASS_REMEDIATED_WITH_NOTES
runners: 12/12
blocking_diagnostics: 0
cleanup_diagnostics: 24
encoding: PASS_WITH_RECORDED_LIMITATION
pollution_guard: PASS
git_unchanged: true
business_unchanged: true
business_file_count: 656
business_fingerprint: A344034211ACD8299E1FE3F1CDED47A80D58815B4D77D9E6B312A4A0569D0928
```

## 4. 可见观察边界

真实窗口中观察到：项目内 Godot 导入 `main.tscn`、主菜单、出发整备、局内 HUD、M 地图、Q 背包、G 地面回收、T 任务提示响应。

未观察 / 未运行：基础移动、撤离完成、结算、返回主菜单、完整分辨率矩阵、性能、发布和 CI。本轮没有持久化可见截图；它是会话内有限烟测，不是完整 manual playtest PASS 或最终视觉 PASS。

## 5. 安全不符合与恢复

可见 Godot 在 UTC 06:24:49–50 对 `C:\Users\33682\AppData\Roaming\Godot\app_userdata\GraytailGodot\logs` 新增一个 12,238-byte rotated log，并改写 262-byte `godot.log`。这是对批准边界的明确违反；恢复 / 后续处置没有删除或再次修改这些文件。在上述已检查的 GraytailGodot app_userdata 范围内，未见同期 save / profile 写入。

可见启动还改变 8 个业务指纹路径。恢复只在 `D:\AGAME1` 内执行：

- 两个 protected tracked 文件恢复到启动前 post-I0 / I0.0 raw preimage。
- 五个 ignored translation 从多个一致早期镜像恢复到 I0.5 prehash。
- 新增 ignored UID 恢复为“不存在”。
- 原始 12 个 status 路径成员全部保留；11 / 12 与 I0.0 dirty raw 字节相同，`project.godot` 恢复到含 I0.3 合法修复的 post-I0 preimage `CD7C9662...E3D46`。最终 business fingerprint 从污染态 `BEAE62B8...` 经分层恢复回 `A3440342...`。

七个 `.godot` cache 内容变化和 `D:\AGAME1\tools\runtimes\godot\4.6.3\editor_data` 的 769 个文件属于允许根内的本地生成状态，未被伪装成业务不变，也未做无依据删除。今后的可见 Godot 启动必须先证明游戏日志也被隔离到 `D:\AGAME1`；在此之前只使用 I0 headless harness。

## 6. 受保护状态

```text
git_status_entries: 12
staged_entries: 0
protected_status_membership: 12/12
frozen_dirty_raw_byte_identical: 11/12
project_godot_post_i0_preimage_sha256: CD7C9662E78D0B2EBBB660CD238E1C8E47E9D11D50020F98A811CDD186DE3D46
stash: a608462968d7913a5bf63c376c186fe1df89d2db
stash_touched: false
old_active_repo_exists: false
registered_worktrees: 1
```

12 项包括 7 个 tracked translation、`project.godot`、EOL-only `run_surface.gd`、2 张 untracked ART21R2 截图和 `tools/__pycache__/`。这些仍归用户所有，I0 没有清理、丢弃或混合提交。

## 7. 保留限制

- 24 条 ObjectDB / resource 退出清理提示仍是技术债。
- PE 签名者与时间戳可读，但本机证书链为 untrusted root。
- 五个历史 Markdown 文件保留精确 UTF-8 损坏 preimage；三个导航职责由有效 `I0_INDEX.md` companion 承担。
- 340 张历史证据截图使用 `.png` 扩展名但具有 JPEG magic；门禁没有做完整图片解码。
- `RunScene` 仍有 1,668 行。
- 长期系统、仓库经济、目标 / 奖励 / Pool、完整规则内容、最终美术、CI、导出和发布仍未完成。

## 8. 下一阶段边界

I0 不授权任何后续阶段。建议的下一批独立决策顺序是：

1. 建立可验证的可见 Godot 日志隔离启动门。
2. 建立最小 CI / release gate。
3. 完成真实 save / profile 往返、恢复和迁移。
4. 继续一次一个职责地缩小 `RunScene`。
5. 以可发布 MVP 为目标完成目标—奖励—局外成长和内容闭环。

任何下一阶段都必须由用户单独批准，并引用本 handoff、最终 validation 与 current state。
