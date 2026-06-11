# Handoff Template

Use this template for every future phase, branch closure, mainline promotion, BUG-fix batch, and runtime smoke report. A handoff is not just a completion report; it is the minimum context needed for the next conversation to continue safely.

## Stage Identity

- Historical label:
- Formal name:
- Chinese name:
- Branch:
- Branch HEAD:
- Merged to main: yes/no
- Corresponding main HEAD:

## Current Fact Source

- Repo:
- Remote:
- Current branch:
- Main HEAD:
- Remote HEAD:
- Worktree status:
- Validation chain status:
- Primary docs to read next:

## Completed

- 

## Explicitly Not Done

- 

## Validation Results

- Static validation:
- Runtime smoke:
- Manual smoke:
- Known unverified items:

## Risks And Debt

- 

## Next Handoff Guide

- Recommended next step:
- Not recommended next step:
- Files or systems to inspect first:
- Decisions that need user approval:

## Safety Boundaries

- Do not modify old UE/Game.git.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not use `git rebase`, `git reset`, `git clean`, or `git stash`.
- Do not run Godot/editor/game/import unless explicitly authorized.
- Dirty whitelist: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.

## Instruction Templates

### Read-Only Audit

Audit `<branch-or-stage>` against `<requirements>`. Do not modify files, do not switch branches unless required for read-only inspection, do not push. Report findings, evidence, risks, and whether the branch is safe to promote or needs follow-up.

### Planning

Generate an execution plan for `<stage-name>`. Do not implement yet. Include precheck, dirty handling, scope, non-goals, validation, documentation, commit, push, and stop conditions.

### Direct Execution

Implement the approved plan for `<stage-name>`. Stop on unknown dirty, conflicts, validation failure, remote mismatch, or scope ambiguity. Commit and push only after validation passes and worktree is clean.

### Mainline Promotion

Promote `<branch>` to `main` by ordinary merge or fast-forward only. Do not rebase, reset, clean, stash, or force push. Run the full validation chain before pushing `main`. Confirm remote HEAD after push.

### BUG Fix

Create a narrow fix branch from current `main`. Reproduce or confirm the issue, fix only the bug, run relevant and full validations, document the fix, commit, push, and confirm remote HEAD. Do not add new features.

### Runtime Smoke

Run Godot/editor/runtime only when explicitly authorized. Check `git status` before and after. If Godot creates whitelisted side effects, list and handle them by explicit path only. Unknown dirty means stop and report.
