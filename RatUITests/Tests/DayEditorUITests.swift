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

    func testTappingAddExercise_dismissesDayNameKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewDayEditor(in: app)

        let nameField = app.textFields["Day Name"]
        nameField.tap()
        nameField.typeText("Push")

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Typing into the name field shows the keyboard.")

        app.buttons["Add Exercise"].tap()
        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0),
            "Adding an exercise dismisses the keyboard left from typing the day name."
        )
    }

    func testTappingBlankSpace_dismissesNameKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewDayEditor(in: app)

        let nameField = app.textFields["Day Name"]
        nameField.tap()
        nameField.typeText("Push")

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Typing into the name field shows the keyboard.")

        app.blankSpace(below: app.buttons["Add Exercise"]).tap()
        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0), "Tapping outside the name field dismisses the keyboard."
        )
    }

    func testDraggingFromBlankSpace_dismissesNameKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewDayEditor(in: app)

        let nameField = app.textFields["Day Name"]
        nameField.tap()
        nameField.typeText("Push")

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Typing into the name field shows the keyboard.")

        let start = app.blankSpace(below: app.buttons["Add Exercise"])
        XCTAssertLessThan(start.screenPoint.y, keyboard.frame.minY, "The drag starts above the keyboard.")

        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: .zero, dy: -50.0)))
        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0), "Dragging outside the name field dismisses the keyboard."
        )
    }

    func testDraggingFromContent_dismissesNameKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewDayEditor(in: app)

        let nameField = app.textFields["Day Name"]
        nameField.tap()
        nameField.typeText("Push")

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Typing into the name field shows the keyboard.")

        let start = app.staticTexts["Exercises"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: .zero, dy: -50.0)))

        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0),
            "Dragging the content outside the name field dismisses the keyboard."
        )
    }

    func testDraggingContentThatFits_doesNotScroll() {
        let app = XCUIApplication.launchedForTesting()
        openNewDayEditor(in: app)

        let addButton = app.buttons["Add Exercise"]
        let restingPosition = addButton.frame.minY

        let start = addButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: .zero, dy: -100.0)))

        XCTAssertEqual(
            addButton.frame.minY,
            restingPosition,
            accuracy: 0.5,
            "The space reserved below the content for touches doesn't make short content scrollable."
        )
    }

    func testTappingEditButton_dismissesNameKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewDayEditor(in: app)

        app.buttons["Add Exercise"].tap()
        app.textFields["Day Name"].tap()

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the name field shows the keyboard.")

        app.navigationBars["New Day"].buttons["Edit"].tap()
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: 5.0), "Tapping Edit dismisses the keyboard.")
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
