# Rat — Design and remaining work

Updated October 31, 2026. This is the maintained backlog of current behavior, ordered remaining work, and
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

## Proposed implementation queue

Revised October 30 using the requested order: high-impact/easier work, high-impact/complex work, lower-impact/easier
work, then lower-impact/complex work. High impact means protecting user data, making workout records reliable,
or preserving core editing and accessibility. Convenience and internal cleanup have lower current user impact.
This proposal assumes reliable everyday use is the next goal; R11 becomes a release gate before distribution.

Effort includes regression coverage, UI/device checks where relevant, Release builds, and on-disk proof when
needed. **Small** means a contained change without a schema migration or broad workflow redesign; **medium**
means several coordinated changes, product decisions, or migration/interaction verification; **large** means
cross-feature behavior or a substantial design/harness requirement. These are estimates, not time commitments.
Re-estimate uncertain items after a scoped plan. Grouped entries can require several branches; each implementation
task still follows the change-size limits and verification rules in `AGENTS.md`.

**Q1–Q23 are proposed execution ranks.** Product tasks **1–5** and review IDs **R1–R16** remain stable references,
not execution positions. K1–K5 identify the other backlog items below. This replaces the former five-item order
without approving implementation plans or resolving their pending product decisions. The approved choice to
save only completed sets remains settled.

### High impact, easier fixes

| Rank | Work | Effort | Why here / dependency |
| --- | --- | --- | --- |
| Q1 | R1 — Make program replacement atomic | Small | Prevents loss of an entire program through a narrow service change, with no intended schema change. Include on-disk atomicity proof. |
| Q2 | R3 — Prevent duplicate workout saves | Small | Protects workout history; an in-flight guard and ID-based save semantics can avoid a schema change. |
| Q3 | Product task 4 — Protect unsaved workouts | Small, scoped | Prevents losing a workout through sheet dismissal. Define confirmation conditions; native Cancel/confirmation handling needs no persisted drafts or completion-feature prerequisite. |
| Q4 | R5 — Surface failed deletion and restore the list | Small | Prevents a misleading success state and supports recovery; contained VM/error-presentation work. |

### High impact, more complex or dependency-bound work

| Rank | Work | Effort | Why here / dependency |
| --- | --- | --- | --- |
| Q5 | K1 — Preserve unreadable stores and handle startup failure | Medium–large | Protects all programs/history from delete-and-retry recovery. Agree on failure/retry behavior before upcoming schema changes. |
| Q6 | R2 — Coordinate autosave across editor lifecycle and deletion | Medium–large | Prevents stale writes and lost edits; dismissal, reopening, and deletion must agree. Simple task cancellation is insufficient. |
| Q7 | R6 — Restore and verify numeric VoiceOver semantics | Medium, uncertain | Concerns core editing accessibility. Resolve the activation-verification gap while preserving settled keyboard behavior. |
| Q8 | R4 — Keep workout cycling correct after day edits | Medium | Stable day identity needs legacy/deleted-day fallback decisions and migration proof. |
| Q9 | Product task 1 — Exercise-level Increase Next Time | Medium | Enables the requested reminder workflow; the existing-flag migration choice and on-disk upgrade proof drive effort. |
| Q10 | Product task 2 — Reliable reminders across program days | Small–medium, blocked | Complete the reminder outcome immediately after task 1. Its smaller isolated diff cannot precede the flag representation it depends on. |
| Q11 | Product task 3 — Save only completed sets | Medium | Corrects what a saved workout means; completion state, omitted exercises, and reminder rules need a coordinated plan after tasks 1–2. |
| Q12 | Product task 5 — Workout edits updating program defaults | Large | Requires reliable program writes plus settled completion/discard behavior and working-max policy. Follow R1/R2 and product tasks 1–4. |

### Lower current user impact, easier improvements

