import Foundation
@testable
import Rat

actor ProgramStubService: ProgramService {

    // MARK: - Properties

    private(set) var deletedIDs = [UUID]()
    private(set) var programs = [Program]()

    // MARK: Private methods

    private var deleteError: Error?
    private var fetchError: Error?
    private var fetchExerciseNamesError: Error?
    private var saveError: Error?

    // MARK: - Methods

    func setPrograms(_ programs: [Program]) {
        self.programs = programs
    }

    func setDeleteError(_ error: Error?) {
        deleteError = error
    }

    func setFetchError(_ error: Error?) {
        fetchError = error
    }

    func setFetchExerciseNamesError(_ error: Error?) {
        fetchExerciseNamesError = error
    }

    func setSaveError(_ error: Error?) {
        saveError = error
    }

    // MARK: ProgramService protocol methods

    func delete(programWithID id: UUID) throws {
        if let deleteError {
            throw deleteError
        }

        programs.removeAll { $0.id == id }
        deletedIDs.append(id)
    }

    nonisolated func fetchExerciseNames() async throws -> [String] {
        try await isolatedFetchExerciseNames()
    }

    nonisolated func fetchPrograms() async throws -> [Program] {
        try await isolatedFetchPrograms()
    }

    func save(_ program: Program) throws {
        if let saveError {
            throw saveError
        }

        programs.removeAll { $0.id == program.id }
        programs.append(program)
    }

    // MARK: Private methods

    private func isolatedFetchExerciseNames() throws -> [String] {
        if let fetchExerciseNamesError {
            throw fetchExerciseNamesError
        }
        return Set(
            programs.flatMap {
                $0.dayTemplates.flatMap { $0.exerciseTemplates.map(\.name) }
            }
        )
            .sorted()
    }

    private func isolatedFetchPrograms() throws -> [Program] {
        if let fetchError {
            throw fetchError
        }
        return programs.sorted { $0.name < $1.name }
    }

}

// MARK: -

struct TestError: Error, Equatable { }
