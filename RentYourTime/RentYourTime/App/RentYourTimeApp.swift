import SwiftUI

@main
struct RentYourTimeApp: App {
    @State private var appState = AppState()
    @State private var selectionStore = ScreenTimeSelectionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(selectionStore)
        }
    }
}
