import Foundation

// Zwykły enum, bez izolacji do aktora — wywoływany zarówno z głównej apki,
// jak i z RentDeviceActivityMonitor. UserDefaults jest bezpieczny wątkowo.
enum NotificationDispatchStore {
    private static let storageKey = "notificationDispatchLog"

    private struct DispatchLog: Codable {
        var dayIdentifier: String
        var sentKinds: Set<String>
    }

    /// Zaznacza dany identyfikator jako wysłany DZIŚ. Zwraca `true` i
    /// zapisuje tylko przy pierwszym wysłaniu tego identyfikatora danego
    /// dnia — kolejne wywołania dla tego samego dnia zwracają `false` i nic
    /// nie zapisują (brak wielokrotnego wysłania tego samego powiadomienia).
    @discardableResult
    static func markSent(_ identifier: String, dayIdentifier: String, userDefaults: UserDefaults) -> Bool {
        var log = load(userDefaults: userDefaults)
        if log.dayIdentifier != dayIdentifier {
            log = DispatchLog(dayIdentifier: dayIdentifier, sentKinds: [])
        }

        guard !log.sentKinds.contains(identifier) else { return false }

        log.sentKinds.insert(identifier)
        save(log, userDefaults: userDefaults)
        return true
    }

    static func hasSent(_ identifier: String, dayIdentifier: String, userDefaults: UserDefaults) -> Bool {
        let log = load(userDefaults: userDefaults)
        return log.dayIdentifier == dayIdentifier && log.sentKinds.contains(identifier)
    }

    static func clear(userDefaults: UserDefaults) {
        userDefaults.removeObject(forKey: storageKey)
    }

    private static func load(userDefaults: UserDefaults) -> DispatchLog {
        guard let data = userDefaults.data(forKey: storageKey),
              let log = try? JSONDecoder().decode(DispatchLog.self, from: data)
        else {
            return DispatchLog(dayIdentifier: "", sentKinds: [])
        }
        return log
    }

    private static func save(_ log: DispatchLog, userDefaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(log) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
