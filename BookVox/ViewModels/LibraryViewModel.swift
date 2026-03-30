import Foundation
import SwiftData

// MARK: - Kutuphane view model
// Kitap import, listeleme, silme, TTS prefetch, chapter detection, Spotlight

@Observable
final class LibraryViewModel {
    var books: [Book] = []
    var isImporting = false
    var isLoading = false
    var errorMessage: String?
    var importProgress: ImportProgress?

    private let supabase = SupabaseService.shared

    // Import asamalari
    struct ImportProgress {
        var step: Step
        var percent: Double

        enum Step: String {
            case reading = "PDF okunuyor..."
            case extracting = "Metin cikariliyor..."
            case analyzing = "Bolumler tespit ediliyor..."
            case uploading = "Buluta yukleniyor..."
            case rendering = "Ilk sayfalar seslendiriliyor..."
            case done = "Tamamlandi"
        }
    }

    // SwiftData'dan kitaplari yukle
    func loadBooks(context: ModelContext) {
        let descriptor = FetchDescriptor<Book>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        do {
            books = try context.fetch(descriptor)
        } catch {
            errorMessage = "Kitaplar yuklenemedi: \(error.localizedDescription)"
        }
    }

    // PDF dosyasindan kitap import et
    func importBook(from url: URL, context: ModelContext) async {
        // Premium kitap limiti kontrolu
        if !SubscriptionService.shared.canAddBook(currentCount: books.count) {
            errorMessage = "Ucretsiz planda en fazla \(Constants.App.freeBookLimit) kitap yukleyebilirsiniz. Premium'a yukseltmek icin Ayarlar'i ziyaret edin."
            HapticService.error()
            return
        }

        isLoading = true
        errorMessage = nil
        importProgress = ImportProgress(step: .reading, percent: 0)

        // Dosyaya erisim izni
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Dosya erisim izni alinamadi"
            isLoading = false
            importProgress = nil
            HapticService.error()
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // 1. PDF tek seferde ac — background thread'de cikar
        importProgress = ImportProgress(step: .reading, percent: 0.1)

        guard let extraction = await PDFService.extractAll(from: url) else {
            errorMessage = "PDF okunamadi"
            isLoading = false
            importProgress = nil
            HapticService.error()
            return
        }

        importProgress = ImportProgress(step: .extracting, percent: 0.3)

        // 2. Kitap modeli olustur
        let book = Book(
            title: extraction.title,
            author: extraction.author,
            totalPages: extraction.pageCount,
            pdfStoragePath: ""
        )
        book.coverImageData = extraction.coverImageData

        // 3. Sayfa modelleri olustur
        for (number, text) in extraction.pages {
            let page = Page(pageNumber: number, textContent: text, book: book)
            book.pages.append(page)
        }

        importProgress = ImportProgress(step: .analyzing, percent: 0.45)

        // 4. Bolum tespiti (hafif islem)
        let detectedChapters = ChapterDetectionService.detectChapters(from: extraction.pages)
        for chapter in detectedChapters {
            book.chapters.append(AudioChapter(
                title: chapter.title,
                startPage: chapter.startPage,
                endPage: chapter.endPage,
                isAutoDetected: true,
                book: book
            ))
        }

        // Context analysis import'ta yapilmaz — sayfa aciliginda lazy hesaplanir

        // 5. Okuma ilerlemesi + SwiftData kaydet
        book.readingProgress = ReadingProgress(book: book)
        context.insert(book)

        do {
            try context.save()
        } catch {
            errorMessage = "Lokal kayit hatasi: \(error.localizedDescription)"
            isLoading = false
            importProgress = nil
            HapticService.error()
            return
        }

        importProgress = ImportProgress(step: .uploading, percent: 0.55)

        // 6. Supabase sync (arka planda, hata kritik degil)
        do {
            let pdfData = try Data(contentsOf: url)
            let storagePath = "pdfs/\(book.id.uuidString).pdf"
            let remotePath = try await supabase.uploadPDF(data: pdfData, path: storagePath)
            book.pdfStoragePath = remotePath

            let remoteId = try await supabase.insertBook([
                "title": book.title,
                "author": book.author,
                "total_pages": book.totalPages,
                "pdf_storage_path": remotePath
            ])
            book.supabaseId = remoteId

            try await supabase.insertPages(
                book.pages.map { [
                    "book_id": remoteId,
                    "page_number": $0.pageNumber,
                    "text_content": $0.textContent
                ] },
                bookId: remoteId
            )
        } catch {
            // Lokal kullanim devam eder
        }

        importProgress = ImportProgress(step: .rendering, percent: 0.8)

        // 7. Ilk 3 sayfa TTS prefetch
        await prefetchAudio(for: book, pages: Array(1...min(3, book.totalPages)))

        try? context.save()
        SpotlightService.indexBook(book)

        isLoading = false
        importProgress = nil
        HapticService.importComplete()
        loadBooks(context: context)
    }

    // Kitap sil
    func deleteBook(_ book: Book, context: ModelContext) {
        SpotlightService.removeBook(book.id)
        context.delete(book)
        try? context.save()
        loadBooks(context: context)
    }

    // Ilk sayfalarin sesini onceden renderla
    private func prefetchAudio(for book: Book, pages: [Int]) async {
        guard let bookId = book.supabaseId else { return }

        do {
            let response = try await TTSService.renderBatch(
                bookId: bookId,
                pages: pages,
                tone: .standard
            )

            for result in response.results {
                if let page = book.pages.first(where: { $0.pageNumber == result.page }) {
                    page.audioURL = result.audioURL
                    page.audioDuration = result.durationSec
                }
            }
        } catch {
            print("Prefetch hatasi: \(error)")
        }
    }
}
