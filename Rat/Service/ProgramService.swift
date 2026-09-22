import Foundation
import SwiftData

/// Manages persisted workout programs.
protocol ProgramService: Actor {

    // MARK: - Methods

    /// Deletes the program with the given identifier, if one exists.
    /// - Parameter id: The identifier of the program to delete.
    /// - Throws: An error if the change couldn't be persisted.
    func delete(programWithID id: UUID) throws
    /// Fetches the distinct exercise names used across all programs, sorted alphabetically.
    /// - Returns: The distinct exercise names.
    /// - Throws: An error if the fetch failed.
    nonisolated func fetchExerciseNames() async throws -> [String]
    /// Fetches all persisted programs, sorted by name.
    /// - Returns: The persisted programs.
    /// - Throws: An error if the fetch failed.
    nonisolated func fetchPrograms() async throws -> [Program]
    /// Persists a program, replacing any existing program with the same identifier.
    /// - Parameter program: The program to persist.
    /// - Throws: An error if the change couldn't be persisted.
    func save(_ program: Program) throws

}

// MARK: -

/// The program service based on a SwiftData persistent storage.
actor ProgramPersistenceService: ProgramService {

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

    // MARK: ProgramService protocol methods

    func delete(programWithID id: UUID) throws {
        let context = ModelContext(container)

        try context.delete(model: ProgramEntity.self, where: #Predicate { $0.id == id })
        try context.save()
    }

    nonisolated func fetchExerciseNames() async throws -> [String] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<ExerciseTemplateEntity>()

        return Set(try context.fetch(descriptor).map(\.name)).sorted()
    }

    nonisolated func fetchPrograms() async throws -> [Program] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<ProgramEntity>(sortBy: [SortDescriptor(\.name)])

        return try context.fetch(descriptor).map(Self.makeDomain(entity:))
    }

    func save(_ program: Program) throws {
        let context = ModelContext(container)
        let id = program.id

        try context.delete(model: ProgramEntity.self, where: #Predicate { $0.id == id })
        context.insert(makeEntity(program: program))

        try context.save()
    }

    // MARK: Private methods

    private static func makeDomain(entity: ProgramEntity) -> Program {
        Program(
            name: entity.name,
            dayTemplates: entity.dayTemplates.sorted { $0.position < $1.position }.map(makeDomain(entity:)),
            id: entity.id
        )
    }

    private static func makeDomain(entity: DayTemplateEntity) -> DayTemplate {
        DayTemplate(
            name: entity.name,
            position: entity.position,
            exerciseTemplates: entity.exerciseTemplates.sorted { $0.position < $1.position }.map(makeDomain(entity:)),
            id: entity.id
        )
    }

    private static func makeDomain(entity: ExerciseTemplateEntity) -> ExerciseTemplate {
        ExerciseTemplate(
            name: entity.name,
            position: entity.position,
            max: entity.max,
            setTemplates: entity.setTemplates.sorted { $0.position < $1.position }.map(makeDomain(entity:)),
            id: entity.id
        )
    }

    private static func makeDomain(entity: SetTemplateEntity) -> SetTemplate {
        SetTemplate(
            kind: entity.kind,
            targetReps: entity.targetReps,
            position: entity.position,
            warmUpWeight: entity.warmUpWeight,
            percentOfMax: entity.percentOfMax,
            id: entity.id
        )
    }

    private func makeEntity(program: Program) -> ProgramEntity {
        let entity = ProgramEntity(name: program.name, id: program.id)
        entity.dayTemplates = program.dayTemplates.map(makeEntity(day:))

        return entity
    }

    private func makeEntity(day: DayTemplate) -> DayTemplateEntity {
        let entity = DayTemplateEntity(name: day.name, position: day.position, id: day.id)
        entity.exerciseTemplates = day.exerciseTemplates.map(makeEntity(exercise:))

        return entity
    }

    private func makeEntity(exercise: ExerciseTemplate) -> ExerciseTemplateEntity {
        let entity = ExerciseTemplateEntity(
            name: exercise.name, position: exercise.position, max: exercise.max, id: exercise.id
        )
        entity.setTemplates = exercise.setTemplates.map(makeEntity(set:))

        return entity
    }

    private func makeEntity(set: SetTemplate) -> SetTemplateEntity {
        SetTemplateEntity(
            kind: set.kind,
            targetReps: set.targetReps,
            position: set.position,
            warmUpWeight: set.warmUpWeight,
            percentOfMax: set.percentOfMax,
            id: set.id
        )
    }

}
