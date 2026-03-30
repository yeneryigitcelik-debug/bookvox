import Foundation
import SwiftData

// MARK: - Koleksiyon modeli
// Kitaplari gruplama ve organize etme (Favoriler, Bilim, Roman vb.)

@Model
final class Collection {
    var id: UUID
    var name: String
    var icon: String          // SF Symbol adi
    var colorHex: String      // Tema rengi hex
    var sortOrder: Int
    var createdAt: Date

    @Relationship(inverse: \Book.collections)
    var books: [Book] = []

    init(
        name: String,
        icon: String = "folder",
        colorHex: String = "#5856D6",
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    // Varsayilan koleksiyonlar
    static let defaultCollections: [(name: String, icon: String, color: String)] = [
        ("Favoriler", "heart.fill", "#FF2D55"),
        ("Dinleniyor", "headphones", "#5856D6"),
        ("Tamamlanan", "checkmark.circle.fill", "#34C759"),
        ("Daha Sonra", "clock.fill", "#FF9500")
    ]
}
