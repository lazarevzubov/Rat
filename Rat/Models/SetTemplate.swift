import Foundation
import SwiftData

@Model
final class SetTemplate {
    var kind: SetKind
    var targetReps: Int
    var position: Int

    /// Free weight entry in kg, used only when `kind == .warmup`.
    var warmupWeight: Double?

    /// Percent of the exercise's max, used only when `kind == .working`.
    var percentOfMax: Int?

    var exerciseTemplate: ExerciseTemplate?

    init(kind: SetKind, targetReps: Int, position: Int, warmupWeight: Double? = nil, percentOfMax: Int? = nil) {
        self.kind = kind
        self.targetReps = targetReps
        self.position = position
        self.warmupWeight = warmupWeight
        self.percentOfMax = percentOfMax
    }
}
