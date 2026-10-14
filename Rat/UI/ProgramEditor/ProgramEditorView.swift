import SwiftUI

/// Edits a single program's name and day templates, autosaving edits as they're made.
struct ProgramEditorView: View {

    // MARK: - Properties

    // MARK: View protocol properties

    var body: some View {
        Form {
            Section("Name") {
                TextField("Program Name", text: $viewModel.program.name)
                    .focused($focusedField, equals: .name)
            }
            Section("Days") {
                ForEach($viewModel.program.dayTemplates) { $day in
                    NavigationLink(
                        day.name.isEmpty
                            ? "Untitled Day"
                            : day.name
                    ) {
                        DayEditorView(
                            day: $day, filterExerciseNameSuggestions: viewModel.filteredExerciseNameSuggestions
                        )
                    }
                        .simultaneousGesture(TapGesture().onEnded { focusedField = nil })
                }
                    .onDelete { viewModel.handleDeleteDay(at: $0) }
                    .onMove { viewModel.handleMoveDay(from: $0, to: $1) }
                Button("Add Day", systemImage: "plus") {
                    focusedField = nil
                    withAnimation { viewModel.handleAddDayButtonTap() }
                }
            }
        }
            .scrollDismissesKeyboard(.immediately)
            .onTouchBelowContent { focusedField = nil }
            .navigationTitle(
                viewModel.program.name.isEmpty
                    ? "New Program"
                    : viewModel.program.name
            )
            .onDisappear { focusedField = nil }
            .onChange(of: editMode) { focusedField = nil }
            .onChange(of: viewModel.program.dayTemplates.isEmpty) {
                if $1 {
                    editMode = .inactive
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Start Workout", systemImage: "figure.run") { viewModel.handleStartWorkoutButtonTap() }
                }
                if !viewModel.program.dayTemplates.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton()
                            .accessibilityLabel("Reorder or Delete Days")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.startingWorkout) {
                NavigationStack {
                    ActiveWorkoutView(viewModel: viewModel.makeActiveWorkoutViewModel())
                }
            }
            .alert("Couldn't save program", isPresented: errorBinding) {
                // No custom actions—the default "OK" button just dismisses the alert.
            } message: {
                Text(viewModel.saveError?.localizedDescription ?? "")
            }
            .environment(\.editMode, $editMode)
    }

    // MARK: Private properties

    @Environment(\.dismiss)
    private var dismiss
    @State
    private var editMode = EditMode.inactive
    private var errorBinding: Binding<Bool> {
        Binding { viewModel.saveError != nil } set: {
            if !$0 {
                viewModel.dismissSaveError()
            }
        }
    }
    @FocusState
    private var focusedField: Field?
    @State
    private var viewModel: ProgramEditorViewModel

    // MARK: - Initialization

    /// Creates a program editor view.
    /// - Parameter viewModel: The view model owning the program being edited, its persistence calls, and what happens next—this view only
    /// renders that state and forwards user intents to it.
    init(viewModel: ProgramEditorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: -

    private enum Field: Hashable {

        case name

    }

}

// MARK: -

#if DEBUG
#Preview {
    NavigationStack {
        ProgramEditorView(
            viewModel: PreviewSupport.makeProgramEditorViewModel(
                program: Program(name: "Push Pull Legs"),
                exerciseNameSuggestions: [
                    "Bench Press",
                    "Squat"
                ]
            )
        )
    }
}
#endif
