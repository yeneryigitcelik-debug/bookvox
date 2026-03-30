import Foundation

// MARK: - PDF metin temizleyici
// PDFKit'ten gelen ham metni okunabilir hale getirir

enum TextCleaner {

    // Ana temizleme fonksiyonu
    static func clean(_ text: String) -> String {
        var result = text

        // Fazla bosluk ve satir sonlarini normalize et
        result = result.replacingOccurrences(
            of: "\\s*\\n\\s*\\n\\s*",
            with: "\n\n",
            options: .regularExpression
        )

        // Satir sonu tireleri birlestir (heceleme)
        result = result.replacingOccurrences(
            of: "-\\s*\\n\\s*",
            with: "",
            options: .regularExpression
        )

        // Tek satir sonlarini bosluklara cevir (paragraf icinde)
        result = result.replacingOccurrences(
            of: "(?<!\\n)\\n(?!\\n)",
            with: " ",
            options: .regularExpression
        )

        // Coklu bosluklari tek bosluga indir
        result = result.replacingOccurrences(
            of: " {2,}",
            with: " ",
            options: .regularExpression
        )

        // Bas ve son bosluklari temizle
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        return result
    }

    // Sayfa ustbilgi/altbilgi temizleme (sayfa numaralari vb.)
    static func removeHeaders(_ text: String, pageNumber: Int) -> String {
        var result = text

        // Baslangic ve sondaki sayfa numaralarini kaldir
        let pageStr = String(pageNumber)
        if result.hasPrefix(pageStr) {
            result = String(result.dropFirst(pageStr.count))
        }
        if result.hasSuffix(pageStr) {
            result = String(result.dropLast(pageStr.count))
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
