import Foundation
@testable
import Rat
import SwiftData
import Synchronization
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
            programs.flatMap(makeSnapshot(program:)) == makeSnapshot(program: program),
            "Every nested value, identifier, and position round-trips in order."
        )
    }

    @Test
    func fetchPrograms_unsortedTemplates_returnsPositionOrder() async throws {
        let expected = makeProgram()

        var program = expected
        program.dayTemplates.reverse()

        for dayIndex in program.dayTemplates.indices {
            program.dayTemplates[dayIndex].exerciseTemplates.reverse()
            for exerciseIndex in program.dayTemplates[dayIndex].exerciseTemplates.indices {
                program.dayTemplates[dayIndex].exerciseTemplates[exerciseIndex].setTemplates.reverse()
            }
        }

        let service = try makeService()
        try await service.save(program)

        let programs = try await service.fetchPrograms()
        #expect(
            programs.flatMap(makeSnapshot(program:)) == makeSnapshot(program: expected),
            "Days, exercises, and both set kinds return in position order regardless of insertion order."
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
        let original = makeProgram()

        var replacement = original
        replacement.name = "Renamed"
        replacement.dayTemplates.removeLast()
        replacement.dayTemplates[0].name = "Upper"
        replacement.dayTemplates.append(DayTemplate(name: "New Day", position: 1))
        replacement.dayTemplates[0].exerciseTemplates.removeLast()
        replacement.dayTemplates[0].exerciseTemplates[0].max = 95.5
        replacement.dayTemplates[0].exerciseTemplates[0].setTemplates.removeLast()
        replacement.dayTemplates[0].exerciseTemplates[0].setTemplates[0].warmUpWeight = 25

        let service = try makeService()

        try await service.save(original)
        try await service.save(replacement)

        let programs = try await service.fetchPrograms()
        #expect(
            programs.flatMap(makeSnapshot(program:)) == makeSnapshot(program: replacement),
            "Replacement preserves retained IDs and updates values, additions, and removals throughout the graph."
        )
    }

    @Test
    func save_replacingProgram_removesOldDescendants() async throws {
        let original = makeProgram()
        let replacement = Program(name: "Empty", id: original.id)

        let container = try makeContainer()
        let service = ProgramPersistenceService(modelContainer: container)

        try await service.save(original)
        try await service.save(replacement)

        #expect(
            try persistedIdentifiers(in: ModelContext(container)) == [replacement.id],
            "Replacement leaves no orphaned days, exercises, or sets."
        )
    }

    @Test
    func save_replacingProgram_preservesOtherPrograms() async throws {
        let service = try makeService()

        let original = makeProgram()
        try await service.save(original)

        let other = Program(name: "Other")
        try await service.save(other)

        let replacement = Program(name: "Renamed", id: original.id)
        try await service.save(replacement)

        let programs = try await service.fetchPrograms()
        #expect(
            programs.flatMap(makeSnapshot(program:)) == [
                other,
                replacement
            ]
                .flatMap(makeSnapshot(program:)),
            "Replacing one program preserves unrelated programs."
        )
    }

    @Test
    func save_readOnlyStore_preservesProgramAfterFailure() async throws {
        let storeURL = try makeStoreURL()
        let service = ProgramPersistenceService(modelContainer: try makeContainer(storeURL: storeURL))

        let original = makeProgram()
        try await service.save(original)

        let readOnlyService = ProgramPersistenceService(
            modelContainer: try makeContainer(storeURL: storeURL, allowsSave: false)
        )

        var didFail = false
        do {
            try await readOnlyService.save(makeProgram(id: original.id))
        } catch {
            didFail = true
        }

        let programs = try await readOnlyService.fetchPrograms()
        #expect(
            didFail
                && (programs.flatMap(makeSnapshot(program:)) == makeSnapshot(program: original)),
            "A rejected on-disk replacement reports failure and preserves every original value and identifier."
        )
    }

    @Test
    func save_onDiskReplacement_keepsOldGraphUntilCommit() async throws {
        let container = try makeContainer(storeURL: makeStoreURL())
        let service = ProgramPersistenceService(modelContainer: container)

        let original = makeProgram()
        try await service.save(original)

        let expectedIDs = try persistedIdentifiers(in: ModelContext(container))

        let observedIDs = Mutex<Result<[UUID], any Error>?>(nil)
        let observer = NotificationCenter.default.addObserver(
            forName: ModelContext.willSave, object: nil, queue: nil
        ) { notification in
            guard let context = notification.object as? ModelContext,
                  context.container === container else {
                return
            }
            observedIDs.withLock {
                $0 = Result { try persistedIdentifiers(in: ModelContext(container)) }
            }
        }

        defer { NotificationCenter.default.removeObserver(observer) }

        try await service.save(makeProgram(id: original.id))
        #expect(
            try observedIDs.withLock { try $0?.get() } == expectedIDs,
            "A separate on-disk context sees the complete old graph until the replacement commits."
        )
    }

    @Test
    func fetchExerciseNames_returnsEmpty_initially() async throws {
        let service = try makeService()
        let names = try await service.fetchExerciseNames()

        #expect(names.isEmpty, "No exercise names are persisted initially.")
    }

    @Test
    func fetchExerciseNames_returnsDistinctSortedNames_acrossPrograms() async throws {
        let service = try makeService()

        try await service.save(makeProgram())
        try await service.save(
            Program(
                name: "Upper Lower",
                dayTemplates: [
                    DayTemplate(
                        name: "Upper",
                        position: 0,
                        exerciseTemplates: [
                            ExerciseTemplate(name: "Bench Press", position: 0, max: 100.0),
                            ExerciseTemplate(name: "Overhead Press", position: 1, max: 60.0)
                        ]
                    )
                ]
            )
        )

        let names = try await service.fetchExerciseNames()
        #expect(
            names == [
                "Bench Press",
                "Overhead Press",
                "Row"
            ],
            "Names are deduplicated across programs and sorted."
        )
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

    @Test
    func delete_nestedProgram_removesDescendants() async throws {
        let container = try makeContainer()
        let service = ProgramPersistenceService(modelContainer: container)

        let program = makeProgram()
        try await service.save(program)

        try await service.delete(programWithID: program.id)
        #expect(
            try persistedIdentifiers(in: ModelContext(container)).isEmpty,
            "Deleting a program also removes every day, exercise, and set."
        )
    }

    // MARK: Private methods

    private func makeProgram(id: UUID = UUID()) -> Program {
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
                            setTemplates: [
                                SetTemplate(kind: .warmUp, targetReps: 10, position: 0, warmUpWeight: 20.5),
                                SetTemplate(kind: .working, targetReps: 5, position: 1, percentOfMax: 80)
                            ]
                        ),
                        ExerciseTemplate(
                            name: "Overhead Press",
                            position: 1,
                            max: 60,
                            setTemplates: [SetTemplate(kind: .working, targetReps: 8, position: 0)]
                        )
                    ]
                ),
                DayTemplate(
                    name: "Pull",
                    position: 1,
                    exerciseTemplates: [
                        ExerciseTemplate(
                            name: "Row",
                            position: 0,
                            max: 80,
                            setTemplates: [SetTemplate(kind: .working, targetReps: 6, position: 0, percentOfMax: 75)]
                        )
                    ]
                )
            ],
            id: id
        )
    }

    private func makeService() throws -> ProgramPersistenceService {
        ProgramPersistenceService(modelContainer: try makeContainer())
    }

    private func makeContainer(storeURL: URL? = nil, allowsSave: Bool = true) throws -> ModelContainer {
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
        let configuration = if let storeURL {
            ModelConfiguration(schema: schema, url: storeURL, allowsSave: allowsSave, cloudKitDatabase: .none)
        } else {
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, allowsSave: allowsSave)
        }

        return try ModelContainer(for: schema, configurations: configuration)
    }

    private func makeStoreURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        return directory.appendingPathComponent("Programs.store")
    }

    private func persistedIdentifiers(in context: ModelContext) throws -> [UUID] {
        let programs = try context.fetch(FetchDescriptor<ProgramEntity>()).map(\.id)
        let days = try context.fetch(FetchDescriptor<DayTemplateEntity>()).map(\.id)
        let exercises = try context.fetch(FetchDescriptor<ExerciseTemplateEntity>()).map(\.id)
        let sets = try context.fetch(FetchDescriptor<SetTemplateEntity>()).map(\.id)

        return (programs + days + exercises + sets).sorted { $0.uuidString < $1.uuidString }
    }

    private func makeSnapshot(program: Program) -> [TemplateValue] {
        [.program(program.id, name: program.name)] + program.dayTemplates.flatMap { day in
            [.day(day.id, name: day.name, position: day.position)] + day.exerciseTemplates.flatMap { exercise in
                [.exercise(exercise.id, name: exercise.name, position: exercise.position, max: exercise.max)]
                    + exercise.setTemplates.map {
                        .set(
                            $0.id,
                            $0.kind,
                            targetReps: $0.targetReps,
                            position: $0.position,
                            warmUpWeight: $0.warmUpWeight,
                            percentOfMax: $0.percentOfMax
                        )
                    }
            }
        }
    }

    // MARK: - Nested types

    private enum TemplateValue: Equatable {

        case program(UUID, name: String)
        case day(UUID, name: String, position: Int)
        case exercise(UUID, name: String, position: Int, max: Double)
        case set(UUID, SetKind, targetReps: Int, position: Int, warmUpWeight: Double?, percentOfMax: Int?)

    }

}
