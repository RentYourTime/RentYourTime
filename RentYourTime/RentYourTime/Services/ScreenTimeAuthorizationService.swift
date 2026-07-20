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

    // `center` jest opcjonalny i budowany leniwie tylko wtedy, gdy nie ma
    // mocka — bez entitlementu Family Controls samo dotknięcie
    // `AuthorizationCenter.shared` (nawet bez wywołania requestAuthorization)
    // potrafi wygenerować błędy sandboxa, więc przy aktywnym mocku w ogóle
    // go nie tworzymy.
    private let center: AuthorizationCenter?

    // Tymczasowe obejście braku płatnego konta Apple Developer: gdy podane,
    // requestAuthorization/refreshStatus omijają AuthorizationCenter i idą
    // przez mocka. Domyślnie nil (prawdziwy FamilyControls) — mockService
    // podpina się jawnie w miejscu tworzenia (patrz ScreenTimePermissionView).
    private let mockService: ScreenTimeService?

    init(center: AuthorizationCenter? = nil, mockService: ScreenTimeService? = nil) {
        self.mockService = mockService
        self.center = mockService == nil ? (center ?? .shared) : nil
        self.state = mockService != nil ? .notDetermined : Self.state(for: self.center?.authorizationStatus ?? .notDetermined)
    }

    func refreshStatus() {
        guard let center else { return }
        state = Self.state(for: center.authorizationStatus)
    }

    func requestAuthorization() async {
        state = .requesting
        do {
            if let mockService {
                try await mockService.requestAuthorization()
                state = .authorized
                return
            }
            guard let center else {
                state = .failed("Brak dostępnego AuthorizationCenter.")
                return
            }
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
