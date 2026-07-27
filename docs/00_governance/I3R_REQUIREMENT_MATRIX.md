# I3R 玩家需求矩阵

文档状态：`ACTIVE`

基线权威：

- I3 历史关闭对象为
  `09aaafe283aa2e4c2f30708c5f88b89ebf7753eb` /
  tree `a077da34237dce5e4a6081d833efd939098b4641`；
- I3R 的 entry/base 为
  `35189aaf524157761d1ab9cdddc39e76baa0d7ca` /
  tree `82f100059add24ecb2c12e7fca0bfb17f3a95c50`。

状态口径：

- `IMPLEMENTED_PRODUCTION` 表示当前生产路径已有真实消费者且相关定向门通过；
- `CURRENT_FULL_JOURNEY_AND_PLAYER_PASS_PENDING` 表示当前工作树仍缺完整生产旅程、
  目标设备或人工玩家签收，不能据此宣布 I3R 完成。
- `PASS_WITH_VISUAL_REVIEW_REQUIRED` 只表示生产画面与元数据完整生成；Codex 总览复核、
  动态玩家签收和真实设备签收必须分开记录。
- `CANONICAL_IMPLEMENTATION_FULL_PASS` 只绑定通过该次 full 的实现快照；一旦后续业务或
  控制面发生修改，就必须再跑 final post-governance full，不能沿用为当前树终验。
- `MAIN_TSCN_AUTOMATED_JOURNEY_PASS` 只证明解析后的生产输入完成了对应路线；真实设备、
  动态手感和人工玩家签收仍需单独记录。

