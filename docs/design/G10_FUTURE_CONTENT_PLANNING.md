# G10 Future Content Planning Notes

## Purpose

This document records what G10 intentionally leaves for later planning. It is not an implementation plan for new gameplay.

## Near-Term Follow-Up

- Stabilization and BUG-fix batches should start from `docs/bugs/G10_BASELINE_BUG_BACKLOG.md`.
- UI readability work should remain bounded to existing shell, InventoryPanel, GroundLootPanel, MapOverlay, ResultPanel, and pause/settings overlay.
- Art production planning should continue through manifest IDs, registry entries, fallback records, ThemeProfile, PresentationLayerEntry, and CharacterPresentationConfig.
- Responsive work should extend `UILayoutProfile` after desktop flow remains stable.

## Later Systems

- Complete MetaProgress remains a later phase.
- Deploy persistence remains a later phase.
- Complete long-term systems remain later phases: tasks, codex, achievements, profile progression, and research.
- Complete character and outfit systems remain later phases.
- Full warehouse economy, consignment, insurance, and lottery-pool systems remain later phases.
- Action combat and new gameplay loops remain later phases.

## Art Boundary

- Do not add loose images, audio, animation files, or untracked presentation resources.
- Do not bake Chinese UI text into images.
- Do not bind core gameplay directly to resource paths.
- Every art smoke or art intake item needs a manifest/registry/fallback record.

## Handoff Rule

Every future branch, closure, mainline promotion, BUG-fix batch, and runtime smoke should update a handoff using `docs/handoff/HANDOFF_TEMPLATE.md`.
