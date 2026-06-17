import UserNotifications
import Foundation

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    private init() {}

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func scheduleReminders(exercises: [Exercise], isAtHome: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let incomplete = exercises.filter { !$0.isGoalMetToday }
        guard !incomplete.isEmpty else { return }

        let settings = AppSettings.shared
        let intervalMinutes = isAtHome ? settings.homeInterval : settings.awayInterval
        let intervalSeconds = Double(intervalMinutes * 60)

        let now = Date()
        let horizon = now.addingTimeInterval(18 * 3600)
        var nextFire = now.addingTimeInterval(intervalSeconds)
        var count = 0

        while nextFire < horizon && count < 24 {
            if !settings.quietHoursEnabled || !isInQuietHours(nextFire, start: settings.quietHoursStart, end: settings.quietHoursEnd) {
                let content = UNMutableNotificationContent()
                content.title = isAtHome ? "Time to move" : "Still got work to do"
                let names = incomplete.map(\.name).joined(separator: ", ")
                content.body = isAtHome
                    ? "Knock out a set of \(names)"
                    : "\(names) — finish up when you get home"
                content.sound = .default

                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextFire)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: "reminder-\(count)", content: content, trigger: trigger)
                center.add(request)
                count += 1
            }
            nextFire = nextFire.addingTimeInterval(intervalSeconds)
        }

        scheduleDailyMorningReminder()
    }

    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func scheduleDailyMorningReminder() {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        let content = UNMutableNotificationContent()
        content.title = "Good morning"
        content.body = "Your daily exercise goals are waiting — start your streak!"
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "morning-reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func isInQuietHours(_ date: Date, start: Int, end: Int) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        if start > end {
            return hour >= start || hour < end
        } else {
            return hour >= start && hour < end
        }
    }
}
