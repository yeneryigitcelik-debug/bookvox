import SwiftUI

// MARK: - Kitap okuma ekrani

struct ReaderView: View {
    @Environment(\.modelContext) private var context
    @State private var readerVM: ReaderViewModel
    @State private var playerVM = PlayerViewModel()
    @State private var showBookmarks = false
    @State private var showChapters = false
    @State private var showSearch = false
    @State private var showQuoteShare = false
    @State private var selectedQuote = ""

    init(book: Book) {
        _readerVM = State(initialValue: ReaderViewModel(book: book))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sayfa
            ScrollView {
                if let page = readerVM.currentPageContent {
                    PageView(page: page)
                        .padding(.horizontal, DS.Spacing.xl)
                        .padding(.vertical, DS.Spacing.lg)
                        .frame(maxWidth: .infinity)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                        .id(readerVM.currentPage)
                        .contextMenu {
                            Button {
                                selectedQuote = String(page.textContent.prefix(200))
                                showQuoteShare = true
                            } label: {
                                Label("Alintiyi Paylas", systemImage: "quote.bubble")
                            }
                            Button {
                                readerVM.toggleBookmark()
                            } label: {
                                Label(
                                    readerVM.isBookmarked ? "Yer Imini Kaldir" : "Yer Imi Ekle",
                                    systemImage: readerVM.isBookmarked ? "bookmark.slash" : "bookmark"
                                )
                            }
                        }
                } else {
                    ContentUnavailableView("Sayfa Bulunamadi", systemImage: "doc.questionmark")
                        .padding(.top, 80)
                }
            }
            .animation(DS.Anim.smooth, value: readerVM.currentPage)

            Divider()
            MiniPlayerView(playerVM: playerVM)
        }
        .navigationTitle(readerVM.book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass")
                }
                Button { showChapters = true } label: {
                    Image(systemName: "list.number")
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    readerVM.toggleBookmark()
                    HapticService.bookmarkAdded()
                } label: {
                    Image(systemName: readerVM.isBookmarked ? "bookmark.fill" : "bookmark")
                        .contentTransition(.symbolEffect(.replace))
                }
                Button { showBookmarks = true } label: {
                    Image(systemName: "list.bullet.rectangle")
                }
            }

            ToolbarItem(placement: .bottomBar) {
                pageNavigator
            }
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarkListView(
                bookmarks: readerVM.book.bookmarks,
                onSelect: { goToPage($0) ; showBookmarks = false },
                onDelete: { readerVM.removeBookmark(at: $0) }
            )
        }
        .sheet(isPresented: $showChapters) {
            ChapterListView(
                chapters: readerVM.book.chapters,
                currentPage: readerVM.currentPage,
                totalPages: readerVM.book.totalPages,
                onSelect: { goToPage($0) }
            )
        }
        .sheet(isPresented: $showSearch) {
            SearchInBookView(
                pages: readerVM.book.pages,
                onSelect: { goToPage($0) }
            )
        }
        .sheet(isPresented: $showQuoteShare) {
            QuoteShareView(
                quote: selectedQuote,
                bookTitle: readerVM.book.title,
                author: readerVM.book.author,
                pageNumber: readerVM.currentPage
            )
        }
        .onAppear {
            readerVM.setContext(context)
            playerVM.loadBook(readerVM.book)
        }
    }

    // MARK: - Sayfa navigasyonu

    private var pageNavigator: some View {
        HStack {
            Button {
                readerVM.goToPreviousPage()
                syncPlayer()
                HapticService.pageFlip()
            } label: {
                Image(systemName: "chevron.left")
                    .frame(minWidth: DS.minTapSize, minHeight: DS.minTapSize)
            }
            .disabled(!readerVM.hasPreviousPage)

            Spacer()

            VStack(spacing: DS.Spacing.xs) {
                Text("\(readerVM.currentPage) / \(readerVM.book.totalPages)")
                    .font(.caption.weight(.medium).monospacedDigit())
                    .foregroundStyle(.secondary)

                ProgressView(value: readerVM.book.completionPercent)
                    .tint(.accent)
                    .frame(maxWidth: 100)
            }

            Spacer()

            Button {
                readerVM.goToNextPage()
                syncPlayer()
                HapticService.pageFlip()
            } label: {
                Image(systemName: "chevron.right")
                    .frame(minWidth: DS.minTapSize, minHeight: DS.minTapSize)
            }
            .disabled(!readerVM.hasNextPage)
        }
    }

    private func goToPage(_ page: Int) {
        readerVM.goToPage(page)
        syncPlayer()
    }

    private func syncPlayer() {
        playerVM.currentPage = readerVM.currentPage
    }
}

#Preview {
    NavigationStack {
        ReaderView(book: Book(title: "Ornek", author: "Yazar", totalPages: 10, pdfStoragePath: ""))
    }
    .modelContainer(for: [Book.self, AudioChapter.self, UserPreferences.self], inMemory: true)
}
