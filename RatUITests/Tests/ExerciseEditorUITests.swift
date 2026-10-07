import XCTest

@MainActor
final class ExerciseEditorUITests: XCTestCase {

    // MARK: - Methods

    override func setUpWithError() throws {
        continueAfterFailure = false
        try super.setUpWithError()
    }

    func testWithoutSets_hidesEditButton() {
        let app = XCUIApplication.launchedForTesting()
        openNewExerciseEditor(in: app)

        XCTAssertTrue(
            app.navigationBars["New Exercise"].buttons["Edit"].waitForNonExistence(timeout: 2.0),
            "There's nothing to reorder or delete while the exercise has no sets."
        )
    }

    func testWithSet_showsEditButton() {
        let app = XCUIApplication.launchedForTesting()
        openNewExerciseEditor(in: app)

        app.buttons["Add Set"].tap()

        XCTAssertTrue(
            app.navigationBars["New Exercise"].buttons["Edit"].waitForExistence(timeout: 5.0),
            "A set can be reordered or deleted, so the edit button is offered."
        )
    }

    func testAfterDeletingLastSetWhileEditing_addedSet_isNotInEditMode() {
        let app = XCUIApplication.launchedForTesting()
        openNewExerciseEditor(in: app)

        app.buttons["Add Set"].tap()

        app.navigationBars["New Exercise"].buttons["Edit"].tap()
        app.images["minus.circle.fill"].firstMatch.tap()
        app.buttons["Delete"].tap()

        app.buttons["Add Set"].tap()
        _ = app.textFields["% of Max"].waitForExistence(timeout: 5.0)

        XCTAssertTrue(
            app.images["minus.circle.fill"].waitForNonExistence(timeout: 2.0),
            "Deleting the last set while editing ends edit mode, so the next set isn't listed with delete controls."
        )
    }

    // MARK: Private methods

    private func openNewExerciseEditor(in app: XCUIApplication) {
        app.buttons["Add Program"].tap()

        let nameField = app.textFields["Program Name"]
        nameField.tap()
        nameField.typeText("Push Pull Legs")

        app.buttons["Add Day"].tap()
        app.buttons["Untitled Day"].tap()

        app.buttons["Add Exercise"].tap()
        app.buttons["Untitled Exercise"].tap()
    }

}
