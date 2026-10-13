import XCTest

@MainActor
final class ProgramEditorUITests: XCTestCase {

    // MARK: - Methods

    override func setUpWithError() throws {
        continueAfterFailure = false
        try super.setUpWithError()
    }

    func testRenameExistingProgram_navigatingBackWithoutTappingAnything_persistsRename() {
        let app = XCUIApplication.launchedForTesting()
        addProgramWithExercise(in: app, programName: "Push Pull Legs", exerciseName: "Bench Press")

        app.staticTexts["Push Pull Legs"].tap()

        let nameField = app.textFields["Program Name"]
        nameField.tap()
        deleteText(in: nameField, previousLength: "Push Pull Legs".count)
        nameField.typeText("Upper Lower")

        app.navigationBars["Upper Lower"].buttons.element(boundBy: 0).tap()

        XCTAssertTrue(
            app.staticTexts["Upper Lower"].waitForExistence(timeout: 5.0),
            "Editing an existing program autosaves the rename without any Save button."
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
        app.buttons["Done"].tap()

        XCTAssertTrue(
            app.staticTexts["Push Pull Legs"].waitForExistence(timeout: 5.0),
            "The autosaved program appears in the list."
        )
    }

    func testAddExercise_tappingSuggestion_fillsNameFromPreviousProgram() {
        let app = XCUIApplication.launchedForTesting()
        addProgramWithExercise(in: app, programName: "Push Pull Legs", exerciseName: "Bench Press")

        app.buttons["Add Program"].tap()

        let nameField = app.textFields["Program Name"]
        nameField.tap()
        nameField.typeText("Upper Lower")

        app.buttons["Add Day"].tap()
        app.buttons["Untitled Day"].tap()

        app.buttons["Add Exercise"].tap()
        app.buttons["Untitled Exercise"].tap()

        let exerciseNameField = app.textFields["Exercise Name"]
        exerciseNameField.tap()
        exerciseNameField.typeText("Bench")

        let suggestion = app.buttons["Bench Press"]
        XCTAssertTrue(
            suggestion.waitForExistence(timeout: 5.0), "A previously used matching exercise name is suggested."
        )
        suggestion.tap()

        XCTAssertEqual(
            exerciseNameField.value as? String, "Bench Press", "Tapping the suggestion fills the field with it."
        )
    }

    func testTappingDayRow_dismissesProgramNameKeyboard() {
        let app = XCUIApplication.launchedForTesting()

        app.buttons["Add Program"].tap()

        let nameField = app.textFields["Program Name"]
        nameField.tap()
        nameField.typeText("Push Pull Legs")

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Typing into the name field shows the keyboard.")

        app.buttons["Add Day"].tap()
        nameField.tap()

        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the name field again shows the keyboard.")

        app.buttons["Untitled Day"].tap()

        wait(
            for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: keyboard)],
            timeout: 5.0
        )
    }

    func testTappingAddDay_dismissesProgramNameKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewProgramEditor(in: app)

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Typing into the name field shows the keyboard.")

        app.buttons["Add Day"].tap()
        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0),
            "Adding a day dismisses the keyboard left from typing the program name."
        )
    }

    func testTappingBlankSpace_dismissesProgramNameKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewProgramEditor(in: app)

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Typing into the name field shows the keyboard.")

        app.blankSpace(below: app.buttons["Add Day"]).tap()
        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0), "Tapping outside the name field dismisses the keyboard."
        )
    }

    func testDraggingFromContent_dismissesProgramNameKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        openNewProgramEditor(in: app)

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Typing into the name field shows the keyboard.")

        let start = app.staticTexts["Days"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: .zero, dy: -50.0)))

        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0),
            "Dragging the content outside the name field dismisses the keyboard."
        )
    }

    func testExerciseMax_editingFromZero_doesNotAppendToTheZero() {
        let app = XCUIApplication.launchedForTesting()

        app.buttons["Add Program"].tap()

        let nameField = app.textFields["Program Name"]
        nameField.tap()
        nameField.typeText("Push Pull Legs")

        app.buttons["Add Day"].tap()
        app.buttons["Untitled Day"].tap()

        app.buttons["Add Exercise"].tap()
        app.buttons["Untitled Exercise"].tap()

        let maxField = app.textFields["Max"]
        maxField.tap()
        maxField.typeText("7")

        XCTAssertEqual(
            maxField.value as? String,
            "7",
            "Editing the untouched, zero-valued field starts it empty rather than appending after the displayed 0."
        )
    }

    func testWithoutDays_hidesEditButton() {
        let app = XCUIApplication.launchedForTesting()
        openNewProgramEditor(in: app)

        XCTAssertTrue(
            app.navigationBars["Push Pull Legs"].buttons["Edit"].waitForNonExistence(timeout: 2.0),
            "There's nothing to reorder or delete while the program has no days."
        )
    }

    func testWithDay_showsEditButton() {
        let app = XCUIApplication.launchedForTesting()
        openNewProgramEditor(in: app)

        app.buttons["Add Day"].tap()
        XCTAssertTrue(
            app.navigationBars["Push Pull Legs"].buttons["Edit"].waitForExistence(timeout: 5.0),
            "A day can be reordered or deleted, so the edit button is offered."
        )
    }

    // MARK: Private methods

    private func deleteText(in field: XCUIElement, previousLength: Int) {
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: previousLength))
    }

    private func addProgramWithExercise(in app: XCUIApplication, programName: String, exerciseName: String) {
        app.buttons["Add Program"].tap()

        let nameField = app.textFields["Program Name"]
        nameField.tap()
        nameField.typeText(programName)

        app.buttons["Add Day"].tap()
        app.buttons["Untitled Day"].tap()

        app.buttons["Add Exercise"].tap()
        app.buttons["Untitled Exercise"].tap()

        let exerciseNameField = app.textFields["Exercise Name"]
        exerciseNameField.tap()
        exerciseNameField.typeText(exerciseName)

        app.navigationBars[exerciseName].buttons.element(boundBy: 0).tap()
        app.navigationBars["New Day"].buttons.element(boundBy: 0).tap()
        app.buttons["Done"].tap()

        XCTAssertTrue(
            app.staticTexts[programName].waitForExistence(timeout: 5.0), "The autosaved program appears in the list."
        )
    }

    private func openNewProgramEditor(in app: XCUIApplication) {
        app.buttons["Add Program"].tap()

        let nameField = app.textFields["Program Name"]
        nameField.tap()
        nameField.typeText("Push Pull Legs")
    }

}
