import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.order) private var all: [Exercise]

    var editing: Exercise?

    @State private var name = ""
    @State private var goalText = ""
    @State private var unit = "reps"
    @State private var scheduledWeekdays = Array(1...7)

    private let units = ["reps", "seconds", "minutes"]
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    private var isEditing: Bool { editing != nil }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(goalText) != nil &&
        (Int(goalText) ?? 0) > 0 &&
        !scheduledWeekdays.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name (e.g. Push-ups)", text: $name)
                    Picker("Unit", selection: $unit) {
                        ForEach(units, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section {
                    HStack {
                        TextField("Target", text: $goalText)
                            .keyboardType(.numberPad)
                        Text(unit)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Daily Goal")
                } footer: {
                    Text("You'll be reminded in sets until you reach this total each day.")
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                        ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                            let weekday = index + 1
                            Button {
                                toggleWeekday(weekday)
                            } label: {
                                Text(symbol)
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(scheduledWeekdays.contains(weekday) ? Color.accentColor : Color.secondary.opacity(0.12))
                                    .foregroundStyle(scheduledWeekdays.contains(weekday) ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button(scheduledWeekdays.count == 7 ? "Weekdays Only" : "Every Day") {
                        scheduledWeekdays = scheduledWeekdays.count == 7 ? [2, 3, 4, 5, 6] : Array(1...7)
                    }
                } header: {
                    Text("Weekly Schedule")
                } footer: {
                    Text("Turn days off for rest days. Rest days are excluded from reminders, streak misses, and required progress.")
                }
            }
            .navigationTitle(isEditing ? "Edit Exercise" : "New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if let e = editing {
                    name = e.name
                    goalText = "\(e.dailyGoal)"
                    unit = e.unit
                    scheduledWeekdays = e.scheduledWeekdays
                }
            }
        }
    }

    private func save() {
        guard let goal = Int(goalText), canSave else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let e = editing {
            e.name = trimmedName
            e.dailyGoal = goal
            e.unit = unit
            e.scheduledWeekdays = scheduledWeekdays.sorted()
        } else {
            let exercise = Exercise(
                name: trimmedName,
                unit: unit,
                dailyGoal: goal,
                scheduledWeekdays: scheduledWeekdays.sorted(),
                order: all.filter(\.isActive).count
            )
            context.insert(exercise)
        }
        dismiss()
    }

    private func toggleWeekday(_ weekday: Int) {
        if let index = scheduledWeekdays.firstIndex(of: weekday) {
            scheduledWeekdays.remove(at: index)
        } else {
            scheduledWeekdays.append(weekday)
            scheduledWeekdays.sort()
        }
    }
}
