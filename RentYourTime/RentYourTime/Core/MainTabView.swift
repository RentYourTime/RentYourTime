import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "gauge.with.dots.needle.67percent") }

            HistoryView()
                .tabItem { Label("Historia", systemImage: "clock.arrow.circlepath") }

            SettingsView()
                .tabItem { Label("Ustawienia", systemImage: "gearshape") }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
