# Rat — Design and remaining work

Updated November 28, 2026. This is the maintained backlog of current behavior, ordered remaining work, and pending
decisions. Recommendations and unresolved decisions are labeled explicitly.

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
- Save accepts one in-flight session snapshot, disables editing, and shows “Saving…”. Repeated saves through the shared
  persistence actor replace the same session ID atomically; failure preserves history and allows retry. Serialization
  relies on that shared actor; there is no database uniqueness constraint across service instances.
- A seeded workout blocks swipe dismissal. Cancel clears keyboard focus and asks before discarding; keeping the workout
  preserves edits. Saving blocks cancellation, and successful Save or confirmed discard dismisses the sheet.
- Programs can be created blank and edited with debounced autosave (500 ms). Done dismisses the new-program sheet;
  Start Workout is in the program editor toolbar. Program cloning is not implemented.

## PR unit-test checks

The `.github/workflows/unit-tests.yml` on `main` defines a `Unit tests` check for new, updated, reopened, retargeted,
and ready-for-review PRs, with a manual trigger as well. It runs the `RatTests` target on a dedicated iOS simulator
using GitHub's `macos-26` runner, Xcode 26.6, and iOS 26.5. Test results and the build log are retained for 14 days.
Pin changes need the runner's installed-tool inventory checked again. The workflow makes no app, accessibility,
localization, telemetry, or schema changes. The active `Require unit tests` branch ruleset targets `main`, requires
pull requests and the up-to-date `Unit tests` check from GitHub Actions, and has no bypass actors or review approval
requirement.

## Proposed implementation queue

The requested order is high-impact/easier work, high-impact/complex work, lower-impact/easier
work, then lower-impact/complex work. High impact means protecting user data, making workout records reliable,
or preserving core editing and accessibility. Convenience and internal cleanup have lower current user impact.
This proposal assumes reliable everyday use is the next goal; R11 becomes a release gate before distribution.

Effort includes regression coverage, UI/device checks where relevant, Release builds, and on-disk proof when
needed. **Small** means a contained change without a schema migration or broad workflow redesign; **medium**
means several coordinated changes, product decisions, or migration/interaction verification; **large** means
cross-feature behavior or a substantial design/harness requirement. These are estimates, not time commitments.
Re-estimate uncertain items after a scoped plan. Grouped entries can require several branches; each implementation
task still follows the change-size limits and verification rules in `AGENTS.md`.

**Q1–Q19 are proposed execution ranks.** Product task and review IDs are stable references; Q-ranks set the execution
order. K1–K5 identify additional backlog items below. Remaining implementation plans and pending product
decisions need approval. Saving only completed sets remains settled.

### High impact, more complex or dependency-bound work

| Rank | Work | Effort | Why here / dependency |
| --- | --- | --- | --- |
| Q1 | K1 — Preserve unreadable stores and handle startup failure | Medium–large | Protects all programs/history from delete-and-retry recovery. Agree on failure/retry behavior before upcoming schema changes. |
| Q2 | R2 — Coordinate autosave across editor lifecycle and deletion | Medium–large | Prevents stale writes and lost edits; dismissal, reopening, and deletion must agree. Simple task cancellation is insufficient. |
| Q3 | R6 — Restore and verify numeric VoiceOver semantics | Medium, uncertain | Concerns core editing accessibility. Resolve the activation-verification gap while preserving settled keyboard behavior. |
| Q4 | R4 — Keep workout cycling correct after day edits | Medium | Stable day identity needs legacy/deleted-day fallback decisions and migration proof. |
| Q5 | Product task 1 — Exercise-level Increase Next Time | Medium | Enables the requested reminder workflow; the existing-flag migration choice and on-disk upgrade proof drive effort. |
| Q6 | Product task 2 — Reliable reminders across program days | Small–medium, blocked | Complete the reminder outcome immediately after task 1. Its smaller isolated diff cannot precede the flag representation it depends on. |
| Q7 | Product task 3 — Save only completed sets | Medium | Corrects what a saved workout means; completion state, omitted exercises, and reminder rules need a coordinated plan after tasks 1–2. |
| Q8 | Product task 5 — Workout edits updating program defaults | Large | Requires coordinated program writes plus settled completion/discard behavior and working-max policy. Follow R2 and product tasks 1–3; preserve the current discard behavior. |

