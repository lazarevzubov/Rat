import SwiftData

/// A single day within a program template (e.g. "Day 1"), holding the exercises planned for that day.
@Model
final class DayTemplate {

    // MARK: - Properties

    /// The exercises planned for this day, in order.
    @Relationship(deleteRule: .cascade, inverse: \ExerciseTemplate.dayTemplate)
    var exerciseTemplates = [ExerciseTemplate]()
    /// The day's user-facing name (e.g. "Day 1").
    var name: String
    /// This day's position within its program, used to cycle through days in order.
    var position: Int
    /// The program this day belongs to.
    var program: Program?

    // MARK: - Initialization

    /// Creates a day template with the given name and position.
    init(name: String, position: Int) {
        self.name = name
        self.position = position
    }

}
