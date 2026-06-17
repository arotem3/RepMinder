import SwiftUI
import Charts

struct BarChartView: View {
    let exercises: [Exercise]
    @State private var periodDays = 30

    private struct DayPoint: Identifiable {
        let id = UUID()
        let progress: Double
        let date: Date
        let isRestDay: Bool
    }

    private var data: [DayPoint] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<periodDays).reversed().compactMap { offset -> DayPoint? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let scheduled = exercises.filter { $0.isScheduled(on: date) }
            let progress = overallProgress(for: date, scheduledExercises: scheduled)
            return DayPoint(progress: progress, date: date, isRestDay: scheduled.isEmpty)
        }
    }

    private func overallProgress(for date: Date, scheduledExercises: [Exercise]) -> Double {
        guard !scheduledExercises.isEmpty else { return 0 }
        let total = scheduledExercises.reduce(0.0) { $0 + $1.goalCompletion(on: date) }
        return total / Double(scheduledExercises.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StreakBadge(exercises: exercises)
                    .padding(.horizontal)

                Picker("Period", selection: $periodDays) {
                    Text("7 days").tag(7)
                    Text("30 days").tag(30)
                    Text("90 days").tag(90)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Chart(data) { point in
                    BarMark(
                        x: .value("Date", point.date),
                        y: .value("Progress", point.progress * 100)
                    )
                    .foregroundStyle(barColor(for: point))
                    .cornerRadius(3)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 50, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) { Text("\(v)%") }
                        }
                    }
                }
                .chartXAxis {
                    if periodDays == 7 {
                        AxisMarks(values: .stride(by: .day)) {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            AxisTick()
                            AxisValueLabel(format: .dateTime.weekday(.narrow))
                        }
                    } else {
                        AxisMarks(values: .stride(by: .day, count: periodDays == 30 ? 7 : 14)) {
                            AxisValueLabel(format: periodDays == 30 ? .dateTime.month(.abbreviated).day() : .dateTime.month(.abbreviated))
                        }
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Per Exercise")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(exercises) { exercise in
                        ExerciseStatRow(exercise: exercise, days: periodDays)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            .padding(.top)
        }
    }
}

private extension BarChartView {
    private func barColor(for point: DayPoint) -> Color {
        if point.isRestDay {
            return Color.secondary.opacity(0.18)
        }
        return point.progress >= 1.0 ? .green : .accentColor
    }
}

struct StreakBadge: View {
    let exercises: [Exercise]

    var streak: Int {
        guard !exercises.isEmpty else { return 0 }
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        let todayComplete = exercises.allSatisfy(\.isGoalMetToday)
        if !todayComplete {
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = prev
        }
        var count = 0
        while true {
            let allMet = exercises.allSatisfy { $0.isGoalMet(on: day) }
            guard allMet else { break }
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 2) {
                Text("\(streak)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(streak > 0 ? .orange : .secondary)
                Text("day streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider().frame(height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(streakMessage)
                    .font(.subheadline.weight(.medium))
                Text(streak > 0 ? "Consistency is the key." : "Complete all goals to start a streak.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var streakMessage: String {
        switch streak {
        case 0: return "No streak yet"
        case 1: return "1 day in a row"
        default: return "\(streak) days in a row"
        }
    }
}

private struct ExerciseStatRow: View {
    let exercise: Exercise
    let days: Int

    private var scheduledDays: Int {
        exercise.scheduledDayCount(forLast: days)
    }

    private var rate: Double {
        guard scheduledDays > 0 else { return 0 }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var met = 0
        for offset in 0..<days {
            if let date = cal.date(byAdding: .day, value: -offset, to: today),
               exercise.isGoalMet(on: date),
               exercise.isScheduled(on: date) {
                met += 1
            }
        }
        return Double(met) / Double(scheduledDays)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline.weight(.medium))
                Text(rateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ProgressView(value: rate)
                .tint(rate >= 0.8 ? .green : rate >= 0.5 ? .yellow : .red)
                .frame(width: 80)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var rateText: String {
        guard scheduledDays > 0 else { return "No scheduled days in range" }
        return "\(Int(rate * 100))% of scheduled days met"
    }
}
