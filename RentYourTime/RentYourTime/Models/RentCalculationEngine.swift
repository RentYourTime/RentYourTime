import Foundation

struct RentCalculationInput: Equatable, Sendable {
    let usedMinutes: Int
    let freeAllowanceMinutes: Int
    let pricePerMinute: Decimal
    let currencyCode: String
}

struct RentCalculationResult: Equatable, Sendable {
    let remainingFreeMinutes: Int
    let overageMinutes: Int
    let virtualRentAmount: Decimal
    let progress: Double
    let status: RentStatus
    let currencyCode: String
}

enum RentCalculationEngine {
    static let warningThreshold: Double = 0.8

    static func calculate(_ input: RentCalculationInput) -> RentCalculationResult {
        let usedMinutes = max(0, input.usedMinutes)
        let freeAllowanceMinutes = max(0, input.freeAllowanceMinutes)
        let pricePerMinute = max(Decimal.zero, input.pricePerMinute)

        let remainingFreeMinutes = max(0, freeAllowanceMinutes - usedMinutes)
        let overageMinutes = max(0, usedMinutes - freeAllowanceMinutes)
        let virtualRentAmount = max(Decimal.zero, Decimal(overageMinutes) * pricePerMinute)

        let progress: Double = freeAllowanceMinutes > 0
            ? min(1, Double(usedMinutes) / Double(freeAllowanceMinutes))
            : (usedMinutes > 0 ? 1 : 0)

        let status: RentStatus
        if overageMinutes > 0 {
            status = .rentActive
        } else if remainingFreeMinutes == 0 {
            status = .warning
        } else if Double(usedMinutes) / Double(freeAllowanceMinutes) >= warningThreshold {
            status = .warning
        } else {
            status = .free
        }

        return RentCalculationResult(
            remainingFreeMinutes: remainingFreeMinutes,
            overageMinutes: overageMinutes,
            virtualRentAmount: virtualRentAmount,
            progress: progress,
            status: status,
            currencyCode: input.currencyCode
        )
    }
}
