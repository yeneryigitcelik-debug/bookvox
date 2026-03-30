import SwiftUI
import SwiftData

// MARK: - Kutuphane ekrani

struct LibraryView: View {
    @Binding var deepLinkBook: Book?

    @Environment(\.modelContext) private var context
    @State private var viewModel = LibraryViewModel()
    @State private var showImporter = false
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .recent
    @State private var navigationPath = NavigationPath()

    enum SortOrder: String, CaseIterable {
        case recent = "Son Eklenen"
        case title = "Baslik"
        case author = "Yazar"
        case progress = "Ilerleme"

        var icon: String {
            switch self {
            case .recent: "clock"
            case .title: "textformat.abc"
            case .author: "person"
            case .progress: "chart.bar"
            }
        }
    }

    private var filteredBooks: [Book] {
        var books = viewModel.books

        if !searchText.isEmpty {
            books = books.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOrder {
        case .recent:  books.sort { $0.updatedAt > $1.updatedAt }
        case .title:   books.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .author:  books.sort { $0.author.localizedCaseInsensitiveCompare($1.author) == .orderedAscending }
        case .progress: books.sort { $0.completionPercent > $1.completionPercent }
        }
        return books
    }

    private var continueBook: Book? {
        viewModel.books
            .filter { ($0.readingProgress?.currentPage ?? 0) > 1 && $0.completionPercent < 0.95 }
            .max { ($0.readingProgress?.lastReadAt ?? .distantPast) < ($1.readingProgress?.lastReadAt ?? .distantPast) }
    }

    private let columns = [GridItem(.adaptive(minimum: DS.Layout.gridMinWidth), spacing: DS.Spacing.lg)]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.books.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    bookList
                }
            }
            .navigationTitle("Kutuphane")
            .navigationDestination(for: Book.ID.self) { bookId in
                if let book = viewModel.books.first(where: { $0.id == bookId }) {
                    ReaderView(book: book)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: DS.Spacing.md) {
                        sortMenu
                        Button { showImporter = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Kitap veya yazar ara...")
            .sheet(isPresented: $showImporter) {
                ImportBookView(viewModel: viewModel)
            }
            .overlay { importOverlay }
            .onAppear { viewModel.loadBooks(context: context) }
            .onChange(of: deepLinkBook) { _, book in
                if let book {
                    navigationPath.append(book.id)
                    deepLinkBook = nil
                }
            }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Kutuphane Bos", systemImage: "books.vertical")
        } description: {
            Text("PDF kitaplarini yukleyerek dinlemeye basla")
        } actions: {
            Button("Kitap Yukle") { showImporter = true }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Book list

    private var bookList: some View {
        ScrollView {
            LazyVStack(spacing: DS.Spacing.xxl) {
                // Devam et banner
                if let book = continueBook {
                    continueBanner(book)
                        .padding(.horizontal, DS.Spacing.lg)
                }

                // Favoriler
                let favorites = filteredBooks.filter(\.isFavorite)
                if !favorites.isEmpty && searchText.isEmpty {
                    sectionHeader("Favoriler", icon: "heart.fill", color: .pink)
                    bookGrid(favorites)
                }

                // Tum kitaplar
                sectionHeader(
                    searchText.isEmpty ? "Tum Kitaplar" : "\(filteredBooks.count) sonuc",
                    icon: "books.vertical",
                    color: .bookVoxAccent
                )
                bookGrid(searchText.isEmpty ? filteredBooks.filter { !$0.isFavorite } : filteredBooks)
            }
            .padding(.vertical, DS.Spacing.lg)
        }
    }

    // MARK: - Continue Banner

    private func continueBanner(_ book: Book) -> some View {
        NavigationLink {
            ReaderView(book: book)
        } label: {
            HStack(spacing: DS.Spacing.lg) {
                ZStack {
                    if let data = book.coverImageData, let img = UIImage(data: data) {
                        Image(uiImage: img).resizable().scaledToFill()
                    } else {
                        Color.bookVoxAccent.opacity(0.15)
                        Image(systemName: "book.fill").foregroundStyle(.bookVoxAccent)
                    }
                }
                .frame(width: 52, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))

                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("Dinlemeye Devam Et")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.bookVoxAccent)

                    Text(book.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    HStack(spacing: DS.Spacing.md) {
                        ProgressView(value: book.completionPercent)
                            .tint(.bookVoxAccent)
                            .frame(maxWidth: 100)

                        Text("%\(Int(book.completionPercent * 100))")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.bookVoxAccent)
            }
            .padding(DS.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .fill(.bookVoxAccent.opacity(0.06))
                    .strokeBorder(.bookVoxAccent.opacity(0.12), lineWidth: 1)
            )
        }
        .foregroundStyle(.primary)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon).foregroundStyle(color)
            Text(title).font(.headline)
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.lg)
    }

    private func bookGrid(_ books: [Book]) -> some View {
        LazyVGrid(columns: columns, spacing: DS.Spacing.lg) {
            ForEach(books, id: \.id) { book in
                NavigationLink { ReaderView(book: book) } label: {
                    BookCardView(book: book)
                }
                .contextMenu {
                    Button {
                        book.isFavorite.toggle()
                        try? context.save()
                    } label: {
                        Label(
                            book.isFavorite ? "Favorilerden Cikar" : "Favorilere Ekle",
                            systemImage: book.isFavorite ? "heart.slash" : "heart"
                        )
                    }
                    Button(role: .destructive) {
                        withAnimation { viewModel.deleteBook(book, context: context) }
                    } label: {
                        Label("Sil", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal, DS.Spacing.lg)
    }

    private var sortMenu: some View {
        Menu {
            ForEach(SortOrder.allCases, id: \.self) { order in
                Button {
                    withAnimation(DS.Anim.smooth) { sortOrder = order }
                } label: {
                    Label(order.rawValue, systemImage: sortOrder == order ? "checkmark" : order.icon)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }

    @ViewBuilder
    private var importOverlay: some View {
        if viewModel.isLoading, let progress = viewModel.importProgress {
            ZStack {
                Color.black.opacity(0.25).ignoresSafeArea()

                VStack(spacing: DS.Spacing.lg) {
                    ProgressView(value: progress.percent)
                        .tint(.bookVoxAccent)

                    Text(progress.step.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)

                    Text("%\(Int(progress.percent * 100))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .frame(width: 240)
                .padding(DS.Spacing.xxl)
                .background(.ultraThickMaterial)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
                .shadow(radius: 30)
            }
            .transition(.opacity)
            .animation(DS.Anim.smooth, value: viewModel.isLoading)
        }
    }
}

#Preview {
    LibraryView(deepLinkBook: .constant(nil))
        .modelContainer(for: [Book.self, Collection.self], inMemory: true)
}
