import XCTest

@MainActor
final class ProgramEditorUITests: XCTestCase {

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

        app.buttons["Save"].tap()
        XCTAssertTrue(
            app.staticTexts["Push Pull Legs"].waitForExistence(timeout: 5.0),
            "The saved program appears in the list."
        )
    }

    func testAddProgram_withDayAndExerciseAndSet_savesNestedHierarchy() {
        let app = XCUIApplication.launchedForTesting()

        app.buttons["Add Program"].tap()

        let nameField = app.textFields["Program Name"]
        nameField.tap()
        nameField.typeText("Push Pull Legs")

        app.buttons["Add Day"].tap()

        let dayLink = app.buttons["Untitled Day"]
        XCTAssertTrue(dayLink.waitForExistence(timeout: 5.0))
        dayLink.tap()

        let dayNameField = app.textFields["Day Name"]
        dayNameField.tap()
        dayNameField.typeText("Push")

        app.buttons["Add Exercise"].tap()

        let exerciseLink = app.buttons["Untitled Exercise"]
        XCTAssertTrue(exerciseLink.waitForExistence(timeout: 5.0))
        exerciseLink.tap()

        let exerciseNameField = app.textFields["Exercise Name"]
        exerciseNameField.tap()
        exerciseNameField.typeText("Bench Press")

        app.buttons["Add Set"].tap()
        XCTAssertTrue(app.textFields["% of Max"].waitForExistence(timeout: 5.0), "A working set is added by default.")

        app.navigationBars["Bench Press"].buttons.element(boundBy: 0).tap()
        app.navigationBars["Push"].buttons.element(boundBy: 0).tap()
        app.buttons["Save"].tap()

        XCTAssertTrue(
            app.staticTexts["Push Pull Legs"].waitForExistence(timeout: 5.0),
            "The saved program appears in the list."
        )
    }

    func testDeleteProgram_removesItFromList() {
        let app = XCUIApplication.launchedForTesting()

        app.buttons["Add Program"].tap()

        let nameField = app.textFields["Program Name"]
        nameField.tap()
        nameField.typeText("Push Pull Legs")

        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Push Pull Legs"].waitForExistence(timeout: 5.0))

        app.staticTexts["Push Pull Legs"].swipeLeft()
        app.buttons["Delete"].tap()

        XCTAssertFalse(
            app.staticTexts["Push Pull Legs"].waitForExistence(timeout: 2.0),
            "The deleted program no longer appears in the list."
        )
    }

}
