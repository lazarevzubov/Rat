@testable
import Rat
import Testing

@MainActor
struct ProgramEditorViewModelTests {

    // MARK: - Methods

    @Test
    func filteredExerciseNameSuggestions_returnsMatches_caseInsensitively() {
        let viewModel = ProgramEditorViewModel(
            program: Program(name: "Push Pull Legs"),
            programService: ProgramStubService(),
            exerciseNameSuggestions: [
                "Bench Press",
                "Overhead Press",
                "Squat"
            ],
            workoutSessionService: WorkoutSessionStubService()
        ) {
            // onSave isn't exercised by this test.
        }
        #expect(
            viewModel.filteredExerciseNameSuggestions(matching: "press") == [
                "Bench Press",
                "Overhead Press"
            ],
            "Suggestions containing the typed text are returned, regardless of case."
        )
    }

    @Test
    func filteredExerciseNameSuggestions_excludesExactMatch() {
        let viewModel = ProgramEditorViewModel(
            program: Program(name: "Push Pull Legs"),
            programService: ProgramStubService(),
            exerciseNameSuggestions: ["Bench Press"],
            workoutSessionService: WorkoutSessionStubService()
        ) {
            // onSave isn't exercised by this test.
        }
        #expect(
            viewModel.filteredExerciseNameSuggestions(matching: "Bench Press").isEmpty,
            "A suggestion identical to the typed text isn't offered."
        )
    }

    @Test
    func filteredExerciseNameSuggestions_givenBlankName_returnsEmpty() {
        let viewModel = ProgramEditorViewModel(
            program: Program(name: "Push Pull Legs"),
            programService: ProgramStubService(),
            exerciseNameSuggestions: ["Bench Press"],
            workoutSessionService: WorkoutSessionStubService()
        ) {
            // onSave isn't exercised by this test.
        }
        #expect(
            viewModel.filteredExerciseNameSuggestions(matching: "   ").isEmpty, "A blank name has no suggestions."
        )
    }

    @Test
    func filteredExerciseNameSuggestions_capsAtFiveResults() {
        let viewModel = ProgramEditorViewModel(
            program: Program(name: "Push Pull Legs"),
            programService: ProgramStubService(),
            exerciseNameSuggestions: (1...6).map { "Press \($0)" },
            workoutSessionService: WorkoutSessionStubService()
        ) {
            // onSave isn't exercised by this test.
        }
        #expect(viewModel.filteredExerciseNameSuggestions(matching: "Press").count == 5, "Suggestions are capped at 5.")
    }

    @Test
    func initializingViewModel_doesNotAutosaveImmediately() async {
        let service = ProgramStubService()
        let program = Program(name: "Push Pull Legs")
        let viewModel = ProgramEditorViewModel(
            program: program,
            programService: service,
            exerciseNameSuggestions: [],
            autosaveDelay: .zero,
            workoutSessionService: WorkoutSessionStubService()
        ) {
            // onSave isn't exercised by this test.
        }

        #expect(
            await service.programs.isEmpty,
            "Merely opening the editor for an existing program, \(viewModel.program.name), doesn't resave it."
        )
    }

    @Test
    func handleProgramChanged_succeeds_persistsProgram() async {
        let service = ProgramStubService()
        let program = Program(name: "Push Pull Legs")
        let viewModel = ProgramEditorViewModel(
            program: program,
            programService: service,
            exerciseNameSuggestions: [],
            autosaveDelay: .zero,
            workoutSessionService: WorkoutSessionStubService()
        ) {
            // onSave isn't exercised by this test.
        }

        viewModel.handleProgramChanged()
        await waitFor { await !service.programs.isEmpty }

        #expect(await service.programs.map(\.id) == [program.id], "The program is persisted.")
    }

    @Test
    func handleProgramChanged_succeeds_awaitsOnSave() async {
        let service = ProgramStubService()

        var onSaveCallCount = 0
        let viewModel = ProgramEditorViewModel(
            program: Program(name: "Push Pull Legs"),
            programService: service,
            exerciseNameSuggestions: [],
            autosaveDelay: .zero,
            workoutSessionService: WorkoutSessionStubService()
        ) {
            onSaveCallCount += 1
        }

        viewModel.handleProgramChanged()
        await waitFor { onSaveCallCount > 0 }

        #expect(onSaveCallCount == 1, "onSave is awaited exactly once.")
    }

    @Test
    func handleProgramChanged_fails_setsSaveError() async {
        let service = ProgramStubService()
        await service.setSaveError(TestError())

        let viewModel = ProgramEditorViewModel(
            program: Program(name: "Push Pull Legs"),
            programService: service,
            exerciseNameSuggestions: [],
            autosaveDelay: .zero,
            workoutSessionService: WorkoutSessionStubService()
        ) {
            // onSave isn't exercised by this test.
        }
        viewModel.handleProgramChanged()

        await waitFor { viewModel.saveError != nil }
        #expect(viewModel.saveError is TestError, "A failed save records the error for the view to present.")
    }

    @Test
    func handleProgramChanged_fails_doesNotAwaitOnSave() async {
        let service = ProgramStubService()
        await service.setSaveError(TestError())

        var onSaveCallCount = 0
        let viewModel = ProgramEditorViewModel(
            program: Program(name: "Push Pull Legs"),
            programService: service,
            exerciseNameSuggestions: [],
            autosaveDelay: .zero,
            workoutSessionService: WorkoutSessionStubService()
        ) {
            onSaveCallCount += 1
        }

        viewModel.handleProgramChanged()
        await waitFor { viewModel.saveError != nil }

        #expect(onSaveCallCount == 0, "A failed save doesn't reload the caller.")
    }

    @Test
    func dismissSaveError_clearsSaveError() async {
        let service = ProgramStubService()
        await service.setSaveError(TestError())

        let viewModel = ProgramEditorViewModel(
            program: Program(name: "Push Pull Legs"),
            programService: service,
            exerciseNameSuggestions: [],
            autosaveDelay: .zero,
            workoutSessionService: WorkoutSessionStubService()
        ) {
            // onSave isn't exercised by this test.
        }

        viewModel.handleProgramChanged()
        await waitFor { viewModel.saveError != nil }

        viewModel.dismissSaveError()
        #expect(viewModel.saveError == nil, "The alert can be dismissed.")
    }

    @Test
    func handleAddDayButtonTap_appendsDay() {
        let viewModel = ProgramEditorViewModel(
            program: Program(name: "Push Pull Legs"),
            programService: ProgramStubService(),
            exerciseNameSuggestions: [],
            workoutSessionService: WorkoutSessionStubService()
        ) {
            // onSave isn't exercised by this test.
        }
        viewModel.handleAddDayButtonTap()

        #expect(viewModel.program.dayTemplates.count == 1, "A day is added to the program being edited.")
    }

    @Test
    func handleAddDayButtonTap_autosavesTheProgram() async {
        let program = Program(name: "Push Pull Legs")
        let service = ProgramStubService()
        let viewModel = ProgramEditorViewModel(
            program: program,
            programService: service,
            exerciseNameSuggestions: [],
            autosaveDelay: .zero,
            workoutSessionService: WorkoutSessionStubService()
        ) {
            // onSave isn't exercised by this test.
        }

        viewModel.handleAddDayButtonTap()
        await waitFor { await !service.programs.isEmpty }

        #expect(await service.programs.map(\.id) == [program.id], "Adding a day autosaves the program.")
    }

    @Test
    func handleDeleteDay_removesDay() {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])
        let viewModel = ProgramEditorViewModel(
            program: program,
            programService: ProgramStubService(),
            exerciseNameSuggestions: [],
            workoutSessionService: WorkoutSessionStubService()
        ) {
            // onSave isn't exercised by this test.
        }

        viewModel.handleDeleteDay(at: [0])
        #expect(viewModel.program.dayTemplates.isEmpty, "The day is removed from the program being edited.")
    }

    @Test
    func handleMoveDay_reordersDays() {
        let program = Program(
            name: "Push Pull Legs",
            dayTemplates: [
                DayTemplate(name: "Push", position: 0),
                DayTemplate(name: "Pull", position: 1)
            ]
        )
        let viewModel = ProgramEditorViewModel(
            program: program,
            programService: ProgramStubService(),
            exerciseNameSuggestions: [],
            workoutSessionService: WorkoutSessionStubService()
        ) {
            // onSave isn't exercised by this test.
        }

        viewModel.handleMoveDay(from: [0], to: 2)
        #expect(
            viewModel.program.dayTemplates.map(\.name) == ["Pull", "Push"],
            "The days in the program being edited are reordered."
        )
    }

    @Test
    func handleStartWorkoutButtonTap_presentsWorkoutForEditing() {
        let viewModel = ProgramEditorViewModel(
            program: Program(name: "Push Pull Legs"),
            programService: ProgramStubService(),
            exerciseNameSuggestions: [],
            workoutSessionService: WorkoutSessionStubService()
        ) {
            // onSave isn't exercised by this test.
        }
        viewModel.handleStartWorkoutButtonTap()

        #expect(viewModel.startingWorkout, "The workout-logging screen is presented.")
    }

    @Test
    func makeActiveWorkoutViewModel_usesProgramBeingEdited() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])
        let viewModel = ProgramEditorViewModel(
            program: program,
            programService: ProgramStubService(),
            exerciseNameSuggestions: [],
            workoutSessionService: WorkoutSessionStubService()
        ) {
            // onSave isn't exercised by this test.
        }

        let activeWorkoutViewModel = viewModel.makeActiveWorkoutViewModel()
        await activeWorkoutViewModel.handleAppear()

        #expect(
            activeWorkoutViewModel.session?.dayName == "Push",
            "The workout is seeded from the program currently being edited."
        )
    }

}
