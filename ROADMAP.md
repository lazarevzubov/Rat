# Rat — Design and remaining work

Updated October 30, 2026. This is the maintained backlog of current behavior, ordered remaining work, and
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

## Additional findings from the October 29 project review

All twelve findings below were recorded at the user's request on October 30. They have no approved implementation
plans or position in the ordered queue; tasks 1–5 and their pending decisions remain unchanged. P1/P2 labels
retain the review's severity assessment, not an approved implementation order. The remaining improvements have
no assigned priority. In particular, R1 is separate from the already-known `ModelContainerFactory` recovery issue.

Each follow-up needs its own scoped plan, branch, regression coverage, and verification under `AGENTS.md`.
Schema changes also require the on-disk migration proof described in task 1. Suggested remedies below are options
for those plans, not settled implementation decisions.

### R1. [P1] Make program replacement atomic

In [ProgramService.swift](Rat/Service/ProgramService.swift), `save(_:)` bulk-deletes the persisted program before
inserting and saving its replacement. A fresh context observed the deletion before `save()`, and `rollback()`
did not restore the program. The sequence was confirmed on an iOS 27.1 in-memory store and a scratch macOS
on-disk store. A failed replacement save or interruption between the operations can therefore lose the entire
previously saved program, including its days, exercises, and sets.

Consider updating the existing graph or using normal entity deletions and insertions in one commit. Add a
regression proving that an aborted replacement preserves the old graph, alongside successful nested replacement
and deletion checks. Verify atomicity on disk, rather than accepting successful replacement alone as proof.

### R2. [P2] Coordinate autosaves with dismissal, reopening, and deletion

[ProgramEditorViewModel.swift](Rat/UI/ProgramEditor/ProgramEditorViewModel.swift) retains a whole-program snapshot
in a delayed save task after the editor is dismissed. Scratch reproductions using the production VMs showed a
successful deletion followed by a pending autosave recreating the program. Reopening from the stale list before
the first save completed also allowed the second editor to overwrite a recent rename.

Plan how to finish or coordinate pending writes when leaving an editor, and how to prevent stale snapshots from
overwriting newer data or recreating deleted programs. Cover both reproduced sequences with deterministic VM
regressions and the affected dismissal/navigation flow. Preserve debounced saving during ordinary editing.

### R3. [P2] Prevent duplicate workout saves

[ActiveWorkoutViewModel.swift](Rat/UI/ActiveWorkout/ActiveWorkoutViewModel.swift) allows overlapping Save tasks,
and [WorkoutSessionService.swift](Rat/Service/WorkoutSessionService.swift) always inserts a new entity graph.
Saving the identical session twice duplicated stored sessions in an iOS in-memory probe. A separate macOS on-disk
probe counted two sessions, two logged exercises, and two logged sets with the same domain identifiers.

Guard in-flight saves and make persistence idempotent for a session identifier. Cover repeated taps, repeated
service calls, and retry after failure; define the visible and accessible saving state. This is separate from
task 3's completed-set filtering and empty-save guard.

### R4. [P2] Preserve workout cycling when days are reordered or deleted

[ActiveWorkoutViewModel.swift](Rat/UI/ActiveWorkout/ActiveWorkoutViewModel.swift) matches the previous workout's
day using `dayPosition`, while program edits renumber those positions. Reproduced example: log Pull in
`[Push, Pull, Legs]`, then delete Push; the next workout repeats Pull instead of selecting Legs. Reordering days
can similarly repeat the previously logged day.

Consider tracking the day template's stable identifier. Define fallback behavior when that day has been removed
and when existing sessions contain only a position. Cover reorder, deletion before the previous day, removal of
the previous day, and wrapping. Any stored identifier change needs migration verification.

### R5. [P2] Surface failed program deletions and restore the list

[ProgramListViewModel.swift](Rat/UI/ProgramList/ProgramListViewModel.swift) removes rows optimistically, then
discards persistence errors with `try?`. A throwing service left zero visible rows, one stored program, and no
presented error; reloading brought the program back.

Restore or reload failed items and present the deletion error. Cover successful deletion, failure, and partial
failure when multiple programs are removed. Include the visible error and recovery behavior in UI verification.

### R6. [P2] Preserve numeric fields' VoiceOver editing semantics

Numeric field wrappers in [ExerciseEditorView.swift](Rat/UI/ProgramEditor/ExerciseEditorView.swift),
[SetRowView.swift](Rat/UI/ProgramEditor/SetRowView.swift), and
[LoggedSetRowView.swift](Rat/UI/ActiveWorkout/LoggedSetRowView.swift) use `accessibilityElement(children: .ignore)`
and restore labels and values without the underlying text field's editing semantics. On the iOS 27.1 simulator,
VoiceOver announced the exercise name as a text field with an editing hint, but max and percentage fields as
labels and values without that indication.

The activation comparison was inconclusive: raw coordinate double-taps opened no keyboard for either the max
field or the name-field control. Do not treat that experiment as proof that numeric editing is impossible.
Plan accessible SwiftUI field representations or labels on the actual editable controls. Verify spoken traits
and actual editing for max, percentage, warm-up weight, and logged weight, while preserving settled keyboard
dismissal behavior. Real-device VoiceOver interaction remains unverified.

### R7. Replace positional Back-button queries in UI tests

