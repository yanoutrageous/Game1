# Known Unfinished Systems

文档状态：I4 活动阶段的当前未完成系统清单；I3R 事实为入口继承边界。
最后更新：2026-07-30

本文件阻止 foundation、preview、schema、runner、capture、定向 PASS 或“已生成截图”
被扩写为完整产品能力。I4 当前分支为
`codex/i4-production-interaction-convergence`；下列 I3R 事实是 I4 入口继承边界，
不代表 I4 已完成。

| 系统 | I4 入口继承事实 | 仍未完成 / 后续门 |
| --- | --- | --- |
| `RunScene` 职责 | 弹层 root、输入盾牌、私有 `_focus_stack` 与首选焦点遍历已提取到 `RunSceneModalController`，RunScene 不再暴露 raw stack；生产 `main.tscn` 接线和相邻回归 PASS；冻结树为 2974 行 / 161 函数，低于 2980 / 176 预算 | 仍是大型协调器；继续一次提取一个有特征测试的职责，但继续压缩行数不是 I3R 关闭的独立硬要求 |
| 弹层与破坏性确认 | Deploy 放弃/批售 stale 与 wrong-top 调用 fail closed；CommandBus 拒绝未确认放弃；Deploy-origin 结果层、焦点、返回和不误开新局已通过真实 `main.tscn` | 真实手柄与动态玩家签收仍未完成 |
| active-run persistence | 当前进程内 continue 可用；终局事务、保存失败恢复和幂等边界已覆盖 | 退出 Godot 后的局内恢复、版本迁移、崩溃恢复与跨进程幂等仍未实现 |
| 完整人工游玩 / 整合 UX | 标准生产旅程 20/20；局外生产旅程 22 checkpoint/22 PNG/36 次解析输入；教程与地图交互合并套件 PASS；最终生产预览 132/132、长期系统 125/125、状态画廊 12/12，269/269 张静态图已完成 Codex 复核；满包替换与放弃/自然失败终局已按当前树渲染 | 真实键鼠/手柄、动态长文本/DPI、减少动态、多终局和长局玩家签收未完成 |
| 教程地图模式 | 教程仍是 Deploy 目录的 `tutorial_5x5` 并沿 `standard_run` 启动；真实 `main.tscn` 首通/重播已证明 completion-only、零金币/物品/salvage 污染和正确返回路由；真实事件顺序覆盖 `trap→dice→altar→trader`，地图鼠标/`ui_accept` 走同一直接操作语义且一次执行，非阻塞提示可主动关闭 | 真实设备输入和动态玩家观感签收；不得恢复独立教程接口 |
| 角色动画、时装与移动手感 | 逻辑位移只走 InputMap 连续路径、拒绝移动无回弹；局内 Sprite2D 消费审计安全 `field_coat` 色型，未拥有/未知 catalog fail closed；受击色与 profile 组合并恢复 | 最终动画方案、生产获取/选择 UI、跨局外场景一致、真实时装素材与拥有/应用交易、目标设备动态手感及性能验收 |
| 门贴图、几何与交互 | 房型/方向贴图、裁切、轴点、显示尺寸、`body_rect`、近距提示、过门对齐与入口落点已由同一描述驱动并通过定向门；当前 I3R.4 战斗入口净空已复核 | 动态玩家观感与最终美术签收 |
| 空间转场与跨页最终视觉 | 主菜单、Deploy、长期系统和局内已有当前转场、焦点与图层安全边界 | 洞口/下层连续空间、全页面最终审美和目标设备动态视觉签收 |
| 玩家死亡表现 | 终局原因、损失/保全/带回信息已进入结果与档案；角色仍使用既有帧/姿态表达 | 独立死亡素材、最终动画与可见验收 |
| 仓库经济 | 原子批量售卖已实现：批选、总价、二次确认、幂等、全有或全无及保存失败回滚均有生产消费者 | 更深的整理/堆叠、扩容、保险、寄售、价格与长期经济平衡仍未完成 |
| 天赋与长期系统 | 当前生产合同为 6 模块/25 页面/58 个 runtime 资产，`gacha_runtime=0`，天赋使用独立 furniture；125/125 最终矩阵、100/125/150% 真实缩放及同场景截图哈希互异门 PASS；历史 ART23 保持冻结为 6×27 页面/58 textures，不充当当前生产门 | 动态玩家签收、更深分支、更多节点、重置/返还规则、长期数值平衡与内容 |
| 装备深度 | 基础装备效果与局内消费者可用 | 强化、耐久、随机词条、完整被动、奖励池与平衡 |
| 内容量 | M7 首轮地图/难度/内容与 I3R 当前特殊房体验可用 | Boss、精英、更深事件、更多奖励池、长期内容与完整平衡 |
| 抽奖 / 唯一物 / 外观 | 收藏与锁定状态可呈现；`field_coat` 只证明局内替换管线和审计安全色型基线，不伪装成独立时装资产或完整可写产品 | 真实获取/消费、唯一物规则、生产获取/选择 UI、跨局外场景一致、真实外观素材与拥有/应用交易 |
| Save future evolution | 未来 schema 降级保护、当前事务回滚与幂等边界存在 | 真正的未来 schema migration、跨版本恢复和发布迁移演练 |
| Cleanup diagnostics | 最终 `20260726T171400780Z_6f66cb6f` worktree full 为 96/96 PASS：53 plain、43 cleanup-diagnostic runner、0 hard failure；static、registration 与 pollution 均 PASS | cleanup 分类仍须保留，不能把 diagnostic runner 写成 cleanup clean；候选提交 exact-head/full 尚未执行 |
| Base 基线与运行时治理 | 1012 个 Base 对象映射到 178 行 crosswalk、175 条 runtime 路径和 149 个 runtime SHA；消费者证明为 47 direct + 108 dynamic + 6 staging-no-consumer + 17 no-production-consumer；1 个 promotion 有完整生产链；2 个跨语义 alias 组已作为开放替换债务登记 | 两个 alias 债务必须以独立语义素材、manifest 更新和独立视觉复验关闭；Base 不因归档或 crosswalk 自动获得运行时准入 |
| 历史快照与项目空间 | 当前归档为 123 snapshots（I3R 60）/6489 CAS objects；final-full 快照 V2 实际恢复和最终 verifier PASS；本轮 38/38 镜像事务裁剪、76 个瞬态目标和孤立 staging 清理完成；当前 `E:\AGAME1` 为 `9.1937 GiB / 56331 files` | 新增证据继续执行 archive → verify → V2 restore → transaction prune；以后最多保留一个活动验证镜像，禁止通配或手工删除；原始来源与任务绑定 worktree 仍受保护 |
| 历史 validator 漂移 | 当前长期系统以 `tools/i3r/validate_i3r_long_term_current.ps1` 验证 6 模块/25 页面/58 runtime 资产；历史 `tools/validate_art23_long_term_final_ui.ps1` 只绑定冻结的 ART23 6×27/58 证据；其余当前入口使用 I3R 工具并复用 I1 隔离执行器 | 历史 validator 不得充当当前生产通过门；仅在确需复用时单独校准，不得恢复已废止的独立教程接口 |
| 战斗房攻击与交互 | seed 13 生产 `main.tscn` 解析输入旅程已证明可见祭坛同源阻挡、近战确定性绕障、held 门单次拒绝/零 transition dispatch、敌预警、攻击期朝向锁定后释放、遮挡扇区视觉裁剪/未命中、无遮挡命中、结算和正常离房；当前 I3R.4 已复核入口净空及自然失败原因为 `runtime_combat_projectile` | 真实物理手柄、动态战斗手感和人工玩家签收 |
| 战斗房绝对性能与通用性能 | 1/3/5 敌人与弹丸 workload、攻击判定契约、生产战斗旅程和 headless CPU 基线已有证据 | 目标 GPU/FPS、可见掉帧、内存、真实设备与长局稳定性仍未验收 |
| CI | 既有 GitHub Actions quick 仅是历史证据 | I3R 当前候选的远端 full、目标平台导出与 artifact gate 尚未建立 |
| 导出 / 发布 | 未建立为当前能力 | target export、package、smoke、release、exact-head/full 与远端 SHA 一致性 |
| 最终美术 / 音频 | 像素字体链、材料安全区、登记效果音与生产反馈路由已有实现 | 全页面人工视觉、目标设备混音/响度、最终动画和整体玩家审美签收 |

I3R quick 或定向 PASS 只证明登记契约；最终状态画廊 12/12、生产预览 132/132、长期系统 125/125、标准旅程 20/20、局外旅程 22/22 和教程合并套件仍只证明相应机器/渲染证据。`PASS_WITH_VISUAL_REVIEW_REQUIRED` 与 269/269 Codex 静态复核不构成真实设备或动态人工玩家签收。最终 worktree full 已 96/96 PASS，空间重收口也已完成；用户已授权 exact-head/full 与 Git 交付，真实设备、目标 GPU 长局和人工玩家签收仍未完成，因此 I3R 保持 `ACTIVE / EXTERNAL_ACCEPTANCE_PENDING`。原始 `sources.zip`、Base 原始策划案、Base 素材和运行时素材属于基线或生产来源，不得作为缓存清理；任务绑定 Git worktree 也不属于快照缓存。
