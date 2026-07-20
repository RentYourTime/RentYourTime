@preconcurrency import UserNotifications
import Foundation
import Observation

@MainActor
@Observable
final class NotificationService {
    enum AuthorizationState: Equatable {
        case notDetermined
        case requesting
        case authorized
        case denied
        case failed(String)
    }

    private(set) var state: AuthorizationState = .notDetermined
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func refreshStatus() async {
        let settings = await center.notificationSettings()
        state = Self.state(for: settings.authorizationStatus)
    }

    func requestAuthorization() async {
        state = .requesting
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            state = granted ? .authorized : .denied
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func scheduleEveningSummary(hour: Int = 21, minute: Int = 0) {
        let content = NotificationContentBuilder.content(for: .eveningSummary)
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationKind.eveningSummary.rawValue,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            #if DEBUG
            if let error {
                print("[NotificationService] Nie udało się zaplanować podsumowania: \(error)")
            }
            #endif
        }
    }

    func cancelEveningSummary() {
        center.removePendingNotificationRequests(withIdentifiers: [NotificationKind.eveningSummary.rawValue])
    }

    private static func state(for status: UNAuthorizationStatus) -> AuthorizationState {
        switch status {
        case .notDetermined:
            .notDetermined
        case .authorized, .provisional, .ephemeral:
            .authorized
        case .denied:
            .denied
        @unknown default:
            .notDetermined
        }
    }
}
