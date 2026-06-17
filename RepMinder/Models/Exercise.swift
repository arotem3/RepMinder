import SwiftData
import Foundation

@Model
final class Exercise {
    var id: UUID
    var name: String
    var unit: String
    var dailyGoal: Int
    var order: Int
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.exercise)
    var logs: [ExerciseLog] = []

    init(name: String, unit: String = "reps", dailyGoal: Int, order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.unit = unit
        self.dailyGoal = dailyGoal
        self.order = order
        self.isActive = true
        self.createdAt = Date()
    }

    func completed(on date: Date) -> Int {
        let day = Calendar.current.startOfDay(for: date)
        return logs
            .filter { Calendar.current.startOfDay(for: $0.loggedAt) == day }
            .reduce(0) { $0 + $1.amount }
    }

    var completedToday: Int { completed(on: Date()) }

    var progressToday: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(completedToday) / Double(dailyGoal))
    }

    var isGoalMetToday: Bool { completedToday >= dailyGoal }

    var remainingToday: Int { max(0, dailyGoal - completedToday) }
}
