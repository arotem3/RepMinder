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

    private let units = ["reps", "seconds", "minutes"]

    private var isEditing: Bool { editing != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && Int(goalText) != nil && (Int(goalText) ?? 0) > 0 }

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
        } else {
            let exercise = Exercise(name: trimmedName, unit: unit, dailyGoal: goal, order: all.filter(\.isActive).count)
            context.insert(exercise)
        }
        dismiss()
    }
}