[ActiveWorkoutUITests.swift](RatUITests/Tests/ActiveWorkoutUITests.swift) and
[ProgramEditorUITests.swift](RatUITests/Tests/ProgramEditorUITests.swift) use
`navigationBars[...].buttons.element(boundBy: 0)` to navigate back. On iOS 27.1,
`testTappingWeightField_keepsKeyboard` tapped Edit instead of Back, then failed looking for the expected day
navigation bar. It never reached the workout behavior under test.

Locate the intended back control explicitly and wait for the destination. Search all UI tests for the same
assumption and rerun the affected scenarios. This observed test-selector failure is separate from the reported
ignored-navigation-tap issue awaiting a device retest above.

### R8. Assert save-completion state after waiting

`handleSaveButtonTap_succeeds_setsDidSave` in
[ActiveWorkoutViewModelTests.swift](RatTests/Tests/ActiveWorkoutViewModelTests.swift) only calls `waitFor`.
[WaitFor.swift](RatTests/WaitFor.swift) returns normally when its deadline expires, so the test cannot fail when
`didSave` stays false. Removing the production `didSave = true` assignment in a scratch copy still left all twelve
workout VM tests passing; this test merely waited about five seconds.

Add a final `#expect` for the completion state with a message. Repeat the scratch mutation to demonstrate that
the corrected test detects the regression, then run the relevant unmodified VM tests.

### R9. Isolate hosted unit-test app startup from the normal store

The [shared scheme's TestAction](Rat.xcodeproj/xcshareddata/xcschemes/Rat.xcscheme) does not set `TEST`, although
[RatApp.swift](Rat/RatApp.swift) selects in-memory startup storage only when that variable is present in Debug.
Because the unit-test target uses `TEST_HOST`, startup opens the normal on-disk container even when a test's own
fixture uses an in-memory container. The dedicated review simulator contained the default store after
hosted unit-test startup.

Configure isolated app startup for unit tests and verify that ordinary test runs do not open the normal store.
Keep explicit on-disk persistence and migration checks available; they must not silently become in-memory tests.

### R10. Refresh autocomplete within an open program editor

[ProgramEditorViewModel.swift](Rat/UI/ProgramEditor/ProgramEditorViewModel.swift) keeps an immutable suggestions
snapshot. Autosave refreshes the parent list's names, but the open editor retains its original list. A scratch
VM check saved Bench Press and confirmed that the parent and persistence knew the name while the same editor
offered no suggestion for Bench; reopening the editor made it available.

Consider merging names from the current editable program or refreshing suggestions after saves. Cover reuse of
a newly saved exercise name within the same editor, preserving filtering, deduplication, and the suggestion limit.

### R11. Complete release version metadata and the app icon

The generated Release app's Info.plist has neither `CFBundleVersion` nor `CFBundleShortVersionString`; the
[project settings](Rat.xcodeproj/project.pbxproj) define no build or marketing version. The
[AppIcon catalog](Rat/Assets.xcassets/AppIcon.appiconset/Contents.json) declares an icon slot without an image.

Choose version/build values and supply the icon before distribution. Inspect the generated Release metadata and
assets after configuration, then perform the relevant Release build and distribution validation. The successful
unsigned review build did not establish distribution readiness.

### R12. Wait for disappearance in the program-deletion UI test

[ProgramListUITests.swift](RatUITests/Tests/ProgramListUITests.swift) uses
`XCTAssertFalse(waitForExistence(...))` immediately after deletion. If the row still exists during its removal
animation, the wait returns true immediately instead of allowing removal to finish.

Use `waitForNonExistence` for this expectation and rerun the affected deletion scenario. This is a static test
robustness finding; an animation-related failure was not reproduced during the review.

### Review verification and limits

- The October 29 review's Release device build, Xcode Analyze action, and Debug test-target build passed with no
  source diagnostics. Tooling emitted the no-AppIntents-dependency metadata-extraction warning.
- All 51 selected unit tests passed: program-editor, program-list, and active-workout VMs, plus program and workout
  persistence services. Of two selected UI tests, the exercise-field focus test passed; the active-workout weight
  keyboard test failed during setup because of R7. The full suite was not run.
- Scratch-only regressions reproduced R1–R5 and R10; R8's mutation demonstrated the false-positive test. R6's spoken
  semantics were checked with simulator VoiceOver, with the activation limitation recorded above.
- Runtime UI checks used an iOS 27.1 simulator; the separate on-disk service probe used macOS. These checks do not
  establish older-runtime, real-device, or on-device migration behavior. Scratch sources and test mutations were
  not added to the project. No production source was changed, staged, or committed by the review.

## Unscheduled proposals and known limits

These items have no approved implementation plan or priority:

- Preserve unreadable stores instead of deleting them after container-creation failure. Task 1's migration proof
  is required regardless of whether this broader recovery redesign is adopted.
- Remove misleading Edit-button accessibility labels and hide Start Workout for a program with no days.
- Move the autocomplete and working-max UI tests from `ProgramEditorUITests` to `ExerciseEditorUITests`.
- Program cloning.
- Address keyboard dismissal on section headers/navigation titles; these remain known gaps. Real-device and
  older-runtime behavior remain unverified. The limited simulator VoiceOver findings are recorded in R6 above.
- Correct the properties section heading in `View+ScrollsToTarget.swift` during an appropriate source cleanup.

## Post-v1

Statistics, progression charts, and workout dates/frequency remain deferred. No implementation plan is approved.
