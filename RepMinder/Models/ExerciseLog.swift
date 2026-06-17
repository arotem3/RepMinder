import SwiftData
import Foundation

@Model
final class ExerciseLog {
    var id: UUID
    var amount: Int
    var loggedAt: Date
    var exercise: Exercise?

    init(amount: Int, exercise: Exercise) {
        self.id = UUID()
        self.amount = amount
        self.loggedAt = Date()
        self.exercise = exercise
    }
}
