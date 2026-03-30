import Foundation
import SwiftData

// MARK: - Okuma ilerlemesi
// Kullanicinin kitaptaki mevcut konumunu takip eder

@Model
final class ReadingProgress {
    var id: UUID
    var currentPage: Int
    var currentPositionSec: Double
    var lastReadAt: Date
    var book: Book?

    init(book: Book? = nil) {
        self.id = UUID()
        self.currentPage = 1
        self.currentPositionSec = 0
        self.lastReadAt = Date()
        self.book = book
    }
}
