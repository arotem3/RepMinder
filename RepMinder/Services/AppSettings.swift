import Foundation
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var homeSSID: String {
        didSet { store(homeSSID, for: .homeSSID) }
    }
    @Published var homeInterval: Int {
        didSet { store(homeInterval, for: .homeInterval) }
    }
    @Published var awayInterval: Int {
        didSet { store(awayInterval, for: .awayInterval) }
    }
    @Published var quietHoursEnabled: Bool {
        didSet { store(quietHoursEnabled, for: .quietHoursEnabled) }
    }
    @Published var quietHoursStart: Int {
        didSet { store(quietHoursStart, for: .quietHoursStart) }
    }
    @Published var quietHoursEnd: Int {
        didSet { store(quietHoursEnd, for: .quietHoursEnd) }
    }
    @Published var manualHomeOverride: Bool {
        didSet { store(manualHomeOverride, for: .manualHomeOverride) }
    }

    private enum Key: String {
        case homeSSID, homeInterval, awayInterval
        case quietHoursEnabled, quietHoursStart, quietHoursEnd
        case manualHomeOverride
    }

    private func store<T>(_ value: T, for key: Key) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    private static func load<T>(_ key: Key, default defaultValue: T) -> T {
        UserDefaults.standard.object(forKey: key.rawValue) as? T ?? defaultValue
    }

    private init() {
        homeSSID           = UserDefaults.standard.string(forKey: Key.homeSSID.rawValue) ?? ""
        homeInterval       = Self.load(.homeInterval, default: 60)
        awayInterval       = Self.load(.awayInterval, default: 180)
        quietHoursEnabled  = Self.load(.quietHoursEnabled, default: true)
        quietHoursStart    = Self.load(.quietHoursStart, default: 22)
        quietHoursEnd      = Self.load(.quietHoursEnd, default: 7)
        manualHomeOverride = Self.load(.manualHomeOverride, default: false)
    }
}
