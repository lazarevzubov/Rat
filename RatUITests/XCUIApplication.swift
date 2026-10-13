import XCTest

extension XCUIApplication {

    // MARK: - Methods

    static func launchedForTesting() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["TEST"] = "1"
        app.launch()

        return app
    }

    func blankSpace(below element: XCUIElement) -> XCUICoordinate {
        coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX, dy: element.frame.maxY + 60.0))
    }

}
