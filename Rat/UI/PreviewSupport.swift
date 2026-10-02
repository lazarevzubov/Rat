import SwiftData

#if DEBUG
@MainActor
enum PreviewSupport {

    // MARK: - Methods

    static func makeActiveWorkoutViewModel(program: Program) -> ActiveWorkoutViewModel {
        ActiveWorkoutViewModel(program: program, workoutSessionService: makeWorkoutSessionService())
    }

    static func makeProgramEditorViewModel(
        program: Program, exerciseNameSuggestions: [String]
    ) -> ProgramEditorViewModel {
        ProgramEditorViewModel(
            program: program,
            programService: makeProgramService(),
            exerciseNameSuggestions: exerciseNameSuggestions,
            workoutSessionService: makeWorkoutSessionService()
        ) {
            // Previews don't reload a program list, so there's nothing to do on save.
        }
    }

    static func makeProgramListViewModel() -> ProgramListViewModel {
        ProgramListViewModel(programService: makeProgramService(), workoutSessionService: makeWorkoutSessionService())
    }

    // MARK: Private methods

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema(
            [
                ProgramEntity.self,
                DayTemplateEntity.self,
                ExerciseTemplateEntity.self,
                SetTemplateEntity.self,
                WorkoutSessionEntity.self,
                LoggedExerciseEntity.self,
                LoggedSetEntity.self
            ]
        )
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Could not create an in-memory ModelContainer for previews: \(error)")
        }
    }

    private static func makeProgramService() -> ProgramService {
        ProgramPersistenceService(modelContainer: makeModelContainer())
    }

    private static func makeWorkoutSessionService() -> WorkoutSessionService {
        WorkoutSessionPersistenceService(modelContainer: makeModelContainer())
    }

}
#endif
