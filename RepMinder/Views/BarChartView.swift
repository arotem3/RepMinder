import SwiftUI
import Charts

struct BarChartView: View {
    let exercises: [Exercise]
    @State private var periodDays = 30

    private struct DayPoint: Identifiable {
        let id = UUID()
        let label: String
        let progress: Double
        let date: Date
    }

    private var data: [DayPoint] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<periodDays).reversed().compactMap { offset -> DayPoint? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let progress = overallProgress(for: date)
            let label = offset == 0 ? "Today" : date.formatted(.dateTime.month(.twoDigits).day(.twoDigits))
            return DayPoint(label: label, progress: progress, date: date)
        }
    }

    private func overallProgress(for date: Date) -> Double {
        guard !exercises.isEmpty else { return 0 }
        let total = exercises.reduce(0.0) { $0 + min(1.0, Double($1.completed(on: date)) / Double(max(1, $1.dailyGoal))) }
        return total / Double(exercises.count)
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
                        x: .value("Date", point.label),
                        y: .value("Progress", point.progress * 100)
                    )
                    .foregroundStyle(point.progress >= 1.0 ? Color.green : Color.accentColor)
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
                    AxisMarks(values: .automatic(desiredCount: 7)) {
                        AxisValueLabel()
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
            let allMet = exercises.allSatisfy { $0.completed(on: day) >= $0.dailyGoal }
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

    private var rate: Double {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var met = 0
        for offset in 0..<days {
            if let date = cal.date(byAdding: .day, value: -offset, to: today),
               exercise.completed(on: date) >= exercise.dailyGoal {
                met += 1
            }
        }
        return Double(met) / Double(max(1, days))
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline.weight(.medium))
                Text("\(Int(rate * 100))% goal days")
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
}
