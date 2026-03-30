import Foundation

// MARK: - Sayfa baglam analizi servisi
// Metin iceriginden duygu, karakter ve sahne bilgisi cikarir
// TTS tonunu otomatik ayarlamak icin kullanilir

struct ContextAnalysisService {

    // Sayfa analiz sonucu
    struct PageContext: Codable {
        let mood: Mood
        let intensity: Double         // 0.0 - 1.0 (sakin → yogun)
        let hasDialogue: Bool
        let dialogueRatio: Double     // Diyalog yuzde orani
        let estimatedReadTime: Double // Tahmini okuma suresi (dakika)
        let wordCount: Int
        let suggestedTone: String     // TTS ton onerisi
        let keywords: [String]        // Anahtar kelimeler
    }

    // Duygu durumlari
    enum Mood: String, Codable, CaseIterable {
        case neutral    // Tarafsiz, bilgilendirici
        case happy      // Mutlu, neseli
        case sad        // Huzunlu, melankolik
        case tense      // Gergin, gerilimli
        case romantic   // Romantik, duygusal
        case dark       // Karanlik, korkutucu
        case action     // Aksiyonlu, hizli
        case reflective // Dusunceli, felsefi

        var suggestedTone: String {
            switch self {
            case .neutral: "standard"
            case .happy: "storyteller"
            case .sad: "intimate"
            case .tense: "dramatic"
            case .romantic: "intimate"
            case .dark: "dramatic"
            case .action: "dramatic"
            case .reflective: "academic"
            }
        }

        var emoji: String {
            switch self {
            case .neutral: "😐"
            case .happy: "😊"
            case .sad: "😢"
            case .tense: "😰"
            case .romantic: "❤️"
            case .dark: "🌑"
            case .action: "⚡"
            case .reflective: "🤔"
            }
        }

        var color: String {
            switch self {
            case .neutral: "#8E8E93"
            case .happy: "#FFD60A"
            case .sad: "#5AC8FA"
            case .tense: "#FF3B30"
            case .romantic: "#FF2D55"
            case .dark: "#1C1C1E"
            case .action: "#FF9500"
            case .reflective: "#AF52DE"
            }
        }
    }

    // Duygu tespit kelime listeleri
    private static let moodKeywords: [Mood: Set<String>] = [
        .happy: ["gulumsedi", "kahkaha", "mutlu", "neseli", "sevindi", "guzel", "harika",
                 "smiled", "laughed", "happy", "joy", "wonderful", "beautiful", "delight"],
        .sad: ["agladi", "gozyasi", "huzun", "uzgun", "kayip", "olum", "yalniz",
               "cried", "tears", "sad", "grief", "loss", "death", "lonely", "sorrow"],
        .tense: ["tehlike", "kacti", "silah", "korku", "titiredi", "panik", "bagirdi",
                 "danger", "ran", "gun", "fear", "trembled", "panic", "screamed"],
        .romantic: ["opustu", "sevgi", "ask", "kalp", "dokundu", "sarild", "guzel",
                    "kissed", "love", "heart", "touched", "embraced", "passion"],
        .dark: ["karanlik", "gece", "olum", "kan", "hayalet", "lanet", "korku",
                "dark", "night", "death", "blood", "ghost", "curse", "shadow"],
        .action: ["kacti", "savasti", "patladi", "hizla", "vurdu", "zipladı",
                  "ran", "fought", "exploded", "quickly", "hit", "jumped", "chase"],
        .reflective: ["dusundu", "merak", "neden", "hayat", "anlam", "zaman",
                      "thought", "wondered", "why", "life", "meaning", "time", "perhaps"]
    ]

    // Diyalog tespit desenleri — onceden derlenmis regex'ler
    private static let compiledDialoguePatterns: [NSRegularExpression] = {
        let patterns = [
            "\"[^\"]+\"",
            "\u{201C}[^\u{201D}]+\u{201D}",
            "—[^—]+—",
            "«[^»]+»"
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    // Sayfa icerigini analiz et
    static func analyze(text: String) -> PageContext {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let wordCount = words.count
        let lowercasedText = text.lowercased()

        // Duygu tespiti
        var moodScores: [Mood: Int] = [:]
        for (mood, keywords) in moodKeywords {
            let score = keywords.reduce(0) { total, keyword in
                total + (lowercasedText.contains(keyword) ? 1 : 0)
            }
            if score > 0 {
                moodScores[mood] = score
            }
        }

        let detectedMood = moodScores.max(by: { $0.value < $1.value })?.key ?? .neutral

        // Duygu yogunlugu
        let maxScore = moodScores.values.max() ?? 0
        let intensity = min(Double(maxScore) / 5.0, 1.0)

        // Diyalog tespiti
        var dialogueCharCount = 0
        let textRange = NSRange(text.startIndex..., in: text)
        for regex in compiledDialoguePatterns {
            let matches = regex.matches(in: text, range: textRange)
            for match in matches {
                dialogueCharCount += match.range.length
            }
        }
        let dialogueRatio = text.isEmpty ? 0 : Double(dialogueCharCount) / Double(text.count)
        let hasDialogue = dialogueRatio > 0.1

        // Okuma suresi tahmini (ortalama 200 kelime/dakika)
        let estimatedReadTime = Double(wordCount) / 200.0

        // Anahtar kelime cikarma (en sik gecen 3+ harfli kelimeler)
        let significantWords = words
            .map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count >= 4 }

        var frequency: [String: Int] = [:]
        for word in significantWords {
            frequency[word, default: 0] += 1
        }
        let keywords = frequency
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map(\.key)

        return PageContext(
            mood: detectedMood,
            intensity: intensity,
            hasDialogue: hasDialogue,
            dialogueRatio: dialogueRatio,
            estimatedReadTime: estimatedReadTime,
            wordCount: wordCount,
            suggestedTone: detectedMood.suggestedTone,
            keywords: keywords
        )
    }

    // JSON olarak encode et (Page.contextAnalysis icin)
    static func encodeToJSON(_ context: PageContext) -> String? {
        guard let data = try? JSONEncoder().encode(context),
              let json = String(data: data, encoding: .utf8)
        else { return nil }
        return json
    }

    // JSON'dan decode et
    static func decodeFromJSON(_ json: String) -> PageContext? {
        guard let data = json.data(using: .utf8),
              let context = try? JSONDecoder().decode(PageContext.self, from: data)
        else { return nil }
        return context
    }
}
