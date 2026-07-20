import XCTest
import SwiftData
@testable import RentYourTime

@MainActor
final class HistoryRepositoryTests: XCTestCase {
    // ModelContainer musi żyć przez cały czas trwania testu — jeśli zostanie
    // zwolniony (np. jako lokalna zmienna wyłącznie wewnątrz funkcji
    // pomocniczej, która zwraca tylko HistoryRepository), użycie jego
    // ModelContext później crashuje. Dlatego zwracamy oba i trzymamy
    // `container` jako lokalną zmienną w każdej metodzie testowej.
    private func makeInMemoryContext() throws -> (repository: HistoryRepository, container: ModelContainer) {
        let schema = Schema([DailyUsageRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let repository = HistoryRepository(modelContext: container.mainContext)
        return (repository, container)
    }

    func testUpsertTwiceSameDayUpdatesInPlaceWithoutDuplicate() throws {
        let (repository, container) = try makeInMemoryContext()
        let date = Date()

        try repository.upsertRecord(
            date: date,
            usedMinutes: 100,
            allowanceMinutes: 120,
            overageMinutes: 0,
            virtualRent: 0,
            currencyCode: "PLN",
            goalMet: true
        )
        try repository.upsertRecord(
            date: date,
            usedMinutes: 150,
            allowanceMinutes: 120,
            overageMinutes: 30,
            virtualRent: 15,
            currencyCode: "PLN",
            goalMet: false
        )

        let all = repository.allRecords()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.usedMinutes, 150)
        XCTAssertEqual(all.first?.goalMet, false)
        XCTAssertNotNil(container)
    }

    func testUpsertDifferentDaysCreatesSeparateRecords() throws {
        let (repository, container) = try makeInMemoryContext()
        let calendar = Calendar.current
        let today = Date()
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: today))

        try repository.upsertRecord(
            date: today, usedMinutes: 100, allowanceMinutes: 120,
            overageMinutes: 0, virtualRent: 0, currencyCode: "PLN", goalMet: true
        )
        try repository.upsertRecord(
            date: yesterday, usedMinutes: 50, allowanceMinutes: 120,
            overageMinutes: 0, virtualRent: 0, currencyCode: "PLN", goalMet: true
        )

        XCTAssertEqual(repository.allRecords().count, 2)
        XCTAssertNotNil(container)
    }

    func testSeedDemoDataIsIdempotent() throws {
        let (repository, container) = try makeInMemoryContext()

        try repository.seedDemoDataIfNeeded()
        let countAfterFirstSeed = repository.allRecords().count
        XCTAssertGreaterThan(countAfterFirstSeed, 0)

        try repository.seedDemoDataIfNeeded()
        XCTAssertEqual(repository.allRecords().count, countAfterFirstSeed)
        XCTAssertNotNil(container)
    }
}
