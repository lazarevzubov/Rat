import Foundation
import SwiftData

/// A single completed (or in-progress) workout, logging what actually happened on a given date.
@Model
final class WorkoutSession {

    // MARK: - Properties

    /// The date this workout took place.
    var date: Date
    /// The day template's name at logging time, captured so later edits to the program don't rewrite history.
    var dayName: String
    /// The exercises logged during this session, in order.
    @Relationship(deleteRule: .cascade, inverse: \LoggedExercise.workoutSession)
    var loggedExercises = [LoggedExercise]()

    // MARK: - Initialization

    /// Creates a workout session for the given date and day name.
    init(date: Date, dayName: String) {
        self.date = date
        self.dayName = dayName
    }

}
