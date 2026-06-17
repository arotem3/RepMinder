import NetworkExtension
import Foundation

@MainActor
final class WiFiService: ObservableObject {
    static let shared = WiFiService()

    @Published var currentSSID: String?

    private var timer: Timer?

    private init() {}

    func startMonitoring() {
        fetchCurrentSSID()
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.fetchCurrentSSID() }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func fetchCurrentSSID() {
        NEHotspotNetwork.fetchCurrent { [weak self] network in
            Task { @MainActor in
                self?.currentSSID = network?.ssid
            }
        }
    }

    func isAtHome(homeSSID: String) -> Bool {
        guard !homeSSID.isEmpty else { return false }
        return currentSSID == homeSSID
    }
}
