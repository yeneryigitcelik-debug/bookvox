import AppIntents

// MARK: - Siri Shortcuts

struct ResumePlaybackIntent: AppIntent {
    static var title: LocalizedStringResource = "Dinlemeye Devam Et"
    static var description: IntentDescription = "Son kitabinizdan kaldığınız yerden dinlemeye devam edin"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        await MainActor.run {
            NotificationCenter.default.post(name: .resumePlaybackFromIntent, object: nil)
        }
        return .result(value: "Dinlemeye devam ediliyor")
    }
}

extension Notification.Name {
    static let resumePlaybackFromIntent = Notification.Name("resumePlaybackFromIntent")
}

// MARK: - Sleep Timer

enum SleepDuration: String, AppEnum {
    case min5 = "5"
    case min15 = "15"
    case min30 = "30"
    case min60 = "60"
    case min90 = "90"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Sure"
    static var caseDisplayRepresentations: [SleepDuration: DisplayRepresentation] = [
        .min5: "5 dakika",
        .min15: "15 dakika",
        .min30: "30 dakika",
        .min60: "1 saat",
        .min90: "1.5 saat"
    ]

    var preset: SleepTimerService.Preset {
        switch self {
        case .min5: .minutes5
        case .min15: .minutes15
        case .min30: .minutes30
        case .min60: .minutes60
        case .min90: .minutes90
        }
    }
}

struct StartSleepTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Uyku Zamanlayicisi Baslat"
    static var description: IntentDescription = "Belirli bir sure sonra oynatmayi durdurur"

    @Parameter(title: "Sure")
    var duration: SleepDuration

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        await MainActor.run {
            SleepTimerService.shared.start(preset: duration.preset)
        }
        return .result(value: "\(duration.rawValue) dakika uyku zamanlayicisi baslatildi")
    }
}

// MARK: - Speed

enum PlaybackSpeed: String, AppEnum {
    case slow = "0.75"
    case normal = "1.0"
    case fast = "1.5"
    case double = "2.0"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Hiz"
    static var caseDisplayRepresentations: [PlaybackSpeed: DisplayRepresentation] = [
        .slow: "0.75x Yavas",
        .normal: "1x Normal",
        .fast: "1.5x Hizli",
        .double: "2x Cift"
    ]

    var value: Float {
        Float(rawValue) ?? 1.0
    }
}

struct ChangeSpeedIntent: AppIntent {
    static var title: LocalizedStringResource = "Oynatma Hizini Degistir"
    static var description: IntentDescription = "Ses oynatma hizini ayarlayin"

    @Parameter(title: "Hiz")
    var speed: PlaybackSpeed

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        await MainActor.run {
            AudioService.shared.playbackSpeed = speed.value
        }
        return .result(value: "Hiz \(speed.rawValue)x olarak ayarlandi")
    }
}

// MARK: - Shortcuts Provider

struct BookVoxShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ResumePlaybackIntent(),
            phrases: [
                "Dinlemeye devam et \(.applicationName)",
                "\(.applicationName) oynat"
            ],
            shortTitle: "Dinlemeye Devam Et",
            systemImageName: "play.circle"
        )

        AppShortcut(
            intent: StartSleepTimerIntent(),
            phrases: [
                "\(.applicationName) uyku zamanlayicisi baslat"
            ],
            shortTitle: "Uyku Zamanlayicisi",
            systemImageName: "moon.zzz"
        )

        AppShortcut(
            intent: ChangeSpeedIntent(),
            phrases: [
                "\(.applicationName) hizini degistir"
            ],
            shortTitle: "Hiz Degistir",
            systemImageName: "gauge"
        )
    }
}
