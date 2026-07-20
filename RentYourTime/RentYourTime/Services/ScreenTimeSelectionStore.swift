@preconcurrency import FamilyControls
import Foundation
import Observation

@MainActor
@Observable
final class ScreenTimeSelectionStore {
    private static let storageKey = "screenTimeSelection"

    private(set) var selection: FamilyActivitySelection
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.selection = Self.loadSelection(from: userDefaults) ?? FamilyActivitySelection()
    }

    var hasSelection: Bool {
        !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
    }

    func updateSelection(_ newSelection: FamilyActivitySelection) {
        selection = newSelection
    }

    func save() {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        userDefaults.set(data, forKey: Self.storageKey)
    }

    func clear() {
        selection = FamilyActivitySelection()
        userDefaults.removeObject(forKey: Self.storageKey)
    }

    private static func loadSelection(from userDefaults: UserDefaults) -> FamilyActivitySelection? {
        guard let data = userDefaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
}
