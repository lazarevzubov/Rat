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
        let editorViewModel = viewModel.makeProgramEditorViewModel(for: program)

        await editorViewModel.handleSaveButtonTap().value
        #expect(viewModel.programs.map(\.id) == [program.id], "Saving in the editor reloads this list.")
    }

}
