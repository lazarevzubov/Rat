import Foundation
@testable
import Rat

actor WorkoutSessionStubService: WorkoutSessionService {

    // MARK: - Properties

    private(set) var savedSessions = [WorkoutSession]()

    // MARK: Private methods

    private var fetchError: Error?
    private var saveError: Error?
    private var sessions = [WorkoutSession]()

    // MARK: - Methods

    func setSessions(_ sessions: [WorkoutSession]) {
        self.sessions = sessions
    }

    func setFetchError(_ error: Error?) {
        fetchError = error
    }

    func setSaveError(_ error: Error?) {
        saveError = error
    }

    // MARK: WorkoutSessionService protocol methods

    func fetchMostRecentSession(forProgramWithID programID: UUID) throws -> WorkoutSession? {
        if let fetchError {
            throw fetchError
        }
        return sessions.filter { $0.programID == programID }.max { $0.date < $1.date }
    }

    func save(_ session: WorkoutSession) throws {
        if let saveError {
            throw saveError
        }
        savedSessions.append(session)
    }

}
