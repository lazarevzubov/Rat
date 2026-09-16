@testable
import Rat
import Testing

struct ProgramEditingTests {

    // MARK: - Methods

    @Test
    func addDay_appendsEmptyDay_atNextPosition() {
        var program = Program(name: "Push Pull Legs", dayTemplates: [DayTemplate(name: "Push", position: 0)])
        program.addDay()

        #expect(
            program.dayTemplates.map(\.position) == [
                0,
                1
            ],
            "The new day is appended at the next position."
        )
    }

    @Test
    func deleteDay_removesDay() {
        var program = Program(
            name: "Push Pull Legs",
            dayTemplates: [
                DayTemplate(name: "Push", position: 0),
                DayTemplate(name: "Pull", position: 1),
                DayTemplate(name: "Legs", position: 2)
            ]
        )
        program.deleteDay(at: [0])

        #expect(program.dayTemplates.map(\.name) == ["Pull", "Legs"], "The deleted day is removed.")
    }

    @Test
    func deleteDay_renumbersRemainingDays() {
        var program = Program(
            name: "Push Pull Legs",
            dayTemplates: [
                DayTemplate(name: "Push", position: 0),
                DayTemplate(name: "Pull", position: 1),
                DayTemplate(name: "Legs", position: 2)
            ]
        )
        program.deleteDay(at: [0])

        #expect(
            program.dayTemplates.map(\.position) == [
                0,
                1
            ],
            "The remaining days are renumbered from zero."
        )
    }

    @Test
    func moveDay_reordersAndRenumbers() {
        var program = Program(
            name: "Push Pull Legs",
            dayTemplates: [
                DayTemplate(name: "Push", position: 0),
                DayTemplate(name: "Pull", position: 1)
            ]
        )
        program.moveDay(from: [0], to: 2)

        #expect(program.dayTemplates.map(\.name) == ["Pull", "Push"], "The moved day is reordered.")
        #expect(program.dayTemplates.map(\.position) == [0, 1], "The days are renumbered to match the new order.")
    }

    @Test
    func addExercise_appendsEmptyExercise_atNextPosition() {
        var day = DayTemplate(
            name: "Push",
            position: 0,
            exerciseTemplates: [ExerciseTemplate(name: "Bench Press", position: 0, max: 100)]
        )
        day.addExercise()

        #expect(day.exerciseTemplates.map(\.position) == [0, 1], "The new exercise is appended at the next position.")
    }

    @Test
    func addSet_appendsWorkingSet_atNextPosition() {
        var exercise = ExerciseTemplate(
            name: "Bench Press",
            position: 0,
            max: 100,
            setTemplates: [SetTemplate(kind: .working, targetReps: 5, position: 0, percentOfMax: 80)]
        )
        exercise.addSet()

        #expect(exercise.setTemplates.map(\.position) == [0, 1], "The new set is appended at the next position.")
        #expect(exercise.setTemplates.last?.kind == .working, "The new set defaults to a working set.")
    }

    @Test
    func setKind_toWarmUp_clearsPercentOfMaxAndDefaultsWarmUpWeight() {
        var set = SetTemplate(kind: .working, targetReps: 5, position: 0, percentOfMax: 80)
        set.setKind(to: .warmUp)

        #expect(set.percentOfMax == nil, "Switching to warm-up clears the percent-of-max field.")
        #expect(set.warmUpWeight == 0, "Switching to warm-up defaults the warm-up weight field.")
    }

    @Test
    func setKind_toWorking_clearsWarmUpWeightAndDefaultsPercentOfMax() {
        var set = SetTemplate(kind: .warmUp, targetReps: 5, position: 0, warmUpWeight: 20)
        set.setKind(to: .working)

        #expect(set.warmUpWeight == nil, "Switching to working clears the warm-up weight field.")
        #expect(set.percentOfMax == 100, "Switching to working defaults the percent-of-max field.")
    }

    @Test
    func setKind_toSameKind_preservesExistingFieldValue() {
        var set = SetTemplate(kind: .working, targetReps: 5, position: 0, percentOfMax: 80)
        set.setKind(to: .working)

        #expect(set.percentOfMax == 80, "Re-selecting the same kind doesn't reset an already-entered value.")
    }

}
