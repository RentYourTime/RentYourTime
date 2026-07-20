import Foundation
@preconcurrency import WidgetKit

@MainActor
final class WidgetSnapshotUpdater {
    private let userDefaults: UserDefaults?

    init(userDefaults: UserDefaults? = UserDefaults(suiteName: AppGroup.identifier)) {
        self.userDefaults = userDefaults
    }

    /// Liczy dokładnie tak samo jak DashboardViewModel (ten sam silnik),
    /// zapisuje zagregowany wynik do App Group i prosi WidgetKit o
    /// odświeżenie. Wołane tylko przy konkretnych zdarzeniach (pojawienie
    /// się Dashboardu, zmiana ustawień) — nie na żadnym timerze.
    func updateSnapshot(appState: AppState, usedMinutes: Int = DemoDataProvider.todayUsedMinutes) {
        guard let userDefaults else {
            #if DEBUG
            print("[WidgetSnapshotUpdater] Brak dostępu do App Group UserDefaults.")
            #endif
            return
        }

        let input = RentCalculationInput(
            usedMinutes: usedMinutes,
            freeAllowanceMinutes: appState.dailyFreeLimitMinutes,
            pricePerMinute: appState.pricePerExtraMinute,
            currencyCode: appState.currency.isoCode
        )
        let result = RentCalculationEngine.calculate(input)

        let snapshot = WidgetSnapshot(
            usedMinutes: usedMinutes,
            allowanceMinutes: appState.dailyFreeLimitMinutes,
            remainingMinutes: result.remainingFreeMinutes,
            virtualRentAmount: result.virtualRentAmount,
            currencyCode: appState.currency.isoCode,
            status: result.status,
            generatedAt: Date()
        )

        WidgetSnapshotStore.save(snapshot, userDefaults: userDefaults)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.rentStatus)

        #if DEBUG
        print("[WidgetSnapshotUpdater] Zapisano snapshot i poproszono o odświeżenie widgetu.")
        #endif
    }
}
