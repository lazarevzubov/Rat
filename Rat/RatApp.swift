import SwiftData
import SwiftUI

@main
struct RatApp: App {
    let modelContainer: ModelContainer = {
        let schema = Schema([
            Program.self,
            DayTemplate.self,
            ExerciseTemplate.self,
            SetTemplate.self,
            WorkoutSession.self,
            LoggedExercise.self,
            LoggedSet.self
        ])
        let configuration = ModelConfiguration(schema: schema)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
