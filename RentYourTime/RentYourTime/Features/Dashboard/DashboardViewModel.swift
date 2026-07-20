import Foundation

@MainActor
struct DashboardViewModel {
    let usedMinutes: Int
    let freeLimitMinutes: Int
    let currency: Currency
    let result: RentCalculationResult

    init(appState: AppState, usedMinutes: Int = DemoDataProvider.todayUsedMinutes) {
        self.usedMinutes = usedMinutes
        self.freeLimitMinutes = appState.dailyFreeLimitMinutes
        self.currency = appState.currency

        let input = RentCalculationInput(
            usedMinutes: usedMinutes,
            freeAllowanceMinutes: appState.dailyFreeLimitMinutes,
            pricePerMinute: appState.pricePerExtraMinute,
            currencyCode: appState.currency.isoCode
        )
        self.result = RentCalculationEngine.calculate(input)
    }

    var overLimitMinutes: Int { result.overageMinutes }
    var rentCost: Decimal { result.virtualRentAmount }
    var isOverLimit: Bool { result.status == .rentActive }
    var status: RentStatus { result.status }
    var progress: Double { result.progress }

    var usedTimeLabel: String { Self.label(forMinutes: usedMinutes) }
    var freeLimitLabel: String { Self.label(forMinutes: freeLimitMinutes) }
    var remainingTimeLabel: String { Self.label(forMinutes: result.remainingFreeMinutes) }

    var rentAmountLabel: String { currency.formatted(rentCost) }

    var progressPercentageLabel: String {
        "\(Int((progress * 100).rounded()))%"
    }

    var summaryText: String {
        switch status {
        case .free:
            "Jesteś w normie — zostało Ci jeszcze \(remainingTimeLabel) dzisiejszego limitu."
        case .warning:
            if result.remainingFreeMinutes == 0 {
                "Wykorzystałeś już cały dzisiejszy limit. Kolejna minuta zacznie naliczać rent."
            } else {
                "Zbliżasz się do limitu — zostało tylko \(remainingTimeLabel)."
            }
        case .rentActive:
            "Przekroczono limit o \(overLimitMinutes) min. Naliczono \(rentAmountLabel)."
        }
    }

    private static func label(forMinutes minutes: Int) -> String {
        "\(minutes / 60)h \(minutes % 60)m"
    }
}
