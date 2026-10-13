import SwiftUI

extension View {

    // MARK: - Methods

    /// Performs an action whenever the user touches the empty space below the content of a scroll view.
    ///
    /// Only the space the content leaves free is covered, and it doesn't take part in scrolling, so the content keeps reacting to touches as usual.
    ///
    /// - Parameter action: The action to perform.
    /// - Returns: A view that performs the action on touches in the empty space below its content.
    func onTouchBelowContent(perform action: @escaping () -> Void) -> some View {
        modifier(TouchBelowContent(action: action))
    }

}

// MARK: -

private struct TouchBelowContent: ViewModifier {

    // MARK: - Properties

    let action: () -> Void

    // MARK: Private properties

    @State
    private var availableHeight = CGFloat.zero
    @State
    private var contentHeight = CGFloat.zero

    // MARK: - Methods

    // MARK: ViewModifier protocol methods

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: Double.self) { $0.contentSize.height } action: { contentHeight = $1 }
            .overlay(alignment: .bottom) {
                Color.clear
                    .frame(height: max(.zero, availableHeight - contentHeight))
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: .zero)
                            .onChanged { _ in
                                action()
                            }
                    )
            }
            .onGeometryChange(for: Double.self) { $0.size.height } action: { availableHeight = $0 }
    }

}
