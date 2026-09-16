import SwiftData
import SwiftUI

/// The app's entry point.
@main
struct RatApp: App {

    // MARK: - Properties

    // MARK: App protocol properties

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }

    // MARK: Private properties

    @State
    private var viewModel: ProgramListViewModel

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

        let programService = ProgramPersistenceService(modelContainer: modelContainer)
        _viewModel = State(initialValue: ProgramListViewModel(programService: programService))
    }

}
