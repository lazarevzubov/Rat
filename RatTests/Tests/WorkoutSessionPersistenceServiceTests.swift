import Foundation
@testable
import Rat
import SwiftData
import Synchronization
import Testing

struct WorkoutSessionPersistenceServiceTests {

    // MARK: - Methods

    @Test
    func fetchMostRecentSession_returnsNil_initially() async throws {
        let service = try makeService()
        let session = try await service.fetchMostRecentSession(forProgramWithID: UUID())

        #expect(session == nil, "No sessions are persisted initially.")
    }

    @Test
    func fetchMostRecentSession_returnsSavedSession_afterSaving() async throws {
        let service = try makeService()

        let session = makeSession()
        try await service.save(session)

        let fetched = try await service.fetchMostRecentSession(forProgramWithID: session.programID)
        #expect(fetched?.id == session.id, "The saved session is returned.")
    }

    @Test
    func fetchMostRecentSession_returnsNestedExercisesAndSets_afterSaving() async throws {
        let service = try makeService()

        let session = makeSession()
        try await service.save(session)

        let fetched = try await service.fetchMostRecentSession(forProgramWithID: session.programID)
        #expect(
            fetched.map(makeSnapshot(session:)) == makeSnapshot(session: session),
            "Every nested value, ID, and position round-trips in order."
        )
    }

    @Test
    func fetchMostRecentSession_returnsLatestByDate_whenMultipleSessionsExist() async throws {
        let programID = UUID()

        let older = makeSession(programID: programID, date: Date(timeIntervalSinceReferenceDate: 0))
        let newer = makeSession(programID: programID, date: Date(timeIntervalSinceReferenceDate: 1_000))

        let service = try makeService()

        try await service.save(older)
        try await service.save(newer)

        let fetched = try await service.fetchMostRecentSession(forProgramWithID: programID)
        #expect(fetched?.id == newer.id, "The session with the latest date is returned.")
    }

    @Test
    func fetchMostRecentSession_ignoresOtherPrograms_whenFetching() async throws {
        let service = try makeService()

        let session = makeSession()
        try await service.save(session)

        let fetched = try await service.fetchMostRecentSession(forProgramWithID: UUID())
        #expect(fetched == nil, "Sessions belonging to other programs aren't returned.")
    }

    @Test(
        arguments: [
            false,
            true
        ]
    )
    func save_repeatedCalls_persistsSingleGraph(concurrently: Bool) async throws {
        let container = try makeContainer()
        let service = WorkoutSessionPersistenceService(modelContainer: container)

        let session = makeSession()

        if concurrently {
            async let firstSave = service.save(session)
            async let secondSave = service.save(session)

            _ = try await (firstSave, secondSave)
        } else {
            try await service.save(session)
            try await service.save(session)
        }

        #expect(
            try persistedIdentifiers(in: ModelContext(container)) == identifiers(session: session),
            "Repeated saves through the same actor retain exactly one session, each exercise, and each set."
        )
    }

    @Test
    func save_changedSession_replacesValuesAndReturnsPositionOrder() async throws {
        let original = makeSession()

        var expected = original

        expected.programID = UUID()
        expected.date = Date(timeIntervalSinceReferenceDate: 2_000)
        expected.dayName = "Upper"
        expected.dayPosition = 2
        expected.loggedExercises.removeLast()

        expected.loggedExercises[0].exerciseName = "Incline Bench Press"
        expected.loggedExercises[0].position = 1
        expected.loggedExercises[0].loggedSets.removeLast()
        expected.loggedExercises[0].loggedSets[0].kind = .working
        expected.loggedExercises[0].loggedSets[0].weight = 82.5
        expected.loggedExercises[0].loggedSets[0].reps = 8
        expected.loggedExercises[0].loggedSets[0].position = 1
        expected.loggedExercises[0].loggedSets[0].increaseNextTime = true

        expected.loggedExercises[0].loggedSets.insert(
            LoggedSet(kind: .warmUp, weight: 25.5, reps: 10, position: 0), at: 0
        )
        expected.loggedExercises.insert(
            LoggedExercise(
                exerciseName: "Row",
                position: 0,
                loggedSets: [LoggedSet(kind: .working, weight: 60, reps: 6, position: 0)]
            ),
            at: 0
        )

        var replacement = expected
        replacement.loggedExercises.reverse()

        for exerciseIndex in replacement.loggedExercises.indices {
            replacement.loggedExercises[exerciseIndex].loggedSets.reverse()
        }

        let container = try makeContainer()
        let service = WorkoutSessionPersistenceService(modelContainer: container)

        try await service.save(original)
        try await service.save(replacement)

        let fetched = try await service.fetchMostRecentSession(forProgramWithID: expected.programID)
        let persistedIDs = try persistedIdentifiers(in: ModelContext(container))

        #expect(
            (fetched.map(makeSnapshot(session:)) == makeSnapshot(session: expected))
                && (persistedIDs == identifiers(session: expected)),
            "Replacement updates the complete graph, preserves retained IDs, removes old descendants, and sorts positions."
        )
    }

    @Test
    func save_emptyReplacement_removesAllDescendants() async throws {
        let original = makeSession()

        var replacement = original
        replacement.loggedExercises.removeAll()

        let container = try makeContainer()
        let service = WorkoutSessionPersistenceService(modelContainer: container)

        try await service.save(original)
        try await service.save(replacement)

        #expect(
            try persistedIdentifiers(in: ModelContext(container)) == [replacement.id],
            "Replacing a session with no exercises leaves no orphaned exercises or sets."
        )
    }

    @Test
    func save_replacingSession_preservesOtherSessions() async throws {
        let original = makeSession()
        let older = makeSession(programID: original.programID, date: Date(timeIntervalSinceReferenceDate: .zero))
        let otherProgram = makeSession()

        var replacement = original
        replacement.dayName = "Upper"

        let container = try makeContainer()

        let service = WorkoutSessionPersistenceService(modelContainer: container)
        try await service.save(older)
        try await service.save(original)
        try await service.save(otherProgram)
        try await service.save(replacement)

        let fetched = try await service.fetchMostRecentSession(forProgramWithID: otherProgram.programID)
        let expectedIDs = [
            replacement,
            older,
            otherProgram
        ]
            .flatMap(identifiers(session:)).sorted(by: compareIdentifiers)
        let persistedIDs = try persistedIdentifiers(in: ModelContext(container))

        #expect(
            (fetched.map(makeSnapshot(session:)) == makeSnapshot(session: otherProgram))
                && (persistedIDs == expectedIDs),
            "Replacing one session preserves history in the same program and every other program's session graph."
        )
    }

    @Test
    func save_rejectedOnDiskReplacement_preservesHistoryAndAllowsRetry() async throws {
        let storeURL = try makeStoreURL()
        let service = WorkoutSessionPersistenceService(modelContainer: try makeContainer(storeURL: storeURL))

        let original = makeSession()
        try await service.save(original)

        var replacement = original
        replacement.dayName = "Upper"
        replacement.loggedExercises.removeLast()

        let readOnlyService = WorkoutSessionPersistenceService(
            modelContainer: try makeContainer(storeURL: storeURL, allowsSave: false)
        )

        var didFail = false
        do {
            try await readOnlyService.save(replacement)
        } catch {
            didFail = true
        }

        let preserved = try await readOnlyService.fetchMostRecentSession(forProgramWithID: original.programID)

        let retryContainer = try makeContainer(storeURL: storeURL)
        let retryService = WorkoutSessionPersistenceService(modelContainer: retryContainer)

        try await retryService.save(replacement)
        let retried = try await retryService.fetchMostRecentSession(forProgramWithID: original.programID)

        let persistedIDs = try persistedIdentifiers(in: ModelContext(retryContainer))
        #expect(
            didFail
                && (preserved.map(makeSnapshot(session:)) == makeSnapshot(session: original))
                && (retried.map(makeSnapshot(session:)) == makeSnapshot(session: replacement))
                && (persistedIDs == identifiers(session: replacement)),
            "A rejected on-disk write preserves history, and retrying with a writable store persists one replacement graph."
        )
    }

    @Test
    func save_onDiskReplacement_keepsOldGraphUntilCommit() async throws {
        let container = try makeContainer(storeURL: makeStoreURL())
        let service = WorkoutSessionPersistenceService(modelContainer: container)

        let original = makeSession()
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

        try await service.save(makeSession(id: original.id))
        #expect(
            try observedIDs.withLock { try $0?.get() } == expectedIDs,
            "A separate on-disk context sees the complete old graph until the replacement commits."
        )
    }

    // MARK: Private methods

    private func makeSession(programID: UUID = UUID(), date: Date = Date(), id: UUID = UUID()) -> WorkoutSession {
        WorkoutSession(
            programID: programID,
            date: date,
            dayName: "Push",
            dayPosition: 0,
            loggedExercises: [
                LoggedExercise(
                    exerciseName: "Bench Press",
                    position: 0,
                    loggedSets: [
                        LoggedSet(kind: .warmUp, weight: 20.5, reps: 10, position: 0),
                        LoggedSet(kind: .working, weight: 80, reps: 5, position: 1, increaseNextTime: true)
                    ]
                ),
                LoggedExercise(
                    exerciseName: "Overhead Press",
                    position: 1,
                    loggedSets: [LoggedSet(kind: .working, weight: 40, reps: 8, position: 0)]
                )
            ],
            id: id
        )
    }

    private func makeService() throws -> WorkoutSessionPersistenceService {
        WorkoutSessionPersistenceService(modelContainer: try makeContainer())
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
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Rat-R3-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        return directory.appendingPathComponent("WorkoutSessions.store")
    }

    private func persistedIdentifiers(in context: ModelContext) throws -> [UUID] {
        let sessions = try context.fetch(FetchDescriptor<WorkoutSessionEntity>()).map(\.id)
        let exercises = try context.fetch(FetchDescriptor<LoggedExerciseEntity>()).map(\.id)

        let sets = try context.fetch(FetchDescriptor<LoggedSetEntity>()).map(\.id)

        return (sessions + exercises + sets).sorted(by: compareIdentifiers)
    }

    private func identifiers(session: WorkoutSession) -> [UUID] {
        ([session.id] + session.loggedExercises.flatMap { [$0.id] + $0.loggedSets.map(\.id) })
            .sorted(by: compareIdentifiers)
    }

    private func compareIdentifiers(_ lhs: UUID, _ rhs: UUID) -> Bool {
        lhs.uuidString < rhs.uuidString
    }

    private func makeSnapshot(session: WorkoutSession) -> [SessionValue] {
        [
            .session(
                session.id,
                programID: session.programID,
                session.date,
                dayName: session.dayName,
                dayPosition: session.dayPosition
            )
        ]
            + session.loggedExercises.flatMap { exercise in
                [.exercise(exercise.id, exerciseName: exercise.exerciseName, position: exercise.position)]
                    + exercise.loggedSets.map {
                        .set(
                            $0.id,
                            $0.kind,
                            weight: $0.weight,
                            reps: $0.reps,
                            position: $0.position,
                            increaseNextTime: $0.increaseNextTime
                        )
                    }
            }
    }

    // MARK: -

    private enum SessionValue: Equatable {

        case session(UUID, programID: UUID, Date, dayName: String, dayPosition: Int)
        case exercise(UUID, exerciseName: String, position: Int)
        case set(UUID, SetKind, weight: Double, reps: Int, position: Int, increaseNextTime: Bool)

    }

}
