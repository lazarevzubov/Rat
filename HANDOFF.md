# Rat — Current handoff

Updated October 29, 2026. Read [AGENTS.md](AGENTS.md) for working agreements and [ROADMAP.md](ROADMAP.md) for the
single ordered backlog.

## Current checkpoint

- No application implementation is in progress.
- Local signing settings include `DEVELOPMENT_TEAM = N4WG592BBR` in two app build configurations. Preserve them
  and keep them out of commits. Check `git status` before relying on this snapshot.
- Program CRUD/autosave, workout persistence and UI, autocomplete, keyboard dismissal fixes, empty Edit button
  handling, and autoscroll are implemented. `ROADMAP.md` distinguishes current behavior from requested changes.

## Resume from here

The next implementation task is **exercise-level Increase Next Time**, followed by reliable reminders across
program days. Their proposed plans and outstanding decisions are in `ROADMAP.md` tasks 1 and 2 and await approval.

The ignored-navigation-tap issue needs a device retest alongside that queue; it is not a reason to pause unrelated
work. Marking completed sets and protecting unsaved workouts follow. Updating program defaults from workout edits
is also requested; its design and proposed position after those tasks need confirmation.

## Verification needs

This documentation update did not run builds or tests. Implementation tasks require the scoped verification
specified in `ROADMAP.md` and `AGENTS.md`. Discover the current toolchain and simulator inventory when needed.
The configured deployment target is iOS 18.0 and the Swift language mode is 6. Real-device, older-runtime,
and VoiceOver behavior remain unverified.

## Persistence

`ModelContainerFactory` currently deletes store files and retries after any container-creation failure. A schema
change must prove that existing programs and workout history survive; a successful app launch alone cannot prove it.
The migration check and fallback decision are part of `ROADMAP.md` task 1.
