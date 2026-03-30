import Foundation
import SwiftData

// MARK: - Kullanici tercihleri modeli
// Tum uygulama ayarlari SwiftData ile kalici

@Model
final class UserPreferences {
    var id: UUID

    // Oynatma
    var defaultTone: String                // TTSService.Tone raw value
    var playbackSpeed: Double              // 0.5 - 3.0
    var skipForwardInterval: Double        // saniye
    var skipBackwardInterval: Double       // saniye
    var autoPlayNextPage: Bool
    var crossfadeEnabled: Bool
    var crossfadeDuration: Double          // saniye

    // Gorunum
    var readerFontSize: Double             // 14-28
    var readerLineSpacing: Double          // 4-12
    var darkModePreference: DarkMode       // system, light, dark
    var accentColorHex: String

    // Bildirimler
    var dailyReminderEnabled: Bool
    var dailyReminderHour: Int             // 0-23
    var dailyReminderMinute: Int           // 0-59
    var dailyGoalMinutes: Double           // gunluk hedef

    // Genel
    var hasCompletedOnboarding: Bool
    var preferredLanguage: String          // TTS icin

    init() {
        self.id = UUID()
        self.defaultTone = "storyteller"
        self.playbackSpeed = 1.0
        self.skipForwardInterval = 15
        self.skipBackwardInterval = 15
        self.autoPlayNextPage = true
        self.crossfadeEnabled = true
        self.crossfadeDuration = 0.5
        self.readerFontSize = 18
        self.readerLineSpacing = 6
        self.darkModePreference = .system
        self.accentColorHex = "#5856D6"
        self.dailyReminderEnabled = false
        self.dailyReminderHour = 20
        self.dailyReminderMinute = 0
        self.dailyGoalMinutes = 30
        self.hasCompletedOnboarding = false
        self.preferredLanguage = "tr"
    }

    enum DarkMode: String, Codable, CaseIterable {
        case system
        case light
        case dark

        var displayName: String {
            switch self {
            case .system: "Sistem"
            case .light: "Acik"
            case .dark: "Koyu"
            }
        }
    }
}
