import Foundation

// Wyłącznie zagregowane liczby potrzebne do wyświetlenia widgetu — celowo
// BEZ FamilyActivitySelection/tokenów aplikacji, historii czy jakichkolwiek
// danych per-aplikacja (wymóg: nie zapisuj w App Group niepotrzebnych
// danych prywatnych).
struct WidgetSnapshot: Codable, Equatable, Sendable {
    let usedMinutes: Int
    let allowanceMinutes: Int
    let remainingMinutes: Int
    let virtualRentAmount: Decimal
    let currencyCode: String
    let status: RentStatus
    let generatedAt: Date
}

// Zwykły enum, bez izolacji do aktora — czytany zarówno z głównej apki, jak
// i z RentWidgetExtension (osobny proces).
enum WidgetSnapshotStore {
    private static let storageKey = "widgetSnapshot"

    static func load(userDefaults: UserDefaults) -> WidgetSnapshot? {
        guard let data = userDefaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    static func save(_ snapshot: WidgetSnapshot, userDefaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
