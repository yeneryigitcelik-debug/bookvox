import SwiftUI
import SwiftData

// MARK: - Tek sayfa gorunumu

struct PageView: View {
    let page: Page
    @Query private var preferences: [UserPreferences]

    private var fontSize: Double { preferences.first?.readerFontSize ?? DS.Font.readerDefault }
    private var lineSpacing: Double { preferences.first?.readerLineSpacing ?? DS.Font.lineSpacingDefault }

    private var context: ContextAnalysisService.PageContext? {
        guard let json = page.contextAnalysis else { return nil }
        return ContextAnalysisService.decodeFromJSON(json)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            // Ust bilgi
            HStack(spacing: DS.Spacing.sm) {
                if let ctx = context {
                    moodBadge(ctx)
                }
                Spacer()
                Text("Sayfa \(page.pageNumber)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)
            }

            // Metin
            Text(page.textContent)
                .font(.system(size: fontSize, design: .serif))
                .lineSpacing(lineSpacing)
                .textSelection(.enabled)
                .frame(maxWidth: DS.Layout.maxReadingWidth, alignment: .leading)

            // Alt bilgi
            bottomInfo
        }
    }

    private func moodBadge(_ ctx: ContextAnalysisService.PageContext) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            Text(ctx.mood.emoji)
                .font(.caption)
            Text(ctx.mood.rawValue.capitalized)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.xs)
        .background(Color(hexString: ctx.mood.color).opacity(0.12))
        .clipShape(Capsule())
    }

    private var bottomInfo: some View {
        HStack(spacing: DS.Spacing.lg) {
            if page.audioURL != nil {
                Label("Ses hazir", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            if let ctx = context {
                Label("\(ctx.wordCount) kelime", systemImage: "text.word.spacing")
                Label(String(format: "%.1fdk", ctx.estimatedReadTime), systemImage: "clock")
            }

            Spacer()

            if let duration = page.audioDuration {
                Label(TimeInterval(duration).mmss, systemImage: "speaker.wave.2")
            }
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .padding(.top, DS.Spacing.sm)
    }
}

#Preview {
    PageView(page: Page(pageNumber: 1, textContent: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."))
        .padding()
        .modelContainer(for: UserPreferences.self, inMemory: true)
}
