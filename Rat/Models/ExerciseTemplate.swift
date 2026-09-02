import Foundation
import SwiftData

@Model
final class ExerciseTemplate {
    var name: String
    var position: Int

    var dayTemplate: DayTemplate?

    @Relationship(deleteRule: .cascade, inverse: \SetTemplate.exerciseTemplate)
    var setTemplates: [SetTemplate] = []

    init(name: String, position: Int) {
        self.name = name
        self.position = position
    }
}
