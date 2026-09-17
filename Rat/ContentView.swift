import SwiftUI

/// The app's root view.
struct ContentView: View {

    // MARK: - Properties

    // MARK: View protocol properties

    var body: some View {
        NavigationStack {
            ProgramListView(viewModel: viewModel)
        }
    }

    // MARK: Private properties

    private let viewModel: ProgramListViewModel

    // MARK: - Initialization

    /// Creates the root view.
    /// - Parameter viewModel: The view model backing the program list this view shows.
    init(viewModel: ProgramListViewModel) {
        self.viewModel = viewModel
    }

}

// MARK: -

#Preview {
    ContentView(
        viewModel: ProgramListViewModel(
            programService: PreviewSupport.makeProgramService(),
            workoutSessionService: PreviewSupport.makeWorkoutSessionService()
        )
    )
}
