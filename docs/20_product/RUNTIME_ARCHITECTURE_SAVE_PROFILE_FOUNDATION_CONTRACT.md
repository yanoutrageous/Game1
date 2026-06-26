# G36 Runtime Architecture / Save Profile Foundation Contract

G36-R2 consolidates current M1 runtime architecture and adds the first save/profile foundation. It is an engineering stabilization stage, not a new gameplay-system stage.

## Scope

- MetaProgress fallback states are read-only. `parse_failed`, `future_schema`, `open_failed`, and other load fallback cases must not silently overwrite the original user save file.
- `SaveManager`, `SaveProfileManifest`, `SaveImportStaging`, and `SaveProfilePreview` define the profile path structure:
  - `user://saves/manifest.json`
  - `user://saves/profiles/<profile_id>/meta_progress.json`
  - `user://saves/profiles/<profile_id>/run_checkpoint.json`
  - `user://saves/profiles/<profile_id>/preview.json`
- Active profile path injection is supported through `MetaProgressAdapter.set_active_profile_path`.
- Profile import/export/switch APIs are bounded foundation APIs. Profile switching is blocked while a run is active.
- `RunScene` remains the current scene lifecycle and high-level orchestration owner, while helper files own debug lookup, meta commit, UI surface building, and route payload normalization.
- `GameKernel` remains a non-authoritative bootstrap placeholder.
- DeployPrep emits a bounded `RunStartConfig` / existing-route payload. Unsupported fields are recorded as `unsupported_config_fields` with a `fallback_reason`; no real RunBootstrapper is implemented.
- Debug panel and debug commands remain protected by `DebugGate` and `CommandBus`.

## Boundaries

G36 does not implement complete SaveManager UI, active-run persistence, runtime profile switching, a complete RunBootstrapper, real warehouse writes, objective/reward/pool systems, new gameplay content, or project/scene/resource metadata changes.

G36 validation is expected to run `tools/validate_g35_runtime_safety.ps1` and `tools/validate_g36_runtime_architecture.ps1`, plus Godot project-load/parser smoke when available. Parser smoke is not gameplay runtime PASS and is not manual playtest PASS.
