# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Rat is a 100% native gym workout tracker for iOS/iPadOS: Swift, SwiftUI, SwiftData, Swift Concurrency, Swift Testing. Sibling project to "Worm". See `ROADMAP.md` for the data model, UI decisions, and build progress.

## Commands

Build and test via `xcodebuild` (scheme `Rat`, no workspace file):

```sh
xcodebuild -scheme Rat -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -scheme Rat -destination 'platform=iOS Simulator,name=iPhone 16' test
xcodebuild -scheme Rat -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:RatTests/ProgramListViewModelTests
xcodebuild -scheme Rat -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:RatTests/ProgramListViewModelTests/handleAppear_succeeds_loadsPrograms
xcodebuild -scheme Rat -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:RatUITests
```

Tests use Swift Testing (`@Test`, `#expect`), not XCTest.

Running with `TEST` set in the environment makes `RatApp` use an in-memory `ModelContainer` instead of the on-disk store (see `RatApp.init()`).

## Architecture

- **Two parallel model layers**: SwiftData `@Model` entities live in `Rat/Service/Models/*Entity.swift`; plain domain structs (no SwiftData dependency) live in `Rat/BusinessLogic/Domain/*.swift`. Services (`Rat/Service/*Service.swift`) are the only place that maps between entity and domain types — views and view models only ever see domain structs.
- **Data model**: `Program` → `DayTemplate` → `ExerciseTemplate` → `SetTemplate` describes a workout plan (`SetTemplate` is `.warmup`, a fixed weight, or `.working`, a `percentOfMax`). Separately, `WorkoutSession` → `LoggedExercise` → `LoggedSet` records what actually happened, decoupled from templates so editing a program later doesn't rewrite history.
- **Services are actors** conforming to a protocol (e.g. `ProgramService` / `ProgramPersistenceService`, `WorkoutSessionService` / `WorkoutSessionPersistenceService`), each holding a `ModelContainer` and creating a fresh `ModelContext` per call. `ModelContainerFactory` builds the container and recovers once from a corrupted on-disk store by deleting it and retrying.
- **Strict MVVM**: `@MainActor @Observable` view models under `Rat/UI/<Feature>/` own all `Task {}`/async/error state and are the only place that talks to services. Views only call intent-named methods (`handleSaveButtonTap()`, `handleAppear()`) and render view model state — they never construct their own dependencies, branch on a method's return value, or hold async logic. A parent view model constructs child view models for child screens (e.g. `ProgramListViewModel.makeProgramEditorViewModel(program:)`, `.makeActiveWorkoutViewModel(program:)`), wiring completion callbacks (e.g. reload the list after a save) rather than the child reaching back into the parent.
- **Composition root**: `RatApp.init()` builds the schema, `ModelContainer`, both services, and the top-level `ProgramListViewModel` once; everything else is constructed from there down.
- Tests use stub services (`RatTests/ProgramStubService.swift`, `WorkoutSessionStubService.swift`) conforming to the same protocols as the real persistence actors, injected directly into view models under test.
