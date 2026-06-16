# G15 阶段总结

## 阶段目标

G15 目标是 Encounter Contract Foundation：在规则层建立 public/display encounter contract，并提供第一版 UI EncounterSlot adapter。G15 是 encounter framework foundation，不是完整遭遇系统。

## 实际完成

- G15-R3 新增 `EncounterContract` 和 `EncounterResolver` 作为规则层 public/display helpers。
- 通过 `RunQueryFacade` 暴露 `encounter_view_model` 和 `encounter_result_summary`。
- 新增 additive CommandBus command `select_encounter_option`。
- search/chest option 委托既有 `search_current_room()`。
- event option 委托既有 `select_event_option()`。
- G15-R4 增加 `RunSurfaceModel` display-only Encounter section。
- G15-R4 增加轻量 `RunSurface` EncounterSlot。
- G15-R4 增加从 `RunSurface.encounter_option_selected` 到 `_dispatch_command(&"select_encounter_option", payload)` 的最小 wiring。

## 关键提交

- `aca5b958a588879a16da97616484424da795da7f` `feat(godot): add encounter contract foundation`
- `1887385af81624ebcd84342ca765d75e6fbf20eb` `feat(godot): add encounter slot surface adapter`
- `e72d3a5dc4a57122d42f881f391f2b47389fcdad` `docs: close G15 encounter framework foundation`
- `a28ae4c0c96f0b964602fd6fe7b88fa254354763` `docs: mark G15 merged to main`

## 新增系统 / 修改系统

- 新增 Encounter public/display contract foundation。
- 新增 EncounterSlot UI adapter。
- 修改 CommandBus command surface，保持 additive。
- 不改变 `search_current_room`、`select_event_option`、`request_extract`、`confirm_extract` 语义。

## 验证状态

- `docs/validation/G15_ENCOUNTER_CONTRACT_VALIDATION.md` 记录 R3 rules contract、R4 EncounterSlot adapter、R5 docs-only closeout、deferred lottery boundary、fast-forward main merge status 和 no-runtime-PASS status。
- G15-R3/R4/R5 未运行 Godot/editor/game/import。
- 不声明 runtime PASS 或 manual playtest PASS。

## 明确未完成

- 未实现完整 combat rooms。
- 未实现 action combat。
- 未实现 lottery、out-of-run progression、MetaProgress、Deploy persistence、unique collectibles、warehouse、codex、appearance library 或 record systems。
- `lottery` 仅保留为未来 encounter type name。

## 后续承接点

- G16 在 G15 public encounter framework 之上加入最小 Monster/combat encounter foundation。

## 主要风险

- Encounter foundation 可能被误读成完整遭遇系统。
- UI adapter 可能被误扩展为直接读取 private rule state。
- `lottery` reserved type 可能被误读成抽奖系统已启动。

## 是否已合并 main

是。事实源记录 G15 R3/R4/R5 complete and fast-forward merged to main。

## 对后续路线的影响

G15 建立 public encounter snapshot 与 option command bridge，使 G16 可以只做 additive combat extension，并让 UI 不直接接触 TruthMap、Ledger、RunRuleService 或 RunContext private state。

## 事实来源

- `docs/PROJECT_BASELINE.md`
- `docs/ENGINEERING_STATUS.md`
- `docs/MILESTONES.md`
- `docs/validation/G15_ENCOUNTER_CONTRACT_VALIDATION.md`
- `docs/handoff/HANDOFF_G15_ENCOUNTER_FRAMEWORK.md`
- `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`
- Git commit log
