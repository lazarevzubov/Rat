import SwiftData

#if DEBUG
enum PreviewSupport {

    // MARK: - Methods

    /// Creates a program service backed by an in-memory store, for previews only.
    static func makeProgramService() -> ProgramService {
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
            let container = try ModelContainer(for: schema, configurations: configuration)
            return ProgramPersistenceService(modelContainer: container)
        } catch {
            fatalError("Could not create an in-memory ModelContainer for previews: \(error)")
        }
    }

}
#endif
