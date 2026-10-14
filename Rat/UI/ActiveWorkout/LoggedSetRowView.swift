import SwiftUI

/// A single row for logging one set's actual weight, reps, and whether to increase it next time.
struct LoggedSetRowView: View {

    // MARK: - Properties

    // MARK: View protocol properties

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(kindTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Stepper("Reps: \(set.reps)", value: $set.reps, in: 1...50)
                .onChange(of: set.reps) { focusedField.wrappedValue = nil }
            HStack {
                Text("Weight")
                TextField("Weight", value: $set.weight, format: .number)
                    .focused(focusedField, equals: .setWeight(set.id))
                    .keyboardType(.decimalPad)
                Text("kg")
                    .foregroundStyle(.secondary)
            }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Weight")
                .accessibilityValue("\(set.weight.formatted()) kilograms")
            Toggle("Increase Next Time", isOn: $set.increaseNextTime)
                .onChange(of: set.increaseNextTime) { focusedField.wrappedValue = nil }
        }
            .contentShape(Rectangle())
            .onTapGesture { focusedField.wrappedValue = nil }
    }

    // MARK: Private properties

    private let focusedField: FocusState<ActiveWorkoutView.Field?>.Binding
    private var kindTitle: String {
        switch set.kind {
            case .warmUp:
                "Warm-up"
            case .working:
                "Working"
        }
    }
    @Binding
    private var set: LoggedSet

    // MARK: - Initialization

    /// Creates a logged set row view.
    /// - Parameters:
    ///   - set: A binding to the logged set being edited.
    ///   - focusedField: The enclosing active workout screen's shared focus state, which the row clears when anything but its weight field is
    ///   touched.
    init(set: Binding<LoggedSet>, focusedField: FocusState<ActiveWorkoutView.Field?>.Binding) {
        self.focusedField = focusedField
        _set = set
    }

}

// MARK: -

#Preview {
    @Previewable
    @FocusState
    var focusedField: ActiveWorkoutView.Field?
    @Previewable
    @State
    var set = LoggedSet(kind: .working, weight: 80, reps: 5, position: 0)

    Form {
        LoggedSetRowView(set: $set, focusedField: $focusedField)
    }
}
