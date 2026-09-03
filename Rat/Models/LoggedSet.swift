import SwiftData

/// A single set as actually logged during a workout.
@Model
final class LoggedSet {

    // MARK: - Properties

    /// Tapped by the user after a set felt too easy; surfaced as a banner on this exercise next session.
    var increaseNextTime: Bool
    /// Whether this was a warm-up or working set.
    var kind: SetKind
    /// The exercise this set belongs to.
    var loggedExercise: LoggedExercise?
    /// This set's position within its exercise, used to order sets.
    var position: Int
    /// The number of reps actually performed.
    var reps: Int
    /// The weight actually used, in kg.
    var weight: Double

    // MARK: - Initialization

    /// Creates a logged set with the given kind, weight, reps, and position.
    init(kind: SetKind, weight: Double, reps: Int, position: Int, increaseNextTime: Bool = false) {
        self.kind = kind
        self.weight = weight
        self.reps = reps
        self.position = position
        self.increaseNextTime = increaseNextTime
    }

}
