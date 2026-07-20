import Foundation

struct NotificationPreferences: Codable, Equatable, Sendable {
    var isEightyPercentEnabled: Bool = true
    var isNinetyFivePercentEnabled: Bool = true
    var isRentStartedEnabled: Bool = true
    // Jedyne domyślnie wyłączone — w wymogu jawnie nazwane "opcjonalne".
    var isEveningSummaryEnabled: Bool = false

    func isEnabled(_ kind: NotificationKind) -> Bool {
        switch kind {
        case .eightyPercent: isEightyPercentEnabled
        case .ninetyFivePercent: isNinetyFivePercentEnabled
        case .rentStarted: isRentStartedEnabled
        case .eveningSummary: isEveningSummaryEnabled
        }
    }
}

// Zwykły enum, bez izolacji do aktora — czytany zarówno z głównej apki, jak
// i z RentDeviceActivityMonitor (osobny proces, nie @MainActor).
enum NotificationPreferencesStorage {
    private static let storageKey = "notificationPreferences"

    static func load(userDefaults: UserDefaults) -> NotificationPreferences {
        guard let data = userDefaults.data(forKey: storageKey),
              let preferences = try? JSONDecoder().decode(NotificationPreferences.self, from: data)
        else {
            return NotificationPreferences()
        }
        return preferences
    }

    static func save(_ preferences: NotificationPreferences, userDefaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
