import Foundation
import SwiftData

@Model
final class LoggedSet {
    var kind: SetKind
    var weight: Double
    var reps: Int
    var position: Int

    /// Tapped by the user after a set felt too easy; surfaced as a banner on this exercise next session.
    var increaseNextTime: Bool

    var loggedExercise: LoggedExercise?

    init(kind: SetKind, weight: Double, reps: Int, position: Int, increaseNextTime: Bool = false) {
        self.kind = kind
        self.weight = weight
        self.reps = reps
        self.position = position
        self.increaseNextTime = increaseNextTime
    }
}
