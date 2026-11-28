# Rat — Current handoff

Updated November 28, 2026. Read [AGENTS.md](AGENTS.md) for working agreements and [ROADMAP.md](ROADMAP.md) for the
single ordered backlog.

## Current checkpoint

- Local signing settings include `DEVELOPMENT_TEAM = N4WG592BBR` in two app build configurations. Preserve them
  and keep them out of commits. Check `git status` before relying on this snapshot.
- `ROADMAP.md` describes current behavior and ranks remaining work at Q1–Q19. Implementation plans and outstanding
  product decisions need approval.

## Resume from here

The active PR unit-test ruleset on `main` requires pull requests to pass the up-to-date `Unit tests` check from GitHub
Actions. It has no bypass actors and requires no review approvals.

**Q1 / K1: preserve unreadable stores and handle startup failure** is next. Saving only completed sets remains settled
for the later completion-tracking task.

D1, the ignored-navigation-tap device retest, can accompany relevant UI verification without blocking unrelated
work. A confirmed navigation failure needs its own scope and impact/effort assessment.

## Verification limits

Spoken VoiceOver and real-device behavior remain unverified. Physical-device checks require usable signing profiles for
the app and test targets. Follow `AGENTS.md` for scoped verification; simulator results do not establish on-device
behavior or migration safety.

## Persistence

`ModelContainerFactory` currently deletes store files and retries after any container-creation failure. A schema
change must prove that existing programs and workout history survive; a successful app launch alone cannot prove it.
Store recovery is K1 in `ROADMAP.md`; task 1 describes the required on-disk upgrade checks.
