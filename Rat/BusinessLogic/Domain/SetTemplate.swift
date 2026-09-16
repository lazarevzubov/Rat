import Foundation

/// A single planned set within an exercise—either a warm-up or a working set.
struct SetTemplate: Identifiable, Sendable {

    // MARK: - Properties

    /// The set's stable identifier.
    let id: UUID
    /// Whether this is a warm-up or working set.
    var kind: SetKind
    /// Percent of the exercise's max, used only when `kind == .working`.
    var percentOfMax: Int?
    /// This set's position within its exercise, used to order sets.
    var position: Int
    /// The number of reps this set targets.
    var targetReps: Int
    /// Free weight entry in kg, used only when `kind == .warmUp`.
    var warmUpWeight: Double?

    // MARK: - Initialization

    /// Creates a set template.
    /// - Parameters:
    ///   - kind: Whether this is a warm-up or working set.
    ///   - targetReps: The number of reps this set targets.
    ///   - position: This set's position within its exercise.
    ///   - warmUpWeight: Free weight entry in kg, used only when `kind == .warmUp`. Defaults to `nil`.
    ///   - percentOfMax: Percent of the exercise's max, used only when `kind == .working`. Defaults to `nil`.
    ///   - id: The set's stable identifier. Defaults to a new identifier.
    init(
        kind: SetKind,
        targetReps: Int,
        position: Int,
        warmUpWeight: Double? = nil,
        percentOfMax: Int? = nil,
        id: UUID = UUID()
    ) {
        self.kind = kind
        self.targetReps = targetReps
        self.position = position
        self.warmUpWeight = warmUpWeight
        self.percentOfMax = percentOfMax
        self.id = id
    }

    // MARK: - Methods

    /// Switches this set to the given kind, clearing the field for the previous kind and defaulting the field for the
    /// new one so the set is never left with a stale value from the kind it's switching away from.
    /// - Parameter newKind: The kind to switch to.
    mutating func setKind(to newKind: SetKind) {
        kind = newKind
        switch newKind {
            case .warmUp:
                percentOfMax = nil
                warmUpWeight = warmUpWeight ?? .zero
            case .working:
                percentOfMax = percentOfMax ?? 100
                warmUpWeight = nil
        }
    }

}
