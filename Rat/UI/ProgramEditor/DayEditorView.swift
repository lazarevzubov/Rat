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
                        ExerciseEditorView(exercise: $exercise)
                    }
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

    @Binding
    private var day: DayTemplate

    @FocusState
    private var focusedField: Field?

    /// A full-screen, invisible tap target placed behind the form, so tapping a blank area between rows
    /// dismisses the keyboard—placed *behind* rather than wrapping the form so it doesn't intercept taps
    /// meant for the form's own buttons and navigation links.
    private var dismissFocusBackground: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { focusedField = nil }
    }

    // MARK: - Initialization

    /// Creates a day editor view.
    /// - Parameter day: A binding to the day template being edited.
    init(day: Binding<DayTemplate>) {
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
        DayEditorView(day: $day)
    }
}
