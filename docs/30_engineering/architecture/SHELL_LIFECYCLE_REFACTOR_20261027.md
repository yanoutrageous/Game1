# AppShell lifecycle refactor implementation plan

> For agentic workers: use superpowers:executing-plans inline. The user explicitly waived repeated design approval and execution-choice questions. Continue through verification and a local commit; no push, PR or merge.

**Goal:** Make AppShell the sole owner of page creation, activation and snapshot delivery, reduce startup work, and remove obsolete RunScene page coupling without changing gameplay or player-facing routes.

**Architecture:** Keep the existing AppShell and NavigationTransitionCoordinator. A single page registry and construction path owns the three page instances; Main is created on startup, Deploy and LongTerm on first demand, then retained until shell release/rebuild. RunScene uses shell actions rather than holding page aliases or calling page internals.

**Tech stack:** Godot 4.6.3 / GDScript / existing I0 isolation and I1–I4 validation.

**Spec:** This document's design and constraints, the user's 2026-10-27 structural-refactoring request, and `I2_TARGET_ARCHITECTURE_AND_MIGRATION_PLAN.md`.

## Constraints and decisions

- Baseline is `49f4c5be6962793230f3d0a0337b33f6a01a8abe`; earlier optimization gains do not count.
- Preserve route prepare/play/commit ordering, single commit, cancel recovery, settings, hidden-page snapshot catch-up, meta-action provenance, focus, and retained page state.
- Preserve gameplay, economy, persistence, art, scenes and project configuration. No external framework or new dependency.
- Continue in the existing clean development branch `codex/performance-loading-20261027`, the user's sole daily work directory. No extra development checkout.
- Explicit page accessors may create a page for existing integrations; passive lifecycle/snapshot/result delivery must not construct unopened pages. Construction receives the current snapshot once; retained hidden pages continue to defer updates until visible.
- Keep script preloads initially: moving parse work into an interactive route is a separate tradeoff, not assumed to improve loading.
- Existing getters remain the presentation boundary; migrate tests that read RunScene aliases or assume every page exists at startup. Preserve their behavioral assertions and register every changed legacy test in I4's disposition audit.
- New and historical validation are separate. I4 remains externally blocked; historical cleanup diagnostics and absent UE source commit are not new regressions.

## Research actually read (2026-10-27)

