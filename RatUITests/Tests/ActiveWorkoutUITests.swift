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

        app.buttons["Save"].tap()
        XCTAssertTrue(
            app.navigationBars["Push Pull Legs"].waitForExistence(timeout: 5.0),
            "Saving the workout dismisses back to the program editor it was started from."
        )

        app.buttons["Start Workout"].tap()
        XCTAssertTrue(app.navigationBars["Push"].waitForExistence(timeout: 5.0), "The day cycles back around to Push.")
        XCTAssertTrue(
            app.staticTexts["Increase next time"].waitForExistence(timeout: 5.0),
            "The flagged exercise shows the increase-next-time banner in its next session."
        )
    }

    // MARK: Private methods

    private func addProgramWithDayExerciseAndSet(in app: XCUIApplication, named name: String) {
        app.buttons["Add Program"].tap()

        let nameField = app.textFields["Program Name"]
        nameField.tap()
        nameField.typeText(name)

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

        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5.0), "The saved program appears in the list.")
    }

}
