import Observation

/// Owns the state, business logic, and persistence calls behind `ActiveWorkoutView`.
@MainActor
@Observable
final class ActiveWorkoutViewModel {

    // MARK: - Properties

    /// The session being logged today.
    var session: WorkoutSession?
    /// Set to `true` once the session has been saved, telling the view it should dismiss itself.
    private(set) var didSave = false
    /// The exercise names the view should show an "increase next time" banner for.
    private(set) var flaggedExerciseNames = Set<String>()
    /// The error from the most recently failed load or save, if any.
    private(set) var presentedError: Error?

    // MARK: Private properties

    private let program: Program
    private let weightSuggestionModel = WeightSuggestionModel()
    private let workoutSessionService: WorkoutSessionService

    // MARK: - Initialization

    /// Creates an active workout view model.
    /// - Parameters:
    ///   - program: The program being worked out against.
    ///   - workoutSessionService: The service used to fetch the most recent session and persist this one.
    init(program: Program, workoutSessionService: WorkoutSessionService) {
        self.program = program
        self.workoutSessionService = workoutSessionService
    }

    // MARK: - Methods

    /// Handles this view appearing: loads the most recently logged session, then seeds today's session from the next day template in the program's
    /// cycle.
    func handleAppear() async {
        guard let sortedDayTemplates else {
            return
        }
        do {
            let mostRecentSession = try await workoutSessionService.fetchMostRecentSession(forProgramWithID: program.id)
            flaggedExerciseNames = Set(
                (mostRecentSession?.loggedExercises ?? [])
                    .filter { $0.loggedSets.contains { $0.increaseNextTime } }
                    .map(\.exerciseName)
            )

            session = makeSession(dayTemplate: nextDayTemplate(in: sortedDayTemplates, after: mostRecentSession))
        } catch {
            presentedError = error
        }
    }

    /// Dismisses the current error, if any.
    func dismissPresentedError() {
        presentedError = nil
    }

    /// Handles a tap on the Save button.
    /// - Returns: The task doing the work, so tests can await its completion.
    @discardableResult
    func handleSaveButtonTap() -> Task<Void, Never> {
        Task {
            guard let session else {
                return
            }
            do {
                try await workoutSessionService.save(session)
                didSave = true
            } catch {
                presentedError = error
            }
        }
    }

    // MARK: Private methods

    private var sortedDayTemplates: [DayTemplate]? {
        program.dayTemplates.isEmpty
            ? nil
            : program.dayTemplates.sorted { $0.position < $1.position }
    }

    private func nextDayTemplate(
        in sortedDays: [DayTemplate], after mostRecentSession: WorkoutSession?
    ) -> DayTemplate {
        guard let mostRecentSession,
              let index = sortedDays.firstIndex(where: { $0.position == mostRecentSession.dayPosition }) else {
            return sortedDays[0]
        }
        return sortedDays[(index + 1) % sortedDays.count]
    }

    private func makeSession(dayTemplate: DayTemplate) -> WorkoutSession {
        WorkoutSession(
            programID: program.id,
            date: .now,
            dayName: dayTemplate.name,
            dayPosition: dayTemplate.position,
            loggedExercises: dayTemplate.exerciseTemplates
                .sorted { $0.position < $1.position }
                .map(makeLoggedExercise(exerciseTemplate:))
        )
    }

    private func makeLoggedExercise(exerciseTemplate: ExerciseTemplate) -> LoggedExercise {
        LoggedExercise(
            exerciseName: exerciseTemplate.name,
            position: exerciseTemplate.position,
            loggedSets: exerciseTemplate.setTemplates
                .sorted { $0.position < $1.position }
                .map { makeLoggedSet(setTemplate: $0, exerciseMax: exerciseTemplate.max) }
        )
    }

    private func makeLoggedSet(setTemplate: SetTemplate, exerciseMax: Double) -> LoggedSet {
        let weight = weightSuggestionModel.suggestedWeight(for: setTemplate, exerciseMax: exerciseMax)
            ?? setTemplate.warmUpWeight
            ?? 0
        return LoggedSet(
            kind: setTemplate.kind, weight: weight, reps: setTemplate.targetReps, position: setTemplate.position
        )
    }

}