| Repository / revision | Files read | Applicable lesson / limits |
| --- | --- | --- |
| [glass-brick/Scene-Manager](https://github.com/glass-brick/Scene-Manager/tree/bf3b1feff0e32421df43d6a7ac12e2cc69007171) | README, SceneManager.gd creation/replacement and pending-load paths, tests/test_scene_change.gd, project.godot | Prepare before commit; exactly one owner and instance; exercise ready/free/order and re-entry. Current project declares Godot 4.7, so do not install/copy into 4.6.3. Game1's Control pages already have a transition coordinator. |
| [godot-gdunit-labs/gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4/tree/b2d258e7914b04e11017a4b65469c9e08f7165d4) | README, GdUnitSceneRunnerImpl.gd ownership/cleanup/input, GdUnitSceneRunnerTest.gd real-input and condition-wait tests | Test actual scenes, owned versus borrowed lifetime, release and repeated entry. Current master v7 requires 4.7; README lists v6.1/6.2 for 4.6.3. Reuse Game1's runners rather than adding this dependency. |
| [JuanFdS/godot-refactors](https://github.com/JuanFdS/godot-refactors/tree/085c68c65b37ce02b54f1143f0853e9ff5dea2b5) | README, rust/src/refactorings.rs selection/scope transforms, rust/src/tests.rs inline/extract and round-trip cases | Explicit call/scope checks and regression fixtures before deletion. Experimental/incomplete parser through Godot 4.4, not an architectural framework or safe batch rewrite tool for 4.6.3. |

Also read [Godot 4.6 scene organization](https://docs.godotengine.org/en/4.6/tutorials/best_practices/scene_organization.html): parents own sibling coordination and injected dependencies. Remote files were read as evidence; no downloaded scripts were run or plugins installed.

## Review focus

1. First navigation creates its target before playback but cannot expose it or steal focus before commit.
2. Hidden/new pages receive the latest snapshot and settings once they become visible; passive updates do not create them.
3. Repeated entry reuses the same instance and selection; shell rebuild/release does not retain stale pages or signal connections.
4. Meta results go only to their originating existing page, and run-start/abandon actions retain the command boundary.
5. Startup savings may shift cost into first navigation; compare startup, first/repeated routes, hidden update, return from run, and resource release under identical settings.

## Task 1: Characterization and baseline

Files: existing `tests/i1_refresh_scope_runner.gd`; new report-only fixed probe under `D:/AGAME1/reports/restart_20261027/refactor/`; existing main handoff.

- [x] Run baseline preflight and preserve exact source identity.
- [x] Record three graphical fresh-process runs at 1280×720, seed 20261027, imported cache, same engine; no OS-cache flush claim.
- [x] Add real lifecycle checks: unopened pages absent after startup/passive snapshots; first request prepares hidden inactive target; re-entry preserves identity; update/hide/rebuild/free coverage. Observe expected failure against old implementation.

## Task 2: Unified owned-page lifecycle and host boundary

Files: `scripts/ui/app_shell/app_shell.gd`, `scripts/core/run/run_scene.gd`, the existing Deploy public action boundary if needed; directly affected legacy tests and navigation validators only.

Interfaces: `get_main_page()`, `get_deploy_page()`, `get_long_term_page()` ensure explicit access; `request_deploy_primary_action()` and `show_deploy_action_message(message)` let the host express actions without holding page instances. Passive loops iterate only constructed pages.

- [x] Replace three separate page assembly paths with a common registration/build/wiring path and lazy ensure operation; main-only startup, prepared hidden targets, settings before construction.
- [x] Route snapshots, activation and release through the owned registry; clear references on rebuild. Keep transition coordinator authoritative.
- [x] Remove three RunScene aliases and three unreferenced legacy entry callbacks; remove AppShell's unused placeholder builder and its unused drawing/button helpers only after complete reference search.
- [x] Migrate affected tests/validators to the real shell boundary while preserving behavior and failure checks; run targeted suites and repair regressions.

## Task 3: Verification, measurements, local delivery

- [x] Repeat the identical probe against the current worktree; report non-improvements and first-open tradeoffs.
- [x] Perform actual graphical navigation/reopen/return validation with bounded previews; do not claim full I4 acceptance.
- [x] Run fresh whole-change review, address material findings, then current worktree I1 full and I4 governance/static audit.
- [x] Preserve compact reports and source hashes; remove only this task's verified temporary mirrors/isolated environments. Keep normal `.godot` and all protected sources/evidence; never retry previously blocked cleanup paths.
- [x] Commit verified changes locally, update the existing handoff and daily entrypoints, verify clean status and recoverable baseline. No push/PR/merge. The resolved delivery commit and post-commit checks are recorded in the external handoff and final report.

## Progress

2026-10-27: research and call-site diagnosis complete; baseline preflight running. No production changes yet.

2026-10-27 implementation: the four expected eager-construction failures became PASS. First-snapshot preparation separately failed on missing markers, then passed after builders accepted initial snapshots. Ten targeted runners passed before that final initialization refinement; current lifecycle runner also passes non-default settings before first creation, cancel/focus restoration, retry reuse and rebuild/free. One test draft used a nonexistent settings method and emitted a script error despite its PASS marker; that draft is invalid evidence. The corrected runner uses real SettingsManager transactions and has no script diagnostics.

Independent read-only review found no Critical/Important issue; its settings/cancellation coverage recommendation is implemented. Preliminary three-run medians (candidate_2–4 versus baseline_1–3): construction 922.256→434.740 ms, engine-to-first-draw 5099→4117 ms, startup nodes 907→659, static bytes 139707603→125092943. First Deploy 108.832→170.781 ms and LongTerm 343.480→573.156 ms are slower; repeat routes and idle p95 are unchanged. These are loading tradeoffs, not a general frame-rate improvement. Candidate_1 was exploratory and is excluded.

Ruling: keep the existing sole daily checkout per the user's explicit preference; reuse this plan and the existing external PERFORMANCE_WORK.md rather than introducing a second progress system. No additional manager/class or remote framework was introduced. Current full/static and graphical validation are still pending at this checkpoint.

## User-directed preload refinement (same task)

The user subsequently requested that the usable main menu continue preloading later content. The adopted scope is background **resource** prewarming, with page nodes still created on the main thread on demand. This avoids moving a multi-hundred-millisecond page build into one deferred idle frame. The existing manifest `variant` groups provide Deploy-first then LongTerm priority through AssetCatalog/ContentDB/ContentDBAccess; no second asset database or generic scheduler is added.

- Start after a 250 ms delay from shell construction. Advance only while Main is active and no navigation transaction is busy. Settings, exit overlay, hidden shell and gameplay pause queue advancement; an already submitted engine request may still finish.
- Keep one low-priority worker outstanding. It calls ResourceLoader.load for a texture only; the main thread checks is_alive before wait_to_finish. Per frame collect at most one result and start at most one worker; a 1 ms check bounds queue skipping, not thread creation or the initial manifest scan.
- A requested page takes the foreground synchronous construction path immediately. Already constructed pages are skipped by later queue work; no duplicate page instance is produced.
- Keep successful resources owned by AppShell and release them on rebuild/exit. A pending worker is joined when finished by an independent static closure that retains the thread/tree/shutdown callback, never the freed shell. Successful and failed workers are both joined. A separate root.tree_exiting closure joins any still-running worker when the application exits; normal collection disconnects that closure.
- Initialization snapshots, visible-only updates of retained pages, command ownership and navigation transactions remain unchanged. Warming does not emit routes, change focus, mutate snapshots, or construct page nodes.
- Prewarm memory is measured after the queue has run; initial low memory is not presented as steady-state memory. GPU texture allocation is reported separately from static CPU memory.

Official sources actually read: [Godot 4.6 background loading](https://docs.godotengine.org/en/4.6/tutorials/io/background_loading.html), [thread-safe APIs](https://docs.godotengine.org/en/4.6/tutorials/performance/thread_safe_apis.html), and [ResourceLoader 4.6 implementation](https://github.com/godotengine/godot/blob/4.6/core/io/resource_loader.cpp) for request ownership. `load_threaded_get` can block unless status is ready; active scene tree and rendering node construction are not generally thread-safe. No global rendering-thread setting was changed.

Validation refinement: the first interrupted full run exposed settings pointer failures missed by the initial read-only review. New pages must be moved before overlays in sibling order because visual z order alone does not preserve Control input priority. The original I3R production journey reproduced seven failures, then passed all 22 checkpoints/37 inputs after `move_child(page, 0)`. A controlled ResourceFormatLoader and semaphore reproduced duplicate completion connections after repeated rebuild, and unreleased FAILED request tokens. Fresh static closures plus completed/failed collection made both cases pass. Expected error output is suppressed only inside the deliberately failed test I/O transaction and restored/asserted afterward.

Measurement sets are separate: original `49f4c5b` eager startup, preserved pure-demand sources in `refactor/ondemand_source`, and final resource prewarming. `prewarm_probe.gd` compares immediate clicks and 3000 ms menu residence, real focus-input response during residence, frame percentiles/max, target-visible time, CPU static bytes, GPU texture bytes, node/resource counts and release. Three repetitions per variant/wait/target; no concurrent Godot test run during these measurements. The earlier full run was deliberately stopped when this strategy changed and is not final validation.

Measured decision: after 3000 ms on Main, pure-demand versus final preparation medians are Deploy 173.259→117.141 ms and LongTerm 440.341→402.411 ms. Immediate click preparation remains about 172/439 ms; it cannot benefit from work that has not run yet. Final first-operable Main is around 4.1 s versus baseline around 5.2 s. Main keeps 659 nodes after resource warmup versus baseline 907. Warmed texture memory is 72.326 MB versus baseline 69.566 MB (pure demand 53.463 MB); this is an explicit memory-for-latency tradeoff. Menu p99 is about 20–21 ms across all variants; one final sample reached 47.934 ms. Three additional isolated traces did not reproduce a >25 ms frame: initial queue assembly was 5.385–5.503 ms and individual resource-process calls were below 1 ms. The isolated peak is retained as a limitation, not attributed to an unproven cause.

Later full-regression finding: run 20261027T083552499Z_8f3fcd58 accepted 103/104 runners but rejected I1_REFRESH_SCOPE for a new ObjectDB leak. This run is failed evidence, despite its lifecycle assertions passing. Verbose isolation found RefCounted with reference count 0. A 30-request standalone ResourceLoader reproduction, without AppShell, reproduced the same warning. Godot 4.6.3 publishes LOADED before the worker drops its internal LoadToken reference; collecting the user reference in that window can leave the worker's last unreference at zero without deleting the token. This inference is grounded in the exact [4.6.3 source](https://github.com/godotengine/godot/blob/4.6.3-stable/core/io/resource_loader.cpp) and local reproduction, not assumed from a different engine issue.

The final implementation uses a joined Thread around synchronous texture loading on that worker, avoiding the user-facing threaded-request token path. It follows the [Thread lifecycle contract](https://docs.godotengine.org/en/4.6/classes/class_thread.html). No scene nodes or settings are changed on the worker. Five consecutive lifecycle runs passed without diagnostics after this change; the scoped loader fixture also passed. The standalone shutdown probe quits with a worker pending and asserts it is joined at root exit (joined_root_exit_scoped); two earlier probe drafts had an overbroad fixture resource type and are invalid evidence. The fixture now recognizes only its synthetic extension.

Independent read-only re-review found no new important defect. Foreground loading of the same resource may wait for an existing worker, and application shutdown intentionally joins; neither is described as universally nonblocking. The prior prewarm numbers above are historical threaded-request measurements and will be superseded by the joined-worker comparison. Final static/full and updated performance measurements remain pending at this checkpoint. All 178 runtime crosswalk resource rows retain their semantics; only three consumer line references changed.

Final joined-worker performance is now measured in prewarm_comparison.json and loading_final_comparison.json: build 922.256→452.965 ms; first draw 5099→4135 ms. After 3 seconds, preparation versus pure demand is Deploy 173.259→114.507 ms and LongTerm 440.341→410.198 ms. Immediate LongTerm visibility and direct-host first LongTerm remain slower than eager baseline. Final menu maximum observed is 24.857 ms; the old 47.934 ms peak belongs only to the replaced request-token prototype. Two 400 ms mid-prewarm navigation cases commit and retain input response. Manual joined-worker validation covers Main→Deploy→LongTerm→Deploy→Main→settings dropdown and normal Alt+F4 exit without diagnostics.

Run 20261027T091451899Z_ee7b1b57 accepted 103/104. The new lifecycle test passed without diagnostics; the unchanged movement/appearance runner emitted PASS but retained 19 instead of its contracted 18 exit resources. Verbose isolation identified only sfx_click.wav / AudioStreamPlaybackWAV as extra, not a texture or Thread. Three unchanged 49f4c5b baseline runs retained 18. The production-case teardown previously waited four headless frames, which did not always allow the audio mixer to release the rejection cue before process exit. Teardown now additionally waits for that stream to leave ResourceLoader's cache, with a 2-second deadline and an explicit failure assertion. All original behavior assertions, the I1 manifest and the 18-resource cleanup contract are unchanged. Three targeted runs retain exactly 18. This added legacy-test edit is registered as file 21; a fresh full/worktree run is required. The eight production scripts and their measured hashes remain unchanged.

## Accepted delivery

The final full/worktree run `20261027T093657251Z_b6291d29` is PASS: 104 runners, 61 PASS, 43 accepted existing cleanup diagnostics and zero failures. Its pollution guard confirms all 2,368 business files unchanged throughout the run. Full report SHA-256: `EA2998F7CF433D5ECA045036955A3131CEA1A09A9830558EC1E8D6F3F24CA19C`. The final governance/static report is PASS, quality 12/12 and legacy assertions 21/21; SHA-256: `7D367A7D660E9A71C9E8CD2C652413851BA16D45312F85B3BC348852598F6EE7`.

All 23 changed code/test/governance files were byte-compared with the accepted full mirror. The eight production scripts also match the final joined-worker performance measurements. Only this plan's delivery closure was edited after the accepted run; the exception is explicit in `refactor/final_source_binding.json`.

The 475 retained evidence files were copied and individually SHA-256 checked before removing 16 explicitly inventoried temporary targets, including five I1 mirrors, isolated environments and temporary engine hardlinks. Logical removed bytes are 5,213,198,428 (hardlinks included); the normal active `.godot` cache remains. Earlier failed/interrupted reports and superseded request-token experiments remain historical evidence. The older blocked cleanup tails were not targeted.

Continue from `D:/AGAME1/reports/restart_20261027/PERFORMANCE_WORK.md`, with detailed results in `refactor/RESULT.md` and final source/Git/preservation checks in `refactor/final_delivery_verification.json`. This closure is a local development delivery, not I4 external acceptance. No further implementation or validation task remains within the authorized scope; there are no active review agents.
