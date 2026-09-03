import SwiftData

/// A workout program made up of ordered day templates.
@Model
final class Program {

    // MARK: - Properties

    /// The days that make up this program, cycled in order.
    @Relationship(deleteRule: .cascade, inverse: \DayTemplate.program)
    var dayTemplates = [DayTemplate]()
    /// The program's user-facing name.
    var name: String

    // MARK: - Initialization

    /// Creates a program.
    /// - Parameter name: The program's user-facing name.
    init(name: String) {
        self.name = name
    }

}
