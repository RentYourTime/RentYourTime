import Foundation

// Tymczasowa atrapa na czas bez płatnego konta Apple Developer — bez niej
// nie da się uzyskać entitlementu Family Controls na realnym urządzeniu.
// Podpięta w ScreenTimeAuthorizationService.init (patrz ScreenTimePermissionView) —
// usuń podpięcie, gdy autoryzacja Family Controls zacznie działać naprawdę.
@MainActor
final class MockScreenTimeService: ScreenTimeService {
    func requestAuthorization() async throws {
        // Udajemy, że użytkownik wyraził zgodę.
    }

    func loadTodayUsage() async throws -> TimeInterval {
        // 4 godziny i 27 minut.
        return (4 * 60 * 60) + (27 * 60)
    }
}
