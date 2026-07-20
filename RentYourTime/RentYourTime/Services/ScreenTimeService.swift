import Foundation

@MainActor
protocol ScreenTimeService {
    func requestAuthorization() async throws
    func loadTodayUsage() async throws -> TimeInterval
}
