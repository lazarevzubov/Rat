import Foundation
import SwiftData

/// Manages persisted workout sessions.
protocol WorkoutSessionService: Actor {

    // MARK: - Methods

    /// Fetches the most recently logged session for the given program, if any.
    /// - Parameter programID: The identifier of the program to fetch the most recent session for.
    /// - Returns: The most recently logged session, or `nil` if none has been logged yet.
    /// - Throws: An error if the fetch failed.
    func fetchMostRecentSession(forProgramWithID programID: UUID) throws -> WorkoutSession?
    /// Persists a workout session.
    /// - Parameter session: The session to persist.
    /// - Throws: An error if the change couldn't be persisted.
    func save(_ session: WorkoutSession) throws

}

// MARK: -

/// The workout session service based on a SwiftData persistent storage.
actor WorkoutSessionPersistenceService: WorkoutSessionService {

    // MARK: - Properties

    // MARK: Private properties

    private let container: ModelContainer

    // MARK: - Initialization

    /// Creates a service instance.
    /// - Parameter modelContainer: An object that manages an app's schema and model storage configuration.
    init(modelContainer: ModelContainer) {
        container = modelContainer
    }

    // MARK: - Methods

    // MARK: WorkoutSessionService protocol methods

    func fetchMostRecentSession(forProgramWithID programID: UUID) throws -> WorkoutSession? {
        let context = ModelContext(container)

        var descriptor = FetchDescriptor<WorkoutSessionEntity>(
            predicate: #Predicate { $0.programID == programID },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first.map(makeDomain(entity:))
    }

    func save(_ session: WorkoutSession) throws {
        let context = ModelContext(container)

        context.insert(makeEntity(session: session))
        try context.save()
    }

    // MARK: Private methods

    private func makeDomain(entity: WorkoutSessionEntity) -> WorkoutSession {
        WorkoutSession(
            programID: entity.programID,
            date: entity.date,
            dayName: entity.dayName,
            dayPosition: entity.dayPosition,
            loggedExercises: entity.loggedExercises.sorted { $0.position < $1.position }.map(makeDomain(entity:)),
            id: entity.id
        )
    }

    private func makeDomain(entity: LoggedExerciseEntity) -> LoggedExercise {
        LoggedExercise(
            exerciseName: entity.exerciseName,
            position: entity.position,
            loggedSets: entity.loggedSets.sorted { $0.position < $1.position }.map(makeDomain(entity:)),
            id: entity.id
        )
    }

    private func makeDomain(entity: LoggedSetEntity) -> LoggedSet {
        LoggedSet(
            kind: entity.kind,
            weight: entity.weight,
            reps: entity.reps,
            position: entity.position,
            increaseNextTime: entity.increaseNextTime,
            id: entity.id
        )
    }

    private func makeEntity(session: WorkoutSession) -> WorkoutSessionEntity {
        let entity = WorkoutSessionEntity(
            programID: session.programID,
            date: session.date,
            dayName: session.dayName,
            dayPosition: session.dayPosition,
            id: session.id
        )
        entity.loggedExercises = session.loggedExercises.map(makeEntity(exercise:))

        return entity
    }

    private func makeEntity(exercise: LoggedExercise) -> LoggedExerciseEntity {
        let entity = LoggedExerciseEntity(
            exerciseName: exercise.exerciseName, position: exercise.position, id: exercise.id
        )
        entity.loggedSets = exercise.loggedSets.map(makeEntity(set:))

        return entity
    }

    private func makeEntity(set: LoggedSet) -> LoggedSetEntity {
        LoggedSetEntity(
            kind: set.kind,
            weight: set.weight,
            reps: set.reps,
            position: set.position,
            increaseNextTime: set.increaseNextTime,
            id: set.id
        )
    }

}
