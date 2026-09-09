import Foundation
import SwiftData

/// A workout program made up of ordered day templates.
@Model
final class ProgramEntity {

    // MARK: - Properties

    /// The days that make up this program, cycled in order.
    @Relationship(deleteRule: .cascade, inverse: \DayTemplateEntity.program)
    var dayTemplates = [DayTemplateEntity]()
    /// The entity's stable identifier.
    var id: UUID
    /// The program's user-facing name.
    var name: String

    // MARK: - Initialization

    /// Creates a program entity.
    /// - Parameters:
    ///   - name: The program's user-facing name.
    ///   - id: The entity's stable identifier. Defaults to a new identifier.
    init(name: String, id: UUID = UUID()) {
        self.name = name
        self.id = id
    }

}
