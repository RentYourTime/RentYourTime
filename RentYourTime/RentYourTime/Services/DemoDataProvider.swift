import Foundation

enum DemoDataProvider {
    static let todayUsedMinutes = 187

    private static let pastDaysUsedMinutes = [95, 140, 210, 60, 175, 230]

    static func historyEntries(
        freeLimitMinutes: Int,
        pricePerExtraMinute: Decimal,
        currency: Currency
    ) -> [UsageEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let allMinutes = pastDaysUsedMinutes + [todayUsedMinutes]

        return allMinutes.enumerated().map { index, minutes in
            let daysAgo = allMinutes.count - 1 - index
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            return UsageEntry(
                date: date,
                usedMinutes: minutes,
                freeLimitMinutes: freeLimitMinutes,
                pricePerExtraMinute: pricePerExtraMinute,
                currency: currency
            )
        }
        .reversed()
    }
}
