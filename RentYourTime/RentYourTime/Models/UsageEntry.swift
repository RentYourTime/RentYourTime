import Foundation

struct UsageEntry: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let usedMinutes: Int
    let freeLimitMinutes: Int
    let pricePerExtraMinute: Decimal
    let currency: Currency

    var overLimitMinutes: Int {
        max(0, usedMinutes - freeLimitMinutes)
    }

    var rentCost: Decimal {
        Decimal(overLimitMinutes) * pricePerExtraMinute
    }
}
