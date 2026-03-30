import Foundation
import SwiftData

// MARK: - Okuma serisi (streak) modeli
// Gunluk okuma aliskanligi takibi ve gamification

@Model
final class ReadingStreak {
    var id: UUID
    var date: Date                    // Hangi gun (saat bilgisi sifirlanmis)
    var minutesRead: Double           // O gun okunan dakika
    var pagesRead: Int                // O gun okunan sayfa
    var booksOpened: Int              // O gun acilan kitap sayisi

    init(date: Date = .now) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.minutesRead = 0
        self.pagesRead = 0
        self.booksOpened = 0
    }
}

// MARK: - Streak hesaplama yardimcilari

extension ReadingStreak {

    // Ardisik gun sayisi hesapla
    static func currentStreakCount(from streaks: [ReadingStreak]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let sorted = streaks
            .filter { $0.minutesRead > 0 }
            .sorted { $0.date > $1.date }

        guard let latest = sorted.first else { return 0 }

        // Bugun veya dun okuma yoksa streak kirilmis
        let daysDiff = calendar.dateComponents([.day], from: latest.date, to: today).day ?? 0
        guard daysDiff <= 1 else { return 0 }

        var count = 1
        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i].date, to: sorted[i - 1].date).day ?? 0
            if diff == 1 {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    // Bu haftanin toplam dakikasi
    static func thisWeekMinutes(from streaks: [ReadingStreak]) -> Double {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return streaks
            .filter { $0.date >= startOfWeek }
            .reduce(0) { $0 + $1.minutesRead }
    }

    // Bu ayin toplam sayfasi
    static func thisMonthPages(from streaks: [ReadingStreak]) -> Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
        return streaks
            .filter { $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.pagesRead }
    }
}
