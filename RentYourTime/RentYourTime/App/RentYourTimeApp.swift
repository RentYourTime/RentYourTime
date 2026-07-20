import SwiftData
import SwiftUI

@main
struct RentYourTimeApp: App {
    @State private var appState = AppState()
    @State private var selectionStore = ScreenTimeSelectionStore()
    @State private var notificationService = NotificationService()
    @State private var notificationPreferencesStore = NotificationPreferencesStore()
    private let modelContainer: ModelContainer

    init() {
        do {
            // Jawnie wymuszamy prywatny kontener apki — bez tego SwiftData
            // automatycznie przenosi store do App Group (bo apka ma
            // entitlement App Groups dla RentAccrualStore), co nie jest tu
            // zamierzone.
            let schema = Schema([DailyUsageRecord.self])
            let configuration = ModelConfiguration(schema: schema, groupContainer: .none)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            try HistoryRepository(modelContext: container.mainContext).seedDemoDataIfNeeded()
            modelContainer = container
        } catch {
            fatalError("Nie udało się utworzyć ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(selectionStore)
                .environment(notificationService)
                .environment(notificationPreferencesStore)
                .task {
                    // Idempotentne dzięki stałemu identyfikatorowi requestu —
                    // bezpieczne do wywołania przy każdym starcie apki.
                    if notificationPreferencesStore.preferences.isEveningSummaryEnabled {
                        notificationService.scheduleEveningSummary()
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
