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

    func testTappingAddSet_dismissesNameKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewExerciseEditor(in: app)

        let nameField = app.textFields["Exercise Name"]
        nameField.tap()
        nameField.typeText("Bench Press")

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Typing into the name field shows the keyboard.")

        app.buttons["Add Set"].tap()
        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0),
            "Adding a set dismisses the keyboard left from typing the exercise name."
        )
    }

    func testTappingBlankSpace_dismissesNumberKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewExerciseEditor(in: app)

        app.textFields["Max"].tap()

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the max field shows the number keyboard.")

        app.blankSpace(below: app.buttons["Add Set"]).tap()
        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0), "Tapping outside the max field dismisses the keyboard."
        )
    }

    func testDraggingFromContent_dismissesNumberKeyboardAndUnfocusesField() {
        let app = XCUIApplication.launchedForTesting()
        openNewExerciseEditor(in: app)

        let maxField = app.textFields["Max"]
        maxField.tap()

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the max field shows the number keyboard.")
        XCTAssertNotEqual(maxField.value as? String, "0", "A focused, untouched max field is shown empty.")

        let start = app.staticTexts["Sets"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: .zero, dy: -50.0)))

        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0),
            "Dragging the content outside the max field dismisses the keyboard."
        )
        XCTAssertEqual(maxField.value as? String, "0", "The field loses focus, so its untouched value is shown again.")
    }

    func testTappingAnotherField_keepsFocusOnIt() {
        let app = XCUIApplication.launchedForTesting()
        openNewExerciseEditor(in: app)

        let nameField = app.textFields["Exercise Name"]
        nameField.tap()
        nameField.typeText("Bench Press")

        let maxField = app.textFields["Max"]
        maxField.tap()
        wait(
            for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "value != '0'"), object: maxField)],
            timeout: 5.0
        )

        let focusLost = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == '0'"), object: maxField)
        focusLost.isInverted = true

        wait(for: [focusLost], timeout: 2.0)
    }

    func testTappingSetField_keepsKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewExerciseEditor(in: app)
        addSet(in: app)

        app.textFields["% of Max"].tap()

        let keyboard = app.keyboards.element

        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the percent field shows the number keyboard.")
        XCTAssertFalse(keyboard.waitForNonExistence(timeout: 2.0), "Tapping the percent field leaves it focused.")
    }

    func testTappingStepper_dismissesNumberKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewExerciseEditor(in: app)
        addSet(in: app)

        app.textFields["% of Max"].tap()

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the percent field shows the number keyboard.")

        app.steppers["Reps: 10"].buttons["Increment"].tap()

        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0), "Tapping outside the percent field dismisses the keyboard."
        )
        XCTAssertTrue(app.steppers["Reps: 11"].exists, "The stepper still steps.")
    }

    func testTappingKindPicker_dismissesNumberKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewExerciseEditor(in: app)
        addSet(in: app)

        app.textFields["% of Max"].tap()

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the percent field shows the number keyboard.")

        app.buttons["Warm-up"].tap()

        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0), "Tapping outside the percent field dismisses the keyboard."
        )
        XCTAssertTrue(app.textFields["Weight"].exists, "The picker still switches the kind of the set.")
    }

    func testTappingUnitLabel_dismissesNumberKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewExerciseEditor(in: app)

        app.textFields["Max"].tap()

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the max field shows the number keyboard.")

        app.staticTexts["kg"].tap()
        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0), "Tapping outside the max field dismisses the keyboard."
        )
    }

    func testTappingSetLabel_dismissesNumberKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewExerciseEditor(in: app)
        addSet(in: app)

        app.textFields["Max"].tap()

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the max field shows the number keyboard.")

        app.staticTexts["% of Max"].tap()
        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0), "Tapping outside the max field dismisses the keyboard."
        )
    }

    func testTappingEditButton_dismissesNumberKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewExerciseEditor(in: app)
        addSet(in: app)

        app.textFields["Max"].tap()

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the max field shows the number keyboard.")

        app.navigationBars["New Exercise"].buttons["Edit"].tap()
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: 5.0), "Tapping Edit dismisses the keyboard.")
    }

    func testAddingSets_scrollsDownToNewSet() {
        let app = XCUIApplication.launchedForTesting()
        openNewExerciseEditor(in: app)

        let nameField = app.textFields["Exercise Name"]
        nameField.tap()
        nameField.typeText("Bench Press")

        let addSetButton = app.buttons["Add Set"]
        for _ in 1...6 {
            addSetButton.tap()
        }

        XCTAssertTrue(
            addSetButton.isHittable, "The button right below the newest set stays on screen, so the set is shown too."
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

    private func addSet(in app: XCUIApplication) {
        app.buttons["Add Set"].tap()
        XCTAssertTrue(app.textFields["% of Max"].waitForExistence(timeout: 5.0), "A working set is added by default.")
    }

}
