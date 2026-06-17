import SwiftUI
import SwiftData

@main
struct RepMinderApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var wifiService = WiFiService.shared
    @StateObject private var settings = AppSettings.shared

    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Exercise.self, ExerciseLog.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        wifiService.fetchCurrentSSID()
                        Task {
                            await NotificationService.shared.refreshAuthorizationStatus()
                        }
                    }
                }
        }
    }
}
