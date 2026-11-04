# Rat — Current handoff

Updated November 1, 2026. Read [AGENTS.md](AGENTS.md) for working agreements and [ROADMAP.md](ROADMAP.md) for the
single ordered backlog.

## Current checkpoint

- Local signing settings include `DEVELOPMENT_TEAM = N4WG592BBR` in two app build configurations. Preserve them
  and keep them out of commits. Check `git status` before relying on this snapshot.
- `ROADMAP.md` describes current behavior and ranks remaining work at Q1–Q22. These are proposed execution ranks;
  implementation plans and outstanding product decisions still need approval.

## Resume from here

The proposed next implementation is **R3: prevent duplicate workout saves**. Product task 4's unsaved-workout
protection and R5 deletion-error handling follow as impactful, contained fixes. Approve each scoped plan before
implementation.

Larger data-safety, accessibility, cycling, and workout-flow work follows before lower-impact convenience and
cleanup tasks. `ROADMAP.md` contains the ranks, effort assumptions, and dependencies. Product task IDs 1–5 remain
stable; the reminder migration/banner decisions are still open. The choice to save only completed sets remains
settled.

D1, the ignored-navigation-tap device retest, can accompany relevant UI verification without blocking unrelated
work. A confirmed navigation failure needs its own scope and impact/effort assessment.

## Verification needs

Implementation tasks require scoped verification under `AGENTS.md`. Repair relevant R7 Back-button queries
before relying on affected UI tests. Existing UI and VoiceOver checks used an iOS 27.1 simulator and do not
establish real-device, older-runtime, or on-device migration behavior. Explicit on-disk persistence and migration
harnesses must remain on disk. Discover the current toolchain and simulator inventory when needed. The deployment
target is iOS 18.0 and Swift mode is 6.

## Persistence

`ModelContainerFactory` currently deletes store files and retries after any container-creation failure. A schema
change must prove that existing programs and workout history survive; a successful app launch alone cannot prove it.
The migration check and fallback decision are part of `ROADMAP.md` task 1.
