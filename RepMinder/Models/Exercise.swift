import SwiftData
import Foundation

@Model
final class Exercise {
    var id: UUID
    var name: String
    var unit: String
    var dailyGoal: Int
    var scheduledWeekdays: [Int]
    var order: Int
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.exercise)
    var logs: [ExerciseLog] = []

    init(
        name: String,
        unit: String = "reps",
        dailyGoal: Int,
        scheduledWeekdays: [Int] = Array(1...7),
        order: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.unit = unit
        self.dailyGoal = dailyGoal
        self.scheduledWeekdays = scheduledWeekdays.sorted()
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

    func isScheduled(on date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return scheduledWeekdays.contains(weekday)
    }

    func goalCompletion(on date: Date) -> Double {
        guard isScheduled(on: date) else { return 1.0 }
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(completed(on: date)) / Double(dailyGoal))
    }

    func isGoalMet(on date: Date) -> Bool {
        !isScheduled(on: date) || completed(on: date) >= dailyGoal
    }

    func remaining(on date: Date) -> Int {
        guard isScheduled(on: date) else { return 0 }
        return max(0, dailyGoal - completed(on: date))
    }

    func scheduledDayCount(forLast numberOfDays: Int, endingOn date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: date)
        return (0..<numberOfDays).reduce(0) { count, offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: endDate) else {
                return count
            }
            return count + (isScheduled(on: day) ? 1 : 0)
        }
    }

    var completedToday: Int { completed(on: Date()) }

    var progressToday: Double {
        goalCompletion(on: Date())
    }

    var isGoalMetToday: Bool { isGoalMet(on: Date()) }

    var isRestToday: Bool { !isScheduled(on: Date()) }

    var remainingToday: Int { remaining(on: Date()) }
}
