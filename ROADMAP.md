# Rat — Design & Roadmap

Native iOS/iPadOS gym workout tracker (replacement for a paper notebook), sibling project to "Worm" (book recommendations). Swift/SwiftUI/SwiftData/Swift Concurrency/Swift Testing, targeting the last 2 major iOS versions.

## Data model

- `Program` → `DayTemplate` (e.g. Day 1/Day 2, cycled in order) → `ExerciseTemplate` (free-text name, no fixed exercise DB) → `SetTemplate`.
- `SetTemplate` is either `.warmup` (free weight entry, e.g. 0 for bodyweight/bar — not a % of max, since warm-ups don't scale with max) or `.working` (`percentOfMax: Int`), plus `targetReps` and `position`.
- Separately, `WorkoutSession` → `LoggedExercise` → `LoggedSet` records what actually happened, decoupled from templates so editing a program later doesn't rewrite history.
- Each logged set has an `increaseNextTime: Bool` flag, set manually by the user after a set felt too easy; surfaced as a banner on that exercise next session. No auto weight-bump suggestion.
- Units: kg only for v1.

## UI decisions

- Active workout screen: one long scrollable list grouped by exercise (not per-exercise full-screen paging).
- Program editing: "Edit Program" clones the current program as a starting point or starts blank; exercise-name entry has autocomplete from previously used names (still free text).
- Stats (progression charts, workout dates/frequency) deliberately deferred out of v1 — schema already supports it later with no changes.

## Architecture

- SwiftData `@Model` entities live under `Rat/Service/Models/*Entity.swift`, separate from plain domain structs under `Rat/BusinessLogic/Domain/*.swift`. Services map between them.
- Strict MVVM: `@MainActor @Observable` view models own all `Task{}`/async/error state; views only call intent-named methods (e.g. `handleSaveButtonTap()`) and react to VM state — never construct their own dependencies or branch on return values.
- Composition root (`RatApp`) builds top-level view models once in `init()` and passes them down.

## Progress

- ✅ Xcode scaffolding, SwiftData models, build/test verified on simulator.
- ✅ Persistence service layer (`ProgramService`/`ProgramPersistenceService`, `ModelContainerFactory`).
- ✅ Program list/editor UI (full CRUD for programs → days → exercises → sets), `RatUITests` target.
- ✅ Workout session persistence (`LoggedExercise`/`LoggedSet`/`WorkoutSession` domain models, `WorkoutSessionService`).
- ✅ Active workout screen (`ActiveWorkoutView`/`ActiveWorkoutViewModel`, "Start Workout" entry point from the program list, increase-next-time banner).
- ✅ Exercise-name autocomplete (`ProgramService.fetchExerciseNames()`, suggestions filtered in `ProgramEditorViewModel`, shown in `ExerciseEditorView`).

## Not yet built

- Stats/progression charts (post-v1).
