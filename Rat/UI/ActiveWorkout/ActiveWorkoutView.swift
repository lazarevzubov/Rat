import SwiftUI

/// Logs a workout session: shows today's exercises and sets, grouped by exercise, and saves the result.
struct ActiveWorkoutView: View {

    /// The fields that can be focused within this screen, one per set row, so all of them can share a single source of truth for "what's currently focused"
    /// and be dismissed together.
    enum Field: Hashable {

        /// A specific set's weight field, identified by that set's stable ID.
        case setWeight(UUID)

    }

    // MARK: - Properties

    // MARK: View protocol properties

    var body: some View {
        Form {
            if let sessionBinding {
                ForEach(sessionBinding.loggedExercises) { $exercise in
                    Section {
                        ForEach($exercise.loggedSets) { $set in
                            LoggedSetRowView(set: $set, focusedField: $focusedField)
                        }
                    } header: {
                        exerciseHeader(name: exercise.exerciseName)
                    }
                }
            }
        }
            .background(dismissFocusBackground)
            .navigationTitle(viewModel.session?.dayName ?? "Workout")
            .onDisappear { focusedField = nil }
            .onChange(of: viewModel.didSave) {
                if $1 {
                    dismiss()
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { viewModel.handleSaveButtonTap() }
                        .disabled(viewModel.session == nil)
                }
            }
            .task { await viewModel.handleAppear() }
            .alert("Couldn't log workout", isPresented: errorBinding) {
                // No custom actions—the default "OK" button just dismisses the alert.
            } message: {
                Text(viewModel.presentedError?.localizedDescription ?? "")
            }
    }

    // MARK: Private properties

    @Environment(\.dismiss)
    private var dismiss
    private var dismissFocusBackground: some View {
        Color
            .clear
            .contentShape(Rectangle())
            .onTapGesture { focusedField = nil }
    }
    private var errorBinding: Binding<Bool> {
        Binding { viewModel.presentedError != nil } set: {
            if !$0 {
                viewModel.dismissPresentedError()
            }
        }
    }
    @FocusState
    private var focusedField: Field?
    private var sessionBinding: Binding<WorkoutSession>? { Binding($viewModel.session) }
    @State
    private var viewModel: ActiveWorkoutViewModel

    // MARK: - Initialization

    /// Creates an active workout view.
    /// - Parameter viewModel: The view model owning the session being logged, its persistence calls, and what happens next.
    init(viewModel: ActiveWorkoutViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Methods

    // MARK: Private methods

    private func exerciseHeader(name: String) -> some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(name)
            if viewModel.flaggedExerciseNames.contains(name) {
                Label("Increase next time", systemImage: "arrow.up.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

}

// MARK: -

#if DEBUG
#Preview {
    NavigationStack {
        ActiveWorkoutView(
            viewModel: PreviewSupport.makeActiveWorkoutViewModel(
                program: Program(
                    name: "Push Pull Legs",
                    dayTemplates: [
                        DayTemplate(
                            name: "Push",
                            position: 0,
                            exerciseTemplates: [
                                ExerciseTemplate(
                                    name: "Bench Press",
                                    position: 0,
                                    max: 100,
                                    setTemplates: [
                                        SetTemplate(kind: .working, targetReps: 5, position: 0, percentOfMax: 80)
                                    ]
                                )
                            ]
                        )
                    ]
                )
            )
        )
    }
}
#endif
