import XCTest

@MainActor
final class DayEditorUITests: XCTestCase {

    // MARK: - Methods

    override func setUpWithError() throws {
        continueAfterFailure = false
        try super.setUpWithError()
    }

    func testWithoutExercises_hidesEditButton() {
        let app = XCUIApplication.launchedForTesting()
        openNewDayEditor(in: app)

        XCTAssertTrue(
            app.navigationBars["New Day"].buttons["Edit"].waitForNonExistence(timeout: 2.0),
            "There's nothing to reorder or delete while the day has no exercises."
        )
    }

    func testWithExercise_showsEditButton() {
        let app = XCUIApplication.launchedForTesting()
        openNewDayEditor(in: app)

        app.buttons["Add Exercise"].tap()

        XCTAssertTrue(
            app.navigationBars["New Day"].buttons["Edit"].waitForExistence(timeout: 5.0),
            "An exercise can be reordered or deleted, so the edit button is offered."
        )
    }

    // MARK: Private methods

    private func openNewDayEditor(in app: XCUIApplication) {
        app.buttons["Add Program"].tap()

        let nameField = app.textFields["Program Name"]
        nameField.tap()
        nameField.typeText("Push Pull Legs")

        app.buttons["Add Day"].tap()
        app.buttons["Untitled Day"].tap()
    }

}
