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
                Button("Add Exercise", systemImage: "plus") { day.addExercise() }
            }
        }
            .background(dismissFocusBackground)
            .navigationTitle(
                day.name.isEmpty
                    ? "New Day"
                    : day.name
            )
            .onDisappear { focusedField = nil }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                        .accessibilityLabel("Reorder or Delete Exercises")
                }
            }
    }

    // MARK: Private properties

    private let filterExerciseNameSuggestions: (String) -> [String]
    @Binding
    private var day: DayTemplate
    private var dismissFocusBackground: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { focusedField = nil }
    }
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
