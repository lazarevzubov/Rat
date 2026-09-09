import Foundation
import SwiftData

/// A single completed (or in-progress) workout, logging what actually happened on a given date.
@Model
final class WorkoutSessionEntity {

    // MARK: - Properties

    /// The date this workout took place.
    var date: Date
    /// The day template's name at logging time, captured so later edits to the program don't rewrite history.
    var dayName: String
    /// The entity's stable identifier.
    var id: UUID
    /// The exercises logged during this session, in order.
    @Relationship(deleteRule: .cascade, inverse: \LoggedExerciseEntity.workoutSession)
    var loggedExercises = [LoggedExerciseEntity]()

    // MARK: - Initialization

    /// Creates a workout session entity.
    /// - Parameters:
    ///   - date: The date this workout took place.
    ///   - dayName: The day template's name at logging time.
    ///   - id: The entity's stable identifier. Defaults to a new identifier.
    init(date: Date, dayName: String, id: UUID = UUID()) {
        self.date = date
        self.dayName = dayName
        self.id = id
    }

}
