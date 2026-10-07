import XCTest

@MainActor
final class ProgramListUITests: XCTestCase {

    // MARK: - Methods

    override func setUpWithError() throws {
        continueAfterFailure = false
        try super.setUpWithError()
    }

    func testAddProgram_appearsInList_withNameFromEditor() {
        let app = XCUIApplication.launchedForTesting()

        app.buttons["Add Program"].tap()

        let nameField = app.textFields["Program Name"]
        nameField.tap()
        nameField.typeText("Push Pull Legs")

        app.buttons["Done"].tap()
        XCTAssertTrue(
            app.staticTexts["Push Pull Legs"].waitForExistence(timeout: 5.0),
            "The autosaved program appears in the list."
        )
    }

    func testDeleteProgram_removesItFromList() {
        let app = XCUIApplication.launchedForTesting()

        app.buttons["Add Program"].tap()

        let nameField = app.textFields["Program Name"]
        nameField.tap()
        nameField.typeText("Push Pull Legs")

        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Push Pull Legs"].waitForExistence(timeout: 5.0))

        app.staticTexts["Push Pull Legs"].swipeLeft()
        app.buttons["Delete"].tap()

        XCTAssertFalse(
            app.staticTexts["Push Pull Legs"].waitForExistence(timeout: 2.0),
            "The deleted program no longer appears in the list."
        )
    }

    func testWithoutPrograms_hidesEditButton() {
        let app = XCUIApplication.launchedForTesting()
        XCTAssertTrue(
            app.navigationBars["Programs"].buttons["Edit"].waitForNonExistence(timeout: 2.0),
            "There's nothing to delete while the list has no programs."
        )
    }

    func testWithProgram_showsEditButton() {
        let app = XCUIApplication.launchedForTesting()
        addProgram(in: app)

        XCTAssertTrue(
            app.navigationBars["Programs"].buttons["Edit"].waitForExistence(timeout: 5.0),
            "A program can be deleted, so the edit button is offered."
        )
    }

    func testAfterDeletingLastProgramWhileEditing_addedProgram_isNotInEditMode() {
        let app = XCUIApplication.launchedForTesting()
        addProgram(in: app)

        app.navigationBars["Programs"].buttons["Edit"].tap()
        app.images["minus.circle.fill"].firstMatch.tap()
        app.buttons["Delete"].tap()

        addProgram(in: app)
        _ = app.buttons["Push Pull Legs"].waitForExistence(timeout: 5.0)

        XCTAssertFalse(
            app.buttons["Remove, Push Pull Legs"].exists,
            "Deleting the last program while editing ends edit mode, so the next program isn't listed with delete "
                + "controls."
        )
    }

    // MARK: Private methods

    private func addProgram(in app: XCUIApplication) {
        app.buttons["Add Program"].tap()

        let nameField = app.textFields["Program Name"]
        nameField.tap()
        nameField.typeText("Push Pull Legs")

        app.buttons["Done"].tap()
    }

}
