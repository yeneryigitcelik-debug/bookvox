import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

// MARK: - Core Spotlight entegrasyonu
// Kitaplarin iOS arama'da gorunmesini saglar

enum SpotlightService {

    private static let domainIdentifier = "com.bookvox.books"

    // Kitabi Spotlight'a ekle
    static func indexBook(_ book: Book) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        attributeSet.title = book.title
        attributeSet.contentDescription = "\(book.author) — \(book.totalPages) sayfa"
        attributeSet.authorNames = [book.author]

        if let imageData = book.coverImageData {
            attributeSet.thumbnailData = imageData
        }

        // Aranabilir alanlar
        attributeSet.keywords = [book.title, book.author, "kitap", "audiobook", "BookVox"]

        let item = CSSearchableItem(
            uniqueIdentifier: book.id.uuidString,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )

        // 30 gun sonra expire
        item.expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: .now)

        CSSearchableIndex.default().indexSearchableItems([item])
    }

    // Kitabi Spotlight'tan kaldir
    static func removeBook(_ bookId: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: [bookId.uuidString]
        )
    }

    // Tum kitaplari yeniden indexle
    static func reindexAll(_ books: [Book]) {
        // Once temizle
        CSSearchableIndex.default().deleteSearchableItems(
            withDomainIdentifiers: [domainIdentifier]
        ) { _ in
            // Sonra tekrar ekle
            for book in books {
                indexBook(book)
            }
        }
    }

    // Tum indexi temizle
    static func removeAll() {
        CSSearchableIndex.default().deleteSearchableItems(
            withDomainIdentifiers: [domainIdentifier]
        )
    }

    // Deep link'ten kitap ID'si cikart
    static func bookId(from userActivity: NSUserActivity) -> UUID? {
        guard userActivity.activityType == CSSearchableItemActionType,
              let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String
        else { return nil }
        return UUID(uuidString: identifier)
    }
}
