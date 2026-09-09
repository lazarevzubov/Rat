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

}
