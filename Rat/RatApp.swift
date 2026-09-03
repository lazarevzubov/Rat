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
            .modelContainer(modelContainer)
    }

    // MARK: Private properties

    private let modelContainer: ModelContainer = {
        let schema = Schema(
            [
                Program.self,
                DayTemplate.self,
                ExerciseTemplate.self,
                SetTemplate.self,
                WorkoutSession.self,
                LoggedExercise.self,
                LoggedSet.self
            ]
        )
        let configuration = ModelConfiguration(schema: schema)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create the SwiftData model container: \(error)")
        }
    }()

}
