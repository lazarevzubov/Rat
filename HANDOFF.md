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
saving UI state, atomic same-ID session replacement, persistence regressions, and a stateful workout double.

Continue with the approved workout UI Back-selector repairs and runtime UI verification (step 3), then final
verification and documentation (step 4). Keep later steps in separate commits and show each unstaged diff for review
before committing; no merge is authorized.

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

Runtime UI and spoken VoiceOver checks remain unverified, as do real-device and older-runtime behavior. Repair the
relevant R7 Back queries before relying on the workout UI tests. Follow `AGENTS.md` for scoped verification.

## Persistence

`ModelContainerFactory` currently deletes store files and retries after any container-creation failure. A schema
change must prove that existing programs and workout history survive; a successful app launch alone cannot prove it.
The migration check and fallback decision are part of `ROADMAP.md` task 1.
