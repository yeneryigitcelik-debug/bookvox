import SwiftUI
import SwiftData

// MARK: - Okuma istatistikleri ekrani

struct StatsView: View {
    @Environment(\.modelContext) private var context
    @Query(
        filter: #Predicate<ReadingStreak> { $0.minutesRead > 0 },
        sort: \ReadingStreak.date,
        order: .reverse
    )
    private var streaks: [ReadingStreak]
    @Query private var books: [Book]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.xl) {
                    streakCard
                    quickStats
                    weeklyChart
                    libraryStats
                }
                .padding(DS.Spacing.lg)
            }
            .navigationTitle("Istatistikler")
        }
    }

    // MARK: - Streak

    private var streakCard: some View {
        let count = ReadingStreak.currentStreakCount(from: streaks)

        return BookVoxCard {
            VStack(spacing: DS.Spacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text("Okuma Serisi")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.xs) {
                            Text("\(count)")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(.bookVoxAccent)
                            Text("gun")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(.orange.opacity(0.12))
                            .frame(width: 60, height: 60)

                        Image(systemName: count > 0 ? "flame.fill" : "flame")
                            .font(.system(size: 28))
                            .foregroundStyle(count > 0 ? .orange : .secondary)
                            .symbolEffect(.bounce, value: count)
                    }
                }

                weekDayRow
            }
            .padding(DS.Spacing.xl)
        }
    }

    private var weekDayRow: some View {
        let days = weekDayActivity()

        return HStack(spacing: DS.Spacing.sm) {
            ForEach(days, id: \.day) { item in
                VStack(spacing: DS.Spacing.xs) {
                    Circle()
                        .fill(item.isActive ? Color.bookVoxAccent : Color(.tertiarySystemFill))
                        .frame(width: 28, height: 28)
                        .overlay {
                            if item.isActive {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    Text(item.day)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(item.isToday ? Color.bookVoxAccent : Color.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick Stats

    private var quickStats: some View {
        let weekMin = ReadingStreak.thisWeekMinutes(from: streaks)
        let monthPages = ReadingStreak.thisMonthPages(from: streaks)
        let totalHrs = books.reduce(0.0) { $0 + $1.totalListenedSec } / 3600

        return HStack(spacing: DS.Spacing.md) {
            statBox(String(format: "%.0f", weekMin), "dk", "Bu hafta", "clock", .blue)
            statBox("\(monthPages)", "sayfa", "Bu ay", "doc.text", .green)
            statBox(String(format: "%.1f", totalHrs), "saat", "Toplam", "headphones", .purple)
        }
    }

    private func statBox(_ value: String, _ unit: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        BookVoxCard {
            VStack(spacing: DS.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title3.weight(.bold).monospacedDigit())
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.lg)
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        let data = computeWeeklyData()
        let maxVal = max(data.map(\.minutes).max() ?? 1, 1)

        return BookVoxCard {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("Haftalik Aktivite")
                    .font(.headline)

                HStack(alignment: .bottom, spacing: DS.Spacing.sm) {
                    ForEach(data, id: \.day) { item in
                        VStack(spacing: DS.Spacing.xs) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.minutes > 0 ? AnyShapeStyle(Color.bookVoxAccent.gradient) : AnyShapeStyle(Color(.tertiarySystemFill)))
                                .frame(height: max(CGFloat(item.minutes) / CGFloat(maxVal) * 110, 4))

                            Text(item.day)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 130, alignment: .bottom)
            }
            .padding(DS.Spacing.xl)
        }
    }

    // MARK: - Library Stats

    private var libraryStats: some View {
        let completed = books.filter { $0.completionPercent >= 0.95 }.count
        let inProgress = books.filter { $0.completionPercent > 0 && $0.completionPercent < 0.95 }.count
        let notStarted = books.filter { $0.completionPercent == 0 }.count

        return BookVoxCard {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("Kutuphane")
                    .font(.headline)

                HStack(spacing: DS.Spacing.lg) {
                    libStat(books.count, "Toplam", "books.vertical", .primary)
                    libStat(completed, "Biten", "checkmark.circle", .green)
                    libStat(inProgress, "Devam", "book.circle", .bookVoxAccent)
                    libStat(notStarted, "Yeni", "plus.circle", .secondary)
                }
            }
            .padding(DS.Spacing.xl)
        }
    }

    private func libStat(_ count: Int, _ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: DS.Spacing.xs) {
            Image(systemName: icon).foregroundStyle(color)
            Text("\(count)").font(.title3.weight(.bold))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private struct DayActivity { let day: String; let isActive: Bool; let isToday: Bool }
    private struct WeekData { let day: String; let minutes: Double }

    private func weekDayActivity() -> [DayActivity] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let names = ["Pt", "Sa", "Ca", "Pe", "Cu", "Ct", "Pz"]
        let offset = (cal.component(.weekday, from: today) + 5) % 7

        return (0..<7).map { i in
            let date = cal.date(byAdding: .day, value: i - offset, to: today) ?? today
            let active = streaks.contains { cal.isDate($0.date, inSameDayAs: date) }
            return DayActivity(day: names[i], isActive: active, isToday: cal.isDateInToday(date))
        }
    }

    private func computeWeeklyData() -> [WeekData] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let names = ["Pt", "Sa", "Ca", "Pe", "Cu", "Ct", "Pz"]
        let offset = (cal.component(.weekday, from: today) + 5) % 7

        return (0..<7).map { i in
            let date = cal.date(byAdding: .day, value: i - offset, to: today) ?? today
            let mins = streaks.filter { cal.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.minutesRead }
            return WeekData(day: names[i], minutes: mins)
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [ReadingStreak.self, Book.self], inMemory: true)
}
