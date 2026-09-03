import SwiftData

/// A single exercise as actually logged during a workout session.
@Model
final class LoggedExercise {

    // MARK: - Properties

    /// The exercise's name at logging time, captured so later edits to the program don't rewrite history.
    var exerciseName: String
    /// The sets logged for this exercise, in order.
    @Relationship(deleteRule: .cascade, inverse: \LoggedSet.loggedExercise)
    var loggedSets = [LoggedSet]()
    /// This exercise's position within its session, used to order exercises.
    var position: Int
    /// The session this exercise belongs to.
    var workoutSession: WorkoutSession?

    // MARK: - Initialization

    /// Creates a logged exercise with the given name and position.
    init(exerciseName: String, position: Int) {
        self.exerciseName = exerciseName
        self.position = position
    }

}
