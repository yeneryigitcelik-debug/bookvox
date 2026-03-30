import Foundation
import SwiftData

// MARK: - Kitap okuma view model
// Sayfa navigasyonu, bookmark yonetimi ve ilerleme takibi

@Observable
final class ReaderViewModel {
    var book: Book
    var currentPage: Int
    var isBookmarked = false

    private var context: ModelContext?

    init(book: Book) {
        self.book = book
        self.currentPage = book.readingProgress?.currentPage ?? 1
    }

    func setContext(_ context: ModelContext) {
        self.context = context
        updateBookmarkState()
    }

    // MARK: - Sayfa Navigasyonu

    var currentPageContent: Page? {
        book.pages.first { $0.pageNumber == currentPage }
    }

    var hasNextPage: Bool {
        currentPage < book.totalPages
    }

    var hasPreviousPage: Bool {
        currentPage > 1
    }

    func goToNextPage() {
        guard hasNextPage else { return }
        currentPage += 1
        updateProgress()
        updateBookmarkState()
    }

    func goToPreviousPage() {
        guard hasPreviousPage else { return }
        currentPage -= 1
        updateProgress()
        updateBookmarkState()
    }

    func goToPage(_ page: Int) {
        guard page >= 1, page <= book.totalPages else { return }
        currentPage = page
        updateProgress()
        updateBookmarkState()
    }

    // MARK: - Ilerleme

    private func updateProgress() {
        guard let progress = book.readingProgress else { return }
        progress.currentPage = currentPage
        progress.lastReadAt = Date()
        book.updatedAt = Date()
        try? context?.save()

        // Supabase sync (arka plan)
        if let bookId = book.supabaseId {
            Task {
                try? await SupabaseService.shared.upsertProgress(
                    bookId: bookId,
                    page: currentPage,
                    positionSec: progress.currentPositionSec
                )
            }
        }
    }

    // MARK: - Bookmark

    func toggleBookmark() {
        if isBookmarked {
            removeBookmark()
        } else {
            addBookmark()
        }
    }

    private func addBookmark() {
        let bookmark = Bookmark(pageNumber: currentPage, book: book)
        book.bookmarks.append(bookmark)
        isBookmarked = true
        try? context?.save()
    }

    private func removeBookmark() {
        if let bookmark = book.bookmarks.first(where: { $0.pageNumber == currentPage }) {
            book.bookmarks.removeAll { $0.id == bookmark.id }
            context?.delete(bookmark)
            isBookmarked = false
            try? context?.save()
        }
    }

    private func updateBookmarkState() {
        isBookmarked = book.bookmarks.contains { $0.pageNumber == currentPage }
    }

    func removeBookmark(at pageNumber: Int) {
        if let bookmark = book.bookmarks.first(where: { $0.pageNumber == pageNumber }) {
            book.bookmarks.removeAll { $0.id == bookmark.id }
            context?.delete(bookmark)
            try? context?.save()
        }
        updateBookmarkState()
    }
}
