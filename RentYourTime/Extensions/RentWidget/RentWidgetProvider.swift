import Foundation
import WidgetKit

struct RentWidgetProvider: TimelineProvider {
    private let userDefaults: UserDefaults?

    init(userDefaults: UserDefaults? = UserDefaults(suiteName: AppGroup.identifier)) {
        self.userDefaults = userDefaults
    }

    func placeholder(in context: Context) -> RentWidgetEntry {
        // Statyczne przykładowe dane — WidgetKit sam nakłada redakcję w
        // galerii, nie czytamy tu App Group (placeholder ma być natychmiastowy).
        RentWidgetEntry(date: Date(), snapshot: Self.placeholderSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (RentWidgetEntry) -> Void) {
        if context.isPreview {
            completion(RentWidgetEntry(date: Date(), snapshot: Self.placeholderSnapshot))
            return
        }
        completion(RentWidgetEntry(date: Date(), snapshot: currentSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RentWidgetEntry>) -> Void) {
        let entry = RentWidgetEntry(date: Date(), snapshot: currentSnapshot())
        // Jeden entry (bieżący stan) + kolejne sprawdzenie za 30 minut —
        // nie próbujemy przewidywać przyszłego użycia ani odświeżać częściej
        // (budżet WidgetKit i tak by na to nie pozwolił).
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
            ?? Date().addingTimeInterval(30 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func currentSnapshot() -> WidgetSnapshot? {
        guard let userDefaults else { return nil }
        return WidgetSnapshotStore.load(userDefaults: userDefaults)
    }

    private static let placeholderSnapshot = WidgetSnapshot(
        usedMinutes: 95,
        allowanceMinutes: 120,
        remainingMinutes: 25,
        virtualRentAmount: 0,
        currencyCode: "PLN",
        status: .free,
        generatedAt: Date()
    )
}
