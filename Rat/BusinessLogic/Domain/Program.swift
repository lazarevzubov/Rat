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

    // MARK: - Methods

    /// Appends a new, empty day at the end of `dayTemplates`.
    mutating func addDay() {
        dayTemplates.append(DayTemplate(name: "", position: dayTemplates.count))
    }

    /// Removes the days at the given offsets, then renumbers the remaining days' positions.
    /// - Parameter offsets: The offsets, within `dayTemplates`, of the days to remove.
    mutating func deleteDay(at offsets: IndexSet) {
        dayTemplates.remove(atOffsets: offsets)
        renumberDays()
    }

    /// Moves days within `dayTemplates`, then renumbers all days' positions.
    /// - Parameters:
    ///   - source: The offsets, within `dayTemplates`, of the days to move.
    ///   - destination: The offset to move the days to.
    mutating func moveDay(from source: IndexSet, to destination: Int) {
        dayTemplates.move(fromOffsets: source, toOffset: destination)
        renumberDays()
    }

    // MARK: Private methods

    private mutating func renumberDays() {
        for index in dayTemplates.indices {
            dayTemplates[index].position = index
        }
    }

}
