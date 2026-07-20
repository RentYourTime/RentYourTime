import Foundation
import SwiftData

@Model
final class DailyUsageRecord {
    @Attribute(.unique) var date: Date
    var usedMinutes: Int
    var allowanceMinutes: Int
    var overageMinutes: Int
    var virtualRent: Decimal
    var currencyCode: String
    var goalMet: Bool

    init(
        date: Date,
        usedMinutes: Int,
        allowanceMinutes: Int,
        overageMinutes: Int,
        virtualRent: Decimal,
        currencyCode: String,
        goalMet: Bool
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.usedMinutes = usedMinutes
        self.allowanceMinutes = allowanceMinutes
        self.overageMinutes = overageMinutes
        self.virtualRent = virtualRent
        self.currencyCode = currencyCode
        self.goalMet = goalMet
    }
}
