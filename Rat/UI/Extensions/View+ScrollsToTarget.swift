import SwiftUI

/// Identifies a view a screen can scroll to.
enum ScrollTarget: Hashable {

    /// The button that appends an item to the list above it.
    case addButton

}

// MARK: -

extension View {

    // MARK: - Methods

    /// Scrolls to a view whenever a count of the items listed above it grows.
    ///
    /// New items are appended at the end, and the button that adds them sits right below, so scrolling the button to the bottom shows both.
    ///
    /// - Parameters:
    ///   - target: The view to scroll to, which has to be marked with `id(_:)`.
    ///   - count: The number of items listed, for example the length of the array the Add button appends to.
    /// - Returns: A view that scrolls to the target as the count grows.
    func scrolls(to target: ScrollTarget, whenCountGrows count: Int) -> some View {
        modifier(ScrollToTargetOnGrowth(count: count, target: target))
    }

}

// MARK: -

private struct ScrollToTargetOnGrowth: ViewModifier {

    // MARK: - Properties

    // MARK: Private methods

    private let count: Int
    private let target: ScrollTarget

    // MARK: - Initialization

    init(count: Int, target: ScrollTarget) {
        self.count = count
        self.target = target
    }

    // MARK: - Methods

    // MARK: ViewModifier protocol methods

    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                .onChange(of: count) {
                    if $1 > $0 {
                        withAnimation { proxy.scrollTo(target, anchor: .bottom) }
                    }
                }
        }
    }

}
