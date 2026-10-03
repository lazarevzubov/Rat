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

#if DEBUG
#Preview {
    ContentView(viewModel: PreviewSupport.makeProgramListViewModel())
}
#endif
