# DOC-GOV-003 Stage Process Minimal

Status: current governance rule.
Scope: stage planning, audit, execution, closeout, and thread continuation for G / ART / M / P work.
Updated: 2026-07-02.

## 0. 中文摘要

本文是阶段流程的最小规则，用于减少阶段编号膨胀、重复提示词和过度声明。

它不替代产品设计、工程契约、验证记录或 handoff。若本文与最新用户指令、当前 Stage Card、最新审计结论或仓库事实冲突，以最新指令、最新审计结论和当前证据为准。

## 1. Core Rule

Planning can only produce a `Stage Candidate`. A candidate becomes a formal stage only after scope review.

A formal stage must represent a meaningful state change for one line:

| Line | Valid stage evidence |
| --- | --- |
| G | repository governance, architecture boundary, validation system, release gate, branch state, or toolchain changes |
| ART | asset, visual, UI wiring, screenshot validation, art pipeline, or runtime screen changes |
| M | prototype, playable loop, player interaction, runtime state, success/failure condition, or playtest evidence changes |
| P | rules, design, process, decision basis, or product contract changes |

Single-point repairs are slices by default, not stages. A narrow task can become stage-worthy only when it closes a blocker, repairs a release gate, or produces reusable validation / pipeline / contract capability.

I0 is a one-time, user-approved independent baseline stage. It does not create a reusable new stage line; later G / ART / M / P stages inherit the I0 repository, toolchain, validation and claim baseline.

Stricter stage-specific rules win. If a Stage Card, audit verdict, or user instruction requires stronger validation, narrower paths, or per-slice audit, follow the stricter rule.

## 2. Scope Check

Every `Stage Candidate` requires a lightweight scope check:

```text
Scope: valid_stage / valid_slice / too_narrow / too_broad / blocked
Risk: low / high
Action: execute / bundle / split / audit / user_decision
```

Judgment:

- `too_narrow`: one field, one screenshot name, one minor validator clause, or one doc sentence, without closing a blocker.
- `valid_slice`: executable work, but it must belong to an existing stage.
- `valid_stage`: covers multiple slices or creates verifiable state change.
- `too_broad`: goal is valid, but it must be split into slices before execution.
- `blocked`: goal, boundary, risk, or evidence is insufficient.

A valid stage should normally satisfy at least two of these:

- Creates a reusable capability, validator, pipeline, contract, or layout rule.
- Crosses multiple systems, screens, documents, files, or process nodes.
- Closes a known blocker.
- Produces runtime, screenshot, test, log, diff, validation, or handoff evidence.
- Changes current project facts, not only conversation claims.

## 3. Four Phase Flow

The stage flow is fixed:

```text
Plan -> Audit -> Execute -> Audit and Closeout
```

### Plan

Human negotiation belongs primarily in Plan. The output is a short `Stage Card`, not an automatic declaration that the stage is accepted.

Required fields:

```text
Stage:
Line:
Goal:
Non-goals:
Scope:
Slices:
Risk:
Evidence:
Stop conditions:
```

### Audit

Audit has two levels:

- `scope_check`: required for every stage candidate.
- `risk_audit`: required before high-risk slices, unclear scope, commit, push, merge, deletion, move, archive, or dirty cleanup.

High-risk examples:

- Runtime path, Godot scene, project setting, asset import rule, or gameplay state changes.
- Delete, move, clean dirty state, alter git history, commit, push, merge, or release gate.
- Visual direction that has not been confirmed, or script validation passing while visible UI remains wrong.

Low-risk slices may execute directly, but they still need short evidence afterward.

### Execute

Execute by slice. Normal slice evidence should include:

```text
Slice:
Changed:
Validation:
Issue:
```

High-risk slice evidence should also include:

```text
Audit:
Allowed paths:
Forbidden scope:
Dirty/staged state:
Next gate:
```

Execution must not let an old prompt, old thread title, or historical stage summary override the current Stage Card.

### Audit and Closeout

Closeout audit should be factual and short:

```text
Scope: valid_stage / valid_slice / too_narrow / too_broad
Evidence: A/B/C/D + one-line basis
Claim check: accurate / overstated
Debt: none / non-blocking / blocking
Next: continue / audit / user_decision / release_gate
```

