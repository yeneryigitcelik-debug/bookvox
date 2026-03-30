import SwiftUI

// MARK: - Bookmark listesi
// Kitaba ait yer imlerini listeler

struct BookmarkListView: View {
    let bookmarks: [Bookmark]
    let onSelect: (Int) -> Void
    let onDelete: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    private var sortedBookmarks: [Bookmark] {
        bookmarks.sorted { $0.pageNumber < $1.pageNumber }
    }

    var body: some View {
        NavigationStack {
            Group {
                if bookmarks.isEmpty {
                    ContentUnavailableView(
                        "Yer Imi Yok",
                        systemImage: "bookmark",
                        description: Text("Okurken sayfalari isaretleyebilirsin")
                    )
                } else {
                    List {
                        ForEach(sortedBookmarks, id: \.id) { bookmark in
                            Button {
                                onSelect(bookmark.pageNumber)
                            } label: {
                                HStack {
                                    Image(systemName: "bookmark.fill")
                                        .foregroundStyle(.accent)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Sayfa \(bookmark.pageNumber)")
                                            .font(.subheadline.bold())

                                        if let note = bookmark.note, !note.isEmpty {
                                            Text(note)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }

                                        Text(bookmark.createdAt, style: .relative)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    onDelete(bookmark.pageNumber)
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Yer Imleri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    BookmarkListView(
        bookmarks: [
            Bookmark(pageNumber: 5, note: "Onemli kisim"),
            Bookmark(pageNumber: 12),
            Bookmark(pageNumber: 23, note: "Buraya geri don")
        ],
        onSelect: { _ in },
        onDelete: { _ in }
    )
}
