import SwiftUI

/// Edits a single program's name and day templates, persisting changes on save.
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
                    withAnimation { viewModel.handleAddDayButtonTap() }
                }
            }
        }
            .background(dismissFocusBackground)
            .navigationTitle(
                viewModel.program.name.isEmpty
                    ? "New Program"
                    : viewModel.program.name
            )
            .onDisappear { focusedField = nil }
            .onChange(of: viewModel.didSave) {
                if $1 {
                    dismiss()
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                    EditButton()
                        .accessibilityLabel("Reorder or Delete Days")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { viewModel.handleSaveButtonTap() }
                        .disabled(viewModel.program.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Couldn't save program", isPresented: errorBinding) {
                // No custom actions—the default "OK" button just dismisses the alert.
            } message: {
                Text(viewModel.saveError?.localizedDescription ?? "")
            }
    }

    // MARK: Private properties

    @Environment(\.dismiss)
    private var dismiss
    private var dismissFocusBackground: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { focusedField = nil }
    }
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

#Preview {
    NavigationStack {
        ProgramEditorView(
            viewModel: ProgramEditorViewModel(
                program: Program(name: "Push Pull Legs"),
                programService: PreviewSupport.makeProgramService(),
                exerciseNameSuggestions: [
                    "Bench Press",
                    "Squat"
                ]
            ) {
                // Previews don't reload a program list, so there's nothing to do on save.
            }
        )
    }
}
