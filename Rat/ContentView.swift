import SwiftUI

/// The app's root view.
struct ContentView: View {

    // MARK: - Properties

    // MARK: View protocol properties

    var body: some View {
        NavigationStack {
            Text("Rat")
                .navigationTitle("Rat")
        }
    }

}

#Preview {
    ContentView()
}
