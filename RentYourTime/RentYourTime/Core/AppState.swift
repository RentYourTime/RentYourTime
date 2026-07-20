import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var hasCompletedOnboarding: Bool
    var dailyFreeLimitMinutes: Int
    var pricePerExtraMinute: Decimal
    var currency: Currency

    init(
        hasCompletedOnboarding: Bool = false,
        dailyFreeLimitMinutes: Int = 120,
        pricePerExtraMinute: Decimal = 0.10,
        currency: Currency = .pln
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.dailyFreeLimitMinutes = dailyFreeLimitMinutes
        self.pricePerExtraMinute = pricePerExtraMinute
        self.currency = currency
    }

    func overLimitMinutes(forUsedMinutes usedMinutes: Int) -> Int {
        max(0, usedMinutes - dailyFreeLimitMinutes)
    }

    func rentCost(forUsedMinutes usedMinutes: Int) -> Decimal {
        Decimal(overLimitMinutes(forUsedMinutes: usedMinutes)) * pricePerExtraMinute
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}
