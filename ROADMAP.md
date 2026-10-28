# Rat — Design and remaining work

Updated October 26, 2026. This is the maintained backlog of current behavior, ordered remaining work, and
pending decisions. Recommendations and unresolved decisions are labeled explicitly.

## Current product and model

Rat is a native iOS/iPadOS gym workout tracker, replacing a paper notebook. It uses SwiftUI, SwiftData,
Swift Concurrency, and Swift Testing, with an iOS 18.0 deployment target and Swift 6 language mode.

- `Program` → `DayTemplate` → `ExerciseTemplate` → `SetTemplate` defines a plan. Days cycle in position order;
  exercise names are free text, with autocomplete from exercise templates used across programs.
- A set template is warm-up (a fixed weight) or working (a percentage of the exercise's working max), with target
  reps and position. Units are kg for v1.
- `WorkoutSession` → `LoggedExercise` → `LoggedSet` snapshots the workout separately from templates, so later
  program edits do not rewrite history.
- **Current implementation:** `increaseNextTime` is stored per logged set; a small exercise-header reminder reads
  flags from only the most recent session. Moving it to the exercise and fixing multi-day reminders are tasks 1–2.
- The active workout is one scrollable list grouped by exercise. Currently Save records all seeded sets, and
  workout edits affect the session only; completion tracking and program writeback remain unfinished.
- Programs can be created blank and edited with debounced autosave (500 ms). Done dismisses the new-program sheet;
  Start Workout is in the program editor toolbar. Program cloning is not implemented.

## Ordered implementation queue

| Order | Task | Status / dependency |
| --- | --- | --- |
| 1 | Exercise-level Increase Next Time | Proposed plan; decisions below need approval |
| 2 | Reliable and visible reminder across program days | Proposed plan; follows task 1 |
| 3 | Mark sets done and save only completed sets | Save-only choice approved; detailed plan pending |
| 4 | Protect an unsaved workout from dismissal | Agreed scope; detailed plan pending |
| 5 | Plan workout edits updating program defaults | Requested; proposed position after tasks 1–4; scope to confirm |

Each implementation task gets its own reviewable branch and scoped verification under `AGENTS.md`.
The device retest below can happen alongside this queue and does not block tasks 1–5.

### 1. Exercise-level Increase Next Time

Requested behavior: one manual reminder flag for an exercise's working base weight, rather than a flag on each set.
This remains a reminder; no automatic weight increase was requested.

Proposed branch: `feature/exercise-level-increase-next-time`.
Move the flag from `LoggedSet`/`LoggedSetEntity` to `LoggedExercise`/`LoggedExerciseEntity`, update service mapping
and VM logic, and show one toggle at the end of each exercise section. Preserve keyboard-dismissal behavior.
The proposed new stored property has an inline default of `false`; migration behavior must be demonstrated.

**Decision needed:** discard existing per-set reminder flags during lightweight migration (recommended),
or preserve them with a custom versioned migration. The former is smaller but loses those reminders; the latter
preserves them and adds migration machinery. Also confirm the proposed split of tasks 1 and 2 into separate branches.

**Required verification before merge:**

- Adapt the flag round-trip persistence, VM, and active-workout UI tests; demonstrate regressions in scratch copies.
- Create an on-disk store using the current baseline, containing a program and saved workout. Confirm the test
  harness preserves it across runs, then install the changed build over it on the same simulator.
- Assert that the program and workout history survive, as well as the chosen reminder-migration behavior. Ordinary
  UI tests use `TEST` and an in-memory store, so they cannot establish migration safety.
- Run the scoped tests and Release device build. If migration fails, revise the strategy before proceeding;
  `ModelContainerFactory`'s delete-and-retry fallback must not turn failure into an accepted empty store.

### 2. Reliable, visible reminders

Current defect: the VM reads one latest session for the whole program, so intervening Pull/Legs days hide a flag
from the previous Push day. The current caption is also easy to miss.

Proposed branch: `bugfix/increase-next-time-banner`, after task 1.
Add a service query returning each exercise name's newest logged occurrence within the program, across all days.
Keep the existing latest-session query for day cycling. Prefer querying logged exercises and choosing the newest
per name; walking sessions newest-first is the fallback if the SwiftData relationship predicate is unsuitable.

**Decision needed:** the proposed reminder is a tinted first row in the exercise section, with an arrow icon and
“Increase today – flagged last time”. A larger header caption is a smaller alternative, but remains in the header.

Cover the multi-day regression, newer unflagged occurrences clearing a reminder, program isolation, empty history,
and visible UI text. Verify with the affected service/VM/UI tests and a Release device build.

### 3. Mark sets done

The user chose **save only the sets marked done**. This choice is settled; do not ask it again.
Proposed branch: `feature/mark-sets-done`.
The draft uses a leading checkmark per set, completion state in the VM, Save disabled until at least one set is
complete, and omission of exercises with no completed sets from saved history.

Before implementation, finish the plan: decide what happens to an exercise reminder when none of its sets are
saved, how completed rows look, and accessible control labels/state. Cover the saved subset, empty-save guard,
omitted exercises, and interaction with exercise-level reminders using the affected unit and UI tests.

### 4. Protect unsaved workouts

Swiping the workout sheet down currently loses the unsaved session. Plan a Cancel action with discard confirmation
and guarded interactive dismissal, including the conditions for showing confirmation and the saved-session
dismissal path. Cover VM state and sheet behavior with scoped tests. Branch naming and exact implementation are
to be settled in that plan.

### 5. Workout edits updating program defaults

Requested behavior: editing workout weights/reps should update the program so the next workout reflects those
edits. Confirm the priority and detailed behavior before implementation.

The proposed approach maps session sets back to templates in memory, preserving the separation of stored history
from templates, and reuses debounced program saving. Reps and warm-up weight can update their template values;
editing a working-set weight requires deriving a new working max, which changes other percentages' next-session
weights too. Confirm that behavior and how program writes interact with cancel/discard before approving a plan.

## Parallel device retest: ignored navigation taps

Some taps on newly added day/exercise rows were reported ignored. The issue was not reproduced in the simulator.
Retest on a device. If it persists, capture reproduction details and plan a separate bugfix branch; otherwise
close it as no longer reproducible.
The row `simultaneousGesture` is a suspect, not a confirmed cause or an approved replacement design.

## Unscheduled proposals and known limits

These items have no approved implementation plan or priority:

- Preserve unreadable stores instead of deleting them after container-creation failure. Task 1's migration proof
  is required regardless of whether this broader recovery redesign is adopted.
- Remove misleading Edit-button accessibility labels and hide Start Workout for a program with no days.
- Move the autocomplete and working-max UI tests from `ProgramEditorUITests` to `ExerciseEditorUITests`.
- Program cloning.
- Address keyboard dismissal on section headers/navigation titles; these remain known gaps. Real-device,
  older-runtime, and VoiceOver behavior remain unverified.
- Correct the properties section heading in `View+ScrollsToTarget.swift` during an appropriate source cleanup.

Remote pushing is an external dependency with unverified access. Follow the restriction in `HANDOFF.md`.

## Post-v1

Statistics, progression charts, and workout dates/frequency remain deferred. No implementation plan is approved.
