import SwiftData
import SwiftUI

/// The app's entry point.
@main
struct RatApp: App {

    // MARK: - Properties

    // MARK: App protocol properties

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    // MARK: Private properties

    private let programService: ProgramService

    // MARK: - Initialization

    init() {
#if DEBUG
        let storedInMemory = ProcessInfo.processInfo.environment["TEST"] != nil
#else
        let storedInMemory = false
#endif
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
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: storedInMemory)

        let modelContainer: ModelContainer
        do {
            modelContainer = try ModelContainerFactory.makeModelContainer(schema: schema, configuration: configuration)
        } catch {
            fatalError("Could not create ModelContainer, even after resetting the store: \(error)")
        }

        programService = ProgramPersistenceService(modelContainer: modelContainer)
    }

}
