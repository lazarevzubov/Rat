import Foundation

/// A single set as actually logged during a workout.
struct LoggedSet: Identifiable, Sendable {

    // MARK: - Properties

    /// Whether the user flagged this set to increase next time.
    var increaseNextTime: Bool
    /// Whether this was a warm-up or working set.
    var kind: SetKind
    /// This set's position within its exercise, used to order sets.
    var position: Int
    /// The number of reps actually performed.
    var reps: Int
    /// The weight actually used, in kg.
    var weight: Double

    // MARK: Identifiable protocol properties

    let id: UUID

    // MARK: - Initialization

    /// Creates a logged set.
    /// - Parameters:
    ///   - kind: Whether this was a warm-up or working set.
    ///   - weight: The weight actually used, in kg.
    ///   - reps: The number of reps actually performed.
    ///   - position: This set's position within its exercise.
    ///   - increaseNextTime: Whether the user flagged this set to increase next time. Defaults to `false`.
    ///   - id: The set's stable identifier. Defaults to a new identifier.
    init(kind: SetKind, weight: Double, reps: Int, position: Int, increaseNextTime: Bool = false, id: UUID = UUID()) {
        self.kind = kind
        self.weight = weight
        self.reps = reps
        self.position = position
        self.increaseNextTime = increaseNextTime
        self.id = id
    }

}