| Rank | Work | Effort | Why here / dependency |
| --- | --- | --- | --- |
| Q13 | R10 — Refresh autocomplete within an open editor | Small | Removes repeated typing; manual entry already works. |
| Q14 | K2 — Correct toolbar labels and empty-program Start Workout | Small | Clearer affordances without changing a core workflow. |
| Q15 | Remaining R7/R8/R9/R12 and K3 — Test reliability and organization | Small tasks | Finish relevant selectors, assertions, doubles, startup isolation, and screen-test placement not already delivered as verification preparation. |
| Q16 | R11 — Release version metadata and app icon | Small, choices pending | Limited everyday-use benefit, but mandatory before distribution; promote if a release becomes the next milestone. |
| Q17 | R14 — Share the production schema definition | Small | Reduces maintenance drift; not a functional or migration prerequisite. |
| Q18 | R13 — Domain ownership and API contracts | Small | Narrow access-control, organization, and documentation cleanup. |
| Q19 | R16 — Remove redundant guards around previews | Small | Simplifies preview declarations without an intended runtime behavior change. |
| Q20 | R15 — Simplify bindings/helpers and correct the section heading | Small | Internal clarity with limited direct user benefit; preserve numeric/focus behavior and avoid reworking R6's field changes. |

### Lower current user impact, more complex work

| Rank | Work | Effort | Why here / dependency |
| --- | --- | --- | --- |
| Q21 | K4 — Program cloning | Medium, scope pending | Convenience feature requiring copy/identity semantics and a new flow; prioritize reliable existing workflows first. |
| Q22 | K5 — Keyboard dismissal on headers/navigation titles | Medium, uncertain | Remaining convenience gap with known SwiftUI gesture constraints and potentially expensive device verification. |
| Q23 | Post-v1 statistics, charts, and workout dates/frequency | Large, deferred | Broad optional scope without an approved design; remains deferred until after v1. |

### Verification preparation and dependencies

- Establish R9's isolated hosted-test startup before ordinary unit-test runs for Q1. Keep explicit on-disk and
  migration harnesses on disk. This small prerequisite is part of safe verification, not a reason to move all
  test cleanup ahead of user-facing fixes.
- Pull only the required R8 assertions into the fixes they verify: nested replacement checks for R1, save
  completion and coherent workout-double behavior for R3 and later workout sequences. Repair relevant R7 Back
  queries before relying on affected UI tests. Remaining R7/R8/R9/R12/K3 work stays at Q15; do not repeat work
  already completed with an earlier fix.
- R14 may be a small preparation task if a schema-owning change actually needs it, but it must not block unrelated
  data-safety fixes or substitute for migration proof. Preserve separate proposed branches for product tasks
  1 and 2; confirmation of that split and the existing product decisions remain pending.
- Run D1, the ignored-navigation-tap device retest below, alongside the next relevant UI verification when a
  device is available. It is an investigation, not an assumed gesture fix or a global blocker. If reproduced as
  a core navigation failure, prioritize the resulting fix by its observed impact and estimated effort.
- Real-device, older-runtime, accessibility, and on-disk checks belong in each relevant plan. They are not
  duplicate feature rows. A UI change needs accessible labels/state and current English text; the app still
  has no localization or telemetry, so any need for those should be explicit in the scoped plan.

## Product task details (stable IDs)

The IDs below are retained so existing migration references and approved choices remain valid. Execution order
comes from Q1–Q23 above. Each detailed plan still needs its outstanding decisions resolved before implementation.

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
edits. Its proposed position is Q12; confirm the detailed behavior before implementation.

The proposed approach maps session sets back to templates in memory, preserving the separation of stored history
from templates, and reuses debounced program saving. Reps and warm-up weight can update their template values;
editing a working-set weight requires deriving a new working max, which changes other percentages' next-session
weights too. Confirm that behavior and how program writes interact with cancel/discard before approving a plan.

## Parallel device retest: ignored navigation taps

**D1:** Some taps on newly added day/exercise rows were reported ignored. The issue was not reproduced in the simulator.
Retest on a device. If it persists, capture reproduction details and plan a separate bugfix branch; otherwise
close it as no longer reproducible.
The row `simultaneousGesture` is a suspect, not a confirmed cause or an approved replacement design.

## Project review findings

R1–R12 record the October 29 project review. The October 30 code-quality pass added R13–R16 and related API/test
cleanup to R2 and R8, consolidating small items by area. The proposed queue above now assigns execution ranks
using user impact, effort, and dependencies. Implementation plans remain unapproved and the product tasks'
pending decisions remain open. P1/P2 labels retain the first review's severity assessment; they are distinct from
Q-ranks and effort estimates. R1 is separate from K1's `ModelContainerFactory` recovery issue.

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

