# Rat — Current handoff

Updated October 30, 2026. Read [AGENTS.md](AGENTS.md) for working agreements and [ROADMAP.md](ROADMAP.md) for the
single ordered backlog.

## Current checkpoint

- No application implementation is in progress.
- Local signing settings include `DEVELOPMENT_TEAM = N4WG592BBR` in two app build configurations. Preserve them
  and keep them out of commits. Check `git status` before relying on this snapshot.
- Program CRUD/autosave, workout persistence and UI, autocomplete, keyboard dismissal fixes, empty Edit button
  handling, and autoscroll are implemented. `ROADMAP.md` distinguishes current behavior from requested changes.
- All twelve findings from the October 29 project review are recorded as R1–R12 in `ROADMAP.md`. Their remedies
  and position relative to the existing queue are not approved; recording them did not authorize implementation.

## Resume from here

The next implementation task is **exercise-level Increase Next Time**, followed by reliable reminders across
program days. Their proposed plans and outstanding decisions are in `ROADMAP.md` tasks 1 and 2 and await approval.
The review also identified a P1 atomicity risk in program replacement (R1); its priority relative to that queue
needs a decision before implementation.

The ignored-navigation-tap issue needs a device retest alongside that queue; it is not a reason to pause unrelated
work. Marking completed sets and protecting unsaved workouts follow. Updating program defaults from workout edits
is also requested; its design and proposed position after those tasks need confirmation.

## Verification needs

This documentation update did not run builds or tests. The October 29 review passed the Release device build,
Xcode Analyze, Debug test-target build, and 51 selected unit tests. One of two selected UI tests failed during
setup because it tapped Edit instead of Back (R7). Scratch regressions and limited iOS 27.1 simulator VoiceOver
checks are summarized with their limits in `ROADMAP.md`; they do not establish real-device, older-runtime, or
on-device migration behavior. Implementation tasks require scoped verification under `AGENTS.md`. Discover the
current toolchain and simulator inventory when needed. The deployment target is iOS 18.0 and Swift mode is 6.

## Persistence

`ModelContainerFactory` currently deletes store files and retries after any container-creation failure. A schema
change must prove that existing programs and workout history survive; a successful app launch alone cannot prove it.
The migration check and fallback decision are part of `ROADMAP.md` task 1.
Separately, `ProgramPersistenceService.save(_:)` bulk-deletes the old graph before its replacement commits;
the review demonstrated that rollback does not restore that deletion. See R1 for evidence and follow-up scope.
