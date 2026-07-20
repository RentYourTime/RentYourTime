import DeviceActivity
import Foundation
import UserNotifications

final class RentDeviceActivityMonitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        #if DEBUG
        print("[RentDeviceActivityMonitor] intervalDidStart: \(activity.rawValue)")
        #endif
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        #if DEBUG
        print("[RentDeviceActivityMonitor] intervalDidEnd: \(activity.rawValue)")
        #endif
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        #if DEBUG
        print("[RentDeviceActivityMonitor] eventDidReachThreshold: \(event.rawValue) dla \(activity.rawValue)")
        #endif

        guard let userDefaults = UserDefaults(suiteName: AppGroup.identifier) else {
            #if DEBUG
            print("[RentDeviceActivityMonitor] Brak dostępu do App Group UserDefaults.")
            #endif
            return
        }

        guard let kind = NotificationKind(rawValue: event.rawValue) else {
            #if DEBUG
            print("[RentDeviceActivityMonitor] Nieznany event: \(event.rawValue)")
            #endif
            return
        }

        let dayIdentifier = RentAccrualStore.dayIdentifier(for: Date())

        if kind == .rentStarted {
            let didRecord = RentAccrualStore.recordThresholdExceeded(
                dayIdentifier: dayIdentifier,
                userDefaults: userDefaults
            )
            #if DEBUG
            print(didRecord ? "[RentDeviceActivityMonitor] Zapisano przekroczenie progu dla \(dayIdentifier)"
                             : "[RentDeviceActivityMonitor] Przekroczenie dla \(dayIdentifier) już zapisane")
            #endif
        }

        postNotificationIfNeeded(kind: kind, dayIdentifier: dayIdentifier, userDefaults: userDefaults)
    }

    private func postNotificationIfNeeded(kind: NotificationKind, dayIdentifier: String, userDefaults: UserDefaults) {
        let preferences = NotificationPreferencesStorage.load(userDefaults: userDefaults)
        guard preferences.isEnabled(kind) else {
            #if DEBUG
            print("[RentDeviceActivityMonitor] \(kind.rawValue) wyłączone w preferencjach, pomijam")
            #endif
            return
        }

        let didMark = NotificationDispatchStore.markSent(
            kind.rawValue,
            dayIdentifier: dayIdentifier,
            userDefaults: userDefaults
        )
        guard didMark else {
            #if DEBUG
            print("[RentDeviceActivityMonitor] \(kind.rawValue) już wysłane dziś, pomijam")
            #endif
            return
        }

        let content = NotificationContentBuilder.content(for: kind)
        let request = UNNotificationRequest(
            identifier: "\(kind.rawValue)-\(dayIdentifier)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error {
                print("[RentDeviceActivityMonitor] Nie udało się dodać powiadomienia: \(error)")
            } else {
                print("[RentDeviceActivityMonitor] Wysłano powiadomienie: \(kind.rawValue)")
            }
            #endif
        }
    }
}
