/// Decides what value an editable numeric field should currently display, based on its underlying value and focus state.
struct NumberFieldValueStrategy {

    // MARK: - Methods

    /// The value a field should display.
    /// - Parameters:
    ///   - value: The field's current underlying value.
    ///   - isFocused: Whether the field is currently focused for editing.
    /// - Returns: The value to display, or `nil` to show an empty field instead.
    func displayedValue<Value: Numeric & Equatable>(for value: Value, isFocused: Bool) -> Value? {
        (isFocused
            && (value == .zero))
            ? nil
            : value
    }

}
