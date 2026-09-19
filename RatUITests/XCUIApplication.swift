import XCTest

extension XCUIApplication {

    // MARK: - Methods

    static func launchedForTesting() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["TEST"] = "1"
        app.launch()

        return app
    }

}
