import SwiftUI

// MARK: - Tema renkleri ve dinamik gradientler

// ShapeStyle extension — .fill(.accent), .fill(.bookVoxAccent) gibi kullanim icin
extension ShapeStyle where Self == Color {
    static var accent: Color { Color.accentColor }
    static var bookVoxAccent: Color { .indigo }
    static var bookVoxBackground: Color { Color(.systemGroupedBackground) }
    static var bookVoxCard: Color { Color(.secondarySystemGroupedBackground) }
}

extension Color {
    static let bookVoxAccent = Color.indigo
    static let bookVoxBackground = Color(.systemGroupedBackground)
    static let bookVoxCard = Color(.secondarySystemGroupedBackground)

    // Ton renkleri
    static func toneColor(for tone: TTSService.Tone) -> Color {
        switch tone {
        case .standard: .blue
        case .storyteller: .purple
        case .academic: .green
        case .intimate: .pink
        case .dramatic: .orange
        }
    }

    // Mood gradient — player arka plani icin
    static func moodGradient(for mood: ContextAnalysisService.Mood?) -> [Color] {
        guard let mood else {
            return [.bookVoxAccent.opacity(0.08), .clear]
        }
        switch mood {
        case .neutral:    return [Color.gray.opacity(0.08), .clear]
        case .happy:      return [Color.yellow.opacity(0.08), Color.orange.opacity(0.04)]
        case .sad:        return [Color.blue.opacity(0.1), Color.cyan.opacity(0.04)]
        case .tense:      return [Color.red.opacity(0.08), Color.orange.opacity(0.04)]
        case .romantic:   return [Color.pink.opacity(0.1), Color.red.opacity(0.04)]
        case .dark:       return [Color.black.opacity(0.15), Color.purple.opacity(0.05)]
        case .action:     return [Color.orange.opacity(0.1), Color.red.opacity(0.05)]
        case .reflective: return [Color.purple.opacity(0.08), Color.blue.opacity(0.04)]
        }
    }

    // Hex'ten color
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Animasyonlu gradient view

struct AnimatedMeshGradient: View {
    let mood: ContextAnalysisService.Mood?

    @State private var animate = false

    var body: some View {
        let colors = Color.moodGradient(for: mood)

        ZStack {
            LinearGradient(
                colors: colors,
                startPoint: animate ? .topLeading : .bottomLeading,
                endPoint: animate ? .bottomTrailing : .topTrailing
            )

            // Hafif noise efekti
            RadialGradient(
                colors: [colors.first?.opacity(0.3) ?? .clear, .clear],
                center: animate ? .topTrailing : .bottomLeading,
                startRadius: 50,
                endRadius: 400
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
        .onChange(of: mood?.rawValue) { _, _ in
            // Mood degistiginde animasyonu sifirla
            animate = false
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
