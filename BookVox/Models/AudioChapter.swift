import Foundation
import SwiftData

// MARK: - Bolum (chapter) modeli
// PDF'ten otomatik tespit edilen veya elle eklenen bolumler

@Model
final class AudioChapter {
    var id: UUID
    var title: String
    var startPage: Int
    var endPage: Int
    var isAutoDetected: Bool   // PDF'ten otomatik tespit mi?
    var book: Book?

    init(
        title: String,
        startPage: Int,
        endPage: Int,
        isAutoDetected: Bool = true,
        book: Book? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.startPage = startPage
        self.endPage = endPage
        self.isAutoDetected = isAutoDetected
        self.book = book
    }

    var pageRange: ClosedRange<Int> {
        startPage...endPage
    }

    var pageCount: Int {
        endPage - startPage + 1
    }
}
