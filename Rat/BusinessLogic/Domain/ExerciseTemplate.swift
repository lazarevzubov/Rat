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

    // MARK: - Methods

    /// Appends a new working set at the end of `setTemplates`.
    mutating func addSet() {
        setTemplates.append(
            SetTemplate(kind: .working, targetReps: 10, position: setTemplates.count, percentOfMax: 100)
        )
    }

    /// Removes the sets at the given offsets, then renumbers the remaining sets' positions.
    /// - Parameter offsets: The offsets, within `setTemplates`, of the sets to remove.
    mutating func deleteSet(at offsets: IndexSet) {
        setTemplates.remove(atOffsets: offsets)
        renumberSets()
    }

    /// Moves sets within `setTemplates`, then renumbers all sets' positions.
    /// - Parameters:
    ///   - source: The offsets, within `setTemplates`, of the sets to move.
    ///   - destination: The offset to move the sets to.
    mutating func moveSet(from source: IndexSet, to destination: Int) {
        setTemplates.move(fromOffsets: source, toOffset: destination)
        renumberSets()
    }

    // MARK: Private methods

    private mutating func renumberSets() {
        for index in setTemplates.indices {
            setTemplates[index].position = index
        }
    }

}
