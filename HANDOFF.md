# Rat — Current handoff

Updated November 13, 2026. Read [AGENTS.md](AGENTS.md) for working agreements and [ROADMAP.md](ROADMAP.md) for the
single ordered backlog.

## Current checkpoint

- Local signing settings include `DEVELOPMENT_TEAM = N4WG592BBR` in two app build configurations. Preserve them
  and keep them out of commits. Check `git status` before relying on this snapshot.
- `ROADMAP.md` describes current behavior and ranks remaining work at Q1–Q22. R3's scoped plan is approved; the other
  implementation plans and outstanding product decisions still need approval.

## Resume from here

**R3: prevent duplicate workout saves** is in progress on `bugfix/prevent-duplicate-workout-saves`. Step 1 adds the
synchronous save guard, disabled editing, accessible “Saving…” button, and focused VM regressions. The user reviewed
and approved step 1 for a commit and pull request on November 13. The draft PR covers step 1; R3 remains incomplete.

Step 1's inline review comments are addressed: progress is named `saving`, and the VM owns the computed
`editingDisabled` and `saveButtonDisabled` policies. The remaining steps still require separate commits, with each
unstaged diff shown for review before committing. No merge is authorized.

The remaining approved steps are ID-based session replacement with persistence coverage and a coherent workout double;
relevant workout UI Back-selector repairs and UI verification; then final verification/documentation. Each step stays
under 500 changed lines. Product task 4's unsaved-workout protection and R5 deletion-error handling follow R3 and still
need scoped-plan approval.

Larger data-safety, accessibility, cycling, and workout-flow work follows before lower-impact convenience and
cleanup tasks. `ROADMAP.md` contains the ranks, effort assumptions, and dependencies. Product task IDs 1–5 remain
stable; the reminder migration/banner decisions are still open. The choice to save only completed sets remains
settled.

D1, the ignored-navigation-tap device retest, can accompany relevant UI verification without blocking unrelated
work. A confirmed navigation failure needs its own scope and impact/effort assessment.

## Verification needs

R3 step 1, including the review fixes, passed all 22 `ActiveWorkoutViewModelTests` on the dedicated iOS 27.2 `Rat-R3`
simulator (`212940A8-FA43-4731-9122-E33D7FA62AAB`) and an unsigned Release device build. Scratch mutations independently
confirmed that removing save completion or the in-flight guard fails the corresponding targeted test. Build data and
results are under `/tmp/rat-r3-*`; the scratch source copy is `/tmp/rat-r3-regression`. Runtime UI and spoken VoiceOver
checks for the new saving state are still unverified; UI verification follows the relevant Back-selector repairs in step
3. Real-device and older-runtime checks remain unverified.

The November 12 review checks used `/tmp/rat-r3-review-dd` and `/tmp/rat-r3-review-release-dd`; their test result
bundle is `/tmp/rat-r3-review-tests-20261112.xcresult`. Control-state assertions cover missing/loaded sessions,
saving, completed saves awaiting dismissal, and failure recovery.

Implementation tasks require scoped verification under `AGENTS.md`. Repair relevant R7 Back-button queries
before relying on affected UI tests. Existing UI and VoiceOver checks used an iOS 27.1 simulator and do not
establish real-device, older-runtime, or on-device migration behavior. Explicit on-disk persistence and migration
harnesses must remain on disk. Discover the current toolchain and simulator inventory when needed. The deployment
target is iOS 18.0 and Swift mode is 6.

## Persistence

`ModelContainerFactory` currently deletes store files and retries after any container-creation failure. A schema
change must prove that existing programs and workout history survive; a successful app launch alone cannot prove it.
The migration check and fallback decision are part of `ROADMAP.md` task 1.
