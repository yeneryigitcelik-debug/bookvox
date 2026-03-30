import UIKit

// MARK: - Dokunsal geri bildirim servisi
// Premium his veren haptic feedback yonetimi

enum HapticService {

    // Sayfa gecisi — hafif tiklama
    static func pageFlip() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.6)
    }

    // Bookmark ekleme — orta darbe
    static func bookmarkAdded() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    // Bookmark silme — hafif darbe
    static func bookmarkRemoved() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.4)
    }

    // Oynatma basla/dur — yumusak tiklama
    static func playPause() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    // Ton degistirme — secim haptic
    static func toneChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // Kitap import tamamlandi — basari
    static func importComplete() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // Hata olustu
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // Sleep timer uyarisi
    static func timerWarning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    // Slider suruklerken hafif tiklamalar
    static func sliderTick() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // Streak tamamlandi — guclu basari
    static func streakMilestone() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
}
