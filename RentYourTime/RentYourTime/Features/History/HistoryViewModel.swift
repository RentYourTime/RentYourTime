import Foundation

enum HistoryPeriod: CaseIterable, Identifiable {
    case sevenDays
    case thirtyDays

    var id: Self { self }

    var days: Int {
        switch self {
        case .sevenDays: 7
        case .thirtyDays: 30
        }
    }

    var displayName: String {
        switch self {
        case .sevenDays: "7 dni"
        case .thirtyDays: "30 dni"
        }
    }
}

@MainActor
struct HistoryViewModel {
    let period: HistoryPeriod
    let records: [DailyUsageRecord]
    let streak: Int

    private let currency: Currency

    init(period: HistoryPeriod, repository: HistoryRepository, fallbackCurrency: Currency) {
        self.period = period
        self.records = repository.records(lastDays: period.days)
        self.streak = repository.currentStreak()
        self.currency = records.first.flatMap { Currency(isoCode: $0.currencyCode) } ?? fallbackCurrency
    }

    var averageUsedMinutesLabel: String {
        guard !records.isEmpty else { return "—" }
        let total = records.reduce(0) { $0 + $1.usedMinutes }
        return Self.label(forMinutes: total / records.count)
    }

    var totalRentLabel: String {
        let total = records.reduce(Decimal.zero) { $0 + $1.virtualRent }
        return currency.formatted(total)
    }

    var daysUnderLimitLabel: String {
        "\(records.filter(\.goalMet).count) z \(records.count)"
    }

    var streakLabel: String {
        streak == 1 ? "1 dzień" : "\(streak) dni"
    }

    private static func label(forMinutes minutes: Int) -> String {
        "\(minutes / 60)h \(minutes % 60)m"
    }
}
