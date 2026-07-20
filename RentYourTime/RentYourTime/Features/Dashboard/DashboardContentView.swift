import SwiftUI

struct DashboardContentView: View {
    let state: DashboardContentState

    var body: some View {
        ScrollView {
            switch state {
            case .loaded(let viewModel):
                loadedContent(viewModel)
            case .empty:
                DashboardMessageView(
                    symbolName: "tray",
                    title: "Brak danych na dziś",
                    message: "Gdy tylko zaczniesz korzystać z wybranych aplikacji, zobaczysz tu swój dzienny postęp.",
                    tint: .white.opacity(0.6)
                )
                .padding(.top, 80)
            case .failed(let message):
                DashboardMessageView(
                    symbolName: "exclamationmark.triangle.fill",
                    title: "Nie udało się wczytać danych",
                    message: message,
                    tint: .red
                )
                .padding(.top, 80)
            }
        }
        .background(Color.rentBackground)
    }

    @ViewBuilder
    private func loadedContent(_ viewModel: DashboardViewModel) -> some View {
        VStack(spacing: 20) {
            Text("Every minute costs.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))

            ProgressRing(
                progress: viewModel.progress,
                status: viewModel.status,
                primaryText: viewModel.progressPercentageLabel,
                secondaryText: viewModel.status.displayName
            )
            .frame(width: 200, height: 200)
            .padding(.top, 8)

            HStack(spacing: 12) {
                StatCard(title: "Czas wykorzystany", value: viewModel.usedTimeLabel, tint: .white)
                StatCard(title: "Czas pozostały", value: viewModel.remainingTimeLabel, tint: viewModel.status.tintColor)
            }

            RentSummaryCard(amountLabel: viewModel.rentAmountLabel, status: viewModel.status)

            StatCard(title: "Dzisiejszy limit", value: viewModel.freeLimitLabel, tint: .white)

            Text(viewModel.summaryText)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Podsumowanie dnia")
                .accessibilityValue(viewModel.summaryText)

            NavigationLink {
                HistoryView()
            } label: {
                HStack {
                    Text("Zobacz historię")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.rentSurface, in: RoundedRectangle(cornerRadius: 16))
            }
            .accessibilityHint("Otwiera historię dziennego użycia")
        }
        .padding()
    }
}

#Preview("Dużo wolnego czasu") {
    DashboardContentView(
        state: .loaded(
            DashboardViewModel(
                appState: AppState(dailyFreeLimitMinutes: 180, pricePerExtraMinute: 0.5, currency: .pln),
                usedMinutes: 20
            )
        )
    )
}

#Preview("Blisko limitu") {
    DashboardContentView(
        state: .loaded(
            DashboardViewModel(
                appState: AppState(dailyFreeLimitMinutes: 180, pricePerExtraMinute: 0.5, currency: .pln),
                usedMinutes: 150
            )
        )
    )
}

#Preview("Limit przekroczony") {
    DashboardContentView(
        state: .loaded(
            DashboardViewModel(
                appState: AppState(dailyFreeLimitMinutes: 180, pricePerExtraMinute: 0.5, currency: .pln),
                usedMinutes: 230
            )
        )
    )
}

#Preview("Brak danych") {
    DashboardContentView(state: .empty)
}

#Preview("Błąd") {
    DashboardContentView(state: .failed("Nie udało się połączyć z usługą Screen Time."))
}
