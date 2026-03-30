import Foundation

// MARK: - Ses oynatici view model
// Audio playback, ton secimi, prefetch, context analysis, sleep timer ve hiz kontrolu

@Observable
final class PlayerViewModel {
    var book: Book?
    var currentPage: Int = 1
    var selectedTone: TTSService.Tone = .standard
    var isRendering = false
    var errorMessage: String?

    // Context analysis sonucu (mood badge icin)
    var currentMood: ContextAnalysisService.Mood?

    private let audioService = AudioService.shared
    private var audioFinishObserver: Any?
    private var audioErrorObserver: Any?

    // AudioService state proxy
    var isPlaying: Bool { audioService.isPlaying }
    var currentTime: Double { audioService.currentTime }
    var duration: Double { audioService.duration }

    init() {
        audioFinishObserver = NotificationCenter.default.addObserver(
            forName: .audioDidFinishPlaying,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handlePageFinished()
            }
        }

        audioErrorObserver = NotificationCenter.default.addObserver(
            forName: .audioDecodeError,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                let error = notification.userInfo?["error"] as? String
                self?.errorMessage = error ?? "Audio decode hatasi"
            }
        }
    }

    deinit {
        if let observer = audioFinishObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = audioErrorObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // Kitabi yukle ve oynatmaya hazirla
    func loadBook(_ book: Book) {
        self.book = book
        self.currentPage = book.readingProgress?.currentPage ?? 1
        buildPageIndex()

        audioService.nowPlayingTitle = book.title
        audioService.nowPlayingAuthor = book.author
        audioService.nowPlayingCoverData = book.coverImageData

        if let lastTone = book.lastPlayedTone,
           let tone = TTSService.Tone(rawValue: lastTone) {
            selectedTone = tone
        }

        // Ilk sayfa context analysis
        analyzeCurrentPage()
    }

    // Mevcut sayfayi oynat
    func play() async {
        guard let page = currentPageData else { return }

        if let audioURL = page.audioURL {
            await playAudio(urlString: audioURL)
        } else {
            await renderAndPlay(page: page)
        }

        // Lock screen guncelle
        audioService.nowPlayingPage = "Sayfa \(currentPage)"

        // 2 sayfa ileriyi prefetch et
        await prefetchUpcoming()
    }

    func togglePlayPause() async {
        if isPlaying {
            audioService.pause()
        } else if duration > 0 {
            audioService.resume()
        } else {
            await play()
        }
        HapticService.playPause()
    }

    func pause() {
        audioService.pause()
    }

    func skipForward() {
        audioService.skipForward()
    }

    func skipBackward() {
        audioService.skipBackward()
    }

    func seek(to time: Double) {
        audioService.seek(to: time)
    }

    // Sonraki sayfaya gec
    func nextPage() async {
        guard let book, currentPage < book.totalPages else { return }
        audioService.stop()
        currentPage += 1
        updateProgress()
        analyzeCurrentPage()
        HapticService.pageFlip()
        await play()
    }

    // Onceki sayfaya gec
    func previousPage() async {
        guard currentPage > 1 else { return }
        audioService.stop()
        currentPage -= 1
        updateProgress()
        analyzeCurrentPage()
        HapticService.pageFlip()
        await play()
    }

    // Ton degistir — mevcut sayfayi yeniden renderla
    func changeTone(to tone: TTSService.Tone) async {
        selectedTone = tone
        book?.lastPlayedTone = tone.rawValue
        HapticService.toneChanged()

        audioService.stop()
        if let page = currentPageData {
            page.audioURL = nil
            await renderAndPlay(page: page)
        }
    }

    // MARK: - Context Analysis

    private func analyzeCurrentPage() {
        guard let page = currentPageData else {
            currentMood = nil
            return
        }

        // Onceden hesaplanmissa cache'ten oku
        if let existing = page.contextAnalysis,
           let cached = ContextAnalysisService.decodeFromJSON(existing) {
            currentMood = cached.mood
            return
        }

        // Ilk kez hesapla ve kaydet
        let context = ContextAnalysisService.analyze(text: page.textContent)
        currentMood = context.mood
        page.contextAnalysis = ContextAnalysisService.encodeToJSON(context)
    }

    // MARK: - Progress Tracking

    private func updateProgress() {
        guard let book else { return }
        book.readingProgress?.currentPage = currentPage
        book.readingProgress?.currentPositionSec = currentTime
        book.readingProgress?.lastReadAt = Date()
        book.updatedAt = Date()
    }

    // Dinleme suresi guncelle
    func updateListeningTime(seconds: Double) {
        book?.totalListenedSec += seconds
    }

    // MARK: - Private

    // O(1) sayfa erisimi icin index
    private var pageIndex: [Int: Page] = [:]

    private func buildPageIndex() {
        guard let book else { return }
        pageIndex = Dictionary(uniqueKeysWithValues: book.pages.map { ($0.pageNumber, $0) })
    }

    private var currentPageData: Page? {
        pageIndex[currentPage]
    }

    private func playAudio(urlString: String) async {
        do {
            let localURL = try await StorageService.shared.getAudioFile(for: urlString)
            try await audioService.play(url: localURL)
        } catch {
            errorMessage = "Ses oynatilamadi: \(error.localizedDescription)"
            HapticService.error()
        }
    }

    private func renderAndPlay(page: Page) async {
        guard let bookId = book?.supabaseId else {
            errorMessage = "Kitap henuz senkronize edilmedi"
            return
        }

        isRendering = true
        errorMessage = nil

        do {
            let result = try await TTSService.renderPage(
                bookId: bookId,
                pageNumber: page.pageNumber,
                tone: selectedTone,
                textContent: page.textContent
            )
            page.audioURL = result.audioURL
            page.audioDuration = result.durationSec
            await playAudio(urlString: result.audioURL)
        } catch {
            errorMessage = "TTS render hatasi: \(error.localizedDescription)"
            HapticService.error()
        }
        isRendering = false
    }

    private func prefetchUpcoming() async {
        guard let book, let bookId = book.supabaseId else { return }

        let upcoming = (currentPage + 1)...min(currentPage + Constants.TTS.prefetchPageCount, book.totalPages)
        let pagesToRender = upcoming.filter { pageIndex[$0]?.audioURL == nil }

        guard !pagesToRender.isEmpty else { return }

        do {
            let response = try await TTSService.renderBatch(
                bookId: bookId,
                pages: Array(pagesToRender),
                tone: selectedTone
            )
            for result in response.results {
                if let page = pageIndex[result.page] {
                    page.audioURL = result.audioURL
                    page.audioDuration = result.durationSec
                }
            }
        } catch {
            // Prefetch hatasi kritik degil
        }
    }

    private func handlePageFinished() {
        // Dinleme suresini guncelle
        updateListeningTime(seconds: duration)

        // Sleep timer — bolum sonu modu kontrolu
        let sleepTimer = SleepTimerService.shared
        if sleepTimer.isActive && sleepTimer.selectedPreset == .endOfChapter {
            // Bolum sonunda dur
            if let book, let chapter = book.chapters.first(where: { $0.pageRange.contains(currentPage) }),
               currentPage == chapter.endPage {
                sleepTimer.stop()
                HapticService.timerWarning()
                return
            }
        }

        // Otomatik sonraki sayfa
        Task {
            await nextPage()
        }
    }
}
