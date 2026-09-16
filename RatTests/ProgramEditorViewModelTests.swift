@testable
import Rat
import Testing

@MainActor
struct ProgramEditorViewModelTests {

    // MARK: - Methods

    @Test
    func handleSaveButtonTap_succeeds_persistsProgram() async {
        let service = ProgramStubService()
        let program = Program(name: "Push Pull Legs")
        let viewModel = ProgramEditorViewModel(program: program, programService: service) {
            // onSave isn't exercised by this test.
        }

        await viewModel.handleSaveButtonTap().value
        #expect(await service.programs.map(\.id) == [program.id], "The program is persisted.")
    }

    @Test
    func handleSaveButtonTap_succeeds_awaitsOnSave() async {
        let service = ProgramStubService()

        var onSaveCallCount = 0
        let viewModel = ProgramEditorViewModel(program: Program(name: "Push Pull Legs"), programService: service) {
            onSaveCallCount += 1
        }

        await viewModel.handleSaveButtonTap().value
        #expect(onSaveCallCount == 1, "onSave is awaited exactly once.")
    }

    @Test
    func handleSaveButtonTap_succeeds_setsDidSave() async {
        let service = ProgramStubService()
        let viewModel = ProgramEditorViewModel(program: Program(name: "Push Pull Legs"), programService: service) {
            // onSave isn't exercised by this test.
        }

        await viewModel.handleSaveButtonTap().value
        #expect(viewModel.didSave, "A successful save tells the view it should dismiss.")
    }

    @Test
    func handleSaveButtonTap_fails_setsSaveError() async {
        let service = ProgramStubService()
        await service.setSaveError(TestError())

        let viewModel = ProgramEditorViewModel(program: Program(name: "Push Pull Legs"), programService: service) {
            // onSave isn't exercised by this test.
        }
        await viewModel.handleSaveButtonTap().value

        #expect(viewModel.saveError is TestError, "A failed save records the error for the view to present.")
    }

    @Test
    func handleSaveButtonTap_fails_doesNotSetDidSave() async {
        let service = ProgramStubService()
        await service.setSaveError(TestError())

        let viewModel = ProgramEditorViewModel(program: Program(name: "Push Pull Legs"), programService: service) {
            // onSave isn't exercised by this test.
        }
        await viewModel.handleSaveButtonTap().value

        #expect(!viewModel.didSave, "A failed save doesn't tell the view to dismiss.")
    }

    @Test
    func handleSaveButtonTap_fails_doesNotAwaitOnSave() async {
        let service = ProgramStubService()
        await service.setSaveError(TestError())

        var onSaveCallCount = 0
        let viewModel = ProgramEditorViewModel(program: Program(name: "Push Pull Legs"), programService: service) {
            onSaveCallCount += 1
        }

        await viewModel.handleSaveButtonTap().value
        #expect(onSaveCallCount == 0, "A failed save doesn't reload the caller.")
    }

    @Test
    func dismissSaveError_clearsSaveError() async {
        let service = ProgramStubService()
        await service.setSaveError(TestError())

        let viewModel = ProgramEditorViewModel(program: Program(name: "Push Pull Legs"), programService: service) {
            // onSave isn't exercised by this test.
        }
        await viewModel.handleSaveButtonTap().value
        viewModel.dismissSaveError()

        #expect(viewModel.saveError == nil, "The alert can be dismissed.")
    }

    @Test
    func handleAddDayButtonTap_appendsDay() {
        let viewModel = ProgramEditorViewModel(program: Program(name: "Push Pull Legs"), programService: ProgramStubService()) {
            // onSave isn't exercised by this test.
        }
        viewModel.handleAddDayButtonTap()

        #expect(viewModel.program.dayTemplates.count == 1, "A day is added to the program being edited.")
    }

    @Test
    func handleDeleteDay_removesDay() {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])
        let viewModel = ProgramEditorViewModel(program: program, programService: ProgramStubService()) {
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
        let viewModel = ProgramEditorViewModel(program: program, programService: ProgramStubService()) {
            // onSave isn't exercised by this test.
        }

        viewModel.handleMoveDay(from: [0], to: 2)
        #expect(
            viewModel.program.dayTemplates.map(\.name) == ["Pull", "Push"],
            "The days in the program being edited are reordered."
        )
    }

}
