/// Computes suggested weights for planned sets, shared across any screen that needs to display one.
struct WeightSuggestionModel {

    // MARK: - Methods

    /// The suggested weight for a working set, in kg, rounded to the nearest 0.5 kg.
    /// - Parameters:
    ///   - set: The set template to suggest a weight for.
    ///   - exerciseMax: The current working max for the exercise the set belongs to, in kg.
    /// - Returns: The suggested weight, or `nil` if `set.kind != .working`.
    func suggestedWeight(for set: SetTemplate, exerciseMax: Double) -> Double? {
        guard set.kind == .working,
              let percentOfMax = set.percentOfMax else {
            return nil
        }
        return (exerciseMax * Double(percentOfMax) / 100.0 * 2.0).rounded() / 2.0
    }

}
