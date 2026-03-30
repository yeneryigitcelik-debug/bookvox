import SwiftUI
import SwiftData
import CoreSpotlight

// MARK: - Ana uygulama giris noktasi
// SwiftData container, Spotlight deep link ve app lifecycle yonetimi

@main
struct BookVoxApp: App {
    let modelContainer: ModelContainer

    // Deep link ile acilacak kitap
    @State private var deepLinkBookId: UUID?

    init() {
        // SwiftData container — migration destegi ile
        let schema = Schema([
            Book.self,
            Page.self,
            ReadingProgress.self,
            Bookmark.self,
            Collection.self,
            ReadingStreak.self,
            UserPreferences.self,
            AudioChapter.self
        ])

        do {
            let config = ModelConfiguration(
                "BookVox",
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )
        } catch {
            // Migration hatasi durumunda yeni container dene
            // Bu sadece gelistirme sirasinda model degisikliklerinde olur
            do {
                let config = ModelConfiguration(
                    "BookVox",
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
                // Eski store'u sil ve yeniden olustur
                let url = config.url
                try? FileManager.default.removeItem(at: url)
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [config]
                )
            } catch {
                fatalError("SwiftData container olusturulamadi: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(deepLinkBookId: $deepLinkBookId)
                .onContinueUserActivity(
                    CSSearchableItemActionType,
                    perform: handleSpotlight
                )
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(modelContainer)
    }

    // Spotlight aramasindan kitap acildiginda
    private func handleSpotlight(_ userActivity: NSUserActivity) {
        if let bookId = SpotlightService.bookId(from: userActivity) {
            deepLinkBookId = bookId
        }
    }

    // URL scheme deep link (bookvox://book/{id})
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "bookvox",
              url.host == "book",
              let idString = url.pathComponents.last,
              let bookId = UUID(uuidString: idString)
        else { return }
        deepLinkBookId = bookId
    }
}
