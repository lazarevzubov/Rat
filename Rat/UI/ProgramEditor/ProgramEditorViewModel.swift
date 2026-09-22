import Foundation
import Observation

/// Owns the state, business logic, and persistence calls behind `ProgramEditorView`.
@MainActor
@Observable
final class ProgramEditorViewModel {

    // MARK: - Properties

    /// The distinct exercise names used across all programs, offered as autocomplete suggestions when editing an exercise's name.
    let exerciseNameSuggestions: [String]
    /// Set to `true` once the program has been saved, telling the view it should dismiss itself.
    private(set) var didSave = false
    /// The program being edited, or a fresh, unsaved `Program`.
    var program: Program
    /// The error from the most recent failed save, if any.
    private(set) var saveError: Error?

    // MARK: Private properties

    private let onSave: () async -> Void
    private let programService: ProgramService

    // MARK: - Initialization

    /// Creates a program editor view model.
    /// - Parameters:
    ///   - program: The program to edit, or a fresh `Program` to create a new one.
    ///   - programService: The service used to persist the program.
    ///   - exerciseNameSuggestions: The distinct exercise names used across all programs, for autocomplete.
    ///   - onSave: Awaited after the program has been successfully saved, before `didSave` is set.
    init(
        program: Program,
        programService: ProgramService,
        exerciseNameSuggestions: [String],
        onSave: @escaping () async -> Void
    ) {
        self.program = program
        self.programService = programService
        self.exerciseNameSuggestions = exerciseNameSuggestions
        self.onSave = onSave
    }

    // MARK: - Methods

    /// Handles a tap on the Add Day button.
    func handleAddDayButtonTap() {
        program.addDay()
    }

    /// Handles the days at the given offsets being deleted from the list.
    /// - Parameter offsets: The offsets, within `program.dayTemplates`, of the days to remove.
    func handleDeleteDay(at offsets: IndexSet) {
        program.deleteDay(at: offsets)
    }

    /// Dismisses the current save error, if any.
    func dismissSaveError() {
        saveError = nil
    }

    /// Handles the days at the given offsets being reordered in the list.
    /// - Parameters:
    ///   - source: The offsets, within `program.dayTemplates`, of the days to move.
    ///   - destination: The offset to move the days to.
    func handleMoveDay(from source: IndexSet, to destination: Int) {
        program.moveDay(from: source, to: destination)
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

    /// Handles a tap on the Save button.
    /// - Returns: The task doing the work, so tests can await its completion.
    @discardableResult
    func handleSaveButtonTap() -> Task<Void, Never> {
        Task {
            do {
                try await programService.save(program)
                await onSave()

                didSave = true
            } catch {
                saveError = error
            }
        }
    }

}
