import Foundation
import SwiftData

// MARK: - Sayfa modeli
// Her kitap sayfasinin metin icerigi ve TTS audio bilgisi

@Model
final class Page {
    var id: UUID
    var pageNumber: Int
    var textContent: String
    var audioURL: String?
    var audioDuration: Double?
    var contextAnalysis: String?
    var book: Book?

    init(
        pageNumber: Int,
        textContent: String,
        book: Book? = nil
    ) {
        self.id = UUID()
        self.pageNumber = pageNumber
        self.textContent = textContent
        self.book = book
    }
}
