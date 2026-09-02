import Foundation
import SwiftData

@Model
final class Program {
    var name: String

    @Relationship(deleteRule: .cascade, inverse: \DayTemplate.program)
    var dayTemplates: [DayTemplate] = []

    init(name: String) {
        self.name = name
    }
}
