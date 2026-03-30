import Foundation
import Network

// MARK: - Ag baglanti izleyici
// Cevrimici/cevrimdisi durumu takip eder, offline mod yonetimi

@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.bookvox.networkmonitor")

    private(set) var isConnected = true
    private(set) var connectionType: ConnectionType = .unknown
    private(set) var isExpensive = false  // Cellular

    enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown

        var icon: String {
            switch self {
            case .wifi: "wifi"
            case .cellular: "cellularbars"
            case .wired: "cable.connector"
            case .unknown: "questionmark.circle"
            }
        }

        var displayName: String {
            switch self {
            case .wifi: "Wi-Fi"
            case .cellular: "Hucresel"
            case .wired: "Kablolu"
            case .unknown: "Bilinmiyor"
            }
        }
    }

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                self?.connectionType = self?.detectType(path) ?? .unknown

                if path.status != .satisfied {
                    NotificationCenter.default.post(name: .networkLost, object: nil)
                } else {
                    NotificationCenter.default.post(name: .networkRestored, object: nil)
                }
            }
        }
        monitor.start(queue: queue)
    }

    private func detectType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .wired }
        return .unknown
    }

    // Buyuk dosya indirilmeden once uyar (cellular'da)
    var shouldWarnBeforeDownload: Bool {
        isExpensive
    }
}

extension Notification.Name {
    static let networkLost = Notification.Name("networkLost")
    static let networkRestored = Notification.Name("networkRestored")
}
