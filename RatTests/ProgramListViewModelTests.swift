@testable
import Rat
import Testing

@MainActor
struct ProgramListViewModelTests {

    // MARK: - Methods

    @Test
    func handleAppear_succeeds_loadsPrograms() async {
        let service = ProgramStubService()

        let program = Program(name: "Push Pull Legs")
        await service.setPrograms([program])

        let viewModel = ProgramListViewModel(
            programService: service, workoutSessionService: WorkoutSessionStubService()
        )
        await viewModel.handleAppear()

        #expect(viewModel.programs.map(\.id) == [program.id], "The loaded programs are exposed to the view.")
    }

    @Test
    func handleAppear_fails_setsLoadError() async {
        let service = ProgramStubService()
        await service.setFetchError(TestError())

        let viewModel = ProgramListViewModel(
            programService: service, workoutSessionService: WorkoutSessionStubService()
        )
        await viewModel.handleAppear()

        #expect(viewModel.loadError is TestError, "A failed load records the error for the view to present.")
    }

    @Test
    func handleAppear_succeeds_loadsExerciseNameSuggestions() async {
        let service = ProgramStubService()

        let program = Program(
            name: "Push Pull Legs",
            dayTemplates: [
                DayTemplate(
                    name: "Push",
                    position: 0,
                    exerciseTemplates: [ExerciseTemplate(name: "Bench Press", position: 0, max: 100)]
                )
            ]
        )
        await service.setPrograms([program])

        let viewModel = ProgramListViewModel(
            programService: service, workoutSessionService: WorkoutSessionStubService()
        )
        await viewModel.handleAppear()

        #expect(
            viewModel.exerciseNameSuggestions == ["Bench Press"], "The distinct exercise names are exposed to the view."
        )
    }

    @Test
    func handleAppear_exerciseNameSuggestionsFetchFails_leavesSuggestionsEmpty() async {
        let service = ProgramStubService()
        await service.setFetchExerciseNamesError(TestError())

        let viewModel = ProgramListViewModel(
            programService: service, workoutSessionService: WorkoutSessionStubService()
        )
        await viewModel.handleAppear()

        #expect(viewModel.exerciseNameSuggestions.isEmpty, "A failed suggestions fetch is silently ignored.")
    }

    @Test
    func dismissLoadError_clearsLoadError() async {
        let service = ProgramStubService()
        await service.setFetchError(TestError())

        let viewModel = ProgramListViewModel(
            programService: service, workoutSessionService: WorkoutSessionStubService()
        )
        await viewModel.handleAppear()
        viewModel.dismissLoadError()

        #expect(viewModel.loadError == nil, "The alert can be dismissed.")
    }

    @Test
    func handleAddProgramButtonTap_presentsFreshProgramForEditing() {
        let viewModel = ProgramListViewModel(
            programService: ProgramStubService(), workoutSessionService: WorkoutSessionStubService()
        )
        viewModel.handleAddProgramButtonTap()

        #expect(viewModel.newProgram?.name == "", "A fresh, unnamed program is presented for editing.")
    }

    @Test
    func handleStartWorkoutButtonTap_presentsGivenProgramForLogging() {
        let program = Program(name: "Push Pull Legs")

        let viewModel = ProgramListViewModel(
            programService: ProgramStubService(), workoutSessionService: WorkoutSessionStubService()
        )
        viewModel.handleStartWorkoutButtonTap(for: program)

        #expect(
            viewModel.programStartingWorkout?.id == program.id,
            "The tapped program is presented for logging a workout."
        )
    }

    @Test
    func handleDelete_removesProgramLocally() async {
        let service = ProgramStubService()

        let program = Program(name: "Push Pull Legs")
        await service.setPrograms([program])

        let viewModel = ProgramListViewModel(
            programService: service, workoutSessionService: WorkoutSessionStubService()
        )
        await viewModel.handleAppear()
        await viewModel.handleDelete(at: [0]).value

        #expect(viewModel.programs.isEmpty, "The deleted program no longer appears in the list.")
    }

    @Test
    func handleDelete_deletesProgramFromPersistence() async {
        let service = ProgramStubService()

        let program = Program(name: "Push Pull Legs")
        await service.setPrograms([program])

        let viewModel = ProgramListViewModel(
            programService: service, workoutSessionService: WorkoutSessionStubService()
        )
        await viewModel.handleAppear()
        await viewModel.handleDelete(at: [0]).value

        #expect(await service.deletedIDs == [program.id], "The deleted program is removed from persistence too.")
    }

    @Test
    func makeProgramEditorViewModel_onSave_reloadsList() async {
        let service = ProgramStubService()
        let viewModel = ProgramListViewModel(
            programService: service, workoutSessionService: WorkoutSessionStubService()
        )

        let program = Program(name: "Push Pull Legs")
        let editorViewModel = viewModel.makeProgramEditorViewModel(program: program)

        await editorViewModel.handleProgramChanged().value
        #expect(viewModel.programs.map(\.id) == [program.id], "Autosaving in the editor reloads this list.")
    }

    @Test
    func makeProgramEditorViewModel_passesLoadedExerciseNameSuggestions() async {
        let service = ProgramStubService()

        let existingProgram = Program(
            name: "Push Pull Legs",
            dayTemplates: [
                DayTemplate(
                    name: "Push",
                    position: 0,
                    exerciseTemplates: [ExerciseTemplate(name: "Bench Press", position: 0, max: 100)]
                )
            ]
        )
        await service.setPrograms([existingProgram])

        let viewModel = ProgramListViewModel(
            programService: service, workoutSessionService: WorkoutSessionStubService()
        )
        await viewModel.handleAppear()

        let editorViewModel = viewModel.makeProgramEditorViewModel(program: Program(name: "Upper Lower"))
        #expect(
            editorViewModel.exerciseNameSuggestions == ["Bench Press"],
            "The editor is handed the list's already-loaded exercise name suggestions."
        )
    }

}
