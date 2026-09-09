import Foundation
import SwiftData

/// A single exercise within a day template, identified by a free-text name rather than a fixed exercise database.
@Model
final class ExerciseTemplateEntity {

    // MARK: - Properties

    /// The day this exercise belongs to.
    var dayTemplate: DayTemplateEntity?
    /// The entity's stable identifier.
    var id: UUID
    /// The current working max for this exercise, in kg.
    var max: Double
    /// The exercise's free-text name.
    var name: String
    /// This exercise's position within its day, used to order exercises.
    var position: Int
    /// The sets planned for this exercise, in order.
    @Relationship(deleteRule: .cascade, inverse: \SetTemplateEntity.exerciseTemplate)
    var setTemplates = [SetTemplateEntity]()

    // MARK: - Initialization

    /// Creates an exercise template entity.
    /// - Parameters:
    ///   - name: The exercise's free-text name.
    ///   - position: This exercise's position within its day.
    ///   - max: The current working max for this exercise, in kg.
    ///   - id: The entity's stable identifier. Defaults to a new identifier.
    init(name: String, position: Int, max: Double, id: UUID = UUID()) {
        self.name = name
        self.position = position
        self.max = max
        self.id = id
    }

}
