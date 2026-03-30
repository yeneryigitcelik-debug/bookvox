import Foundation
import SwiftData

// MARK: - Kitap modeli
// PDF'ten import edilen kitapların ana veri modeli

@Model
final class Book {
    var id: UUID
    var title: String
    var author: String
    var totalPages: Int
    var coverImageData: Data?
    var pdfStoragePath: String
    var supabaseId: String?
    var isFavorite: Bool
    var lastPlayedTone: String?     // Son kullanilan ses tonu
    var totalListenedSec: Double    // Toplam dinleme suresi
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Page.book)
    var pages: [Page] = []

    @Relationship(deleteRule: .cascade, inverse: \Bookmark.book)
    var bookmarks: [Bookmark] = []

    @Relationship(deleteRule: .cascade, inverse: \ReadingProgress.book)
    var readingProgress: ReadingProgress?

    @Relationship(deleteRule: .cascade, inverse: \AudioChapter.book)
    var chapters: [AudioChapter] = []

    var collections: [Collection] = []

    init(
        title: String,
        author: String = "Unknown",
        totalPages: Int,
        pdfStoragePath: String
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.totalPages = totalPages
        self.pdfStoragePath = pdfStoragePath
        self.isFavorite = false
        self.totalListenedSec = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // Tamamlanma yuzdesi
    var completionPercent: Double {
        guard totalPages > 0, let progress = readingProgress else { return 0 }
        return Double(progress.currentPage) / Double(totalPages)
    }

    // Tahmini kalan dinleme suresi (ortalama sayfa suresi x kalan sayfalar)
    var estimatedRemainingMinutes: Double? {
        guard totalPages > 0,
              let progress = readingProgress,
              totalListenedSec > 0
        else { return nil }

        let avgSecPerPage = totalListenedSec / Double(max(progress.currentPage - 1, 1))
        let remainingPages = Double(totalPages - progress.currentPage)
        return (avgSecPerPage * remainingPages) / 60.0
    }

    // Formatted dinleme suresi
    var formattedListenTime: String {
        let hours = Int(totalListenedSec) / 3600
        let minutes = (Int(totalListenedSec) % 3600) / 60
        if hours > 0 {
            return "\(hours)s \(minutes)dk"
        }
        return "\(minutes)dk"
    }
}
