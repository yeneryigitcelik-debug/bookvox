import SwiftUI

// MARK: - Bolum listesi
// Otomatik tespit edilen bolumleri gosterir ve sayfa navigasyonu saglar

struct ChapterListView: View {
    let chapters: [AudioChapter]
    let currentPage: Int
    let totalPages: Int
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    private var sortedChapters: [AudioChapter] {
        chapters.sorted { $0.startPage < $1.startPage }
    }

    var body: some View {
        NavigationStack {
            Group {
                if chapters.isEmpty {
                    ContentUnavailableView(
                        "Bolum Bulunamadi",
                        systemImage: "text.book.closed",
                        description: Text("Bu kitapta otomatik bolum tespiti yapilamadi")
                    )
                } else {
                    List {
                        ForEach(sortedChapters, id: \.id) { chapter in
                            Button {
                                onSelect(chapter.startPage)
                                HapticService.pageFlip()
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    // Bolum durumu
                                    chapterStatusIcon(for: chapter)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(chapter.title)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(isCurrentChapter(chapter) ? .accent : .primary)

                                        HStack(spacing: 8) {
                                            Text("Sayfa \(chapter.startPage)-\(chapter.endPage)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)

                                            Text("\(chapter.pageCount) sayfa")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }

                                    Spacer()

                                    if isCurrentChapter(chapter) {
                                        Text("Suanki")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(.accent.opacity(0.15))
                                            .foregroundStyle(.accent)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bolumler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private func isCurrentChapter(_ chapter: AudioChapter) -> Bool {
        chapter.pageRange.contains(currentPage)
    }

    @ViewBuilder
    private func chapterStatusIcon(for chapter: AudioChapter) -> some View {
        if currentPage > chapter.endPage {
            // Tamamlanmis
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else if isCurrentChapter(chapter) {
            // Suanki
            Image(systemName: "book.circle.fill")
                .foregroundStyle(.accent)
        } else {
            // Henuz baslanmamis
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ChapterListView(
        chapters: [
            AudioChapter(title: "Giris", startPage: 1, endPage: 15),
            AudioChapter(title: "Bolum 1: Baslangic", startPage: 16, endPage: 45),
            AudioChapter(title: "Bolum 2: Yolculuk", startPage: 46, endPage: 80)
        ],
        currentPage: 20,
        totalPages: 80,
        onSelect: { _ in }
    )
}
