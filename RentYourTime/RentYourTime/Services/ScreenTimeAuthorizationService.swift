@preconcurrency import FamilyControls
import Observation

@MainActor
@Observable
final class ScreenTimeAuthorizationService {
    enum AuthorizationState: Equatable {
        case notDetermined
        case requesting
        case authorized
        case denied
        case failed(String)
    }

    private(set) var state: AuthorizationState
    private let center: AuthorizationCenter

    init(center: AuthorizationCenter = .shared) {
        self.center = center
        self.state = Self.state(for: center.authorizationStatus)
    }

    func refreshStatus() {
        state = Self.state(for: center.authorizationStatus)
    }

    func requestAuthorization() async {
        state = .requesting
        do {
            try await center.requestAuthorization(for: .individual)
            state = Self.state(for: center.authorizationStatus)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private static func state(for status: AuthorizationStatus) -> AuthorizationState {
        switch status {
        case .notDetermined:
            .notDetermined
        case .approved, .approvedWithDataAccess:
            .authorized
        case .denied:
            .denied
        @unknown default:
            .notDetermined
        }
    }
}
