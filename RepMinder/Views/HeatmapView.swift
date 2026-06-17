import SwiftUI

struct HeatmapView: View {
    let exercises: [Exercise]

    private let weeksBack = 26
    private let dayLetters = ["S", "M", "T", "W", "T", "F", "S"]

    private var weeks: [[Date?]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Build flat list from weeksBack*7 days ago → today
        var days: [Date?] = (0..<(weeksBack * 7)).reversed().compactMap {
            cal.date(byAdding: .day, value: -$0, to: today)
        }

        // Pad front so first day lands on correct weekday column (0=Sun)
        if let first = days.compactMap({ $0 }).first {
            let weekday = cal.component(.weekday, from: first) - 1
            days = Array(repeating: nil as Date?, count: weekday) + days
        }

        // Chunk into 7-day columns (rows = Sun…Sat, columns = weeks)
        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0 + 7, days.count)]) }
    }

    private func cellColor(for date: Date) -> Color {
        guard !exercises.isEmpty else { return Color.secondary.opacity(0.1) }
        if date > Date() { return .clear }
        let progress = exercises.reduce(0.0) {
            $0 + min(1.0, Double($1.completed(on: date)) / Double(max(1, $1.dailyGoal)))
        } / Double(exercises.count)

        switch progress {
        case 0:          return Color.secondary.opacity(0.12)
        case ..<0.5:     return Color.accentColor.opacity(0.25)
        case ..<1.0:     return Color.accentColor.opacity(0.6)
        default:         return Color.green
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 4) {
                        // Weekday labels
                        VStack(spacing: 4) {
                            ForEach(dayLetters, id: \.self) { letter in
                                Text(letter)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 14, height: 14)
                            }
                        }

                        ForEach(weeks.indices, id: \.self) { w in
                            VStack(spacing: 4) {
                                ForEach(0..<7) { d in
                                    if let date = weeks[w][safe: d] ?? nil {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(cellColor(for: date))
                                            .frame(width: 14, height: 14)
                                    } else {
                                        Color.clear.frame(width: 14, height: 14)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Legend
                HStack(spacing: 6) {
                    Text("Less")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.12)).frame(width: 14, height: 14)
                    RoundedRectangle(cornerRadius: 3).fill(Color.accentColor.opacity(0.25)).frame(width: 14, height: 14)
                    RoundedRectangle(cornerRadius: 3).fill(Color.accentColor.opacity(0.6)).frame(width: 14, height: 14)
                    RoundedRectangle(cornerRadius: 3).fill(Color.green).frame(width: 14, height: 14)
                    Text("More")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // All-time totals
                VStack(alignment: .leading, spacing: 10) {
                    Text("All-Time Totals")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(exercises) { exercise in
                        let total = exercise.logs.reduce(0) { $0 + $1.amount }
                        HStack {
                            Text(exercise.name)
                                .font(.subheadline)
                            Spacer()
                            Text("\(total) \(exercise.unit)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            .padding(.top)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
