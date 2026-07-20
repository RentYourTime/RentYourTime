import Foundation

enum StreakCalculator {
    struct DayStatus: Equatable, Sendable {
        let date: Date
        let goalMet: Bool
    }

    /// Liczy streak wstecz od najnowszego dnia w `days`: kolejne kalendarzowe
    /// dni (bez luk) z `goalMet == true`. Luka w danych albo dzień z
    /// `goalMet == false` przerywa streak. Jeśli najnowszy dzień ma
    /// `goalMet == false`, streak wynosi 0 (liczymy od "dziś" wstecz, a nie
    /// najlepszy streak historyczny).
    static func currentStreak(days: [DayStatus], calendar: Calendar = .current) -> Int {
        let sorted = days.sorted { $0.date > $1.date }
        guard var expectedDate = sorted.first?.date else { return 0 }

        var streak = 0
        for day in sorted {
            guard calendar.isDate(day.date, inSameDayAs: expectedDate), day.goalMet else { break }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: expectedDate) else { break }
            expectedDate = previous
        }
        return streak
    }
}
