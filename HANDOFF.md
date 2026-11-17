# Rat — Current handoff

Updated November 16, 2026. Read [AGENTS.md](AGENTS.md) for working agreements and [ROADMAP.md](ROADMAP.md) for the
single ordered backlog.

## Current checkpoint

- Local signing settings include `DEVELOPMENT_TEAM = N4WG592BBR` in two app build configurations. Preserve them
  and keep them out of commits. Check `git status` before relying on this snapshot.
- `ROADMAP.md` describes current behavior and ranks remaining work at Q1–Q21. Remaining implementation plans and
  outstanding product decisions still need approval.

## Resume from here

**R3: prevent duplicate workout saves** is implemented and its scoped verification is complete on
`bugfix/prevent-duplicate-workout-saves`, tracked by [draft PR #5](https://github.com/lazarevzubov/Rat/pull/5). The save
guard, saving UI state, atomic same-ID replacement, regression coverage, and workout UI checks are published. The final
checkpoint/backlog update is the separate fourth step. No merge is authorized.

Next is product task 4's unsaved-workout protection, followed by R5 deletion-error handling. Both need scoped-plan
approval. `ROADMAP.md` holds the ordered backlog and pending product decisions; saving only completed sets remains
settled.

D1, the ignored-navigation-tap device retest, can accompany relevant UI verification without blocking unrelated
work. A confirmed navigation failure needs its own scope and impact/effort assessment.

## Verification evidence and limits

The 12 persistence cases and 23 workout VM tests passed on the dedicated iOS 27.2 `Rat-R3` simulator
(`212940A8-FA43-4731-9122-E33D7FA62AAB`). An unsigned Release device build also passed. Results are under
`/tmp/rat-r3-step2-*.xcresult`.

On-disk failure/retry and atomic replacement checks passed. Retain the disk fixtures at
`/tmp/rat-r3-step2-on-disk-artifacts` and scratch regression harness at `/tmp/rat-r3-step2-regression`. Serialization
covers the shared service actor; there is no database uniqueness constraint across service instances.

All seven workout UI cases passed on iOS 27.2. Passing results are `/tmp/rat-r3-step3-save-smoke.xcresult` and
`/tmp/rat-r3-step3-keyboard-tests.xcresult`. A scratch copy with a delayed save also confirmed the native saving label,
disabled controls, keyboard dismissal, and eventual sheet dismissal. Its source is `/tmp/rat-r3-step3-saving-probe`; the
passing result is `/tmp/rat-r3-step3-saving-probe-final.xcresult`.

Spoken VoiceOver and real-device behavior remain unverified. The iOS 27.1 automation probe encountered app-idle and
accessibility failures, so the repaired flow remains unverified there. Follow `AGENTS.md` for scoped verification.

## Persistence

`ModelContainerFactory` currently deletes store files and retries after any container-creation failure. A schema
change must prove that existing programs and workout history survive; a successful app launch alone cannot prove it.
The migration check and fallback decision are part of `ROADMAP.md` task 1.