### Lower current user impact, easier improvements

| Rank | Work | Effort | Why here / dependency |
| --- | --- | --- | --- |
| Q9 | R10 — Refresh autocomplete within an open editor | Small | Removes repeated typing; manual entry already works. |
| Q10 | K2 — Correct toolbar labels and empty-program Start Workout | Small | Clearer affordances without changing a core workflow. |
| Q11 | R7/R8/R12 and K3 — Test reliability and organization | Small tasks | Correct navigation selectors, saved-hierarchy and deletion assertions, and screen-test placement. |
| Q12 | R11 — Release version metadata and app icon | Small, choices pending | Limited everyday-use benefit, but mandatory before distribution; promote if a release becomes the next milestone. |
| Q13 | R14 — Share the production schema definition | Small | Reduces maintenance drift; not a functional or migration prerequisite. |
| Q14 | R13 — Domain ownership and API contracts | Small | Narrow access-control, organization, and documentation cleanup. |
| Q15 | R16 — Remove redundant guards around previews | Small | Simplifies preview declarations without an intended runtime behavior change. |
| Q16 | R15 — Simplify bindings/helpers and correct the section heading | Small | Internal clarity with limited direct user benefit; preserve numeric/focus behavior and avoid reworking R6's field changes. |

### Lower current user impact, more complex work

| Rank | Work | Effort | Why here / dependency |
| --- | --- | --- | --- |
| Q17 | K4 — Program cloning | Medium, scope pending | Convenience feature requiring copy/identity semantics and a new flow; prioritize reliable existing workflows first. |
| Q18 | K5 — Keyboard dismissal on headers/navigation titles | Medium, uncertain | Remaining convenience gap with known SwiftUI gesture constraints and potentially expensive device verification. |
| Q19 | Post-v1 statistics, charts, and workout dates/frequency | Large, deferred | Broad optional scope without an approved design; remains deferred until after v1. |

### Verification preparation and dependencies

- Keep explicit on-disk persistence and migration harnesses on disk.
- Repair R7's navigation queries before relying on affected UI tests. R7/R8/R12/K3 work stays at Q11.
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

The IDs below are retained so existing migration references and approved choices remain valid. Execution order comes
from Q1–Q19 above. Resolve each plan's outstanding decisions before implementation.

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

### 5. Workout edits updating program defaults

Requested behavior: editing workout weights/reps should update the program so the next workout reflects those edits. Its
proposed position is Q8; confirm the detailed behavior before implementation.

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

The proposed queue assigns execution ranks using user impact, effort, and dependencies. These implementation plans and
product decisions need approval. Priority labels record severity; they are distinct from Q-ranks and effort estimates.

Each follow-up needs its own scoped plan, branch, regression coverage, and verification under `AGENTS.md`.
Schema changes also require the on-disk migration proof described in task 1. Suggested remedies below are options
for those plans, not settled implementation decisions.

### R2. [P2] Coordinate autosaves with dismissal, reopening, and deletion

[ProgramEditorViewModel.swift](Rat/UI/ProgramEditor/ProgramEditorViewModel.swift) retains a whole-program snapshot
in a delayed save task after the editor is dismissed. A pending autosave can recreate a deleted program. Reopening from
a stale list before the first save completes can also let the second editor overwrite a recent rename.

Plan how to finish or coordinate pending writes when leaving an editor, and how to prevent stale snapshots from
overwriting newer data or recreating deleted programs. Cover both reproduced sequences with deterministic VM
regressions and the affected dismissal/navigation flow. Preserve debounced saving during ordinary editing.

**Related code-quality cleanup:** production calls `handleProgramChanged()` only from
`program.didSet`, but the method is externally callable and several VM tests invoke it directly. Make autosave
scheduling a private implementation detail with a name such as `scheduleAutosave()`. Tests should edit program
names or nested values, then observe persistence, errors, and callbacks through the actual mutation path.
Keep lifecycle correctness coverage above distinct from merely testing that the scheduling helper was called.

### R4. [P2] Preserve workout cycling when days are reordered or deleted

[ActiveWorkoutViewModel.swift](Rat/UI/ActiveWorkout/ActiveWorkoutViewModel.swift) matches the previous workout's
day using `dayPosition`, while program edits renumber those positions. Reproduced example: log Pull in
`[Push, Pull, Legs]`, then delete Push; the next workout repeats Pull instead of selecting Legs. Reordering days
can similarly repeat the previously logged day.

