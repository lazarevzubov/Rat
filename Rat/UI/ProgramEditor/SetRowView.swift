import SwiftUI

/// A single row for editing one set template's kind, reps, and weight.
struct SetRowView: View {

    // MARK: - Properties

    // MARK: View protocol properties

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Picker("Kind", selection: kindBinding) {
                Text("Warm-up")
                    .tag(SetKind.warmUp)
                Text("Working")
                    .tag(SetKind.working)
            }
                .pickerStyle(.segmented)
            Stepper("Reps: \(set.targetReps)", value: $set.targetReps, in: 1...50)
            if set.kind == .warmUp {
                HStack {
                    Text("Weight")
                    TextField("Weight", value: clearableWarmUpWeightBinding, format: .number)
                        .focused(focusedField, equals: .setWeight(set.id))
                        .keyboardType(.decimalPad)
                    Text("kg")
                        .foregroundStyle(.secondary)
                }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Weight")
                    .accessibilityValue("\((set.warmUpWeight ?? 0).formatted()) kilograms")
            } else {
                HStack {
                    Text("% of Max")
                    TextField("% of Max", value: clearablePercentOfMaxBinding, format: .number)
                        .focused(focusedField, equals: .setWeight(set.id))
                        .keyboardType(.numberPad)
                    if let suggestedWeight = weightSuggestionModel.suggestedWeight(for: set, exerciseMax: exerciseMax) {
                        Text("≈ \(suggestedWeight, format: .number) kg")
                            .foregroundStyle(.secondary)
                    }
                }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Percent of Max")
                    .accessibilityValue(percentOfMaxAccessibilityValue)
            }
        }
    }

    // MARK: Private properties

    private let exerciseMax: Double
    private let fieldValueStrategy: NumberFieldValueStrategy
    private let focusedField: FocusState<ExerciseEditorView.Field?>.Binding
    private let weightSuggestionModel = WeightSuggestionModel()
    private var clearablePercentOfMaxBinding: Binding<Int?> {
        Binding {
            fieldValueStrategy.displayedValue(for: percentOfMaxBinding.wrappedValue, isFocused: weightFieldFocused)
        } set: { percentOfMaxBinding.wrappedValue = $0 ?? 0 }
    }
    private var clearableWarmUpWeightBinding: Binding<Double?> {
        Binding {
            fieldValueStrategy.displayedValue(for: warmUpWeightBinding.wrappedValue, isFocused: weightFieldFocused)
        } set: { warmUpWeightBinding.wrappedValue = $0 ?? 0 }
    }
    private var kindBinding: Binding<SetKind> {
        Binding { set.kind } set: { set.setKind(to: $0) }
    }
    private var percentOfMaxAccessibilityValue: String {
        let percent = set.percentOfMax ?? 0
        guard let suggestedWeight = weightSuggestionModel.suggestedWeight(for: set, exerciseMax: exerciseMax) else {
            return "\(percent) percent"
        }

        return "\(percent) percent, approximately \(suggestedWeight.formatted()) kilograms"
    }
    private var percentOfMaxBinding: Binding<Int> {
        Binding { set.percentOfMax ?? 0 } set: { set.percentOfMax = $0 }
    }
    @Binding
    private var set: SetTemplate
    private var warmUpWeightBinding: Binding<Double> {
        Binding { set.warmUpWeight ?? 0 } set: { set.warmUpWeight = $0 }
    }
    private var weightFieldFocused: Bool { focusedField.wrappedValue == .setWeight(set.id) }

    // MARK: - Initialization

    /// Creates a set row view.
    /// - Parameters:
    ///   - set: A binding to the set template being edited.
    ///   - exerciseMax: The exercise's current working max in kg, used to suggest a weight.
    ///   - focusedField: The enclosing exercise editor's shared focus state, so the screen can dismiss whichever row's keyboard is showing.
    ///   - fieldValueStrategy: Decides what the weight/percent fields should currently display.
    init(
        set: Binding<SetTemplate>,
        exerciseMax: Double,
        focusedField: FocusState<ExerciseEditorView.Field?>.Binding,
        fieldValueStrategy: NumberFieldValueStrategy = NumberFieldValueStrategy()
    ) {
        self.exerciseMax = exerciseMax
        self.focusedField = focusedField
        self.fieldValueStrategy = fieldValueStrategy

        _set = set
    }

}

// MARK: -

#Preview {
    @Previewable
    @FocusState
    var focusedField: ExerciseEditorView.Field?
    @Previewable
    @State
    var set = SetTemplate(kind: .working, targetReps: 5, position: 0, percentOfMax: 80)

    Form {
        SetRowView(set: $set, exerciseMax: 100, focusedField: $focusedField)
    }
}