**Related code-quality cleanup from October 30:** production calls `handleProgramChanged()` only from
`program.didSet`, but the method is externally callable and several VM tests invoke it directly. Make autosave
scheduling a private implementation detail with a name such as `scheduleAutosave()`. Tests should edit program
names or nested values, then observe persistence, errors, and callbacks through the actual mutation path.
Keep lifecycle correctness coverage above distinct from merely testing that the scheduling helper was called.

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

### R8. Strengthen test assertions and service doubles

**Save completion, confirmed by the October 29 mutation:**

`handleSaveButtonTap_succeeds_setsDidSave` in
[ActiveWorkoutViewModelTests.swift](RatTests/Tests/ActiveWorkoutViewModelTests.swift) only calls `waitFor`.
[WaitFor.swift](RatTests/WaitFor.swift) returns normally when its deadline expires, so the test cannot fail when
`didSave` stays false. Removing the production `didSave = true` assignment in a scratch copy still left all twelve
workout VM tests passing; this test merely waited about five seconds.

Add a final `#expect` for the completion state with a message. Repeat the scratch mutation to demonstrate that
the corrected test detects the regression, then run the relevant unmodified VM tests.

**Related test-quality cleanup from October 30:**

- The nested round-trip tests in
  [ProgramPersistenceServiceTests.swift](RatTests/Tests/ProgramPersistenceServiceTests.swift) and
  [WorkoutSessionPersistenceServiceTests.swift](RatTests/Tests/WorkoutSessionPersistenceServiceTests.swift)
  assert only the first exercise's name. Losing every set or changing set values and identifiers would still
  satisfy those assertions. Use multiple siblings and both set kinds, with focused checks of nested values,
  identifiers, and ordering. Preserve the one-assertion-per-unit-test convention. The hierarchy-saving UI test in
  [ProgramEditorUITests.swift](RatUITests/Tests/ProgramEditorUITests.swift) should also inspect the saved hierarchy
  after reopening it, rather than checking only the program's list label. It also uses the fragile positional
  navigation tracked in R7.
- [WorkoutSessionStubService.swift](RatTests/Mocks/WorkoutSessionStubService.swift) fetches from `sessions`, but
  saving only appends to `savedSessions`. In contrast, the program service double updates its fetchable state.
  Either make the workout double stateful too, retaining the call log if useful, or explicitly distinguish a
  configured stub from a stateful fake. Verify that the chosen contract supports save-then-start-next-workout
  sequences without silently depending on manually reseeded history.

These additional observations are coverage and test-double design gaps, not demonstrated production defects.
Coordinate mutation-based autosave tests with R2, and keep the UI disappearance expectation tracked in R12.

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

### R13. Clarify domain ownership and enforce existing API contracts

Group these small domain cleanups:

- In [SetTemplate.swift](Rat/BusinessLogic/Domain/SetTemplate.swift), make `kind` externally read-only so callers
  change it through `setKind(to:)`, which clears/defaults the kind-dependent weight and percentage fields. The UI
  already uses that transition method. Keep the existing initializer and optional-field semantics; working sets
  with no percentage are deliberately supported and tested.
- Move [SetKind.swift](Rat/Service/Models/SetKind.swift) into `BusinessLogic/Domain`, because it is a plain domain
  concept used by templates, logged sets, and views. Retain its type name, cases, raw values, and Codable
  conformance; no second enum or mapping layer is needed.
- Complete [WeightSuggestionModel.swift](Rat/BusinessLogic/WeightSuggestionModel.swift)'s return documentation:
  it returns `nil` for a missing working percentage as well as for a nonworking set. That behavior is already
  covered by the weight-suggestion tests.

Verify the existing set-kind transitions and weight suggestions with their scoped tests and a Release build.
This grouping concerns API enforcement, ownership, and documentation; it does not propose a stored-model change.

### R14. Share the production schema definition

The identical seven-entity list appears in [RatApp.swift](Rat/RatApp.swift),
[PreviewSupport.swift](Rat/UI/PreviewSupport.swift),
[ProgramPersistenceServiceTests.swift](RatTests/Tests/ProgramPersistenceServiceTests.swift), and
[WorkoutSessionPersistenceServiceTests.swift](RatTests/Tests/WorkoutSessionPersistenceServiceTests.swift).
Upcoming model changes otherwise require keeping four lists synchronized manually.

Consider one small service-layer schema definition shared by runtime, previews, and those test fixtures. Keep
each caller's store configuration, in-memory/on-disk choice, and recovery policy explicit. This does not call for
a general repository/container abstraction, and R9's hosted-test startup isolation remains a separate concern.
Verify that the shared definition preserves the current schema, both build configurations, previews, and scoped
persistence tests; centralizing the list alone must not be treated as migration proof.

