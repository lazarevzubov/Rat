import XCTest

@MainActor
final class ActiveWorkoutUITests: XCTestCase {

    // MARK: - Methods

    override func setUpWithError() throws {
        continueAfterFailure = false
        try super.setUpWithError()
    }

    func testStartWorkout_logSetAndSave_dismissesToList() {
        let app = XCUIApplication.launchedForTesting()
        addProgramWithDayExerciseAndSet(in: app, named: "Push Pull Legs")

        app.staticTexts["Push Pull Legs"].swipeRight()
        app.buttons["Start Workout"].tap()

        XCTAssertTrue(
            app.navigationBars["Push"].waitForExistence(timeout: 5.0), "The workout screen shows the seeded day's name."
        )

        app.steppers["Reps: 5"].buttons["Increment"].tap()
        app.switches["Increase Next Time"].tap()

        app.buttons["Save"].tap()
        XCTAssertTrue(
            app.navigationBars["Programs"].waitForExistence(timeout: 5.0),
            "Saving the workout dismisses back to the program list."
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
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5.0), "The saved program appears in the list.")
    }

}
