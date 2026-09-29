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

        app.buttons["Done"].tap()
        XCTAssertTrue(
            app.staticTexts["Push Pull Legs"].waitForExistence(timeout: 5.0),
            "The autosaved program appears in the list."
        )
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
        app.buttons["Untitled Day"].tap()

        wait(
            for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: keyboard)],
            timeout: 5.0
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

}
