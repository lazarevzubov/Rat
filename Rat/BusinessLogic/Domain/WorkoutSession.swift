import Foundation

/// A single completed (or in-progress) workout, logging what actually happened on a given date.
struct WorkoutSession: Identifiable, Sendable {

    // MARK: - Properties

    /// The date this workout took place.
    var date: Date
    /// The day template's name at logging time, captured so later edits to the program don't rewrite history.
    var dayName: String
    /// The day template's position within its program at logging time, used to suggest the next day in the cycle.
    var dayPosition: Int
    /// The exercises logged during this session, in order.
    var loggedExercises: [LoggedExercise]
    /// The identifier of the program this session was logged against.
    var programID: UUID

    // MARK: Identifiable protocol properties

    let id: UUID

    // MARK: - Initialization

    /// Creates a workout session.
    /// - Parameters:
    ///   - programID: The identifier of the program this session was logged against.
    ///   - date: The date this workout took place.
    ///   - dayName: The day template's name at logging time.
    ///   - dayPosition: The day template's position within its program at logging time.
    ///   - loggedExercises: The exercises logged during this session. Defaults to none.
    ///   - id: The session's stable identifier. Defaults to a new identifier.
    init(
        programID: UUID,
        date: Date,
        dayName: String,
        dayPosition: Int,
        loggedExercises: [LoggedExercise] = [],
        id: UUID = UUID()
    ) {
        self.programID = programID
        self.date = date
        self.dayName = dayName
        self.dayPosition = dayPosition
        self.loggedExercises = loggedExercises
        self.id = id
    }

}
