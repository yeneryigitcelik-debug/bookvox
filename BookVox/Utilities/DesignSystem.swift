import SwiftUI

// MARK: - BookVox Design System
// Tum gorunum sabitleri tek dosyada — tutarli estetik icin

enum DS {

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Corner Radius
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 999
    }

    // MARK: - Shadows
    static let cardShadow = ShadowStyle(color: .black.opacity(0.08), radius: 8, y: 4)
    static let elevatedShadow = ShadowStyle(color: .black.opacity(0.12), radius: 16, y: 8)

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let y: CGFloat
    }

    // MARK: - Tap Targets (Apple HIG)
    static let minTapSize: CGFloat = 44

    // MARK: - Animation
    enum Anim {
        static let quick: Animation = .easeOut(duration: 0.2)
        static let smooth: Animation = .easeInOut(duration: 0.3)
        static let spring: Animation = .spring(response: 0.35, dampingFraction: 0.7)
        static let springBounce: Animation = .spring(response: 0.4, dampingFraction: 0.6)
        static let slow: Animation = .easeInOut(duration: 0.5)
    }

    // MARK: - Typography
    enum Font {
        static let readerDefault: CGFloat = 18
        static let readerMin: CGFloat = 14
        static let readerMax: CGFloat = 28
        static let lineSpacingDefault: CGFloat = 6
    }

    // MARK: - Layout
    enum Layout {
        static let maxReadingWidth: CGFloat = 680
        static let gridMinWidth: CGFloat = 160
        static let coverMinHeight: CGFloat = 180
        static let coverMaxHeight: CGFloat = 240
        static let playButtonSize: CGFloat = 76
    }
}

// MARK: - Reusable View Components

struct BookVoxCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(.fill.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
            .shadow(color: DS.cardShadow.color, radius: DS.cardShadow.radius, y: DS.cardShadow.y)
    }
}

// Accent pill badge (PRO, sayfa sayisi vb.)
struct PillBadge: View {
    let text: String
    let icon: String?
    let color: Color

    init(_ text: String, icon: String? = nil, color: Color = .bookVoxAccent) {
        self.text = text
        self.icon = icon
        self.color = color
    }

    var body: some View {
        HStack(spacing: 3) {
            if let icon {
                Image(systemName: icon)
            }
            Text(text)
        }
        .font(.caption2.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.xs)
        .background(color)
        .clipShape(Capsule())
    }
}

// Hata banner'i
struct ErrorBanner: View {
    let message: String?

    var body: some View {
        if let message, !message.isEmpty {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(DS.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
