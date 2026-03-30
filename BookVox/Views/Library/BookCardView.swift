import SwiftUI

// MARK: - Kitap karti

struct BookCardView: View {
    let book: Book
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            // Kapak
            ZStack(alignment: .topTrailing) {
                coverImage
                    .frame(minHeight: DS.Layout.coverMinHeight, maxHeight: DS.Layout.coverMaxHeight)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                    .shadow(color: DS.cardShadow.color, radius: DS.cardShadow.radius, y: DS.cardShadow.y)

                // Badges
                VStack(alignment: .trailing, spacing: DS.Spacing.xs) {
                    if book.isFavorite {
                        PillBadge("", icon: "heart.fill", color: .pink)
                    }

                    let audioCount = book.pages.filter { $0.audioURL != nil }.count
                    if audioCount > 0 {
                        PillBadge("\(audioCount)", icon: "headphones", color: .bookVoxAccent.opacity(0.9))
                    }
                }
                .padding(DS.Spacing.sm)
            }

            // Bilgi
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(book.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                Text(book.author)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Ilerleme
            if book.completionPercent > 0 {
                HStack(spacing: DS.Spacing.sm) {
                    ProgressView(value: book.completionPercent)
                        .tint(.bookVoxAccent)

                    Text("%\(Int(book.completionPercent * 100))")
                        .font(.caption2.monospacedDigit().weight(.medium))
                        .foregroundStyle(.tertiary)
                }
            }

            // Dinleme suresi
            if book.totalListenedSec > 60 {
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "headphones")
                    Text(book.formattedListenTime)
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(DS.Anim.spring.delay(Double.random(in: 0...0.15))) {
                appeared = true
            }
        }
    }

    @ViewBuilder
    private var coverImage: some View {
        if let imageData = book.coverImageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [.bookVoxAccent.opacity(0.7), .bookVoxAccent.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: DS.Spacing.md) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.85))

                    Text(book.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, DS.Spacing.md)
                }
            }
        }
    }
}

#Preview {
    HStack(spacing: DS.Spacing.lg) {
        BookCardView(book: Book(title: "Ornek Kitap", author: "Yazar", totalPages: 120, pdfStoragePath: ""))
            .frame(width: 180)
        BookCardView(book: {
            let b = Book(title: "Uzun Baslikli Kitap Adi Buraya", author: "Yazar Adi", totalPages: 50, pdfStoragePath: "")
            b.isFavorite = true
            return b
        }())
        .frame(width: 180)
    }
    .padding()
}