Evidence scale:

- A: runnable, interactive, visible, screenshot, video, replay, or manual smoke evidence.
- B: automated validation, script, log, test result, or headless runner output.
- C: document, handoff, governance record, source registry, or index.
- D: conversation statement only.

For visual, UI, playable, path-completion, or player-understanding claims, static scripts are not enough when the result is user-facing. Use Computer Use, screenshots, visible smoke, video, headless runner output, or equivalent evidence when available. If not actually run or visibly verified, do not claim that it passed.

## 4. Claim Control

Stage summaries must match evidence.

Examples:

- G stages can claim governance, validation, repository, or release gate progress. They cannot claim gameplay completion.
- ART stages can claim visual wiring, screenshots, layout rules, asset pipeline, or UI layer progress. They cannot claim core gameplay completion.
- M stages can claim only the playable loops actually verified.
- P stages can claim rules or planning clarity. They cannot claim runtime implementation.

Documents, contracts, handoffs, and validation records can prove governance or planning facts. They do not replace runtime implementation, UI behavior, asset wiring, or playable-loop evidence.

Every audit conclusion should include a `Claim check`. If claims are overstated, the stage must not close as written.

## 5. Context Recovery

Context recovery is required before:

- Starting a new stage.
- Switching line, stage, execution role, or audit role.
- Commit, push, merge, release gate, deletion, move, archive, or dirty cleanup.
- Any case where latest user instruction, Stage Card, audit verdict, branch, HEAD, origin, dirty state, or staged state is unclear.
- ART/UI work that depends on visual direction.
- M work that depends on playable or runtime state.

Minimum recovery checklist:

```text
latest user instruction
current Stage Card
latest audit verdict
git branch / HEAD / origin
dirty / staged / untracked state
relevant validation / handoff / current facts
visual evidence for ART/UI stages
runtime path and unfinished systems for M stages
```

Thread title and initial prompt are never authoritative. If they conflict with current facts, state that they are stale and continue from current evidence.

## 6. Chinese Monitoring

Chinese status updates are required at key turning points so the user can decide whether to intervene.

Send updates when:

- Starting execution.
- Waiting for audit.
- Audit passes or blocks.
- Completing a slice group.
- Starting or completing validation.
- Preparing commit / push / merge / release gate.
- User decision is needed.
- Closeout completes.

Recommended format:

```text
当前阶段：
正在做：
依据：
风险：
是否需要你介入：
下一步：
```

English should be kept for machine markers, paths, commit hashes, validator names, and PASS-style tokens when needed.

## 7. Prompt Deduplication

Do not paste long historical rule blocks into every execution prompt. Send only the stage delta:

```text
Stage:
Line:
Goal:
Must review:
Allowed:
Forbidden:
Risk:
Output:
Stop:
```

Long-term rules should be referenced by this document. Copy only changed or newly added rules.

## 8. Stop Conditions

Stop and return to audit or user decision when:

- A high-risk slice has not passed audit.
- The audit thread gives no explicit PASS / PASS_WITH_NOTES.
- Dirty / staged state cannot be explained.
- Branch, HEAD, or origin conflicts with the stage requirement.
- Latest user instruction conflicts with the Stage Card.
- Visible UI is clearly wrong even if scripts pass.
- Context recovery cannot confirm current goal, boundary, or audit verdict.
- Scope is `too_narrow` or `too_broad` and has not been adjusted.

Dirty-state rule: classify dirty state before escalation. Known generated/editor dirty may be cleared only by exact dry-run-approved paths. Unknown dirty, semantic dirty, staged dirty, external-path dirty, destructive cleanup, or dirty state that conflicts with the current Stage Card remains blocking and must go back to audit.

## 9. Minimal Review Rule

Read this document before:

- Planning a new stage.
- Auditing a stage plan.
- Recovering after long context or role transition.
- Commit, push, merge, deletion, archive, or dirty cleanup.

Ordinary continuous execution does not require rereading the full document every time; it requires following the current Stage Card and latest audit verdict.
