import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var date: Date

    /// Captured at logging time, decoupled from the template so later program edits don't rewrite history.
    var dayName: String

    @Relationship(deleteRule: .cascade, inverse: \LoggedExercise.workoutSession)
    var loggedExercises: [LoggedExercise] = []

    init(date: Date, dayName: String) {
        self.date = date
        self.dayName = dayName
    }
}
