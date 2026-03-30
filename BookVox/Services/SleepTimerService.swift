import Foundation

// MARK: - Uyku zamanlayicisi servisi
// Belirli bir sure sonra oynatmayi durdurur

@Observable
final class SleepTimerService {
    static let shared = SleepTimerService()

    private var timer: Timer?
    private var fadeTimer: Timer?

    private(set) var isActive = false
    private(set) var remainingSeconds: TimeInterval = 0
    private(set) var selectedPreset: Preset?

    // Zamanlayici secenekleri
    enum Preset: CaseIterable, Identifiable {
        case minutes5
        case minutes15
        case minutes30
        case minutes45
        case minutes60
        case minutes90
        case endOfChapter

        var id: String { displayName }

        var seconds: TimeInterval {
            switch self {
            case .minutes5: 5 * 60
            case .minutes15: 15 * 60
            case .minutes30: 30 * 60
            case .minutes45: 45 * 60
            case .minutes60: 60 * 60
            case .minutes90: 90 * 60
            case .endOfChapter: 0  // Ozel islem
            }
        }

        var displayName: String {
            switch self {
            case .minutes5: "5 dk"
            case .minutes15: "15 dk"
            case .minutes30: "30 dk"
            case .minutes45: "45 dk"
            case .minutes60: "1 saat"
            case .minutes90: "1.5 saat"
            case .endOfChapter: "Bolum sonu"
            }
        }

        var icon: String {
            switch self {
            case .minutes5, .minutes15: "moon"
            case .minutes30, .minutes45: "moon.zzz"
            case .minutes60, .minutes90: "moon.stars"
            case .endOfChapter: "text.book.closed"
            }
        }
    }

    private init() {}

    // Zamanlayici baslat
    func start(preset: Preset) {
        stop()

        selectedPreset = preset
        guard preset != .endOfChapter else {
            // Bolum sonu modu — AudioService sayfa bittiginde kontrol edecek
            isActive = true
            return
        }

        remainingSeconds = preset.seconds
        isActive = true

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }

                self.remainingSeconds -= 1

                if self.remainingSeconds == 30 {
                    self.beginFadeOut()
                }

                if self.remainingSeconds <= 0 {
                    self.timerFired()
                }
            }
        }

        // Bildirim zamanlayicisi
        NotificationService.scheduleSleepTimerWarning(afterSeconds: preset.seconds)
    }

    // 5 dakika ekle
    func addFiveMinutes() {
        remainingSeconds += 5 * 60
        HapticService.sliderTick()
    }

    // Zamanlayici durdur
    func stop() {
        timer?.invalidate()
        timer = nil
        fadeTimer?.invalidate()
        fadeTimer = nil
        isActive = false
        remainingSeconds = 0
        selectedPreset = nil
    }

    // Formatted kalan sure
    var formattedRemaining: String {
        if selectedPreset == .endOfChapter {
            return "Bolum sonu"
        }
        return remainingSeconds.mmss
    }

    // MARK: - Private

    private func timerFired() {
        HapticService.timerWarning()
        AudioService.shared.pause()
        stop()
        NotificationCenter.default.post(name: .sleepTimerFired, object: nil)
    }

    private func beginFadeOut() {
        // Fade-out zaten basladiysa tekrar baslatma
        guard fadeTimer == nil else { return }
        // Fade-out mantigi PlayerViewModel'de handle edilecek
        NotificationCenter.default.post(name: .sleepTimerFadeOut, object: nil)
    }
}

extension Notification.Name {
    static let sleepTimerFired = Notification.Name("sleepTimerFired")
    static let sleepTimerFadeOut = Notification.Name("sleepTimerFadeOut")
}
