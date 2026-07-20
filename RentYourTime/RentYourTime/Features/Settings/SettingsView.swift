import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        NavigationStack {
            Form {
                Section("Dzienny darmowy limit") {
                    Stepper(
                        "\(appState.dailyFreeLimitMinutes / 60)h \(appState.dailyFreeLimitMinutes % 60)m",
                        value: $appState.dailyFreeLimitMinutes,
                        in: 15...600,
                        step: 15
                    )
                }

                Section("Cena za dodatkową minutę") {
                    HStack {
                        Text(appState.currency.formatted(appState.pricePerExtraMinute))
                        Spacer()
                        Stepper(
                            "",
                            value: Binding(
                                get: { NSDecimalNumber(decimal: appState.pricePerExtraMinute).doubleValue },
                                set: { appState.pricePerExtraMinute = Decimal($0) }
                            ),
                            in: 0.05...5.0,
                            step: 0.05
                        )
                        .labelsHidden()
                    }
                }

                Section("Waluta") {
                    Picker("Waluta", selection: $appState.currency) {
                        ForEach(Currency.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                }

                Section {
                    Button("Zresetuj onboarding", role: .destructive) {
                        appState.resetOnboarding()
                    }
                }
            }
            .navigationTitle("Ustawienia")
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
