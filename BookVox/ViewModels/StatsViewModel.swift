import Foundation
import SwiftData

// MARK: - Okuma istatistikleri view model
// Streak guncelleme, gunluk kayit ve istatistik hesaplama

@Observable
final class StatsViewModel {

    // Bugunun streak kaydini olustur veya guncelle
    static func recordReading(
        minutes: Double,
        pages: Int,
        context: ModelContext
    ) {
        let today = Calendar.current.startOfDay(for: .now)

        // Bugune ait kayit var mi?
        let descriptor = FetchDescriptor<ReadingStreak>(
            predicate: #Predicate { $0.date == today }
        )

        let existing = try? context.fetch(descriptor)

        if let streak = existing?.first {
            streak.minutesRead += minutes
            streak.pagesRead += pages
            streak.booksOpened += 1
        } else {
            let streak = ReadingStreak(date: .now)
            streak.minutesRead = minutes
            streak.pagesRead = pages
            streak.booksOpened = 1
            context.insert(streak)
        }

        try? context.save()
    }

    // Streak milestone kontrolu (7, 30, 100 gun vb.)
    static func checkMilestone(streaks: [ReadingStreak]) -> Int? {
        let count = ReadingStreak.currentStreakCount(from: streaks)
        let milestones = [7, 14, 30, 50, 100, 200, 365]
        return milestones.contains(count) ? count : nil
    }

    // En uzun streak
    static func longestStreak(from streaks: [ReadingStreak]) -> Int {
        let calendar = Calendar.current
        let sorted = streaks
            .filter { $0.minutesRead > 0 }
            .sorted { $0.date < $1.date }

        guard !sorted.isEmpty else { return 0 }

        var maxStreak = 1
        var currentStreak = 1

        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i - 1].date, to: sorted[i].date).day ?? 0
            if diff == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else if diff > 1 {
                currentStreak = 1
            }
        }

        return maxStreak
    }

    // Toplam dinleme suresi (tum zamanlarin)
    static func totalListeningHours(from books: [Book]) -> Double {
        books.reduce(0) { $0 + $1.totalListenedSec } / 3600
    }

    // Toplam okunan sayfa
    static func totalPagesRead(from streaks: [ReadingStreak]) -> Int {
        streaks.reduce(0) { $0 + $1.pagesRead }
    }

    // En cok okunan gun
    static func bestDay(from streaks: [ReadingStreak]) -> (date: Date, minutes: Double)? {
        streaks.max(by: { $0.minutesRead < $1.minutesRead })
            .map { ($0.date, $0.minutesRead) }
    }
}
