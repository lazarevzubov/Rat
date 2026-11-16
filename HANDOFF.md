# Rat — Current handoff

Updated November 15, 2026. Read [AGENTS.md](AGENTS.md) for working agreements and [ROADMAP.md](ROADMAP.md) for the
single ordered backlog.

## Current checkpoint

- Local signing settings include `DEVELOPMENT_TEAM = N4WG592BBR` in two app build configurations. Preserve them
  and keep them out of commits. Check `git status` before relying on this snapshot.
- `ROADMAP.md` describes current behavior and ranks remaining work at Q1–Q22. R3's scoped plan is approved; the other
  implementation plans and outstanding product decisions still need approval.

## Resume from here

**R3: prevent duplicate workout saves** is in progress on `bugfix/prevent-duplicate-workout-saves`.
[Draft PR #5](https://github.com/lazarevzubov/Rat/pull/5) tracks the change. Steps 1–2 implement the save guard and
saving UI state, atomic same-ID session replacement, persistence regressions, and a stateful workout double. The
published branch is at step 2, commit `18a9ab4`.

Step 3 is local: the workout UI helper selects the native Back control explicitly and waits for each destination; the
save scenario checks keyboard and sheet disappearance. Its targeted UI checks passed; review its unstaged diff before
committing. Final verification and documentation (step 4) remain; no merge is authorized.

Product task 4's unsaved-workout protection and R5 deletion-error handling follow R3 and still need scoped-plan approval.
`ROADMAP.md` holds the ordered backlog and pending product decisions; saving only completed sets remains settled.

D1, the ignored-navigation-tap device retest, can accompany relevant UI verification without blocking unrelated
work. A confirmed navigation failure needs its own scope and impact/effort assessment.

## Verification needs

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
