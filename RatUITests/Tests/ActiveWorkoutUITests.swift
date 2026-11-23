import XCTest

@MainActor
final class ActiveWorkoutUITests: XCTestCase {

    // MARK: - Methods

    override func setUpWithError() throws {
        continueAfterFailure = false
        try super.setUpWithError()
    }

    func testStartWorkout_logSetAndSave_dismissesToProgramEditor() {
        let app = XCUIApplication.launchedForTesting()
        addProgramWithDayExerciseAndSet(in: app, named: "Push Pull Legs")

        app.staticTexts["Push Pull Legs"].tap()
        app.buttons["Start Workout"].tap()

        XCTAssertTrue(
            app.navigationBars["Push"].waitForExistence(timeout: 5.0), "The workout screen shows the seeded day's name."
        )

        app.steppers["Reps: 10"].buttons["Increment"].tap()

        let toggle = app.switches["Increase Next Time"]
        // The row also has a Stepper and a TextField, so the switch's own hit area—not the whole row—must be tapped;
        // its reported accessibility frame includes the label, so a plain `tap()` lands there instead of the switch.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "1", "The set is flagged to increase next time.")

        app.textFields["Weight"].tap()
        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "The weight keyboard is visible before saving.")

        app.buttons["Save"].tap()
        XCTAssertTrue(
            app.navigationBars["Push Pull Legs"].waitForExistence(timeout: 5.0),
            "Saving the workout dismisses back to the program editor it was started from."
        )
        XCTAssertTrue(
            app.navigationBars["Push"].waitForNonExistence(timeout: 5.0), "The saved workout sheet disappears."
        )
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: 5.0), "Saving dismisses the weight keyboard.")

        app.buttons["Start Workout"].tap()
        XCTAssertTrue(app.navigationBars["Push"].waitForExistence(timeout: 5.0), "The day cycles back around to Push.")
        XCTAssertTrue(
            increaseNextTimeReminder(in: app).waitForExistence(timeout: 5.0),
            "The flagged exercise shows the increase-next-time banner in its next session."
        )
    }

    func testSwipingUnchangedWorkout_keepsSheetPresented() {
        let app = XCUIApplication.launchedForTesting()
        addProgramWithDayExerciseAndSet(in: app, named: "Push Pull Legs")

        app.staticTexts["Push Pull Legs"].tap()
        app.buttons["Start Workout"].tap()

        let workoutBar = app.navigationBars["Push"]
        XCTAssertTrue(workoutBar.waitForExistence(timeout: 5.0), "The unchanged workout is ready to log.")

        let start = workoutBar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: .zero, dy: 450.0)))

        XCTAssertFalse(
            workoutBar.waitForNonExistence(timeout: 2.0),
            "Swiping down cannot discard a seeded workout, even before its values change."
        )
        XCTAssertTrue(app.buttons["Cancel"].isHittable, "The workout still offers its explicit Cancel action.")
    }

    func testCancelThenKeepWorkingOut_preservesEditsAndDismissesKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        addProgramWithDayExerciseAndSet(in: app, named: "Push Pull Legs")

        app.staticTexts["Push Pull Legs"].tap()
        app.buttons["Start Workout"].tap()
        app.steppers["Reps: 10"].buttons["Increment"].tap()

        let toggle = app.switches["Increase Next Time"]
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()

        let weightField = app.textFields["Weight"]
        weightField.tap()

        let originalWeight = weightField.value as? String ?? ""
        weightField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: originalWeight.count) + "42")

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "The weight keyboard is visible before Cancel.")

        app.buttons["Cancel"].tap()

        let confirmationTitle = app.staticTexts["Discard Workout?"]
        XCTAssertTrue(confirmationTitle.waitForExistence(timeout: 5.0), "Cancel asks before discarding the workout.")
        XCTAssertTrue(
            app.staticTexts["This workout hasn't been saved."].exists,
            "The confirmation explains why the workout needs a discard decision."
        )
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: 5.0), "Cancel dismisses the weight keyboard.")

        let keepWorkingOutButton = app.buttons["Keep Working Out"]
        if keepWorkingOutButton.exists {
            keepWorkingOutButton.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)).tap()
        }

        XCTAssertTrue(
            confirmationTitle.waitForNonExistence(timeout: 5.0), "Keeping the workout closes the confirmation."
        )
        XCTAssertTrue(app.navigationBars["Push"].exists, "Keeping the workout leaves its sheet presented.")
        XCTAssertTrue(app.steppers["Reps: 11"].exists, "Keeping the workout preserves the edited reps.")
        XCTAssertEqual(toggle.value as? String, "1", "Keeping the workout preserves its reminder flag.")
        XCTAssertEqual(weightField.value as? String, "42", "Keeping the workout preserves its edited weight.")
        XCTAssertFalse(keyboard.exists, "Keeping the workout leaves the weight field unfocused.")
    }

    func testCancelThenDiscard_restartsWithUnsavedDefaults() {
        let app = XCUIApplication.launchedForTesting()
        addProgramWithDayExerciseAndSet(in: app, named: "Push Pull Legs")

        app.staticTexts["Push Pull Legs"].tap()
        app.buttons["Start Workout"].tap()
        app.steppers["Reps: 10"].buttons["Increment"].tap()

        let toggle = app.switches["Increase Next Time"]
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()

        XCTAssertEqual(toggle.value as? String, "1", "The workout has an unsaved reminder before it is discarded.")

        app.buttons["Cancel"].tap()
        XCTAssertTrue(
            app.staticTexts["Discard Workout?"].waitForExistence(timeout: 5.0), "Cancel presents discard confirmation."
        )

        app.buttons["Discard Workout"].tap()

        XCTAssertTrue(
            app.navigationBars["Push"].waitForNonExistence(timeout: 5.0), "Discarding removes the workout sheet."
        )
        XCTAssertTrue(
            app.navigationBars["Push Pull Legs"].waitForExistence(timeout: 5.0),
            "Discarding returns to the program editor."
        )

        app.buttons["Start Workout"].tap()

        XCTAssertTrue(
            app.navigationBars["Push"].waitForExistence(timeout: 5.0), "A fresh workout starts from the program."
        )
        XCTAssertTrue(app.steppers["Reps: 10"].exists, "The fresh workout uses the program's original reps.")
        XCTAssertEqual(
            toggle.value as? String, "0", "The discarded reminder does not carry into the fresh workout."
        )
        XCTAssertFalse(
            increaseNextTimeReminder(in: app).exists, "Discarding does not save a reminder into history."
        )
    }

    func testTappingBlankSpace_dismissesWeightKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        addProgramWithDayExerciseAndSet(in: app, named: "Push Pull Legs")

        app.staticTexts["Push Pull Legs"].tap()
        app.buttons["Start Workout"].tap()
        app.textFields["Weight"].tap()

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the weight field shows the number keyboard.")

        app.blankSpace(below: app.switches["Increase Next Time"]).tap()

        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0), "Tapping outside the weight field dismisses the keyboard."
        )
    }

    func testDraggingFromContent_dismissesWeightKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        addProgramWithDayExerciseAndSet(in: app, named: "Push Pull Legs")

        app.staticTexts["Push Pull Legs"].tap()
        app.buttons["Start Workout"].tap()
        app.textFields["Weight"].tap()

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the weight field shows the number keyboard.")

        let start = app.staticTexts["Bench Press"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: .zero, dy: -50.0)))

        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0),
            "Dragging the content outside the weight field dismisses the keyboard."
        )
    }

    func testTappingWeightField_keepsKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        addProgramWithDayExerciseAndSet(in: app, named: "Push Pull Legs")

        app.staticTexts["Push Pull Legs"].tap()
        app.buttons["Start Workout"].tap()
        app.textFields["Weight"].tap()

        let keyboard = app.keyboards.element

        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the weight field shows the number keyboard.")
        XCTAssertFalse(keyboard.waitForNonExistence(timeout: 2.0), "Tapping the weight field leaves it focused.")
    }

    func testTappingStepper_dismissesWeightKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        addProgramWithDayExerciseAndSet(in: app, named: "Push Pull Legs")

        app.staticTexts["Push Pull Legs"].tap()
        app.buttons["Start Workout"].tap()
        app.textFields["Weight"].tap()

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the weight field shows the number keyboard.")

        app.steppers["Reps: 10"].buttons["Increment"].tap()

        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0), "Tapping outside the weight field dismisses the keyboard."
        )
        XCTAssertTrue(app.steppers["Reps: 11"].exists, "The stepper still steps.")
    }

    func testTappingToggle_dismissesWeightKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        addProgramWithDayExerciseAndSet(in: app, named: "Push Pull Legs")

        app.staticTexts["Push Pull Legs"].tap()
        app.buttons["Start Workout"].tap()
        app.textFields["Weight"].tap()

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the weight field shows the number keyboard.")

        let toggle = app.switches["Increase Next Time"]

        // The switch's reported frame spans the whole row, so only its trailing edge is the actual switch.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()

        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0), "Tapping outside the weight field dismisses the keyboard."
        )
        XCTAssertEqual(toggle.value as? String, "1", "The toggle still toggles.")
    }

    func testTappingKindCaption_dismissesWeightKeyboard() {
        let app = XCUIApplication.launchedForTesting()
        addProgramWithDayExerciseAndSet(in: app, named: "Push Pull Legs")

        app.staticTexts["Push Pull Legs"].tap()
        app.buttons["Start Workout"].tap()
        app.textFields["Weight"].tap()

        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5.0), "Tapping the weight field shows the number keyboard.")

        app.staticTexts["Working"].tap()
        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5.0), "Tapping outside the weight field dismisses the keyboard."
        )
    }

    // MARK: Private methods

    private func increaseNextTimeReminder(in app: XCUIApplication) -> XCUIElement {
        app
            .staticTexts
            .matching(NSPredicate(format: "label == %@ OR label == %@", "Increase next time", "INCREASE NEXT TIME"))
            .element
    }

    private func addProgramWithDayExerciseAndSet(in app: XCUIApplication, named name: String) {
        app.buttons["Add Program"].tap()

        let nameField = app.textFields["Program Name"]
        nameField.tap()
        nameField.typeText(name)

        XCTAssertEqual(nameField.value as? String, name, "The program name is entered before adding its day.")

        app.buttons["Add Day"].tap()

        let dayLink = app.buttons["Untitled Day"]
        XCTAssertTrue(dayLink.waitForExistence(timeout: 5.0))
        dayLink.tap()

        let dayNameField = app.textFields["Day Name"]
        dayNameField.tap()
        dayNameField.typeText("Push")

        XCTAssertEqual(dayNameField.value as? String, "Push", "The day name is entered before adding its exercise.")

        app.buttons["Add Exercise"].tap()

        let exerciseLink = app.buttons["Untitled Exercise"]
        XCTAssertTrue(exerciseLink.waitForExistence(timeout: 5.0))
        exerciseLink.tap()

        let exerciseNameField = app.textFields["Exercise Name"]
        exerciseNameField.tap()
        exerciseNameField.typeText("Bench Press")

        XCTAssertEqual(
            exerciseNameField.value as? String,
            "Bench Press",
            "The exercise name is entered before adding its set."
        )

        app.buttons["Add Set"].tap()
        XCTAssertTrue(app.textFields["% of Max"].waitForExistence(timeout: 5.0), "A working set is added by default.")

        let exerciseBackButton = app
            .navigationBars["Bench Press"]
            .buttons
            .matching(NSPredicate(format: "identifier == %@ OR label == %@", "BackButton", "Push"))
            .element
        XCTAssertTrue(exerciseBackButton.waitForExistence(timeout: 5.0), "The exercise editor exposes its Back button.")

        exerciseBackButton.tap()
        XCTAssertTrue(
            app.navigationBars["Push"].waitForExistence(timeout: 5.0), "Back returns to the day editor."
        )

        let dayBackButton = app
            .navigationBars["Push"]
            .buttons
            .matching(NSPredicate(format: "identifier == %@ OR label == %@", "BackButton", name))
            .element
        XCTAssertTrue(dayBackButton.waitForExistence(timeout: 5.0), "The day editor exposes its Back button.")

        dayBackButton.tap()
        XCTAssertTrue(
            app.navigationBars[name].waitForExistence(timeout: 5.0), "Back returns to the program editor."
        )
        app.buttons["Done"].tap()

        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5.0), "The saved program appears in the list.")
    }

}
