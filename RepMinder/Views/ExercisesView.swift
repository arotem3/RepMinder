import SwiftUI
import SwiftData

struct ExercisesView: View {
    @Query(sort: \Exercise.order) var exercises: [Exercise]
    @Environment(\.modelContext) var context
    @State private var showingAdd = false
    @State private var exerciseToEdit: Exercise?

    private var active: [Exercise] { exercises.filter(\.isActive) }

    var body: some View {
        NavigationStack {
            List {
                ForEach(active) { exercise in
                    ExerciseRow(exercise: exercise)
                        .contentShape(Rectangle())
                        .onTapGesture { exerciseToEdit = exercise }
                }
                .onMove(perform: reorder)
                .onDelete(perform: softDelete)
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAdd) { AddExerciseView() }
            .sheet(item: $exerciseToEdit) { AddExerciseView(editing: $0) }
            .overlay {
                if active.isEmpty {
                    ContentUnavailableView {
                        Label("No Goals Yet", systemImage: "target")
                    } description: {
                        Text("Tap + to add your first exercise goal.")
                    } actions: {
                        Button("Add Exercise") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }

    private func reorder(from source: IndexSet, to destination: Int) {
        var list = active.sorted { $0.order < $1.order }
        list.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in list.enumerated() {
            exercise.order = index
        }
    }

    private func softDelete(at offsets: IndexSet) {
        let list = active.sorted { $0.order < $1.order }
        for index in offsets {
            list[index].isActive = false
        }
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            Text("Goal: \(exercise.dailyGoal) \(exercise.unit) / day")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
