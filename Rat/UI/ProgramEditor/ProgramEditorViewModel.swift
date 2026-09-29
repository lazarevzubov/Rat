import Foundation
import Observation

/// Owns the state, business logic, and persistence calls behind `ProgramEditorView`.
@MainActor
@Observable
final class ProgramEditorViewModel {

    // MARK: - Properties

    /// The distinct exercise names used across all programs, offered as autocomplete suggestions when editing an exercise's name.
    let exerciseNameSuggestions: [String]
    /// The program being edited, or a fresh, unsaved `Program`.
    var program: Program {
        didSet { handleProgramChanged() }
    }
    /// The error from the most recent failed save, if any.
    private(set) var saveError: Error?

    // MARK: Private properties

    private let autosaveDelay: Duration
    private let onSave: () async -> Void
    private let programService: ProgramService
    private var saveTask = Task<Void, Never> {}

    // MARK: - Initialization

    /// Creates a program editor view model.
    /// - Parameters:
    ///   - program: The program to edit, or a fresh `Program` to create a new one.
    ///   - programService: The service used to persist the program.
    ///   - exerciseNameSuggestions: The distinct exercise names used across all programs, for autocomplete.
    ///   - autosaveDelay: How long to wait after an edit before persisting (so rapid edits (e.g., typing) don't each trigger their own persistence
    ///   call.)
    ///   - onSave: Awaited after the program has been successfully saved.
    init(
        program: Program,
        programService: ProgramService,
        exerciseNameSuggestions: [String],
        autosaveDelay: Duration = .milliseconds(500),
        onSave: @escaping () async -> Void
    ) {
        self.program = program
        self.programService = programService
        self.exerciseNameSuggestions = exerciseNameSuggestions
        self.autosaveDelay = autosaveDelay
        self.onSave = onSave
    }

    // MARK: - Methods

    /// Handles a tap on the Add Day button.
    /// - Returns: The task doing the autosave work triggered by `program`'s `didSet`, so tests can await its completion.
    @discardableResult
    func handleAddDayButtonTap() -> Task<Void, Never> {
        program.addDay()
        return saveTask
    }

    /// Handles the days at the given offsets being deleted from the list.
    /// - Parameter offsets: The offsets, within `program.dayTemplates`, of the days to remove.
    /// - Returns: The task doing the autosave work triggered by `program`'s `didSet`, so tests can await its completion.
    @discardableResult
    func handleDeleteDay(at offsets: IndexSet) -> Task<Void, Never> {
        program.deleteDay(at: offsets)
        return saveTask
    }

    /// Dismisses the current save error, if any.
    func dismissSaveError() {
        saveError = nil
    }

    /// Handles the days at the given offsets being reordered in the list.
    /// - Parameters:
    ///   - source: The offsets, within `program.dayTemplates`, of the days to move.
    ///   - destination: The offset to move the days to.
    /// - Returns: The task doing the autosave work triggered by `program`'s `didSet`, so tests can await its completion.
    @discardableResult
    func handleMoveDay(from source: IndexSet, to destination: Int) -> Task<Void, Never> {
        program.moveDay(from: source, to: destination)
        return saveTask
    }

    /// Filters `exerciseNameSuggestions` down to those matching the given, partially-typed exercise name.
    /// - Parameter name: The exercise name currently being typed.
    /// - Returns: Up to 5 suggestions containing `name`, excluding one identical to it.
    func filteredExerciseNameSuggestions(matching name: String) -> [String] {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            return []
        }

        return Array(
            exerciseNameSuggestions
                .filter {
                    $0.localizedStandardContains(trimmedName)
                        && ($0.localizedCaseInsensitiveCompare(trimmedName) != .orderedSame)
                }
                .prefix(5)
        )
    }

    /// Handles any edit to `program`, saving it after `autosaveDelay` once edits settle, unless it's still unnamed.
    /// - Returns: The task doing the work, so tests can await its completion.
    @discardableResult
    func handleProgramChanged() -> Task<Void, Never> {
        saveTask.cancel()

        let program = program

        let task = Task {
            try? await Task.sleep(for: autosaveDelay)
            guard !Task.isCancelled,
                  !program.name.trimmingCharacters(in: .whitespaces).isEmpty else {
                return
            }

            do {
                try await programService.save(program)
                await onSave()
            } catch {
                saveError = error
            }
        }
        saveTask = task

        return task
    }

}
