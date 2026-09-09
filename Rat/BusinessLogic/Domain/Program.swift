import Foundation

/// A workout program made up of ordered day templates.
struct Program: Identifiable, Sendable {

    // MARK: - Properties

    /// The days that make up this program, cycled in order.
    var dayTemplates: [DayTemplate]
    /// The program's stable identifier.
    let id: UUID
    /// The program's user-facing name.
    var name: String

    // MARK: - Initialization

    /// Creates a program.
    /// - Parameters:
    ///   - name: The program's user-facing name.
    ///   - dayTemplates: The days that make up this program. Defaults to none.
    ///   - id: The program's stable identifier. Defaults to a new identifier.
    init(name: String, dayTemplates: [DayTemplate] = [], id: UUID = UUID()) {
        self.name = name
        self.dayTemplates = dayTemplates
        self.id = id
    }

}
