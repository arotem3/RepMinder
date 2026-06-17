import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var wifi = WiFiService.shared
    @StateObject private var notifications = NotificationService.shared

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Location
                Section {
                    LabeledContent("Current network") {
                        Text(wifi.currentSSID ?? "Unknown")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Home Wi-Fi")
                        Spacer()
                        TextField("Network name (SSID)", text: $settings.homeSSID)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                            .autocorrectionDisabled()
                    }

                    if let ssid = wifi.currentSSID {
                        Button("Use \"\(ssid)\"") {
                            settings.homeSSID = ssid
                        }
                    }

                    Toggle("I'm home right now", isOn: $settings.manualHomeOverride)
                } header: {
                    Text("Location")
                } footer: {
                    Text("When you're on your home Wi-Fi, reminders fire more often. Toggle \"I'm home\" as a manual override if Wi-Fi detection isn't available.")
                }

                // MARK: - Intervals
                Section("Reminder Frequency") {
                    LabeledContent("At home, every") {
                        Picker("", selection: $settings.homeInterval) {
                            Text("30 min").tag(30)
                            Text("45 min").tag(45)
                            Text("1 hr").tag(60)
                            Text("90 min").tag(90)
                            Text("2 hr").tag(120)
                        }
                        .labelsHidden()
                    }

                    LabeledContent("Away, every") {
                        Picker("", selection: $settings.awayInterval) {
                            Text("1 hr").tag(60)
                            Text("90 min").tag(90)
                            Text("2 hr").tag(120)
                            Text("3 hr").tag(180)
                            Text("4 hr").tag(240)
                        }
                        .labelsHidden()
                    }
                }

                // MARK: - Quiet Hours
                Section {
                    Toggle("Enable quiet hours", isOn: $settings.quietHoursEnabled)

                    if settings.quietHoursEnabled {
                        LabeledContent("No reminders from") {
                            Picker("", selection: $settings.quietHoursStart) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(formattedHour(hour)).tag(hour)
                                }
                            }
                            .labelsHidden()
                        }

                        LabeledContent("Until") {
                            Picker("", selection: $settings.quietHoursEnd) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(formattedHour(hour)).tag(hour)
                                }
                            }
                            .labelsHidden()
                        }
                    }
                } header: {
                    Text("Quiet Hours")
                } footer: {
                    if settings.quietHoursEnabled {
                        Text("No reminders between \(formattedHour(settings.quietHoursStart)) and \(formattedHour(settings.quietHoursEnd)).")
                    }
                }

                // MARK: - Notifications
                Section {
                    HStack {
                        Label("Notifications", systemImage: "bell.fill")
                        Spacer()
                        if notifications.isAuthorized {
                            Label("Enabled", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .labelStyle(.iconOnly)
                                .font(.title3)
                        } else {
                            Button("Enable") {
                                Task { await notifications.requestPermission() }
                            }
                            .buttonStyle(.bordered)
                            .tint(.accentColor)
                        }
                    }
                } header: {
                    Text("Permissions")
                } footer: {
                    if !notifications.isAuthorized {
                        Text("Notifications are required for reminders to work.")
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                wifi.startMonitoring()
                Task { await notifications.refreshAuthorizationStatus() }
            }
        }
    }

    private func formattedHour(_ hour: Int) -> String {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = 0
        guard let date = Calendar.current.date(from: comps) else { return "\(hour):00" }
        return date.formatted(.dateTime.hour().minute())
    }
}