Consider tracking the day template's stable identifier. Define fallback behavior when that day has been removed
and when existing sessions contain only a position. Cover reorder, deletion before the previous day, removal of
the previous day, and wrapping. Any stored identifier change needs migration verification.

### R6. [P2] Preserve numeric fields' VoiceOver editing semantics

Numeric field wrappers in [ExerciseEditorView.swift](Rat/UI/ProgramEditor/ExerciseEditorView.swift),
[SetRowView.swift](Rat/UI/ProgramEditor/SetRowView.swift), and
[LoggedSetRowView.swift](Rat/UI/ActiveWorkout/LoggedSetRowView.swift) use `accessibilityElement(children: .ignore)` and
restore labels and values without the underlying text field's editing semantics. Numeric fields need their editable
traits and hints preserved; actual VoiceOver activation remains unverified. Plan accessible SwiftUI field
representations or labels on the actual editable controls. Verify spoken traits and actual editing for max, percentage,
warm-up weight, and logged weight, while preserving settled keyboard dismissal behavior. Real-device VoiceOver
interaction remains unverified.

### R7. Replace positional Back-button queries in UI tests

[ProgramEditorUITests.swift](RatUITests/Tests/ProgramEditorUITests.swift) still has five positional Back queries.
Replace them with the intended native control and wait for each destination. A positional query can tap Edit and
prevent the test from reaching the behavior it intends to verify.

### R8. Verify the saved program hierarchy after reopening

The hierarchy-saving UI test in [ProgramEditorUITests.swift](RatUITests/Tests/ProgramEditorUITests.swift) should inspect
the saved hierarchy after reopening it, rather than checking only the program's list label. Repair its positional
navigation queries as tracked in R7. Coordinate mutation-based autosave tests with R2; R12 covers the separate
deletion-disappearance expectation.

### R10. Refresh autocomplete within an open program editor

[ProgramEditorViewModel.swift](Rat/UI/ProgramEditor/ProgramEditorViewModel.swift) keeps an immutable suggestions
snapshot. Autosave refreshes the parent list's names, but the open editor retains its original list. Newly saved
exercise names remain unavailable as suggestions until the editor is reopened.

Consider merging names from the current editable program or refreshing suggestions after saves. Cover reuse of
a newly saved exercise name within the same editor, preserving filtering, deduplication, and the suggestion limit.

### R11. Complete release version metadata and the app icon

The generated Release app's Info.plist has neither `CFBundleVersion` nor `CFBundleShortVersionString`; the
[project settings](Rat.xcodeproj/project.pbxproj) define no build or marketing version. The
[AppIcon catalog](Rat/Assets.xcassets/AppIcon.appiconset/Contents.json) declares an icon slot without an image.

Choose version/build values and supply the icon before distribution. Inspect the generated Release metadata and assets
after configuration, then perform the relevant Release build and distribution validation. An unsigned build does not
establish distribution readiness.

### R12. Wait for disappearance in the program-deletion UI test

[ProgramListUITests.swift](RatUITests/Tests/ProgramListUITests.swift) uses
`XCTAssertFalse(waitForExistence(...))` immediately after deletion. If the row still exists during its removal
animation, the wait returns true immediately instead of allowing removal to finish.

Use `waitForNonExistence` for this expectation and rerun the affected deletion scenario.

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
a general repository/container abstraction.
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

`AGENTS.md` records the convention to leave `#Preview` blocks unguarded. Keep dependency setup in `PreviewSupport`
and check its conditional compilation alongside these callers so both configurations compile. Verify Debug
previews and a Release device build when implementing this cleanup.

### Verification limits

Real-device behavior and spoken VoiceOver editing remain unverified. Physical-device checks require usable signing
profiles for the app and test targets. R6 describes the numeric editing verification gap. Simulator UI checks cannot
establish on-device behavior or migration safety; schema changes require on-disk upgrade checks.

## Other backlog details and known limits

K1–K5 identify the additional proposals in the queue. Their implementation plans remain unapproved.

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

Statistics, progression charts, and workout dates/frequency remain deferred at Q19. No implementation plan is approved.
