import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            DashboardContentView(state: .loaded(DashboardViewModel(appState: appState)))
                .navigationTitle("Dashboard")
                .toolbarBackground(Color.rentBackground, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
}
