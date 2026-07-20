@preconcurrency import DeviceActivity
@preconcurrency import FamilyControls
import Foundation

@MainActor
final class DeviceActivityService {
    static let activityName = DeviceActivityName("com.rentyourtime.dailyMonitoring")
    static let thresholdEventName = DeviceActivityEvent.Name("com.rentyourtime.thresholdExceeded")

    private let center: DeviceActivityCenter

    init(center: DeviceActivityCenter = DeviceActivityCenter()) {
        self.center = center
    }

    func startDailyMonitoring(
        selection: FamilyActivitySelection,
        threshold: DateComponents = DeviceActivityThreshold.default
    ) throws {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: threshold
        )

        do {
            try center.startMonitoring(
                Self.activityName,
                during: schedule,
                events: [Self.thresholdEventName: event]
            )
            #if DEBUG
            print("[DeviceActivityService] Rozpoczęto monitoring, próg: \(threshold)")
            #endif
        } catch {
            #if DEBUG
            print("[DeviceActivityService] Nie udało się rozpocząć monitoringu: \(error)")
            #endif
            throw error
        }
    }

    func stopMonitoring() {
        center.stopMonitoring([Self.activityName])
        #if DEBUG
        print("[DeviceActivityService] Zatrzymano monitoring")
        #endif
    }
}
