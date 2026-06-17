import SwiftUI
import SwiftData

@main
struct RepMinderApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var wifiService = WiFiService.shared
    @StateObject private var settings = AppSettings.shared

    let container: ModelContainer

    init() {
        let schema = Schema([Exercise.self, ExerciseLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            let storeURL = config.url
            let fm = FileManager.default
            for ext in ["", "-shm", "-wal"] {
                let url = storeURL.deletingPathExtension().appendingPathExtension("store\(ext)")
                try? fm.removeItem(at: url)
            }
            try? fm.removeItem(at: storeURL)
            do {
                container = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to create SwiftData container: \(error)")
            }
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
