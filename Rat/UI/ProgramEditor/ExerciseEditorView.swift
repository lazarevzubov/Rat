import Foundation
import SwiftUI

/// Edits a single exercise template's name, working max, and set templates.
struct ExerciseEditorView: View {

    // MARK: -

    /// The fields that can be focused within this screen, including one per set row, so all of them can share a single
    /// source of truth for "what's currently focused" and be dismissed together.
    enum Field: Hashable {

        /// The working max field.
        case max
        /// The exercise name field.
        case name
        /// A specific set's weight or percent-of-max field, identified by that set's stable ID.
        case setWeight(UUID)

    }

    // MARK: - Properties

    // MARK: View protocol properties

    var body: some View {
        Form {
            Section("Name") {
                TextField("Exercise Name", text: $exercise.name)
                    .focused($focusedField, equals: .name)
            }
            if focusedField == .name {
                let nameSuggestions = filterNameSuggestions(exercise.name)
                if !nameSuggestions.isEmpty {
                    Section("Suggestions") {
                        ForEach(nameSuggestions, id: \.self) { suggestion in
                            Button(suggestion) {
                                exercise.name = suggestion
                                focusedField = nil
                            }
                        }
                    }
                }
            }
            Section("Working Max") {
                HStack {
                    TextField("Max", value: maxBinding, format: .number)
                        .focused($focusedField, equals: .max)
                        .keyboardType(.decimalPad)
                    Text("kg")
                        .foregroundStyle(.secondary)
                }
                    .contentShape(Rectangle())
                    .onTapGesture { focusedField = nil }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Working Max")
                    .accessibilityValue("\(exercise.max.formatted()) kilograms")
            }
            Section("Sets") {
                ForEach($exercise.setTemplates) { $set in
                    SetRowView(set: $set, exerciseMax: exercise.max, focusedField: $focusedField)
                }
                    .onDelete { exercise.deleteSet(at: $0) }
                    .onMove { exercise.moveSet(from: $0, to: $1) }
                Button("Add Set", systemImage: "plus") {
                    focusedField = nil
                    withAnimation { exercise.addSet() }
                }
            }
        }
            .scrollDismissesKeyboard(.immediately)
            .onTouchBelowContent { focusedField = nil }
            .navigationTitle(
                exercise.name.isEmpty
                    ? "New Exercise"
                    : exercise.name
            )
            .onDisappear { focusedField = nil }
            .onChange(of: editMode) { focusedField = nil }
            .onChange(of: exercise.setTemplates.isEmpty) {
                if $1 {
                    editMode = .inactive
                }
            }
            .toolbar {
                if !exercise.setTemplates.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton()
                            .accessibilityLabel("Reorder or Delete Sets")
                    }
                }
            }
            .environment(\.editMode, $editMode)
    }

    // MARK: Private properties

    private let fieldValueStrategy: NumberFieldValueStrategy
    private let filterNameSuggestions: (String) -> [String]
    @State
    private var editMode = EditMode.inactive
    @Binding
    private var exercise: ExerciseTemplate
    @FocusState
    private var focusedField: Field?
    private var maxBinding: Binding<Double?> {
        Binding { fieldValueStrategy.displayedValue(for: exercise.max, isFocused: focusedField == .max) } set: {
            exercise.max = $0 ?? 0
        }
    }

    // MARK: - Initialization

    /// Creates an exercise editor view.
    /// - Parameters:
    ///   - exercise: A binding to the exercise template being edited.
    ///   - filterNameSuggestions: Filters autocomplete suggestions down to those matching a partially-typed exercise name.
    ///   - fieldValueStrategy: Decides what the max field should currently display.
    init(
        exercise: Binding<ExerciseTemplate>,
        filterNameSuggestions: @escaping (String) -> [String],
        fieldValueStrategy: NumberFieldValueStrategy = NumberFieldValueStrategy()
    ) {
        self.filterNameSuggestions = filterNameSuggestions
        self.fieldValueStrategy = fieldValueStrategy

        _exercise = exercise
    }

}

// MARK: -

#Preview {
    @Previewable
    @State
    var exercise = ExerciseTemplate(
        name: "Bench Press",
        position: 0,
        max: 100,
        setTemplates: [SetTemplate(kind: .working, targetReps: 5, position: 0, percentOfMax: 80)]
    )

    NavigationStack {
        ExerciseEditorView(exercise: $exercise) { name in
            [
                "Bench Press",
                "Squat"
            ]
                .filter { $0.localizedStandardContains(name) }
        }
    }
}
