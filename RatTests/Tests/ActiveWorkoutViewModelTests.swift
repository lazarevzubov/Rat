@testable
import Rat
import Testing

@MainActor
struct ActiveWorkoutViewModelTests {

    // MARK: - Methods

    @Test
    func handleAppear_noPriorSession_seedsFirstDay() async {
        let program = Program(
            name: "Push Pull Legs",
            dayTemplates: [
                DayTemplate(name: "Push", position: 0),
                DayTemplate(name: "Pull", position: 1)
            ]
        )
        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: WorkoutSessionStubService())

        await viewModel.handleAppear()
        #expect(viewModel.session?.dayName == "Push", "With no prior session, the first day in the cycle is seeded.")
    }

    @Test
    func handleAppear_sessionLoaded_enablesEditingAndSaving() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])
        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: WorkoutSessionStubService())

        await viewModel.handleAppear()

        #expect(
            !viewModel.editingDisabled
                && !viewModel.saveButtonDisabled,
            "A loaded session can be edited and saved."
        )
    }

    @Test
    func handleAppear_priorSession_seedsNextDayInCycle() async {
        let program = Program(
            name: "Push Pull Legs",
            dayTemplates: [
                DayTemplate(name: "Push", position: 0),
                DayTemplate(name: "Pull", position: 1)
            ]
        )

        let service = WorkoutSessionStubService()
        await service.setSessions(
            [WorkoutSession(programID: program.id, date: .now, dayName: "Push", dayPosition: 0)]
        )

        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: service)
        await viewModel.handleAppear()

        #expect(viewModel.session?.dayName == "Pull", "The day after the most recently logged one is seeded.")
    }

    @Test
    func handleAppear_priorSessionWasLastDay_wrapsToFirstDay() async {
        let program = Program(
            name: "Push Pull Legs",
            dayTemplates: [
                DayTemplate(name: "Push", position: 0),
                DayTemplate(name: "Pull", position: 1)
            ]
        )

        let service = WorkoutSessionStubService()
        await service.setSessions(
            [WorkoutSession(programID: program.id, date: .now, dayName: "Pull", dayPosition: 1)]
        )

        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: service)
        await viewModel.handleAppear()

        #expect(viewModel.session?.dayName == "Push", "The cycle wraps back to the first day.")
    }

    @Test
    func handleAppear_seedsLoggedSetsFromTemplates() async {
        let exercise = ExerciseTemplate(
            name: "Bench Press",
            position: 0,
            max: 100,
            setTemplates: [
                SetTemplate(kind: .warmUp, targetReps: 10, position: 0, warmUpWeight: 20),
                SetTemplate(kind: .working, targetReps: 5, position: 1, percentOfMax: 80)
            ]
        )
        let program = Program(
            name: "Push Pull Legs",
            dayTemplates: [DayTemplate(name: "Push", position: 0, exerciseTemplates: [exercise])]
        )

        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: WorkoutSessionStubService())
        await viewModel.handleAppear()

        #expect(
            viewModel.session?.loggedExercises.first?.loggedSets.map(\.weight) == [
                20,
                80
            ],
            "Each logged set is pre-filled with the template's warm-up weight or suggested working weight."
        )
    }

    @Test
    func handleAppear_priorSessionFlaggedExercise_recordsFlaggedExerciseName() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])
        let flaggedSet = LoggedSet(kind: .working, weight: 80, reps: 5, position: 0, increaseNextTime: true)

        let service = WorkoutSessionStubService()
        await service.setSessions(
            [
                WorkoutSession(
                    programID: program.id,
                    date: .now,
                    dayName: "Push",
                    dayPosition: 0,
                    loggedExercises: [
                        LoggedExercise(exerciseName: "Bench Press", position: 0, loggedSets: [flaggedSet])
                    ]
                )
            ]
        )

        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: service)
        await viewModel.handleAppear()

        #expect(
            viewModel.flaggedExerciseNames == ["Bench Press"],
            "Exercises with a set flagged to increase next time are surfaced to the view."
        )
    }

    @Test
    func handleAppear_noDayTemplates_doesNotSeedSession() async {
        let program = Program(name: "Push Pull Legs")
        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: WorkoutSessionStubService())

        await viewModel.handleAppear()
        #expect(viewModel.session == nil, "There's no day to seed a session from.")
    }

    @Test
    func handleAppear_fails_setsPresentedError() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])

        let service = WorkoutSessionStubService()
        await service.setFetchError(TestError())

        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: service)
        await viewModel.handleAppear()

        #expect(viewModel.presentedError is TestError, "A failed load records the error for the view to present.")
    }

    @Test
    func dismissPresentedError_clearsPresentedError() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])

        let service = WorkoutSessionStubService()
        await service.setFetchError(TestError())

        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: service)
        await viewModel.handleAppear()
        viewModel.dismissPresentedError()

        #expect(viewModel.presentedError == nil, "The alert can be dismissed.")
    }

    @Test
    func handleSaveButtonTap_succeeds_persistsSession() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])
        let service = WorkoutSessionStubService()

        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: service)

        await viewModel.handleAppear()
        viewModel.handleSaveButtonTap()

        await waitFor { await !service.savedSessions.isEmpty }
        #expect(await service.savedSessions.map(\.id) == [viewModel.session?.id], "The session is persisted.")
    }

    @Test
    func handleSaveButtonTap_succeeds_setsDidSave() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])
        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: WorkoutSessionStubService())

        await viewModel.handleAppear()
        viewModel.handleSaveButtonTap()

        await waitFor { viewModel.didSave }
        #expect(viewModel.didSave, "A successful save tells the view to dismiss.")
    }

    @Test
    func handleSaveButtonTap_noSession_doesNotStartSaving() {
        let viewModel = ActiveWorkoutViewModel(
            program: Program(name: "Push Pull Legs"), workoutSessionService: WorkoutSessionStubService()
        )
        viewModel.handleSaveButtonTap()

        #expect(
            !viewModel.saving
                && !viewModel.editingDisabled
                && viewModel.saveButtonDisabled,
            "Without a session, Save stays disabled without starting a save or locking editing."
        )
    }

    @Test
    func handleSaveButtonTap_beforeTaskStarts_setsSaving() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])
        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: WorkoutSessionStubService())

        await viewModel.handleAppear()
        viewModel.handleSaveButtonTap()

        #expect(
            viewModel.saving
                && viewModel.editingDisabled
                && viewModel.saveButtonDisabled,
            "Saving synchronously disables editing and Save before another tap can start a save."
        )
    }

    @Test
    func handleSaveButtonTap_repeatedTaps_persistsSessionOnce() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])
        let service = WorkoutSessionStubService()

        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: service)
        await viewModel.handleAppear()

        viewModel.handleSaveButtonTap()
        viewModel.handleSaveButtonTap()

        await waitFor { viewModel.didSave }
        #expect(
            await service.savedSessions.map(\.id) == [viewModel.session?.id],
            "Repeated taps persist the active session only once."
        )
    }

    @Test
    func handleSaveButtonTap_sessionChangesBeforeTaskStarts_persistsAcceptedSnapshot() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])
        let service = WorkoutSessionStubService()

        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: service)
        await viewModel.handleAppear()

        let sessionID = viewModel.session?.id

        viewModel.handleSaveButtonTap()
        viewModel.session = nil

        await waitFor { viewModel.didSave }
        #expect(
            await service.savedSessions.map(\.id) == [sessionID],
            "The save uses the session snapshot accepted when Save was tapped."
        )
    }

    @Test
    func handleSaveButtonTap_succeeds_clearsSaving() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])
        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: WorkoutSessionStubService())

        await viewModel.handleAppear()
        viewModel.handleSaveButtonTap()

        await waitFor { viewModel.didSave }
        #expect(
            viewModel.didSave
                && !viewModel.saving
                && viewModel.editingDisabled
                && viewModel.saveButtonDisabled,
            "After saving finishes, editing and Save stay disabled until dismissal."
        )
    }

    @Test
    func handleSaveButtonTap_alreadySaved_doesNotStartSavingAgain() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])

        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: WorkoutSessionStubService())
        await viewModel.handleAppear()

        viewModel.handleSaveButtonTap()
        await waitFor { viewModel.didSave }

        viewModel.handleSaveButtonTap()
        #expect(
            viewModel.didSave
                && !viewModel.saving,
            "A completed session cannot start another save while dismissal is pending."
        )
    }

    @Test
    func handleSaveButtonTap_fails_setsPresentedError() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])

        let service = WorkoutSessionStubService()
        await service.setSaveError(TestError())

        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: service)
        await viewModel.handleAppear()

        viewModel.handleSaveButtonTap()
        await waitFor { viewModel.presentedError != nil }

        #expect(viewModel.presentedError is TestError, "A failed save records the error for the view to present.")
    }

    @Test
    func handleSaveButtonTap_fails_doesNotSetDidSave() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])

        let service = WorkoutSessionStubService()
        await service.setSaveError(TestError())

        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: service)
        await viewModel.handleAppear()

        viewModel.handleSaveButtonTap()
        await waitFor { viewModel.presentedError != nil }

        #expect(!viewModel.didSave, "A failed save doesn't tell the view to dismiss.")
    }

    @Test
    func handleSaveButtonTap_fails_clearsSaving() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])

        let service = WorkoutSessionStubService()
        await service.setSaveError(TestError())

        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: service)
        await viewModel.handleAppear()

        viewModel.handleSaveButtonTap()
        await waitFor { viewModel.presentedError != nil }

        #expect(
            (viewModel.presentedError is TestError)
                && !viewModel.saving
                && !viewModel.editingDisabled
                && !viewModel.saveButtonDisabled,
            "A failed save clears the saving state and enables editing and Save for another attempt."
        )
    }

    @Test
    func handleSaveButtonTap_retryAfterFailure_savesSuccessfully() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])

        let service = WorkoutSessionStubService()
        await service.setSaveError(TestError())

        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: service)
        await viewModel.handleAppear()

        viewModel.handleSaveButtonTap()
        await waitFor { viewModel.presentedError != nil }

        let didFail = viewModel.presentedError is TestError

        await service.setSaveError(nil)
        viewModel.handleSaveButtonTap()

        await waitFor { viewModel.didSave }
        #expect(
            didFail
                && viewModel.didSave,
            "A failed save can be retried successfully."
        )
    }

    @Test
    func handleSaveButtonTap_retryAfterFailure_clearsPresentedError() async {
        let program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])

        let service = WorkoutSessionStubService()
        await service.setSaveError(TestError())

        let viewModel = ActiveWorkoutViewModel(program: program, workoutSessionService: service)
        await viewModel.handleAppear()

        viewModel.handleSaveButtonTap()
        await waitFor { viewModel.presentedError != nil }

        let didFail = viewModel.presentedError is TestError

        await service.setSaveError(nil)
        viewModel.handleSaveButtonTap()

        #expect(
            didFail
                && (viewModel.presentedError == nil),
            "Starting a retry clears the previous save error."
        )
    }

}
