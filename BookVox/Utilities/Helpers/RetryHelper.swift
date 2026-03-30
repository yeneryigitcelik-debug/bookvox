import Foundation

// MARK: - Retry helper
// Network istekleri icin exponential backoff ile tekrar deneme

enum RetryHelper {

    struct RetryConfig {
        var maxAttempts: Int = 3
        var initialDelay: TimeInterval = 1.0
        var maxDelay: TimeInterval = 30.0
        var multiplier: Double = 2.0
    }

    // Exponential backoff ile tekrar dene
    static func withRetry<T>(
        config: RetryConfig = RetryConfig(),
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var delay = config.initialDelay

        for attempt in 1...config.maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                // Son deneme ise hatayi firlat
                if attempt == config.maxAttempts {
                    throw error
                }

                // Iptal edilebilir bekleme
                try await Task.sleep(for: .seconds(delay))
                delay = min(delay * config.multiplier, config.maxDelay)
            }
        }

        throw lastError ?? NSError(domain: "RetryHelper", code: -1)
    }

    // Ag baglantisi varsa dene, yoksa hata firlat
    static func withNetworkCheck<T>(
        operation: () async throws -> T
    ) async throws -> T {
        guard NetworkMonitor.shared.isConnected else {
            throw NetworkError.offline
        }
        return try await operation()
    }

    enum NetworkError: LocalizedError {
        case offline

        var errorDescription: String? {
            "Internet baglantisi yok. Lutfen baglantiyi kontrol edin."
        }
    }
}
