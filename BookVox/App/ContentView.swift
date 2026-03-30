import SwiftUI
import SwiftData

// MARK: - Root navigation

struct ContentView: View {
    @Binding var deepLinkBookId: UUID?

    @State private var selectedTab = 0
    @State private var authVM = AuthViewModel()
    @State private var showOnboarding = false
    @State private var deepLinkBook: Book?

    @Query private var preferences: [UserPreferences]
    @Query private var books: [Book]
    @Environment(\.modelContext) private var context

    private var userPrefs: UserPreferences { preferences.first ?? UserPreferences() }

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                mainTabView
            } else {
                LoginView(authVM: authVM)
                    .transition(.opacity)
            }
        }
        .animation(DS.Anim.smooth, value: authVM.isAuthenticated)
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .interactiveDismissDisabled()
        }
        .onAppear { ensurePreferences() }
        .onChange(of: authVM.isAuthenticated) { _, isAuth in
            if isAuth && !userPrefs.hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .onChange(of: deepLinkBookId) { _, bookId in
            handleDeepLink(bookId)
        }
        .overlay(alignment: .top) { offlineBanner }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            LibraryView(deepLinkBook: $deepLinkBook)
                .tabItem { Label("Kutuphane", systemImage: "books.vertical") }
                .tag(0)

            NavigationStack { CollectionGridView() }
                .tabItem { Label("Koleksiyonlar", systemImage: "folder") }
                .tag(1)

            StatsView()
                .tabItem { Label("Istatistikler", systemImage: "chart.bar") }
                .tag(2)

            SettingsView(authVM: authVM)
                .tabItem { Label("Ayarlar", systemImage: "gearshape") }
                .tag(3)
        }
        .tint(.accent)
    }

    @ViewBuilder
    private var offlineBanner: some View {
        if !NetworkMonitor.shared.isConnected {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "wifi.slash")
                Text("Cevrimdisi")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.sm)
            .background(.red.gradient, in: Capsule())
            .padding(.top, DS.Spacing.xs)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(DS.Anim.spring, value: NetworkMonitor.shared.isConnected)
        }
    }

    private func ensurePreferences() {
        if preferences.isEmpty {
            context.insert(UserPreferences())
            try? context.save()
        }
    }

    private func handleDeepLink(_ bookId: UUID?) {
        guard let bookId else { return }
        if let book = books.first(where: { $0.id == bookId }) {
            selectedTab = 0
            deepLinkBook = book
        }
        deepLinkBookId = nil
    }
}

#Preview {
    ContentView(deepLinkBookId: .constant(nil))
        .modelContainer(for: [
            Book.self, Page.self, ReadingProgress.self,
            Bookmark.self, Collection.self, ReadingStreak.self,
            UserPreferences.self, AudioChapter.self
        ], inMemory: true)
}