| 范围 | 必须结果 | 当前状态 |
| --- | --- | --- |
| 战斗攻击 | 有限输入缓冲；windup/active/recovery 中判定、扇区和角色贴图共享冻结朝向，恢复后才接受反向输入；可见障碍以同一合同裁剪命中与扇区视觉 | `TARGETED_PASS / MAIN_TSCN_OBSTACLE_JOURNEY_PASS / FINAL_WORKTREE_FULL_PASS / DEVICE_AND_PLAYER_PASS_PENDING` |
| 敌方攻击 | 预警、伤害半径、障碍和投射物/激光表现一致；近战敌人按确定性净空角点绕过祭坛并恢复无遮挡接近 | `TARGETED_PASS / MAIN_TSCN_WARNING_AND_MELEE_NAVIGATION_PASS / DEVICE_PASS_PENDING` |
| 角色运动与外观替换边界 | 无首键双路径、无拒绝回弹；逻辑位移只走 InputMap 连续路径；局内 Sprite2D 消费审计安全色型 profile，未拥有/未知 catalog 选择 fail closed；受击色与 profile 组合并精确恢复 | `TARGETED_PASS / IN_RUN_APPEARANCE_PIPELINE_PASS / ACQUISITION_SELECTION_UI_CROSS_SCENE_REAL_COSTUME_AND_PLAYER_PASS_PENDING` |
| 动画策略 | 帧动画/动画集只负责呈现并可替换；不得接管 fixed tick、命中、碰撞或存档；骨骼帧生成需单独风格与运行门，不作为默认补帧 | `PRESENTATION_BOUNDARY_IMPLEMENTED / PLAYER_ANIMATION_PASS_PENDING` |
| 输入与弹层 | InputMap 单一语义、键鼠/手柄提示、ESC 顶层归属、LIFO 与焦点恢复；Deploy 放弃/批售 stale 或 wrong-top 回调无副作用，放弃还须通过 CommandBus 显式确认门；Deploy-origin 结算进入可见结果层并取得焦点 | `TARGETED_PASS / PHYSICAL_GAMEPAD_PENDING` |
| `RunScene` 职责边界 | 弹层注册、输入盾牌、首选焦点及私有 `_focus_stack` 由 `RunSceneModalController` 负责；`RunScene` 不暴露 raw stack，生产 `main.tscn` 接线及相邻回归受架构门保护 | `TARGETED_PASS / 2974_LINES_161_FUNCTIONS_WITHIN_2980_176_BUDGET / FURTHER_EXTRACTION_NON_BLOCKING` |
| 音效与震动 | 9 个内部生成 SFX 经来源门准入；真实领域事件路由、防重、主/效果音量、设置回滚、无设备与 reduced-motion 安全 | `TARGETED_PASS / PHYSICAL_GAMEPAD_AND_PLAYER_MIX_PENDING` |
| 字体 | 玩家可见 UI（含设置/tooltip/悬浮窗/弹层）默认像素字体；CJK 缺字回退、许可和长文可读性完整 | `IMPLEMENTED_PRODUCTION / FINAL_132_CASE_MATRIX_PASS / CODEX_STATIC_REVIEW_PASS / PLAYER_VISUAL_PASS_PENDING` |
| 玩家文案 | 不显示内部 trigger、raw enum、英文工程消息或“操作反馈”等冗余前缀；同一失败原因跨结果/档案一致 | `TARGETED_PASS / FINAL_WORKTREE_FULL_PASS / PLAYER_SIGNOFF_PENDING` |
| 边框与文本 | UI-only 缩放、材料统一、逐素材九切、安全区和长中文零交叉 | `IMPLEMENTED_PRODUCTION / FINAL_132_CASE_MATRIX_PASS / CODEX_STATIC_REVIEW_PASS / PLAYER_VISUAL_PASS_PENDING` |
| 悬浮窗与视觉焦点 | 像素框停靠房间外围；避开玩家、交互对象、协议卡、底栏和主要房间焦点 | `IMPLEMENTED_PRODUCTION / CURRENT_I3R4_STATE_GALLERY_12_OF_12 / CODEX_SCOPED_VISUAL_REVIEW_COMPLETE / DEVICE_AND_PLAYER_SIGNOFF_PENDING` |
| 箱子/门 | 类型、状态、定向贴图、轴点、几何、碰撞和交互内容一一对应；门由同一房间图源与同一 `body_rect` 驱动呈现和交互 | `TARGETED_PASS / DOOR_TEXTURE_GEOMETRY_INTERACTION_SINGLE_SOURCE / PLAYER_PASS_PENDING` |
| 搜索/掉落 | 首次揭示、重访稳定、靠近显示、显式拾取和品质清晰 | `IMPLEMENTED_PRODUCTION / CURRENT_FULL_JOURNEY_AND_PLAYER_PASS_PENDING` |
| 地图 | UE 信息层级与反馈；保留 Godot KnownMap；地图像素材质统一；外点/Esc/右键关闭 | `IMPLEMENTED_PRODUCTION / POST_CANONICAL_PIXEL_MATERIAL_FIX / FINAL_WORKTREE_FULL_PASS / PLAYER_PASS_PENDING` |
| 背包 | 无伪空位、可滚动、负重居中、统一物品描述和可用操作 | `IMPLEMENTED_PRODUCTION / CURRENT_FULL_JOURNEY_AND_PLAYER_PASS_PENDING` |
| HUD/协议 | 玩家信息优先；八邻域真实周围雷险（排除当前格，unknown/0 明确）；动作提示来自真实输入上下文 | `IMPLEMENTED_PRODUCTION / CURRENT_FULL_JOURNEY_AND_PLAYER_PASS_PENDING` |
| 特殊房 | 战斗、雷房、事件和撤离具有清晰进入、反馈、收益与后果；战斗封锁门持续输入只提示一次且不重复 dispatch | `IMPLEMENTED_PRODUCTION / COMBAT_MAIN_TSCN_JOURNEY_PASS / OTHER_BRANCH_DEVICE_AND_PLAYER_PASS_PENDING` |
| 结果 | 成功/失败/放弃原因、带回、损失、salvage 和保存状态清晰；从 Deploy 放弃后结果层必须可见、可聚焦且不得误启动新局 | `IMPLEMENTED_PRODUCTION / DEPLOY_ORIGIN_RESULT_JOURNEY_PASS / CURRENT_FULL_JOURNEY_AND_PLAYER_PASS_PENDING` |
| 主菜单 | 文案/场景协调、锚点正确、空间转场连贯、设置真实生效 | `TARGETED_PASS / OUT_OF_RUN_MAIN_TSCN_JOURNEY_PASS / CODEX_SCOPED_VISUAL_REVIEW_PASS / DEVICE_AND_PLAYER_SIGNOFF_PENDING` |
| 出发探索 | 同页地图/难度双栏、仓库/申领/目标/摘要和常驻金币；藏品等级从权威数据读取，详情动作不得与中央收起控件争夺图层 | `TARGETED_PASS / OUT_OF_RUN_MAIN_TSCN_JOURNEY_PASS / CODEX_SCOPED_VISUAL_REVIEW_PASS / DEVICE_AND_PLAYER_SIGNOFF_PENDING` |
| 仓库批量售卖 | 多选/全选/总价/二次确认；整批原子、幂等、回滚与配置同步 | `TARGETED_PASS / CANCEL_THEN_CONFIRM_PRODUCTION_JOURNEY_PASS / CODEX_SCOPED_VISUAL_REVIEW_PASS / DEVICE_AND_PLAYER_SIGNOFF_PENDING` |
| 长期系统 | 统一视觉、详细信息、真实成长/三分支天赋规则和完整结果/角色档案；当前生产口径为 6 模块、25 页面、58 个运行资产，gacha 运行资产为 0，天赋使用独立 furniture；历史 ART23 的 6×27 页面/58 资产证据原样保留，但不是当前生产门；100/125/150% 必须产生真实且互异的生产截图 | `TARGETED_PASS / CURRENT_6_MODULES_25_PAGES_58_ASSETS / GACHA_RUNTIME_0 / DEDICATED_TALENT_FURNITURE / HISTORICAL_ART23_6X27_58_PRESERVED_NOT_CURRENT_GATE / OUT_OF_RUN_MAIN_TSCN_JOURNEY_PASS / SCALE_EFFECT_ANTI_SELF_PROOF_PASS / FINAL_125_CASE_MATRIX_PASS / CODEX_STATIC_REVIEW_PASS / DEVICE_AND_PLAYER_PASS_PENDING` |
| 教程 | 是 Deploy 地图目录中的 `tutorial_5x5` 模式，沿 `standard_run` 进入固定 5×5 教学内容；不得建立独立生产接口；四类事件按 UE 权重进入不同提示；地图单击/`ui_accept` 同源，非阻塞提示可主动关闭；1280×720/1920×1080 × UI 100/125/150 响应矩阵通过；且零正式成长污染 | `TARGETED_PASS / CURRENT_COMBINED_SUITE_PASS / UE_INTERACTION_ALIGNMENT_PASS / RESPONSIVE_2_RESOLUTIONS_X_3_SCALES_PASS / CODEX_SCOPED_VISUAL_REVIEW_PASS / DEVICE_AND_PLAYER_SIGNOFF_PENDING` |
| Base | 原件完整、精确去重、语义目录、许可、运行时准入和真实消费者交叉账；1012 个语义对象映射到 178 行 runtime 账、175 个 runtime 路径和 149 个 runtime SHA；1 条显式 promotion；消费者证明为 direct 47、dynamic 108、staging 6、无生产 consumer 17；2 组共享 alias 作为显式替换债登记 | `MACHINE_GATE_PASS / 1012_SEMANTIC_OBJECTS / 178_RUNTIME_ROWS / 175_RUNTIME_PATHS / 149_RUNTIME_SHAS / 1_EXPLICIT_PROMOTION / CONSUMER_DIRECT_47_DYNAMIC_108_STAGING_6_NO_CONSUMER_17 / ALIAS_DEBT_GROUPS_2 / PLAYER_ROUTE_SIGNOFF_PENDING` |
| 快速预览 | 生产页面矩阵、对象/特殊房/战斗状态画廊、教程及明确操作说明 | `IMPLEMENTED_TOOLING / FINAL_PREVIEW_132_OF_132 / FINAL_LONG_TERM_125_OF_125 / FINAL_GALLERY_12_OF_12 / CODEX_STATIC_REVIEW_269_OF_269 / DYNAMIC_PLAYER_REVIEW_PENDING` |
| 标准生产玩家旅程 | 固定 seed 的主菜单→洞口转场→Deploy→Run→撤离→真实保存失败重试→主菜单 | `PASS / 20_CHECKPOINTS / 20_SCREENSHOTS / FINAL_I3R4_RENDERED_EVIDENCE` |
| 局外生产玩家旅程 | 真实 `main.tscn` 经解析输入覆盖设置应用/取消/危险显示回退、Deploy 五页、仓库批售取消/确认、长期任务/天赋/档案与三级 Esc 返回 | `PASS / 22_CHECKPOINTS / 22_SCREENSHOTS / 36_INPUTS / CODEX_SCOPED_VISUAL_REVIEW_PASS / DEVICE_AND_PLAYER_SIGNOFF_PENDING` |
| 战斗房生产自动旅程 | seed 13 的真实 `main.tscn` 通过解析输入，证明祭坛同源阻挡、拒绝后移动恢复、近战自然绕障、封锁门单次拒绝/零 transition dispatch、敌预警、攻击期朝向锁定后释放、早按拒绝不耗回合、后段缓冲、遮挡视觉裁剪/未命中、无遮挡命中、结算与正常离房（64 inputs） | `TARGETED_PASS / REAL_PRODUCTION_INPUT_PATH / DEVICE_GPU_AND_PLAYER_SIGNOFF_PENDING` |
| 教程完成与重播旅程 | 真实 `main.tscn` 从 Deploy 目录进入 `tutorial_5x5`；完成只写 `tutorial_completed`，重播不再写入，金币、物品与 salvage 均为零，并按首通/重播规则返回；当前合并套件同时证明事件顺序、地图直接操作、弹层优先级与公开信息隔离 | `MAIN_TSCN_AUTOMATED_JOURNEY_PASS / CURRENT_COMBINED_SUITE_PASS / COMPLETION_ONLY / ZERO_META_POLLUTION / DEVICE_AND_PLAYER_SIGNOFF_PENDING` |
| Worktree 自动门 | 注册、静态、污染、cleanup 分类和 full 均绑定对应工作树快照；最终 `20260726T171400780Z_6f66cb6f` 为 96/96 PASS，53 plain、43 cleanup-diagnostic、0 hard failure；其后仅有治理文档终态回写 | `FINAL_WORKTREE_FULL_PASS_96_OF_96 / DOCUMENT_WRITEBACK_SEPARATELY_VERIFIED / EXACT_HEAD_PENDING` |
| 空间治理 | 最终归档为 123 snapshots（I3R 60）/6489 CAS objects；代表性 final-full 快照 V2 实际恢复两次校验通过；本轮 38/38 镜像事务裁剪、76 个瞬态目标与孤立 staging 清理完成；当前 `E:\AGAME1` 为 9.1937 GiB / 56331 files | `CURRENT_ARCHIVE_VERIFY_V2_RESTORE_PRUNE_AND_PHYSICAL_RECLOSE_PASS` |
| Exact-head 与交付 | 候选提交的 full、commit、push 和远端 SHA 一致 | `PENDING / NO_COMMIT_OR_PUSH_AUTHORIZATION` |
| 视觉矩阵与人工裁决 | 11 场景 × 4 分辨率 × 3 UI 缩放，加 25 页×5 分辨率长期系统和 12 状态画廊；逐图检查和动态玩家签收分离 | `FINAL_132_PLUS_125_PLUS_12_GENERATED / CODEX_STATIC_REVIEW_269_OF_269_PASS / PLAYER_SIGNOFF_PENDING` |
| 真实设备与可访问性 | 真实手柄、音频设备、震动和 reduced-motion | `PENDING` |
| 性能长局 | 目标 GPU/FPS、可见战斗房和长局稳定性 | `HEADLESS_CPU_BASELINE_PASS / TARGET_DEVICE_PENDING` |