### R15. Simplify UI binding and helper APIs

Group these small simplifications while preserving current behavior:

- [SetRowView.swift](Rat/UI/ProgramEditor/SetRowView.swift) wraps numeric bindings around other bindings that
  merely read and write fields. Each weight/percentage field can use one direct binding while retaining the
  focused-zero presentation and nil-to-zero conversion. Keep `kindBinding` routed through `setKind(to:)`.
- [NumberFieldValueStrategy.swift](Rat/BusinessLogic/NumberFieldValueStrategy.swift) has no state, configuration,
  or replaceable implementation, yet views store and accept concrete instances. Consider a static operation or
  otherwise removing constructor parameters that offer no configuration or substitution. Do not introduce a
  generic field framework for this cleanup.
- [ActiveWorkoutViewModel.swift](Rat/UI/ActiveWorkout/ActiveWorkoutViewModel.swift)'s `sortedDayTemplates`
  computed property performs a sort and returns `nil` for an empty collection. Prefer a local sorted array and
  explicit empty guard, or a clearly named method. This makes the work and the nonempty precondition visible
  without introducing an optional collection; R4 separately tracks the cycling-identity defect.
- Correct the properties section heading in
  [View+ScrollsToTarget.swift](Rat/UI/Extensions/View+ScrollsToTarget.swift) during this helper cleanup.

Verify the affected number-field and workout-seeding behavior with scoped tests and a Release build. Preserve
the settled focus, keyboard-dismissal, and autoscroll behavior, and coordinate numeric accessibility changes
with R6 rather than treating simplified bindings as proof that accessibility is fixed.

### R16. Remove redundant guards around previews

[ContentView.swift](Rat/ContentView.swift),
[ProgramListView.swift](Rat/UI/ProgramList/ProgramListView.swift),
[ProgramEditorView.swift](Rat/UI/ProgramEditor/ProgramEditorView.swift), and
[ActiveWorkoutView.swift](Rat/UI/ActiveWorkout/ActiveWorkoutView.swift) wrap their `#Preview` blocks in explicit
`#if DEBUG` guards. Remove those wrappers; the other four preview blocks already follow the desired convention.

The October 31 review decision replaces the earlier recommendation to add guards. `AGENTS.md` now records the
convention to leave `#Preview` blocks unguarded. Keep dependency setup in `PreviewSupport` and check its
conditional compilation alongside these callers so both configurations compile. Verify Debug previews and a
Release device build when implementing this cleanup.

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
- The October 30 code-quality pass was static source inspection. It ran no additional builds or tests and made
  no application changes. Its recommendations describe maintainability, API consistency, and test coverage;
  the earlier runtime evidence should not be attributed to these new cleanup suggestions.

## Other backlog details and known limits

K1–K5 identify previously unscheduled proposals now included in the suggested queue. Their implementation plans
remain unapproved. The small section-heading correction is consolidated into R15 rather than listed twice.

- **K1 — Store preservation/recovery:** preserve unreadable stores instead of deleting them after container-creation
  failure, and agree on a usable startup failure/retry path. This protects existing data before schema changes;
  product task 1's migration proof is required regardless of the chosen recovery design. Do not hide a failed
  migration behind a successful launch with an empty replacement store.
- **K2 — Toolbar affordances:** remove misleading Edit-button accessibility labels and hide Start Workout for a
  program with no days. Verify the changed labels and empty/nonempty states in affected UI tests.
- **K3 — UI test organization:** move the autocomplete and working-max UI tests from `ProgramEditorUITests` to
  `ExerciseEditorUITests`, alongside the relevant R7/R8 test maintenance.
- **K4 — Program cloning:** define the copy flow and which values are copied; copied programs and all descendants
  need independent identities. The feature remains a proposal, not an approved implementation plan.
- **K5 — Remaining keyboard dismissal:** address section headers/navigation titles while preserving the settled
  gesture constraints. Real-device and older-runtime behavior remain unverified; R6 records the limited simulator
  VoiceOver evidence. Estimate again after a supported SwiftUI approach and reproduction are established.

## Post-v1

Statistics, progression charts, and workout dates/frequency remain deferred at Q23. No implementation plan is approved.
