import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(filter: #Predicate<Exercise> { $0.isActive }, sort: \Exercise.order)
    var exercises: [Exercise]

    @Environment(\.modelContext) var context
    @StateObject private var wifiService = WiFiService.shared
    @StateObject private var settings = AppSettings.shared
    @State private var selectedExercise: Exercise?

    private var isAtHome: Bool {
        settings.manualHomeOverride || wifiService.isAtHome(homeSSID: settings.homeSSID)
    }

    private var overallProgress: Double {
        guard !exercises.isEmpty else { return 0 }
        return exercises.reduce(0.0) { $0 + $1.progressToday } / Double(exercises.count)
    }

    private var allGoalsMet: Bool {
        !exercises.isEmpty && exercises.allSatisfy(\.isGoalMetToday)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    OverallProgressRing(progress: overallProgress, complete: allGoalsMet)
                        .padding(.horizontal)

                    HomeStatusBanner(isAtHome: isAtHome, ssidConfigured: !settings.homeSSID.isEmpty)
                        .padding(.horizontal)

                    if exercises.isEmpty {
                        EmptyExercisesPrompt()
                            .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(exercises) { exercise in
                                ExerciseCard(exercise: exercise) {
                                    selectedExercise = exercise
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(dayOfWeekTitle)
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedExercise) { exercise in
                LogRepsView(exercise: exercise)
            }
            .onAppear {
                wifiService.startMonitoring()
                reschedule()
            }
            .onChange(of: exercises) { _, _ in reschedule() }
        }
    }

    private var dayOfWeekTitle: String {
        Date().formatted(.dateTime.weekday(.wide))
    }

    private func reschedule() {
        NotificationService.shared.scheduleReminders(exercises: exercises, isAtHome: isAtHome)
    }
}

private struct OverallProgressRing: View {
    let progress: Double
    let complete: Bool

    var body: some View {
        HStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        complete ? Color.green : Color.accentColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
            }
            .frame(width: 100, height: 100)

            VStack(alignment: .leading, spacing: 6) {
                Text(complete ? "All done!" : "Daily progress")
                    .font(.headline)
                Text(complete ? "Great work today." : "Keep going — you've got this.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct HomeStatusBanner: View {
    let isAtHome: Bool
    let ssidConfigured: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isAtHome ? "house.fill" : "location.slash.fill")
                .foregroundStyle(isAtHome ? .green : .secondary)
            Text(isAtHome ? "Home — frequent reminders on" : "Away — reminders reduced")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if !ssidConfigured {
                Text("Configure in Settings")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct EmptyExercisesPrompt: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("No exercises yet")
                .font(.title3.weight(.medium))
            Text("Add your daily goals in the Goals tab.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: exercise.progressToday)
                        .stroke(
                            exercise.isGoalMetToday ? Color.green : Color.accentColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: exercise.progressToday)
                    if exercise.isGoalMetToday {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(exercise.completedToday) / \(exercise.dailyGoal) \(exercise.unit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: exercise.isGoalMetToday ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(exercise.isGoalMetToday ? .green : .accentColor)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
