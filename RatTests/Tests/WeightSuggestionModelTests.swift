import Testing
@testable
import Rat

struct WeightSuggestionModelTests {

    // MARK: - Methods

    @Test
    func suggestedWeight_returnsNil_whenWarmUp() {
        let set = SetTemplate(kind: .warmUp, targetReps: 10, position: 0, warmUpWeight: 20.0)

        #expect(
            WeightSuggestionModel().suggestedWeight(for: set, exerciseMax: 100.0) == nil,
            "Warm-up sets have no suggested weight."
        )
    }

    @Test
    func suggestedWeight_returnsNil_whenPercentOfMaxMissing() {
        let set = SetTemplate(kind: .working, targetReps: 10, position: 0)

        #expect(
            WeightSuggestionModel().suggestedWeight(for: set, exerciseMax: 100.0) == nil,
            "A working set without a percent has no suggested weight."
        )
    }

    @Test
    func suggestedWeight_returnsExactValue_whenAlreadyRounded() {
        let set = SetTemplate(kind: .working, targetReps: 10, position: 0, percentOfMax: 50)

        #expect(WeightSuggestionModel().suggestedWeight(for: set, exerciseMax: 100.0) == 50.0, "50% of 100 kg is 50 kg.")
    }

    @Test
    func suggestedWeight_roundsDownToNearestHalfKilogram_whenBelowMidpoint() {
        let set = SetTemplate(kind: .working, targetReps: 10, position: 0, percentOfMax: 50)

        #expect(
            WeightSuggestionModel().suggestedWeight(for: set, exerciseMax: 90.2) == 45.0,
            "50% of 90.2 kg is 45.1 kg, which rounds down to 45 kg."
        )
    }

    @Test
    func suggestedWeight_roundsUpToNearestHalfKilogram_whenAboveMidpoint() {
        let set = SetTemplate(kind: .working, targetReps: 10, position: 0, percentOfMax: 80)

        #expect(
            WeightSuggestionModel().suggestedWeight(for: set, exerciseMax: 61.0) == 49.0,
            "80% of 61 kg is 48.8 kg, which rounds up to 49 kg."
        )
    }

}
