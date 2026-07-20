import DeviceActivity
import Foundation

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

        let now = Date()
        let dayIdentifier = RentAccrualStore.dayIdentifier(for: now)
        let didRecord = RentAccrualStore.recordThresholdExceeded(
            dayIdentifier: dayIdentifier,
            date: now,
            userDefaults: userDefaults
        )

        #if DEBUG
        if didRecord {
            print("[RentDeviceActivityMonitor] Zapisano przekroczenie progu dla \(dayIdentifier)")
        } else {
            print("[RentDeviceActivityMonitor] Przekroczenie dla \(dayIdentifier) już zapisane, pomijam")
        }
        #endif
    }
}
