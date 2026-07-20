@preconcurrency import DeviceActivity
@preconcurrency import FamilyControls
import Foundation

@MainActor
final class DeviceActivityService {
    static let activityName = DeviceActivityName("com.rentyourtime.dailyMonitoring")

    private let center: DeviceActivityCenter

    init(center: DeviceActivityCenter = DeviceActivityCenter()) {
        self.center = center
    }

    /// Rejestruje trzy progi względem RZECZYWISTEGO dziennego limitu
    /// (`allowanceMinutes`, np. z AppState.dailyFreeLimitMinutes): 80%, 95%
    /// i 100% (start naliczania rentu). Do szybkiego testu wystarczy ustawić
    /// mały limit w Ustawieniach (min. 15 minut).
    func startDailyMonitoring(selection: FamilyActivitySelection, allowanceMinutes: Int) throws {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
            DeviceActivityEvent.Name(NotificationKind.eightyPercent.rawValue): makeEvent(
                selection: selection,
                thresholdMinutes: percentage(0.8, of: allowanceMinutes)
            ),
            DeviceActivityEvent.Name(NotificationKind.ninetyFivePercent.rawValue): makeEvent(
                selection: selection,
                thresholdMinutes: percentage(0.95, of: allowanceMinutes)
            ),
            DeviceActivityEvent.Name(NotificationKind.rentStarted.rawValue): makeEvent(
                selection: selection,
                thresholdMinutes: allowanceMinutes
            ),
        ]

        do {
            try center.startMonitoring(Self.activityName, during: schedule, events: events)
            #if DEBUG
            print("[DeviceActivityService] Rozpoczęto monitoring, limit: \(allowanceMinutes) min")
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

    private func makeEvent(selection: FamilyActivitySelection, thresholdMinutes: Int) -> DeviceActivityEvent {
        DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: thresholdMinutes)
        )
    }

    private func percentage(_ fraction: Double, of minutes: Int) -> Int {
        max(1, Int((Double(minutes) * fraction).rounded()))
    }
}
