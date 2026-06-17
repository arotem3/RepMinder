import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(filter: #Predicate<Exercise> { $0.isActive }, sort: \Exercise.order)
    var exercises: [Exercise]

    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedTab) {
                    Text("Chart").tag(0)
                    Text("Heatmap").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    BarChartView(exercises: exercises)
                } else {
                    HeatmapView(exercises: exercises)
                }
            }
            .navigationTitle("History")
        }
    }
}
