import Foundation
import Observation

/// Owns the state and persistence calls behind `ProgramListView`.
@MainActor
@Observable
final class ProgramListViewModel {

    // MARK: - Properties

    /// A program being created, presented for editing until it's saved or discarded.
    var newProgram: Program?
    /// The distinct exercise names used across all programs, offered as autocomplete suggestions when editing an exercise's name.
    private(set) var exerciseNameSuggestions = [String]()
    /// The error from the most recent failed operation, if any.
    private(set) var presentedError: Error?
    /// The title for the most recent error alert, if any.
    private(set) var presentedErrorTitle: String?
    /// The currently loaded programs.
    private(set) var programs = [Program]()

    // MARK: Private properties

    private let programService: ProgramService
    private let workoutSessionService: WorkoutSessionService

    // MARK: - Initialization

    /// Creates a program list view model.
    /// - Parameters:
    ///   - programService: The service used to load and delete programs.
    ///   - workoutSessionService: The service used to log and fetch workout sessions.
    init(programService: ProgramService, workoutSessionService: WorkoutSessionService) {
        self.programService = programService
        self.workoutSessionService = workoutSessionService
    }

    // MARK: - Methods

    /// Handles a tap on the Add Program button.
    func handleAddProgramButtonTap() {
        newProgram = Program(name: "")
    }

    /// Handles the programs at the given offsets being deleted from the list.
    /// - Parameter offsets: The offsets, within `programs`, of the programs to delete.
    func handleDelete(at offsets: IndexSet) {
        let programsToDelete = offsets.map { programs[$0] }
        programs.remove(atOffsets: offsets)

        let programService = programService
        Task {
            var failedPrograms = [Program]()
            var deletionError: Error?

            for program in programsToDelete {
                do {
                    try await programService.delete(programWithID: program.id)
                } catch {
                    failedPrograms.append(program)
                    deletionError = deletionError ?? error
                }
            }

            guard !failedPrograms.isEmpty,
                  let deletionError else {
                return
            }

            let programIDs = Set(programs.map(\.id))
            programs.append(contentsOf: failedPrograms.filter { !programIDs.contains($0.id) })

            programs.sort { $0.name < $1.name }

            presentedErrorTitle = failedPrograms.count == 1 ? "Couldn't delete program" : "Couldn't delete programs"
            presentedError = deletionError
        }
    }

    /// Dismisses the current error alert, if any.
    func dismissPresentedError() {
        presentedError = nil
        presentedErrorTitle = nil
    }

    /// Handles this list's view appearing.
    func handleAppear() async {
        await reloadProgramsAndExerciseNameSuggestions()
    }

    /// Creates a view model for editing the given program.
    /// - Parameter program: The program to edit, or a fresh `Program` to create a new one.
    func makeProgramEditorViewModel(program: Program) -> ProgramEditorViewModel {
        ProgramEditorViewModel(
            program: program,
            programService: programService,
            exerciseNameSuggestions: exerciseNameSuggestions,
            workoutSessionService: workoutSessionService
        ) { [weak self] in
            await self?.reloadProgramsAndExerciseNameSuggestions()
        }
    }

    // MARK: Private methods

    private func reloadProgramsAndExerciseNameSuggestions() async {
        async let fetchedPrograms = programService.fetchPrograms()
        async let fetchedExerciseNames = programService.fetchExerciseNames()

        do {
            programs = try await fetchedPrograms
        } catch {
            presentedErrorTitle = "Couldn't load programs"
            presentedError = error
        }
        exerciseNameSuggestions = (try? await fetchedExerciseNames) ?? []
    }

}
