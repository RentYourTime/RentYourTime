import Foundation

@MainActor
struct DashboardViewModel {
    let usedMinutes: Int
    let freeLimitMinutes: Int
    let pricePerExtraMinute: Decimal
    let currency: Currency

    init(appState: AppState, usedMinutes: Int = DemoDataProvider.todayUsedMinutes) {
        self.usedMinutes = usedMinutes
        self.freeLimitMinutes = appState.dailyFreeLimitMinutes
        self.pricePerExtraMinute = appState.pricePerExtraMinute
        self.currency = appState.currency
    }

    var overLimitMinutes: Int {
        max(0, usedMinutes - freeLimitMinutes)
    }

    var rentCost: Decimal {
        Decimal(overLimitMinutes) * pricePerExtraMinute
    }

    var isOverLimit: Bool {
        overLimitMinutes > 0
    }

    var progress: Double {
        guard freeLimitMinutes > 0 else { return 1 }
        return min(1, Double(usedMinutes) / Double(freeLimitMinutes))
    }

    var usedTimeLabel: String { Self.label(forMinutes: usedMinutes) }
    var freeLimitLabel: String { Self.label(forMinutes: freeLimitMinutes) }

    private static func label(forMinutes minutes: Int) -> String {
        "\(minutes / 60)h \(minutes % 60)m"
    }
}
