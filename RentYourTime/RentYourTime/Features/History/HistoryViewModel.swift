import Foundation

@MainActor
struct HistoryViewModel {
    let entries: [UsageEntry]

    init(appState: AppState) {
        entries = DemoDataProvider.historyEntries(
            freeLimitMinutes: appState.dailyFreeLimitMinutes,
            pricePerExtraMinute: appState.pricePerExtraMinute,
            currency: appState.currency
        )
    }
}
