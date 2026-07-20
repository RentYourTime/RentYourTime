import XCTest
@testable import RentYourTime

@MainActor
final class AppStateTests: XCTestCase {
    func testNoRentWhenUnderLimit() {
        let appState = AppState(dailyFreeLimitMinutes: 120, pricePerExtraMinute: 0.5, currency: .pln)

        XCTAssertEqual(appState.overLimitMinutes(forUsedMinutes: 90), 0)
        XCTAssertEqual(appState.rentCost(forUsedMinutes: 90), 0)
    }

    func testNoRentExactlyAtLimit() {
        let appState = AppState(dailyFreeLimitMinutes: 120, pricePerExtraMinute: 0.5, currency: .pln)

        XCTAssertEqual(appState.overLimitMinutes(forUsedMinutes: 120), 0)
        XCTAssertEqual(appState.rentCost(forUsedMinutes: 120), 0)
    }

    func testRentChargedWhenOverLimit() {
        let appState = AppState(dailyFreeLimitMinutes: 120, pricePerExtraMinute: 0.5, currency: .pln)

        XCTAssertEqual(appState.overLimitMinutes(forUsedMinutes: 150), 30)
        XCTAssertEqual(appState.rentCost(forUsedMinutes: 150), 15)
    }

    func testCompleteAndResetOnboarding() {
        let appState = AppState()

        XCTAssertFalse(appState.hasCompletedOnboarding)
        appState.completeOnboarding()
        XCTAssertTrue(appState.hasCompletedOnboarding)
        appState.resetOnboarding()
        XCTAssertFalse(appState.hasCompletedOnboarding)
    }
}
