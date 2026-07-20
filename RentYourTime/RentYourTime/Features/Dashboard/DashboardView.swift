import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let viewModel = DashboardViewModel(appState: appState)

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Every minute costs.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ProgressRing(progress: viewModel.progress, isOverLimit: viewModel.isOverLimit)
                        .frame(width: 180, height: 180)
                        .padding(.top, 8)

                    VStack(spacing: 4) {
                        Text(viewModel.usedTimeLabel)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("z \(viewModel.freeLimitLabel) darmowego limitu")
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        StatCard(
                            title: "Ponad limit",
                            value: "\(viewModel.overLimitMinutes) min",
                            tint: viewModel.isOverLimit ? .red : .secondary
                        )
                        StatCard(
                            title: "Naliczony rent",
                            value: viewModel.currency.formatted(viewModel.rentCost),
                            tint: viewModel.isOverLimit ? .red : .green
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
}
