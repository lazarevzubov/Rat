import Foundation

/// A single exercise within a day, identified by a free-text name rather than a fixed exercise database.
struct ExerciseTemplate: Identifiable, Sendable {

    // MARK: - Properties

    /// The exercise's stable identifier.
    let id: UUID
    /// The current working max for this exercise, in kg.
    var max: Double
    /// The exercise's free-text name.
    var name: String
    /// This exercise's position within its day, used to order exercises.
    var position: Int
    /// The sets planned for this exercise, in order.
    var setTemplates: [SetTemplate]

    // MARK: - Initialization

    /// Creates an exercise template.
    /// - Parameters:
    ///   - name: The exercise's free-text name.
    ///   - position: This exercise's position within its day.
    ///   - max: The current working max for this exercise, in kg.
    ///   - setTemplates: The sets planned for this exercise. Defaults to none.
    ///   - id: The exercise's stable identifier. Defaults to a new identifier.
    init(name: String, position: Int, max: Double, setTemplates: [SetTemplate] = [], id: UUID = UUID()) {
        self.name = name
        self.position = position
        self.max = max
        self.setTemplates = setTemplates
        self.id = id
    }

}
