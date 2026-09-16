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
    /// The day template's position within its program at logging time, used to suggest the next day in the cycle.
    var dayPosition: Int
    /// The entity's stable identifier.
    var id: UUID
    /// The exercises logged during this session, in order.
    @Relationship(deleteRule: .cascade, inverse: \LoggedExerciseEntity.workoutSession)
    var loggedExercises = [LoggedExerciseEntity]()
    /// The identifier of the program this session was logged against.
    var programID: UUID

    // MARK: - Initialization

    /// Creates a workout session entity.
    /// - Parameters:
    ///   - programID: The identifier of the program this session was logged against.
    ///   - date: The date this workout took place.
    ///   - dayName: The day template's name at logging time.
    ///   - dayPosition: The day template's position within its program at logging time.
    ///   - id: The entity's stable identifier. Defaults to a new identifier.
    init(programID: UUID, date: Date, dayName: String, dayPosition: Int, id: UUID = UUID()) {
        self.programID = programID
        self.date = date
        self.dayName = dayName
        self.dayPosition = dayPosition
        self.id = id
    }

}
