import SwiftUI

/// Edits a single day template's name and exercise templates.
struct DayEditorView: View {

    // MARK: - Properties

    // MARK: View protocol properties

    var body: some View {
        Form {
            Section("Name") {
                TextField("Day Name", text: $day.name)
                    .focused($focusedField, equals: .name)
            }
            Section("Exercises") {
                ForEach($day.exerciseTemplates) { $exercise in
                    NavigationLink(
                        exercise.name.isEmpty
                            ? "Untitled Exercise"
                            : exercise.name
                    ) {
                        ExerciseEditorView(exercise: $exercise, filterNameSuggestions: filterExerciseNameSuggestions)
                    }
                        .simultaneousGesture(TapGesture().onEnded { focusedField = nil })
                }
                    .onDelete(perform: { day.deleteExercise(at: $0) })
                    .onMove(perform: { day.moveExercise(from: $0, to: $1) })
                Button("Add Exercise", systemImage: "plus") {
                    focusedField = nil
                    withAnimation { day.addExercise() }
                }
                    .id(ScrollTarget.addButton)
            }
        }
            .scrollDismissesKeyboard(.immediately)
            .onTouchBelowContent { focusedField = nil }
            .scrolls(to: .addButton, whenCountGrows: day.exerciseTemplates.count)
            .navigationTitle(
                day.name.isEmpty
                    ? "New Day"
                    : day.name
            )
            .onDisappear { focusedField = nil }
            .onChange(of: editMode) { focusedField = nil }
            .onChange(of: day.exerciseTemplates.isEmpty) {
                if $1 {
                    editMode = .inactive
                }
            }
            .toolbar {
                if !day.exerciseTemplates.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton()
                            .accessibilityLabel("Reorder or Delete Exercises")
                    }
                }
            }
            .environment(\.editMode, $editMode)
    }

    // MARK: Private properties

    private let filterExerciseNameSuggestions: (String) -> [String]
    @Binding
    private var day: DayTemplate
    @State
    private var editMode = EditMode.inactive
    @FocusState
    private var focusedField: Field?

    // MARK: - Initialization

    /// Creates a day editor view.
    /// - Parameters:
    ///   - day: A binding to the day template being edited.
    ///   - filterExerciseNameSuggestions: Filters autocomplete suggestions down to those matching a partially-typed exercise name.
    init(day: Binding<DayTemplate>, filterExerciseNameSuggestions: @escaping (String) -> [String]) {
        self.filterExerciseNameSuggestions = filterExerciseNameSuggestions
        _day = day
    }

    // MARK: -

    private enum Field: Hashable {
        case name
    }

}

// MARK: -

#Preview {
    @Previewable
    @State
    var day = DayTemplate(name: "Push", position: 0)

    NavigationStack {
        DayEditorView(day: $day) { name in
            [
                "Bench Press",
                "Squat"
            ]
                .filter { $0.localizedStandardContains(name) }
        }
    }
}
