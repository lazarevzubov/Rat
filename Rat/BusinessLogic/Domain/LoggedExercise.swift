import Foundation

/// A single exercise as actually logged during a workout session.
struct LoggedExercise: Identifiable, Sendable {

    // MARK: - Properties

    /// The exercise's name at logging time, captured so later edits to the program don't rewrite history.
    var exerciseName: String
    /// The sets logged for this exercise, in order.
    var loggedSets: [LoggedSet]
    /// This exercise's position within its session, used to order exercises.
    var position: Int

    // MARK: Identifiable protocol properties

    let id: UUID

    // MARK: - Initialization

    /// Creates a logged exercise.
    /// - Parameters:
    ///   - exerciseName: The exercise's name at logging time.
    ///   - position: This exercise's position within its session.
    ///   - loggedSets: The sets logged for this exercise. Defaults to none.
    ///   - id: The exercise's stable identifier. Defaults to a new identifier.
    init(exerciseName: String, position: Int, loggedSets: [LoggedSet] = [], id: UUID = UUID()) {
        self.exerciseName = exerciseName
        self.position = position
        self.loggedSets = loggedSets
        self.id = id
    }

}
