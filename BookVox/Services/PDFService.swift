import Foundation
import PDFKit

// MARK: - PDF isleme servisi
// Tek seferde metadata + cover + tum sayfa metinleri cikarir
// Background actor uzerinde calisir — main thread'i bloklamaz

actor PDFService {

    // Tek seferlik PDF islem sonucu
    struct PDFExtractionResult: Sendable {
        let title: String
        let author: String
        let pageCount: Int
        let coverImageData: Data?
        let pages: [(pageNumber: Int, text: String)]
    }

    // PDF'i bir kez ac, her seyi cikar — ana giris noktasi
    static func extractAll(from url: URL) async -> PDFExtractionResult? {
        await Task.detached(priority: .userInitiated) {
            guard let document = PDFDocument(url: url) else { return nil }

            // Metadata
            let attributes = document.documentAttributes
            let title = attributes?[PDFDocumentAttribute.titleAttribute] as? String
                ?? url.deletingPathExtension().lastPathComponent
            let author = attributes?[PDFDocumentAttribute.authorAttribute] as? String
                ?? "Unknown"

            // Cover — ilk sayfadan thumbnail
            let coverData: Data? = {
                guard let page = document.page(at: 0) else { return nil }
                let bounds = page.bounds(for: .mediaBox)
                let scale = min(300.0 / bounds.width, 400.0 / bounds.height)
                let image = page.thumbnail(of: CGSize(
                    width: bounds.width * scale,
                    height: bounds.height * scale
                ), for: .mediaBox)
                return image.pngData()
            }()

            // Sayfa metinleri — tek dongu
            var pages: [(Int, String)] = []
            pages.reserveCapacity(document.pageCount)

            for i in 0..<document.pageCount {
                guard let page = document.page(at: i),
                      let text = page.string,
                      !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else { continue }
                pages.append((i + 1, TextCleaner.clean(text)))
            }

            return PDFExtractionResult(
                title: title,
                author: author,
                pageCount: document.pageCount,
                coverImageData: coverData,
                pages: pages
            )
        }.value
    }

    // Tek sayfa metni cikar (on-demand okuma icin)
    static func extractSinglePage(from url: URL, pageNumber: Int) async -> String? {
        await Task.detached(priority: .utility) {
            guard let document = PDFDocument(url: url),
                  pageNumber > 0,
                  pageNumber <= document.pageCount,
                  let page = document.page(at: pageNumber - 1),
                  let text = page.string
            else { return nil }
            return TextCleaner.clean(text)
        }.value
    }
}
