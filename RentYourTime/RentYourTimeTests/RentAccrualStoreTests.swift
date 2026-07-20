import XCTest
@testable import RentYourTime

final class RentAccrualStoreTests: XCTestCase {
    private let suiteName = "test.rentaccrual"
    private var userDefaults: UserDefaults?

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        userDefaults?.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        super.tearDown()
    }

    func testFirstRecordForDaySucceedsAndPersists() throws {
        let defaults = try XCTUnwrap(userDefaults)
        let date = Date()
        let dayIdentifier = RentAccrualStore.dayIdentifier(for: date)

        let didRecord = RentAccrualStore.recordThresholdExceeded(
            dayIdentifier: dayIdentifier,
            date: date,
            userDefaults: defaults
        )

        XCTAssertTrue(didRecord)
        let stored = RentAccrualStore.load(userDefaults: defaults)
        XCTAssertEqual(stored?.dayIdentifier, dayIdentifier)
        XCTAssertTrue(stored?.hasStartedRent ?? false)
    }

    func testSecondRecordForSameDayIsIgnored() throws {
        let defaults = try XCTUnwrap(userDefaults)
        let firstDate = Date()
        let dayIdentifier = RentAccrualStore.dayIdentifier(for: firstDate)

        _ = RentAccrualStore.recordThresholdExceeded(
            dayIdentifier: dayIdentifier,
            date: firstDate,
            userDefaults: defaults
        )

        let secondDate = firstDate.addingTimeInterval(60)
        let didRecordAgain = RentAccrualStore.recordThresholdExceeded(
            dayIdentifier: dayIdentifier,
            date: secondDate,
            userDefaults: defaults
        )

        XCTAssertFalse(didRecordAgain)
        let stored = RentAccrualStore.load(userDefaults: defaults)
        XCTAssertEqual(stored?.thresholdExceededAt, firstDate)
    }

    func testRecordForDifferentDayOverwrites() throws {
        let defaults = try XCTUnwrap(userDefaults)
        let firstDate = Date()
        let firstDayIdentifier = RentAccrualStore.dayIdentifier(for: firstDate)
        _ = RentAccrualStore.recordThresholdExceeded(
            dayIdentifier: firstDayIdentifier,
            date: firstDate,
            userDefaults: defaults
        )

        let nextDay = firstDate.addingTimeInterval(24 * 60 * 60)
        let nextDayIdentifier = RentAccrualStore.dayIdentifier(for: nextDay)
        let didRecord = RentAccrualStore.recordThresholdExceeded(
            dayIdentifier: nextDayIdentifier,
            date: nextDay,
            userDefaults: defaults
        )

        XCTAssertTrue(didRecord)
        XCTAssertEqual(RentAccrualStore.load(userDefaults: defaults)?.dayIdentifier, nextDayIdentifier)
    }

    func testClearRemovesStoredEvent() throws {
        let defaults = try XCTUnwrap(userDefaults)
        let date = Date()
        let dayIdentifier = RentAccrualStore.dayIdentifier(for: date)
        _ = RentAccrualStore.recordThresholdExceeded(
            dayIdentifier: dayIdentifier,
            date: date,
            userDefaults: defaults
        )

        RentAccrualStore.clear(userDefaults: defaults)

        XCTAssertNil(RentAccrualStore.load(userDefaults: defaults))
    }
}
