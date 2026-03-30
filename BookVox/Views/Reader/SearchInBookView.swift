import SwiftUI

// MARK: - Kitap icinde arama
// Tum sayfalarda metin arar ve sonuclari listeler

struct SearchInBookView: View {
    let pages: [Page]
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private var results: [SearchResult] {
        guard searchText.count >= 2 else { return [] }
        let query = searchText.lowercased()

        return pages.compactMap { page in
            let text = page.textContent.lowercased()
            guard let range = text.range(of: query) else { return nil }

            // Eslesen kismin etrafindaki metni al (context snippet)
            let matchStart = text.distance(from: text.startIndex, to: range.lowerBound)
            let snippetStart = max(0, matchStart - 40)
            let snippetEnd = min(text.count, matchStart + query.count + 60)

            let startIdx = text.index(text.startIndex, offsetBy: snippetStart)
            let endIdx = text.index(text.startIndex, offsetBy: snippetEnd)
            var snippet = String(page.textContent[startIdx..<endIdx])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if snippetStart > 0 { snippet = "..." + snippet }
            if snippetEnd < text.count { snippet += "..." }

            // Kac kez gectigini say
            var count = 0
            var searchRange = text.startIndex..<text.endIndex
            while let found = text.range(of: query, range: searchRange) {
                count += 1
                searchRange = found.upperBound..<text.endIndex
            }

            return SearchResult(
                pageNumber: page.pageNumber,
                snippet: snippet,
                matchCount: count
            )
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Sonuc sayisi
                if !searchText.isEmpty {
                    HStack {
                        let totalMatches = results.reduce(0) { $0 + $1.matchCount }
                        Text("\(totalMatches) sonuc, \(results.count) sayfada")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.fill.quaternary)
                }

                // Sonuc listesi
                if results.isEmpty && searchText.count >= 2 {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(results, id: \.pageNumber) { result in
                        Button {
                            onSelect(result.pageNumber)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Sayfa \(result.pageNumber)")
                                        .font(.subheadline.bold())

                                    Spacer()

                                    if result.matchCount > 1 {
                                        Text("\(result.matchCount)x")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.bookVoxAccent.opacity(0.15))
                                            .foregroundStyle(.bookVoxAccent)
                                            .clipShape(Capsule())
                                    }
                                }

                                Text(highlightedSnippet(result.snippet))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Kitapta Ara")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, isPresented: .constant(true), prompt: "Metin ara...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    // Eslesen metni vurgula (AttributedString)
    private func highlightedSnippet(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        guard !searchText.isEmpty else { return attributed }

        let lowerText = text.lowercased()
        let lowerQuery = searchText.lowercased()
        var searchStart = lowerText.startIndex

        while let range = lowerText.range(of: lowerQuery, range: searchStart..<lowerText.endIndex) {
            if let attrRange = Range(range, in: attributed) {
                attributed[attrRange].foregroundColor = .bookVoxAccent
                attributed[attrRange].font = .caption.bold()
            }
            searchStart = range.upperBound
        }

        return attributed
    }

    struct SearchResult {
        let pageNumber: Int
        let snippet: String
        let matchCount: Int
    }
}

#Preview {
    SearchInBookView(
        pages: [
            Page(pageNumber: 1, textContent: "Bu bir ornek metin. Kitap icinde arama testi."),
            Page(pageNumber: 2, textContent: "Ikinci sayfa icerigi burada yer aliyor.")
        ],
        onSelect: { _ in }
    )
}
