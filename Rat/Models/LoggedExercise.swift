import Foundation
import SwiftData

@Model
final class LoggedExercise {
    /// Captured at logging time, decoupled from the template so later program edits don't rewrite history.
    var exerciseName: String
    var position: Int

    var workoutSession: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \LoggedSet.loggedExercise)
    var loggedSets: [LoggedSet] = []

    init(exerciseName: String, position: Int) {
        self.exerciseName = exerciseName
        self.position = position
    }
}
