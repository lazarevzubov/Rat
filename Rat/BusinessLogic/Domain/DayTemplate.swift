import Foundation

/// A single day within a program (e.g., "Day 1"), holding the exercises planned for that day.
struct DayTemplate: Identifiable, Sendable {

    // MARK: - Properties

    /// The exercises planned for this day, in order.
    var exerciseTemplates: [ExerciseTemplate]
    /// The day's stable identifier.
    let id: UUID
    /// The day's user-facing name (e.g., "Day 1").
    var name: String
    /// This day's position within its program, used to cycle through days in order.
    var position: Int

    // MARK: - Initialization

    /// Creates a day template.
    /// - Parameters:
    ///   - name: The day's user-facing name (e.g., "Day 1").
    ///   - position: This day's position within its program.
    ///   - exerciseTemplates: The exercises planned for this day. Defaults to none.
    ///   - id: The day's stable identifier. Defaults to a new identifier.
    init(name: String, position: Int, exerciseTemplates: [ExerciseTemplate] = [], id: UUID = UUID()) {
        self.name = name
        self.position = position
        self.exerciseTemplates = exerciseTemplates
        self.id = id
    }

    // MARK: - Methods

    /// Appends a new, empty exercise at the end of `exerciseTemplates`.
    mutating func addExercise() {
        exerciseTemplates.append(ExerciseTemplate(name: "", position: exerciseTemplates.count, max: 0))
    }

    /// Removes the exercises at the given offsets, then renumbers the remaining exercises' positions.
    /// - Parameter offsets: The offsets, within `exerciseTemplates`, of the exercises to remove.
    mutating func deleteExercise(at offsets: IndexSet) {
        exerciseTemplates.remove(atOffsets: offsets)
        renumberExercises()
    }

    /// Moves exercises within `exerciseTemplates`, then renumbers all exercises' positions.
    /// - Parameters:
    ///   - source: The offsets, within `exerciseTemplates`, of the exercises to move.
    ///   - destination: The offset to move the exercises to.
    mutating func moveExercise(from source: IndexSet, to destination: Int) {
        exerciseTemplates.move(fromOffsets: source, toOffset: destination)
        renumberExercises()
    }

    // MARK: Private methods

    private mutating func renumberExercises() {
        for index in exerciseTemplates.indices {
            exerciseTemplates[index].position = index
        }
    }

}
