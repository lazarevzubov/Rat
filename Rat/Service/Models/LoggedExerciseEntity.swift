import Foundation
import SwiftData

/// A single exercise as actually logged during a workout session.
@Model
final class LoggedExerciseEntity {

    // MARK: - Properties

    /// The exercise's name at logging time, captured so later edits to the program don't rewrite history.
    var exerciseName: String
    /// The entity's stable identifier.
    var id: UUID
    /// The sets logged for this exercise, in order.
    @Relationship(deleteRule: .cascade, inverse: \LoggedSetEntity.loggedExercise)
    var loggedSets = [LoggedSetEntity]()
    /// This exercise's position within its session, used to order exercises.
    var position: Int
    /// The session this exercise belongs to.
    var workoutSession: WorkoutSessionEntity?

    // MARK: - Initialization

    /// Creates a logged exercise entity.
    /// - Parameters:
    ///   - exerciseName: The exercise's name at logging time.
    ///   - position: This exercise's position within its session.
    ///   - id: The entity's stable identifier. Defaults to a new identifier.
    init(exerciseName: String, position: Int, id: UUID = UUID()) {
        self.exerciseName = exerciseName
        self.position = position
        self.id = id
    }

}
