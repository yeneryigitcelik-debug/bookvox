import Foundation

// MARK: - Bolum tespit servisi
// PDF metin iceriginden otomatik bolum/baslik tespiti

enum ChapterDetectionService {

    // Bolum tespit desenleri (Turkce + Ingilizce)
    private static let chapterPatterns: [String] = [
        // Turkce
        "^\\s*BOLUM\\s+\\d+",
        "^\\s*Bolum\\s+\\d+",
        "^\\s*KISIM\\s+\\d+",
        "^\\s*Kisim\\s+\\d+",
        "^\\s*BÖLÜM\\s+\\d+",
        "^\\s*Bölüm\\s+\\d+",
        // Ingilizce
        "^\\s*CHAPTER\\s+\\d+",
        "^\\s*Chapter\\s+\\d+",
        "^\\s*PART\\s+\\d+",
        "^\\s*Part\\s+\\d+",
        // Romen rakamlari
        "^\\s*(CHAPTER|Chapter|BOLUM|Bolum|BÖLÜM|Bölüm)\\s+[IVXLCDM]+",
        // Sadece rakam (1., 2., vb.)
        "^\\s*\\d+\\.",
        // Uzun tire ile baslayanlar
        "^\\s*—\\s*\\d+"
    ]

    // Baslik tespit kriterleri
    private struct TitleCandidate {
        let text: String
        let pageNumber: Int
        let confidence: Double
    }

    // Sayfa metinlerinden bolumleri tespit et
    static func detectChapters(from pages: [(pageNumber: Int, text: String)]) -> [DetectedChapter] {
        var candidates: [TitleCandidate] = []

        for (pageNumber, text) in pages {
            let lines = text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            // Ilk 5 satiri kontrol et (basliklar genelde sayfa basinda)
            for line in lines.prefix(5) {
                let confidence = calculateConfidence(line: line, isFirstLine: line == lines.first)
                if confidence > 0.4 {
                    candidates.append(TitleCandidate(
                        text: cleanTitle(line),
                        pageNumber: pageNumber,
                        confidence: confidence
                    ))
                }
            }
        }

        // Cok yakin sayfalardaki tekrarlari filtrele (en az 3 sayfa aralik)
        var filtered: [TitleCandidate] = []
        for candidate in candidates {
            if let last = filtered.last, candidate.pageNumber - last.pageNumber < 3 {
                // Daha yuksek confidence'li olani tut
                if candidate.confidence > last.confidence {
                    filtered.removeLast()
                    filtered.append(candidate)
                }
            } else {
                filtered.append(candidate)
            }
        }

        // DetectedChapter'lara donustur
        var chapters: [DetectedChapter] = []
        for (index, candidate) in filtered.enumerated() {
            let endPage: Int
            if index + 1 < filtered.count {
                endPage = filtered[index + 1].pageNumber - 1
            } else {
                endPage = pages.last?.pageNumber ?? candidate.pageNumber
            }

            chapters.append(DetectedChapter(
                title: candidate.text,
                startPage: candidate.pageNumber,
                endPage: endPage,
                confidence: candidate.confidence
            ))
        }

        return chapters
    }

    struct DetectedChapter {
        let title: String
        let startPage: Int
        let endPage: Int
        let confidence: Double
    }

    // Confidence hesaplama
    private static func calculateConfidence(line: String, isFirstLine: Bool) -> Double {
        var score = 0.0

        // Pattern eslesmesi
        for pattern in chapterPatterns {
            if line.range(of: pattern, options: .regularExpression) != nil {
                score += 0.5
                break
            }
        }

        // Kisa satirlar baslik olma olasiligi yuksek
        if line.count < 60 { score += 0.15 }
        if line.count < 30 { score += 0.1 }

        // Tamamen buyuk harf
        if line == line.uppercased() && line.count > 3 { score += 0.15 }

        // Sayfanin ilk satiri
        if isFirstLine { score += 0.1 }

        // Sayfa numarasiyla baslamiyorsa
        if !line.hasPrefix(String(describing: Int(line) ?? -1)) { score += 0.05 }

        return min(score, 1.0)
    }

    // Baslik temizleme
    private static func cleanTitle(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Sondaki noktalamalari kaldir
        while cleaned.hasSuffix(".") || cleaned.hasSuffix(":") {
            cleaned = String(cleaned.dropLast())
        }

        // 80 karakterle sinirla
        if cleaned.count > 80 {
            cleaned = String(cleaned.prefix(80)) + "..."
        }

        return cleaned
    }
}
