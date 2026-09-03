import SwiftData

/// A single exercise within a day template, identified by a free-text name rather than a fixed exercise database.
@Model
final class ExerciseTemplate {

    // MARK: - Properties

    /// The day this exercise belongs to.
    var dayTemplate: DayTemplate?
    /// The exercise's free-text name.
    var name: String
    /// This exercise's position within its day, used to order exercises.
    var position: Int
    /// The sets planned for this exercise, in order.
    @Relationship(deleteRule: .cascade, inverse: \SetTemplate.exerciseTemplate)
    var setTemplates = [SetTemplate]()

    // MARK: - Initialization

    /// Creates an exercise template with the given name and position.
    /// - Parameters:
    ///   - name: The exercise's free-text name.
    ///   - position: This exercise's position within its day.
    init(name: String, position: Int) {
        self.name = name
        self.position = position
    }

}
