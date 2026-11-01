# Working in Rat

## Start here

Read `HANDOFF.md` for the current checkpoint and `ROADMAP.md` for the ordered backlog and pending decisions.
Those are the maintained sources of project state.
Update the maintained documents when a task or decision changes, rather than adding another competing plan.

## Working agreements

- Plan non-trivial changes with realistic alternatives and tradeoffs; obtain approval before implementing a new
  plan. Existing user approval remains valid; do not ask for it again. Split work into distinct tasks, each at most
  500 changed lines, preferably 200–300. Include relevant verification, accessibility, localization, and telemetry
  considerations in the scope; the app currently has no localization or telemetry.
- Use one `feature/<kebab-description>` or `bugfix/<kebab-description>` branch per distinct change, including local
  work. Leave the resulting diff unstaged for the user's review and edits.
- Leave changes unstaged so the user can review them before committing. Never stage, commit, or push without
  explicit approval for that action and task. Requests to implement changes or address PR feedback do not grant
  commit or push approval; approval for an earlier commit or push does not cover subsequent changes. Merging
  requires its own authorization. Staged content is not permission to commit. Preserve the index when making new edits.
- Re-read files before follow-up edits and preserve the user's changes. Review comments may be inline `TODO` or
  `FIXME` comments; search `Rat`, `RatTests`, and `RatUITests` for related comments before reporting a fix complete.
- On an authorized merge, use `--no-ff`, verify the resulting tree matches the branch tip, then delete the merged
  branch. Commit subjects are imperative; bodies explain why and wrap around 72 columns. Follow the active
  environment's attribution requirements.
- Never force-push, reset destructively, or rewrite pushed history without explicit authorization.
- Keep the user's local `DEVELOPMENT_TEAM` changes in `Rat.xcodeproj/project.pbxproj` out of commits.
- Critically self-review changes before presenting them. Report what changed, how it was verified, material
  limits, and anything the user should check.

## Architecture and Swift

Rat explores modern Apple frameworks: Swift, SwiftUI, SwiftData, Swift Concurrency, and Swift Testing.
The project currently uses Swift 6 language mode and an iOS 18.0 deployment target.

- No UIKit usage in application code, including bridges and color initializers. XCTest UI tests are allowed.
  When SwiftUI appears unable to support a behavior, check the local SDK interfaces and present evidence and
  SwiftUI alternatives before changing approach.
- Plain domain structs live in `Rat/BusinessLogic/Domain/`; SwiftData entities live in `Rat/Service/Models/`.
  Service implementations alone map between them. Views and view models use domain structs.
- Persistence services are actors behind protocols, hold a `ModelContainer`, and create a fresh `ModelContext`
  per call. Existing read-only `ProgramService` fetches are `nonisolated async`; independent async work runs concurrently.
- `@MainActor @Observable` view models own unstructured `Task {}` operations, business decisions, errors, and
  completion state. Methods express UI intents, such as `handleSaveButtonTap()`, and do not return tasks for tests.
  SwiftUI lifecycle `.task { await viewModel.handleAppear() }` remains appropriate.
- Views render state and forward intents. Parent view models construct child view models; `RatApp` composes the
  root dependencies. Previews use `PreviewSupport` factories. Do not wrap `#Preview` blocks in `#if DEBUG`.
- Prefer simple code and existing conventions over new abstractions. Do not reformat unchanged code. Follow the
  [Swift style guide](https://github.com/lazarevzubov/Ultimate-Swift-Code-Style-Guidelines) and surrounding examples.
  Preserve the existing `// MARK:` organization and `.zero` style; the user wraps doc comments around 140 columns.
- Use American English doc comments on non-private production members, none on private members or tests.
  Explain only non-obvious reasons in ordinary comments; every empty closure needs a short explanation.
  Do not record tickets or code-review discussions in source comments.

The source folders are Xcode synchronized groups: new source files need no project-file entries. Keep notes and
scripts outside `Rat/`, `RatTests/`, and `RatUITests/` so they are not included in app/test targets.

## Verification

- Run only tests covering the changed behavior with `-only-testing:`. Never run the full suite unasked, including
  before a merge. Documentation and formatting changes need no tests.
- Unit tests use Swift Testing, one assertion per test with a message, named `method_condition_expectation`.
  Stubs live in `RatTests/Mocks/`; asynchronous VM tests wait for a positive observable effect with
  `RatTests/WaitFor.swift`, without fixed sleeps or test-only production infrastructure.
- UI tests use XCTest and one file/class per screen in `RatUITests/Tests/`, named `test<Scenario>_<expectation>`.
  Wrap assertion messages around 120 columns. Search all UI tests when a visible label or navigation flow changes.
- `TEST` selects an in-memory store only in Debug builds. `XCUIApplication.launchedForTesting()` sets it;
  persistence/migration checks need an on-disk store instead.
- Use a dedicated available simulator and scratch DerivedData. Run regression experiments in scratch copies.
  Schema changes require a real on-disk migration check; see `ROADMAP.md` task 1.
- Also check a Release device build for implementation changes as scoped in the plan, especially changes to
  configuration, previews, or `#if DEBUG`. Single-file editor diagnostics do not replace an Xcode build.

Discover available simulator UDIDs with `xcrun simctl list devices available`.
Examples for an approved implementation task:

```sh
RAT_SIMULATOR_UDID='<available dedicated simulator UDID>'
xcodebuild -project Rat.xcodeproj -scheme Rat \
  -destination "platform=iOS Simulator,id=$RAT_SIMULATOR_UDID" -derivedDataPath /tmp/rat-dd \
  -collect-test-diagnostics never -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 90 -maximum-test-execution-time-allowance 120 \
  test -only-testing:RatTests/ActiveWorkoutViewModelTests

# Substitute RatUITests/<Screen>UITests[/<test>] when those UI tests cover the change.
xcodebuild -project Rat.xcodeproj -scheme Rat -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO \
  -derivedDataPath /tmp/rat-dd-release build
```

## Settled implementation constraints

Preserve these constraints unless new evidence supports a change; do not reverse a settled decision solely
because a review comment proposes it. The UI behavior below has only been verified on an iOS 27 simulator.

- Taps outside the focused field and drags should dismiss the keyboard and clear focus. Do not add a dedicated
  Hide Keyboard or keyboard Done button as a substitute for that behavior.
- Keyboard dismissal uses `.scrollDismissesKeyboard(.immediately)`, explicit focus clears in control actions/value
  changes, and `View+TouchBelowContent.swift`. Gestures on `Form` or `Section` canceled row actions; backgrounds
  behind `Form` received no touches. Keep dismissal gestures on appropriate row content.
- The blank-space catcher is an overlay, not a `safeAreaInset`. Its height uses two independent measurements:
  available view height minus scroll content height. The available height already accounts for safe areas.
  `DragGesture(minimumDistance: .zero)` also handles touches starting in the blank area.
- Autoscroll uses `ScrollViewReader` and the Add button's `ScrollTarget.addButton` ID. Scrolling that button to the
  bottom reveals the newly appended row. `ScrollPosition.scrollTo(edge:)` did not work on `Form` in those checks.
- Editor screens own and explicitly inject `EditMode`; reading it at a `NavigationStack` root was unreliable.
- UI drag tests start on content to exercise scroll dismissal. An off-screen Form row may leave the accessibility
  tree. For a row containing multiple controls, verify a toggle changed rather than assuming a row-center tap worked.
