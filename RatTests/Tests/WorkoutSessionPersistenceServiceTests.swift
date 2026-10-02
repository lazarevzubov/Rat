import Foundation
@testable
import Rat
import SwiftData
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
        #expect(fetched?.loggedExercises.first?.exerciseName == "Bench Press", "Nested exercises and sets round-trip.")
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

    // MARK: Private methods

    private func makeSession(programID: UUID = UUID(), date: Date = Date()) -> WorkoutSession {
        WorkoutSession(
            programID: programID,
            date: date,
            dayName: "Push",
            dayPosition: 0,
            loggedExercises: [
                LoggedExercise(
                    exerciseName: "Bench Press",
                    position: 0,
                    loggedSets: [LoggedSet(kind: .working, weight: 80.0, reps: 5, position: 0)]
                )
            ]
        )
    }

    private func makeService() throws -> WorkoutSessionPersistenceService {
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

        return WorkoutSessionPersistenceService(modelContainer: container)
    }

}
