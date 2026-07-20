import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    @State private var step: Step = .welcome
    @State private var dailyLimitMinutes = 120
    @State private var pricePerExtraMinute: Decimal = 0.10
    @State private var currency: Currency = .pln

    private enum Step: Int {
        case welcome, screenTime, chooseApps, limit, price, currency
    }

    var body: some View {
        Group {
            switch step {
            case .welcome:
                standardStepLayout(buttonTitle: "Dalej") { welcomeStep }
            case .screenTime:
                ScreenTimePermissionView(onAuthorized: advance)
            case .chooseApps:
                ScreenTimeSelectionView(
                    title: "Choose what to track",
                    continueButtonTitle: "Zapisz i kontynuuj",
                    onSave: advance
                )
            case .limit:
                standardStepLayout(buttonTitle: "Dalej") { limitStep }
            case .price:
                standardStepLayout(buttonTitle: "Dalej") { priceStep }
            case .currency:
                standardStepLayout(buttonTitle: "Rozpocznij") { currencyStep }
            }
        }
        .animation(.default, value: step)
    }

    private func standardStepLayout(buttonTitle: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 24) {
            Spacer()

            content()

            Spacer()

            Button(buttonTitle) {
                advance()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    private var welcomeStep: some View {
        VStack(spacing: 12) {
            Image(systemName: "hourglass")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
            Text("RentYourTime")
                .font(.largeTitle.bold())
            Text("Every minute costs.")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Ustaw dzienny darmowy limit czasu ekranowego. Za każdą minutę ponad limit naliczymy wirtualny czynsz.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
    }

    private var limitStep: some View {
        VStack(spacing: 16) {
            Text("Dzienny darmowy limit")
                .font(.title2.bold())
            Text("\(dailyLimitMinutes / 60)h \(dailyLimitMinutes % 60)m")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
            Slider(
                value: Binding(
                    get: { Double(dailyLimitMinutes) },
                    set: { dailyLimitMinutes = Int($0) }
                ),
                in: 15...600,
                step: 15
            )
        }
    }

    private var priceStep: some View {
        VStack(spacing: 16) {
            Text("Cena za dodatkową minutę")
                .font(.title2.bold())
            Text(currency.formatted(pricePerExtraMinute))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
            Slider(
                value: Binding(
                    get: { NSDecimalNumber(decimal: pricePerExtraMinute).doubleValue },
                    set: { pricePerExtraMinute = Decimal($0) }
                ),
                in: 0.05...2.0,
                step: 0.05
            )
        }
    }

    private var currencyStep: some View {
        VStack(spacing: 16) {
            Text("Waluta")
                .font(.title2.bold())
            Picker("Waluta", selection: $currency) {
                ForEach(Currency.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else {
            appState.dailyFreeLimitMinutes = dailyLimitMinutes
            appState.pricePerExtraMinute = pricePerExtraMinute
            appState.currency = currency
            appState.completeOnboarding()
            return
        }
        step = next
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
