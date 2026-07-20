import Foundation
import SwiftData

@MainActor
final class HistoryRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    @discardableResult
    func upsertRecord(
        date: Date,
        usedMinutes: Int,
        allowanceMinutes: Int,
        overageMinutes: Int,
        virtualRent: Decimal,
        currencyCode: String,
        goalMet: Bool
    ) throws -> DailyUsageRecord {
        let day = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<DailyUsageRecord>(
            predicate: #Predicate { $0.date == day }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.usedMinutes = usedMinutes
            existing.allowanceMinutes = allowanceMinutes
            existing.overageMinutes = overageMinutes
            existing.virtualRent = virtualRent
            existing.currencyCode = currencyCode
            existing.goalMet = goalMet
            try modelContext.save()
            return existing
        }

        let record = DailyUsageRecord(
            date: day,
            usedMinutes: usedMinutes,
            allowanceMinutes: allowanceMinutes,
            overageMinutes: overageMinutes,
            virtualRent: virtualRent,
            currencyCode: currencyCode,
            goalMet: goalMet
        )
        modelContext.insert(record)
        try modelContext.save()
        return record
    }

    func records(lastDays: Int, referenceDate: Date = Date(), calendar: Calendar = .current) -> [DailyUsageRecord] {
        let today = calendar.startOfDay(for: referenceDate)
        guard let startDate = calendar.date(byAdding: .day, value: -(lastDays - 1), to: today) else {
            return []
        }

        let descriptor = FetchDescriptor<DailyUsageRecord>(
            predicate: #Predicate { $0.date >= startDate },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            #if DEBUG
            print("[HistoryRepository] Nie udało się pobrać rekordów: \(error)")
            #endif
            return []
        }
    }

    func allRecords() -> [DailyUsageRecord] {
        let descriptor = FetchDescriptor<DailyUsageRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            #if DEBUG
            print("[HistoryRepository] Nie udało się pobrać wszystkich rekordów: \(error)")
            #endif
            return []
        }
    }

    func currentStreak(calendar: Calendar = .current) -> Int {
        let statuses = allRecords().map { StreakCalculator.DayStatus(date: $0.date, goalMet: $0.goalMet) }
        return StreakCalculator.currentStreak(days: statuses, calendar: calendar)
    }

    /// Wypełnia pustą bazę przykładowymi dniami (niezależnie od bieżącego
    /// AppState, tak jak dotychczasowy DemoDataProvider.todayUsedMinutes) —
    /// no-op, jeśli w bazie jest już cokolwiek.
    func seedDemoDataIfNeeded() throws {
        guard allRecords().isEmpty else { return }

        let allowanceMinutes = 120
        let pricePerMinute: Decimal = 0.10
        let currencyCode = Currency.pln.isoCode
        // Ostatnie 7 dni celowo pod limitem, żeby ekran od razu pokazywał streak.
        let sampleUsedMinutes = [190, 80, 220, 60, 110, 95, 70, 100, 40, 85]

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for (index, usedMinutes) in sampleUsedMinutes.enumerated() {
            let daysAgo = sampleUsedMinutes.count - 1 - index
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }

            let input = RentCalculationInput(
                usedMinutes: usedMinutes,
                freeAllowanceMinutes: allowanceMinutes,
                pricePerMinute: pricePerMinute,
                currencyCode: currencyCode
            )
            let result = RentCalculationEngine.calculate(input)

            let record = DailyUsageRecord(
                date: date,
                usedMinutes: usedMinutes,
                allowanceMinutes: allowanceMinutes,
                overageMinutes: result.overageMinutes,
                virtualRent: result.virtualRentAmount,
                currencyCode: currencyCode,
                goalMet: result.overageMinutes == 0
            )
            modelContext.insert(record)
        }

        try modelContext.save()
    }
}
