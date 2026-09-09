import Foundation
import SwiftData

/// A single day within a program template (e.g., "Day 1"), holding the exercises planned for that day.
@Model
final class DayTemplateEntity {

    // MARK: - Properties

    /// The exercises planned for this day, in order.
    @Relationship(deleteRule: .cascade, inverse: \ExerciseTemplateEntity.dayTemplate)
    var exerciseTemplates = [ExerciseTemplateEntity]()
    /// The entity's stable identifier.
    var id: UUID
    /// The day's user-facing name (e.g., "Day 1").
    var name: String
    /// This day's position within its program, used to cycle through days in order.
    var position: Int
    /// The program this day belongs to.
    var program: ProgramEntity?

    // MARK: - Initialization

    /// Creates a day template entity.
    /// - Parameters:
    ///   - name: The day's user-facing name (e.g., "Day 1").
    ///   - position: This day's position within its program.
    ///   - id: The entity's stable identifier. Defaults to a new identifier.
    init(name: String, position: Int, id: UUID = UUID()) {
        self.name = name
        self.position = position
        self.id = id
    }

}
