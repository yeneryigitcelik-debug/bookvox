import Foundation

// MARK: - Audio dosya cache servisi
// R2'den indirilen audio dosyalarini lokal cache'ler

actor StorageService {
    static let shared = StorageService()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("BookVoxAudio", isDirectory: true)

        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    // Audio dosyasini cache'ten getir veya indir
    func getAudioFile(for audioURL: String) async throws -> URL {
        let fileName = audioURL.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "")
        let localURL = cacheDirectory.appendingPathComponent(fileName)

        // Cache'te varsa direkt don
        if fileManager.fileExists(atPath: localURL.path) {
            return localURL
        }

        // Yoksa indir ve cache'le
        guard let remoteURL = URL(string: audioURL) else {
            throw StorageError.invalidURL
        }

        let data = try await RetryHelper.withRetry {
            let (data, response) = try await URLSession.shared.data(from: remoteURL)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw StorageError.downloadFailed
            }
            return data
        }

        try data.write(to: localURL)

        // Cache boyutu kontrolu — 500MB'yi asarsa eski dosyalari sil
        try? evictIfNeeded()

        return localURL
    }

    private static let maxCacheBytes: Int64 = 500 * 1024 * 1024 // 500 MB

    private func evictIfNeeded() throws {
        let currentSize = try cacheSize()
        guard currentSize > Self.maxCacheBytes else { return }

        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentAccessDateKey, .fileSizeKey]
        )

        // En eski erisilen dosyalardan baslayarak sil
        let sorted = contents.sorted { a, b in
            let dateA = (try? a.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate) ?? .distantPast
            let dateB = (try? b.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate) ?? .distantPast
            return dateA < dateB
        }

        var freedBytes: Int64 = 0
        let targetFree = currentSize - Self.maxCacheBytes + (50 * 1024 * 1024) // 50MB tampon

        for file in sorted {
            guard freedBytes < targetFree else { break }
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            try? fileManager.removeItem(at: file)
            freedBytes += Int64(size)
        }
    }

    // Belirli bir kitabin cache'ini temizle
    func clearCache(for bookId: String) throws {
        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        )
        for file in contents where file.lastPathComponent.contains(bookId) {
            try fileManager.removeItem(at: file)
        }
    }

    // Tum cache'i temizle
    func clearAllCache() throws {
        if fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.removeItem(at: cacheDirectory)
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    // Cache boyutunu byte olarak dondur
    func cacheSize() throws -> Int64 {
        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        )
        return try contents.reduce(0) { total, url in
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            return total + Int64(size)
        }
    }

    enum StorageError: LocalizedError {
        case invalidURL
        case downloadFailed

        var errorDescription: String? {
            switch self {
            case .invalidURL: "Gecersiz audio URL"
            case .downloadFailed: "Audio indirme basarisiz"
            }
        }
    }
}
