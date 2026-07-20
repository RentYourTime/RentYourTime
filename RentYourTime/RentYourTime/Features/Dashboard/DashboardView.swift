import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var widgetSnapshotUpdater = WidgetSnapshotUpdater()

    var body: some View {
        NavigationStack {
            DashboardContentView(state: .loaded(DashboardViewModel(appState: appState)))
                .navigationTitle("Dashboard")
                .toolbarBackground(Color.rentBackground, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            widgetSnapshotUpdater.updateSnapshot(appState: appState)
        }
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
}
