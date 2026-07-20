import XCTest
@testable import RentYourTime

final class StreakCalculatorTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private var today: Date {
        calendar.startOfDay(for: Date())
    }

    private func daysAgo(_ count: Int) -> Date {
        guard let date = calendar.date(byAdding: .day, value: -count, to: today) else {
            XCTFail("Nie udało się policzyć daty")
            return today
        }
        return date
    }

    func testEmptyDaysReturnsZero() {
        XCTAssertEqual(StreakCalculator.currentStreak(days: [], calendar: calendar), 0)
    }

    func testSingleGoalMetDayReturnsOne() {
        let days = [StreakCalculator.DayStatus(date: today, goalMet: true)]
        XCTAssertEqual(StreakCalculator.currentStreak(days: days, calendar: calendar), 1)
    }

    func testSingleNonGoalMetDayReturnsZero() {
        let days = [StreakCalculator.DayStatus(date: today, goalMet: false)]
        XCTAssertEqual(StreakCalculator.currentStreak(days: days, calendar: calendar), 0)
    }

    func testConsecutiveGoalMetDaysCountAll() {
        let days = (0..<5).map { StreakCalculator.DayStatus(date: daysAgo($0), goalMet: true) }
        XCTAssertEqual(StreakCalculator.currentStreak(days: days, calendar: calendar), 5)
    }

    func testBrokenByNonGoalMetDayInTheMiddle() {
        // dziś, wczoraj: goalMet; przedwczoraj: nie; wcześniej: goalMet (nie powinno się liczyć)
        let days = [
            StreakCalculator.DayStatus(date: daysAgo(0), goalMet: true),
            StreakCalculator.DayStatus(date: daysAgo(1), goalMet: true),
            StreakCalculator.DayStatus(date: daysAgo(2), goalMet: false),
            StreakCalculator.DayStatus(date: daysAgo(3), goalMet: true),
        ]
        XCTAssertEqual(StreakCalculator.currentStreak(days: days, calendar: calendar), 2)
    }

    func testCalendarGapBreaksStreakEvenWithGoodDaysAround() {
        // dziś, wczoraj: goalMet; brak rekordu za przedwczoraj; 3 dni temu: goalMet (nie powinno się liczyć)
        let days = [
            StreakCalculator.DayStatus(date: daysAgo(0), goalMet: true),
            StreakCalculator.DayStatus(date: daysAgo(1), goalMet: true),
            StreakCalculator.DayStatus(date: daysAgo(3), goalMet: true),
        ]
        XCTAssertEqual(StreakCalculator.currentStreak(days: days, calendar: calendar), 2)
    }

    func testMostRecentDayNotGoalMetResetsStreakToZero() {
        let days = [
            StreakCalculator.DayStatus(date: daysAgo(0), goalMet: false),
            StreakCalculator.DayStatus(date: daysAgo(1), goalMet: true),
            StreakCalculator.DayStatus(date: daysAgo(2), goalMet: true),
        ]
        XCTAssertEqual(StreakCalculator.currentStreak(days: days, calendar: calendar), 0)
    }

    func testUnsortedInputIsHandledCorrectly() {
        let days = [
            StreakCalculator.DayStatus(date: daysAgo(2), goalMet: true),
            StreakCalculator.DayStatus(date: daysAgo(0), goalMet: true),
            StreakCalculator.DayStatus(date: daysAgo(1), goalMet: true),
        ]
        XCTAssertEqual(StreakCalculator.currentStreak(days: days, calendar: calendar), 3)
    }
}
