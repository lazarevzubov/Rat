# Rat — Current handoff

Updated October 31, 2026. Read [AGENTS.md](AGENTS.md) for working agreements and [ROADMAP.md](ROADMAP.md) for the
single ordered backlog.

## Current checkpoint

- No application implementation is in progress.
- Local signing settings include `DEVELOPMENT_TEAM = N4WG592BBR` in two app build configurations. Preserve them
  and keep them out of commits. Check `git status` before relying on this snapshot.
- Program CRUD/autosave, workout persistence and UI, autocomplete, keyboard dismissal fixes, empty Edit button
  handling, and autoscroll are implemented. `ROADMAP.md` distinguishes current behavior from requested changes.
- The October 29 project review and October 30 code-quality pass are documented under R1–R16 in `ROADMAP.md`.
  Related small quality items are grouped, including API/test cleanup within R2 and R8. The proposed Q1–Q23 queue
  now ranks the product tasks, review findings, and other backlog by user impact and estimated effort. This is
  a scheduling proposal; implementation plans and outstanding product decisions remain unapproved.
- The October 31 review decision corrects R16 to remove existing `#if DEBUG` wrappers around `#Preview` blocks.
  `AGENTS.md` records the updated convention; the source cleanup remains queued at Q19.

## Resume from here

The proposed next implementation is **R1: atomic program replacement**, with R9 startup isolation and the needed
R8 persistence assertions scoped as verification preparation. R3 duplicate-save protection, product task 4's
unsaved-workout protection, and R5 deletion-error handling follow as impactful, contained fixes. Accept the
proposed order and approve each scoped plan before implementation.

Larger data-safety, accessibility, cycling, and workout-flow work follows before lower-impact convenience and
cleanup tasks. `ROADMAP.md` contains the ranks, effort assumptions, and dependencies. Product task IDs 1–5 remain
stable; exercise-level reminders no longer lead the queue, and their migration/banner decisions are still open.
The choice to save only completed sets remains settled.

D1, the ignored-navigation-tap device retest, can accompany relevant UI verification without blocking unrelated
work. A confirmed navigation failure needs its own scope and impact/effort assessment.

## Verification needs

This documentation update did not run builds or tests. The October 29 review passed the Release device build,
Xcode Analyze, Debug test-target build, and 51 selected unit tests. One of two selected UI tests failed during
setup because it tapped Edit instead of Back (R7). Scratch regressions and limited iOS 27.1 simulator VoiceOver
checks are summarized with their limits in `ROADMAP.md`; they do not establish real-device, older-runtime, or
on-device migration behavior. Implementation tasks require scoped verification under `AGENTS.md`. Discover the
current toolchain and simulator inventory when needed. The deployment target is iOS 18.0 and Swift mode is 6.
The October 30 quality pass was static and ran no additional builds or tests; its cleanup recommendations do
not carry new runtime verification.

## Persistence

`ModelContainerFactory` currently deletes store files and retries after any container-creation failure. A schema
change must prove that existing programs and workout history survive; a successful app launch alone cannot prove it.
The migration check and fallback decision are part of `ROADMAP.md` task 1.
Separately, `ProgramPersistenceService.save(_:)` bulk-deletes the old graph before its replacement commits;
the review demonstrated that rollback does not restore that deletion. See R1 for evidence and follow-up scope.
