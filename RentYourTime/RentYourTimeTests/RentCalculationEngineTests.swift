import XCTest
@testable import RentYourTime

final class RentCalculationEngineTests: XCTestCase {
    private func makeInput(
        usedMinutes: Int,
        freeAllowanceMinutes: Int = 120,
        pricePerMinute: Decimal = 0.5,
        currencyCode: String = "PLN"
    ) -> RentCalculationInput {
        RentCalculationInput(
            usedMinutes: usedMinutes,
            freeAllowanceMinutes: freeAllowanceMinutes,
            pricePerMinute: pricePerMinute,
            currencyCode: currencyCode
        )
    }

    // MARK: - 0 minut

    func testZeroMinutesUsed() {
        let result = RentCalculationEngine.calculate(makeInput(usedMinutes: 0, freeAllowanceMinutes: 120))

        XCTAssertEqual(result.remainingFreeMinutes, 120)
        XCTAssertEqual(result.overageMinutes, 0)
        XCTAssertEqual(result.virtualRentAmount, 0)
        XCTAssertEqual(result.status, .free)
    }

    // MARK: - Dokładny limit

    func testExactlyAtLimit() {
        let result = RentCalculationEngine.calculate(makeInput(usedMinutes: 120, freeAllowanceMinutes: 120))

        XCTAssertEqual(result.remainingFreeMinutes, 0)
        XCTAssertEqual(result.overageMinutes, 0)
        XCTAssertEqual(result.virtualRentAmount, 0)
        XCTAssertEqual(result.status, .warning)
    }

    // MARK: - 1 minuta ponad limit

    func testOneMinuteOverLimit() {
        let result = RentCalculationEngine.calculate(
            makeInput(usedMinutes: 121, freeAllowanceMinutes: 120, pricePerMinute: 0.5)
        )

        XCTAssertEqual(result.overageMinutes, 1)
        XCTAssertEqual(result.virtualRentAmount, Decimal(0.5))
        XCTAssertEqual(result.status, .rentActive)
    }

    // MARK: - Duże przekroczenie

    func testLargeOverage() {
        let pricePerMinute: Decimal = 0.37
        let result = RentCalculationEngine.calculate(
            makeInput(usedMinutes: 620, freeAllowanceMinutes: 120, pricePerMinute: pricePerMinute)
        )

        XCTAssertEqual(result.overageMinutes, 500)
        XCTAssertEqual(result.virtualRentAmount, Decimal(500) * pricePerMinute)
        XCTAssertEqual(result.status, .rentActive)
    }

    // MARK: - Zerowa stawka

    func testZeroPrice() {
        let result = RentCalculationEngine.calculate(
            makeInput(usedMinutes: 200, freeAllowanceMinutes: 120, pricePerMinute: 0)
        )

        XCTAssertEqual(result.overageMinutes, 80)
        XCTAssertEqual(result.virtualRentAmount, 0)
        XCTAssertEqual(result.status, .rentActive)
    }

    // MARK: - Nieprawidłowe wartości wejściowe

    func testNegativeUsedMinutesIsClampedToZero() {
        let negative = RentCalculationEngine.calculate(makeInput(usedMinutes: -50, freeAllowanceMinutes: 120))
        let zero = RentCalculationEngine.calculate(makeInput(usedMinutes: 0, freeAllowanceMinutes: 120))

        XCTAssertEqual(negative, zero)
    }

    func testNegativeFreeAllowanceIsClampedToZero() {
        let result = RentCalculationEngine.calculate(
            makeInput(usedMinutes: 10, freeAllowanceMinutes: -30, pricePerMinute: 1)
        )

        XCTAssertEqual(result.remainingFreeMinutes, 0)
        XCTAssertEqual(result.overageMinutes, 10)
        XCTAssertEqual(result.virtualRentAmount, 10)
        XCTAssertEqual(result.status, .rentActive)
    }

    func testNegativePriceNeverProducesNegativeRent() {
        let result = RentCalculationEngine.calculate(
            makeInput(usedMinutes: 200, freeAllowanceMinutes: 120, pricePerMinute: -5)
        )

        XCTAssertEqual(result.overageMinutes, 80)
        XCTAssertGreaterThanOrEqual(result.virtualRentAmount, 0)
        XCTAssertEqual(result.virtualRentAmount, 0)
    }

    func testCurrencyCodeIsPassedThroughUnchanged() {
        let result = RentCalculationEngine.calculate(
            makeInput(usedMinutes: 10, currencyCode: "xx")
        )

        XCTAssertEqual(result.currencyCode, "xx")
    }
}
