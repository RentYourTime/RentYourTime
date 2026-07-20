import XCTest
@testable import RentYourTime

final class NotificationDispatchStoreTests: XCTestCase {
    private let suiteName = "test.notificationdispatch"

    private func makeUserDefaults() throws -> UserDefaults {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func testFirstMarkSentSucceeds() throws {
        let defaults = try makeUserDefaults()

        let didMark = NotificationDispatchStore.markSent(
            NotificationKind.eightyPercent.rawValue,
            dayIdentifier: "2026-07-20",
            userDefaults: defaults
        )

        XCTAssertTrue(didMark)
        XCTAssertTrue(NotificationDispatchStore.hasSent(
            NotificationKind.eightyPercent.rawValue, dayIdentifier: "2026-07-20", userDefaults: defaults
        ))
    }

    func testSecondMarkSentSameDayIsIgnored() throws {
        let defaults = try makeUserDefaults()
        let identifier = NotificationKind.rentStarted.rawValue

        NotificationDispatchStore.markSent(identifier, dayIdentifier: "2026-07-20", userDefaults: defaults)
        let didMarkAgain = NotificationDispatchStore.markSent(identifier, dayIdentifier: "2026-07-20", userDefaults: defaults)

        XCTAssertFalse(didMarkAgain)
    }

    func testDifferentIdentifiersSameDayAreIndependent() throws {
        let defaults = try makeUserDefaults()

        let didMarkEighty = NotificationDispatchStore.markSent(
            NotificationKind.eightyPercent.rawValue, dayIdentifier: "2026-07-20", userDefaults: defaults
        )
        let didMarkNinetyFive = NotificationDispatchStore.markSent(
            NotificationKind.ninetyFivePercent.rawValue, dayIdentifier: "2026-07-20", userDefaults: defaults
        )

        XCTAssertTrue(didMarkEighty)
        XCTAssertTrue(didMarkNinetyFive)
    }

    func testNewDayResetsDispatchLog() throws {
        let defaults = try makeUserDefaults()
        let identifier = NotificationKind.eightyPercent.rawValue

        NotificationDispatchStore.markSent(identifier, dayIdentifier: "2026-07-20", userDefaults: defaults)
        let didMarkNextDay = NotificationDispatchStore.markSent(identifier, dayIdentifier: "2026-07-21", userDefaults: defaults)

        XCTAssertTrue(didMarkNextDay)
        XCTAssertFalse(NotificationDispatchStore.hasSent(identifier, dayIdentifier: "2026-07-20", userDefaults: defaults))
        XCTAssertTrue(NotificationDispatchStore.hasSent(identifier, dayIdentifier: "2026-07-21", userDefaults: defaults))
    }

    func testClearRemovesLog() throws {
        let defaults = try makeUserDefaults()
        let identifier = NotificationKind.rentStarted.rawValue
        NotificationDispatchStore.markSent(identifier, dayIdentifier: "2026-07-20", userDefaults: defaults)

        NotificationDispatchStore.clear(userDefaults: defaults)

        XCTAssertFalse(NotificationDispatchStore.hasSent(identifier, dayIdentifier: "2026-07-20", userDefaults: defaults))
    }
}
