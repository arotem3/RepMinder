import SwiftUI
import SwiftData

struct LogRepsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let exercise: Exercise

    @State private var amount: Int = 10

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.title.bold())
                    Text("\(exercise.completedToday) of \(exercise.dailyGoal) \(exercise.unit) done today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if exercise.remainingToday > 0 {
                        Text("\(exercise.remainingToday) to go")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 32)
                .padding(.bottom, 40)

                // Amount picker
                VStack(spacing: 20) {
                    Text("\(amount)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .animation(.bouncy, value: amount)

                    HStack(spacing: 32) {
                        Button {
                            if amount > 1 { amount -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(amount > 1 ? .secondary : Color.secondary.opacity(0.3))
                        }
                        .disabled(amount <= 1)

                        Button {
                            amount += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.accentColor)
                        }
                    }

                    // Quick-select chips
                    let quickAmounts = quickOptions()
                    if !quickAmounts.isEmpty {
                        HStack(spacing: 10) {
                            ForEach(quickAmounts, id: \.self) { val in
                                Button {
                                    withAnimation(.bouncy) { amount = val }
                                } label: {
                                    Text("\(val)")
                                        .font(.subheadline.weight(.medium))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(amount == val ? Color.accentColor : Color.secondary.opacity(0.12))
                                        .foregroundStyle(amount == val ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                Spacer()

                Button {
                    logReps()
                } label: {
                    Text("Log \(amount) \(exercise.unit)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            amount = exercise.remainingToday > 0 ? min(exercise.remainingToday, exercise.dailyGoal / 5 + 1) : 10
        }
    }

    private func quickOptions() -> [Int] {
        var options: Set<Int> = [5, 10, 15, 20]
        if exercise.remainingToday > 0 { options.insert(exercise.remainingToday) }
        return options.filter { $0 > 0 && $0 <= exercise.dailyGoal }.sorted()
    }

    private func logReps() {
        let log = ExerciseLog(amount: amount, exercise: exercise)
        context.insert(log)
        dismiss()
    }
}
