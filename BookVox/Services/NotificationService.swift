import Foundation
import UserNotifications

// MARK: - Bildirim servisi
// Gunluk okuma hatirlatici ve streak bildirimleri

enum NotificationService {

    // Bildirim izni iste
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // Gunluk okuma hatirlatici ayarla
    static func scheduleDailyReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()

        // Onceki hatirlaticiyi iptal et
        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Okuma Zamani"
        content.body = dailyReminderMessage()
        content.sound = .default
        content.categoryIdentifier = "reading_reminder"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // Streak motivasyon bildirimi
    static func scheduleStreakReminder(currentStreak: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])

        guard currentStreak > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(currentStreak) Gunluk Seri"
        content.body = "Serini kaybetme! Bugun henuz okumadin."
        content.sound = .default

        // Aksam 21:00'de hatırlat (eger o gün okumamışsa)
        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_reminder",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // Sleep timer bitmeden once uyari
    static func scheduleSleepTimerWarning(afterSeconds: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["sleep_warning"])

        let content = UNMutableNotificationContent()
        content.title = "Uyku Zamanlayicisi"
        content.body = "1 dakika icinde oynatma duracak"
        content.sound = .default

        let warningTime = max(afterSeconds - 60, 0)
        guard warningTime > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: warningTime, repeats: false)
        let request = UNNotificationRequest(
            identifier: "sleep_warning",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // Tum zamanlayicilari iptal et
    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // Rastgele motivasyon mesaji
    private static func dailyReminderMessage() -> String {
        let messages = [
            "Kitabinda kaldıgın yerden devam et",
            "Bugun birkac sayfa dinlemeye ne dersin?",
            "Bir kahve, bir kitap — harika bir kombinas yon",
            "Okuma aliskanlıgını surdurmek icin harika bir an",
            "Dunden kalan hikayeni merak etmiyor musun?",
            "15 dakikan var mi? Bir bolum dinle",
            "Bugunun kitap zamani geldi"
        ]
        return messages.randomElement() ?? "Bugun birkac sayfa dinlemeye ne dersin?"
    }
}
