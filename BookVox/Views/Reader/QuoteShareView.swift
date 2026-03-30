import SwiftUI

// MARK: - Alinti paylasim ekrani
// Secilen metni gorsel olarak paylas

struct QuoteShareView: View {
    let quote: String
    let bookTitle: String
    let author: String
    let pageNumber: Int

    @Environment(\.dismiss) private var dismiss
    @State private var selectedStyle: QuoteStyle = .gradient

    enum QuoteStyle: String, CaseIterable, Identifiable {
        case gradient
        case minimal
        case dark
        case paper

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .gradient: "Gradient"
            case .minimal: "Minimal"
            case .dark: "Koyu"
            case .paper: "Kagit"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Alinti karti onizleme
                quoteCard
                    .padding(.horizontal)

                // Stil secimi
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(QuoteStyle.allCases) { style in
                            Button {
                                selectedStyle = style
                                HapticService.sliderTick()
                            } label: {
                                Text(style.displayName)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedStyle == style ? Color.accentColor : Color(.tertiarySystemFill))
                                    .foregroundStyle(selectedStyle == style ? Color.white : Color.primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // Paylas butonu
                ShareLink(item: shareText, preview: SharePreview(bookTitle)) {
                    Label("Paylas", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // Kopyala butonu
                Button {
                    UIPasteboard.general.string = shareText
                    HapticService.importComplete()
                } label: {
                    Label("Metni Kopyala", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.fill.tertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("Alintiyi Paylas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private var shareText: String {
        "\"\(quote)\"\n\n— \(author), \(bookTitle) (s. \(pageNumber))\n\n#BookVox"
    }

    @ViewBuilder
    private var quoteCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "quote.opening")
                .font(.title)
                .foregroundStyle(quoteAccentColor)

            Text(quote)
                .font(.body.italic())
                .foregroundStyle(quoteTextColor)
                .lineSpacing(6)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(bookTitle)
                        .font(.caption.bold())
                    Text(author)
                        .font(.caption)
                }
                .foregroundStyle(quoteSecondaryColor)

                Spacer()

                Text("s. \(pageNumber)")
                    .font(.caption2)
                    .foregroundStyle(quoteSecondaryColor)
            }
        }
        .padding(24)
        .background(quoteBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var quoteBackground: some View {
        switch selectedStyle {
        case .gradient:
            LinearGradient(
                colors: [.accent.opacity(0.15), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .minimal:
            Color(.systemBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.accent.opacity(0.3), lineWidth: 1)
                )
        case .dark:
            Color.black
        case .paper:
            Color(.systemGray6)
        }
    }

    private var quoteTextColor: Color {
        selectedStyle == .dark ? .white : .primary
    }

    private var quoteAccentColor: Color {
        selectedStyle == .dark ? .accent.opacity(0.8) : .accent
    }

    private var quoteSecondaryColor: Color {
        selectedStyle == .dark ? .white.opacity(0.6) : .secondary
    }
}

#Preview {
    QuoteShareView(
        quote: "Hayat, ya cesur bir macera ya da hictir.",
        bookTitle: "Hayat Dersleri",
        author: "Helen Keller",
        pageNumber: 42
    )
}
