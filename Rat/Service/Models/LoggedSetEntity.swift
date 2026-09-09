import Foundation
import SwiftData

/// A single set as actually logged during a workout.
@Model
final class LoggedSetEntity {

    // MARK: - Properties

    /// Tapped by the user after a set felt too easy; surfaced as a banner on this exercise next session.
    var increaseNextTime: Bool
    /// The entity's stable identifier.
    var id: UUID
    /// Whether this was a warm-up or working set.
    var kind: SetKind
    /// The exercise this set belongs to.
    var loggedExercise: LoggedExerciseEntity?
    /// This set's position within its exercise, used to order sets.
    var position: Int
    /// The number of reps actually performed.
    var reps: Int
    /// The weight actually used, in kg.
    var weight: Double

    // MARK: - Initialization

    /// Creates a logged set entity.
    /// - Parameters:
    ///   - kind: Whether this was a warm-up or working set.
    ///   - weight: The weight actually used, in kg.
    ///   - reps: The number of reps actually performed.
    ///   - position: This set's position within its exercise.
    ///   - increaseNextTime: Whether the user flagged this set to increase next time.
    ///   - id: The entity's stable identifier. Defaults to a new identifier.
    init(kind: SetKind, weight: Double, reps: Int, position: Int, increaseNextTime: Bool = false, id: UUID = UUID()) {
        self.kind = kind
        self.weight = weight
        self.reps = reps
        self.position = position
        self.increaseNextTime = increaseNextTime
        self.id = id
    }

}
