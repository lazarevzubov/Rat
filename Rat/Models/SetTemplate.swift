import SwiftData

/// A single planned set within an exercise template—either a warm-up or a working set.
@Model
final class SetTemplate {

    // MARK: - Properties

    /// The exercise this set belongs to.
    var exerciseTemplate: ExerciseTemplate?
    /// Whether this is a warm-up or working set.
    var kind: SetKind
    /// Percent of the exercise's max, used only when `kind == .working`.
    var percentOfMax: Int?
    /// This set's position within its exercise, used to order sets.
    var position: Int
    /// The number of reps this set targets.
    var targetReps: Int
    /// Free weight entry in kg, used only when `kind == .warmup`.
    var warmupWeight: Double?

    // MARK: - Initialization

    /// Creates a set template.
    /// - Parameters:
    ///   - kind: Whether this is a warm-up or working set.
    ///   - targetReps: The number of reps this set targets.
    ///   - position: This set's position within its exercise.
    ///   - warmupWeight: Free weight entry in kg, used only when `kind == .warmup`. Defaults to `nil`.
    ///   - percentOfMax: Percent of the exercise's max, used only when `kind == .working`. Defaults to `nil`.
    init(kind: SetKind, targetReps: Int, position: Int, warmupWeight: Double? = nil, percentOfMax: Int? = nil) {
        self.kind = kind
        self.targetReps = targetReps
        self.position = position
        self.warmupWeight = warmupWeight
        self.percentOfMax = percentOfMax
    }

}
