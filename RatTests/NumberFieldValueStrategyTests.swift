@testable
import Rat
import Testing

struct NumberFieldValueStrategyTests {

    // MARK: - Methods

    @Test
    func displayedValue_returnsNil_whenFocusedAndZero() {
        #expect(
            NumberFieldValueStrategy().displayedValue(for: Double.zero, isFocused: true) == nil,
            "A focused, untouched zero-valued field displays as empty."
        )
    }

    @Test
    func displayedValue_returnsValue_whenFocusedAndNonZero() {
        #expect(
            NumberFieldValueStrategy().displayedValue(for: 7.0, isFocused: true) == 7.0,
            "A focused field with a real value keeps displaying it."
        )
    }

    @Test
    func displayedValue_returnsValue_whenUnfocusedAndZero() {
        #expect(
            NumberFieldValueStrategy().displayedValue(for: Double.zero, isFocused: false) == Double.zero,
            "An unfocused zero-valued field displays its 0, rather than staying blank."
        )
    }

    @Test
    func displayedValue_returnsValue_whenUnfocusedAndNonZero() {
        #expect(
            NumberFieldValueStrategy().displayedValue(for: 7.0, isFocused: false) == 7.0,
            "An unfocused field with a real value keeps displaying it."
        )
    }

}
