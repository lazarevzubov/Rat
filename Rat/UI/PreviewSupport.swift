import SwiftData

#if DEBUG
enum PreviewSupport {

    // MARK: - Methods

    static func makeProgramService() -> ProgramService {
        ProgramPersistenceService(modelContainer: makeModelContainer())
    }

    static func makeWorkoutSessionService() -> WorkoutSessionService {
        WorkoutSessionPersistenceService(modelContainer: makeModelContainer())
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

}
#endif
