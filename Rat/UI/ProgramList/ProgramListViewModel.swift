import Foundation
import Observation

/// Owns the state and persistence calls behind `ProgramListView`.
@MainActor
@Observable
final class ProgramListViewModel {

    // MARK: - Properties

    /// A program being created, presented for editing until it's saved or discarded.
    var newProgram: Program?
    /// The error from the most recent failed load, if any.
    private(set) var loadError: Error?
    /// The currently loaded programs.
    private(set) var programs = [Program]()

    // MARK: Private properties

    private let programService: ProgramService

    // MARK: - Initialization

    /// Creates a program list view model.
    /// - Parameter programService: The service used to load and delete programs.
    init(programService: ProgramService) {
        self.programService = programService
    }

    // MARK: - Methods

    /// Handles a tap on the Add Program button.
    func handleAddProgramButtonTap() {
        newProgram = Program(name: "")
    }

    /// Handles the programs at the given offsets being deleted from the list.
    /// - Parameter offsets: The offsets, within `programs`, of the programs to delete.
    /// - Returns: The task doing the persistence work, so tests can await its completion.
    @discardableResult
    func handleDelete(at offsets: IndexSet) -> Task<Void, Never> {
        let idsToDelete = offsets.map { programs[$0].id }
        programs.remove(atOffsets: offsets)

        let programService = programService

        return Task {
            await withTaskGroup(of: Void.self) { group in
                for id in idsToDelete {
                    group.addTask { try? await programService.delete(programWithID: id) }
                }
            }
        }
    }

    /// Dismisses the current load error, if any.
    func dismissLoadError() {
        loadError = nil
    }

    /// Handles this list's view appearing.
    func handleAppear() async {
        do {
            programs = try await programService.fetchPrograms()
        } catch {
            loadError = error
        }
    }

    /// Creates a view model for editing the given program, wired to reload this list once it's saved.
    /// - Parameter program: The program to edit, or a fresh `Program` to create a new one.
    func makeProgramEditorViewModel(for program: Program) -> ProgramEditorViewModel {
        ProgramEditorViewModel(program: program, programService: programService) { [weak self] in
            await self?.handleAppear()
        }
    }

}
