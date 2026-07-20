import Foundation

struct RentAccrualEvent: Codable, Equatable, Sendable {
    let dayIdentifier: String
    let thresholdExceededAt: Date
    let hasStartedRent: Bool
}

// Zwykły enum bez izolacji do aktora — wywoływany zarówno z głównej apki
// (@MainActor), jak i z RentDeviceActivityMonitor (nie jest @MainActor).
// UserDefaults jest bezpieczny wątkowo, więc nie potrzeba tu synchronizacji.
enum RentAccrualStore {
    private static let storageKey = "rentAccrualEvent"

    // Zapisuje przekroczenie progu tylko raz na dayIdentifier — kolejne
    // wywołania dla tego samego dnia nic nie nadpisują (brak wielokrotnego
    // naliczenia tego samego eventu). Zwraca true, jeśli faktycznie zapisano.
    @discardableResult
    static func recordThresholdExceeded(
        dayIdentifier: String,
        date: Date = Date(),
        userDefaults: UserDefaults
    ) -> Bool {
        if let existing = load(userDefaults: userDefaults), existing.dayIdentifier == dayIdentifier {
            return false
        }

        let event = RentAccrualEvent(
            dayIdentifier: dayIdentifier,
            thresholdExceededAt: date,
            hasStartedRent: true
        )

        guard let data = try? JSONEncoder().encode(event) else { return false }
        userDefaults.set(data, forKey: storageKey)
        return true
    }

    static func load(userDefaults: UserDefaults) -> RentAccrualEvent? {
        guard let data = userDefaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(RentAccrualEvent.self, from: data)
    }

    static func clear(userDefaults: UserDefaults) {
        userDefaults.removeObject(forKey: storageKey)
    }

    static func dayIdentifier(for date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
