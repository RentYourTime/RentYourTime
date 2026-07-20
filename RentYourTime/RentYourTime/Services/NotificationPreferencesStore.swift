import Foundation
import Observation

@MainActor
@Observable
final class NotificationPreferencesStore {
    private(set) var preferences: NotificationPreferences
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard) {
        self.userDefaults = userDefaults
        self.preferences = NotificationPreferencesStorage.load(userDefaults: userDefaults)
    }

    func setEnabled(_ isEnabled: Bool, for kind: NotificationKind) {
        switch kind {
        case .eightyPercent:
            preferences.isEightyPercentEnabled = isEnabled
        case .ninetyFivePercent:
            preferences.isNinetyFivePercentEnabled = isEnabled
        case .rentStarted:
            preferences.isRentStartedEnabled = isEnabled
        case .eveningSummary:
            preferences.isEveningSummaryEnabled = isEnabled
        }
        NotificationPreferencesStorage.save(preferences, userDefaults: userDefaults)
    }
}
