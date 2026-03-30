import Foundation
import SwiftData

// MARK: - Yer imi modeli
// Kullanicinin isaretledigi sayfalari ve notlarini saklar

@Model
final class Bookmark {
    var id: UUID
    var pageNumber: Int
    var note: String?
    var createdAt: Date
    var book: Book?

    init(
        pageNumber: Int,
        note: String? = nil,
        book: Book? = nil
    ) {
        self.id = UUID()
        self.pageNumber = pageNumber
        self.note = note
        self.createdAt = Date()
        self.book = book
    }
}
