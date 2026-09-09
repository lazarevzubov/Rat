import Foundation
@testable
import Rat
import SwiftData
import Testing

struct ProgramPersistenceServiceTests {

    // MARK: - Methods

    @Test
    func fetchPrograms_returnsEmpty_initially() async throws {
        let service = try makeService()
        let programs = try await service.fetchPrograms()

        #expect(programs.isEmpty, "No programs are persisted initially.")
    }

    @Test
    func fetchPrograms_returnsSavedProgram_afterSaving() async throws {
        let service = try makeService()
        let program = makeProgram()

        try await service.save(program)
        let programs = try await service.fetchPrograms()

        #expect(programs.map(\.id) == [program.id], "The saved program is returned.")
    }

    @Test
    func fetchPrograms_returnsNestedDaysExercisesAndSets_afterSaving() async throws {
        let service = try makeService()
        let program = makeProgram()

        try await service.save(program)
        let programs = try await service.fetchPrograms()

        #expect(
            programs.first?.dayTemplates.first?.exerciseTemplates.first?.name == "Bench Press",
            "Nested days, exercises, and sets round-trip."
        )
    }

    @Test
    func save_replacesExistingProgram_whenIDMatches() async throws {
        let service = try makeService()
        let id = UUID()

        try await service.save(Program(name: "Original", id: id))
        try await service.save(Program(name: "Renamed", id: id))

        let programs = try await service.fetchPrograms()

        #expect(programs.count == 1, "Saving with the same ID replaces the existing program rather than duplicating it.")
    }

    @Test
    func save_usesReplacementFields_whenIDMatches() async throws {
        let service = try makeService()
        let id = UUID()

        try await service.save(Program(name: "Original", id: id))
        try await service.save(Program(name: "Renamed", id: id))

        let programs = try await service.fetchPrograms()

        #expect(programs.first?.name == "Renamed", "The replacement's fields are used.")
    }

    @Test
    func delete_removesProgram_whenIDMatches() async throws {
        let service = try makeService()
        let program = Program(name: "Push Pull Legs")

        try await service.save(program)
        try await service.delete(programWithID: program.id)

        let programs = try await service.fetchPrograms()
        #expect(programs.isEmpty, "The deleted program is no longer returned.")
    }

    // MARK: Private methods

    private func makeProgram() -> Program {
        Program(
            name: "Push Pull Legs",
            dayTemplates: [
                DayTemplate(
                    name: "Push",
                    position: 0,
                    exerciseTemplates: [
                        ExerciseTemplate(
                            name: "Bench Press",
                            position: 0,
                            max: 100.0,
                            setTemplates: [SetTemplate(kind: .working, targetReps: 5, position: 0, percentOfMax: 80)]
                        )
                    ]
                )
            ]
        )
    }

    private func makeService() throws -> ProgramPersistenceService {
        let schema = Schema(
            [
                ProgramEntity.self,
                DayTemplateEntity.self,
                ExerciseTemplateEntity.self,
                SetTemplateEntity.self,
                WorkoutSessionEntity.self,
                LoggedExerciseEntity.self,
                LoggedSetEntity.self
            ]
        )
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)

        return ProgramPersistenceService(modelContainer: container)
    }

}
