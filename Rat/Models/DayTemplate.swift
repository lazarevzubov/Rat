import Foundation
import SwiftData

@Model
final class DayTemplate {
    var name: String
    var position: Int

    var program: Program?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseTemplate.dayTemplate)
    var exerciseTemplates: [ExerciseTemplate] = []

    init(name: String, position: Int) {
        self.name = name
        self.position = position
    }
}
