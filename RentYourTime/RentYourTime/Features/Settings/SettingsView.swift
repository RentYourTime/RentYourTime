import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(ScreenTimeSelectionStore.self) private var selectionStore
    @Environment(NotificationService.self) private var notificationService
    @Environment(NotificationPreferencesStore.self) private var notificationPreferencesStore
    @Environment(\.openURL) private var openURL

    @State private var isSelectionSheetPresented = false
    @State private var isNotificationExplainerPresented = false
    @State private var pendingNotificationKind: NotificationKind?
    @State private var deviceActivityService = DeviceActivityService()
    @State private var widgetSnapshotUpdater = WidgetSnapshotUpdater()

    var body: some View {
        @Bindable var appState = appState

        NavigationStack {
            Form {
                Section("Śledzone aplikacje") {
                    Text(selectionSummary)
                        .foregroundStyle(.secondary)

                    Button("Zmień wybór") {
                        isSelectionSheetPresented = true
                    }

                    if selectionStore.hasSelection {
                        Button("Wyczyść wybór", role: .destructive) {
                            selectionStore.clear()
                            deviceActivityService.stopMonitoring()
                        }
                    }
                }

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

                Section("Powiadomienia") {
                    notificationToggle("80% dziennego limitu", kind: .eightyPercent)
                    notificationToggle("95% dziennego limitu", kind: .ninetyFivePercent)
                    notificationToggle("Start naliczania rentu", kind: .rentStarted)
                    notificationToggle("Wieczorne podsumowanie dnia", kind: .eveningSummary)

                    if notificationService.state == .denied {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Powiadomienia są wyłączone w Ustawieniach systemowych.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Button("Otwórz Ustawienia") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    openURL(url)
                                }
                            }
                            .font(.footnote)
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
            .task {
                await notificationService.refreshStatus()
            }
            .onChange(of: appState.dailyFreeLimitMinutes) { refreshWidgetSnapshot() }
            .onChange(of: appState.pricePerExtraMinute) { refreshWidgetSnapshot() }
            .onChange(of: appState.currency) { refreshWidgetSnapshot() }
            .sheet(isPresented: $isSelectionSheetPresented) {
                ScreenTimeSelectionView(
                    title: "Śledzone aplikacje",
                    continueButtonTitle: "Zapisz zmiany",
                    onSave: { isSelectionSheetPresented = false }
                )
            }
            .sheet(isPresented: $isNotificationExplainerPresented) {
                NotificationPermissionExplainerView(onFinished: handlePermissionExplainerFinished)
            }
        }
    }

    private func notificationToggle(_ title: String, kind: NotificationKind) -> some View {
        Toggle(title, isOn: Binding(
            get: { notificationPreferencesStore.preferences.isEnabled(kind) },
            set: { isEnabled in setNotificationEnabled(isEnabled, for: kind) }
        ))
    }

    private func setNotificationEnabled(_ isEnabled: Bool, for kind: NotificationKind) {
        guard isEnabled, notificationService.state == .notDetermined else {
            applyNotificationPreference(isEnabled, for: kind)
            return
        }

        // Wymóg: poproś o zgodę systemową dopiero po wyjaśnieniu korzyści.
        pendingNotificationKind = kind
        isNotificationExplainerPresented = true
    }

    private func handlePermissionExplainerFinished() {
        guard let kind = pendingNotificationKind else { return }
        pendingNotificationKind = nil

        if notificationService.state == .authorized {
            applyNotificationPreference(true, for: kind)
        }
    }

    private func applyNotificationPreference(_ isEnabled: Bool, for kind: NotificationKind) {
        notificationPreferencesStore.setEnabled(isEnabled, for: kind)
        if kind == .eveningSummary {
            if isEnabled {
                notificationService.scheduleEveningSummary()
            } else {
                notificationService.cancelEveningSummary()
            }
        }
    }

    private func refreshWidgetSnapshot() {
        widgetSnapshotUpdater.updateSnapshot(appState: appState)
    }

    private var selectionSummary: String {
        guard selectionStore.hasSelection else {
            return "Nie wybrano jeszcze żadnych aplikacji ani kategorii."
        }
        let selection = selectionStore.selection
        return "\(selection.applicationTokens.count) aplikacji, \(selection.categoryTokens.count) kategorii, \(selection.webDomainTokens.count) domen"
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(ScreenTimeSelectionStore())
        .environment(NotificationService())
        .environment(NotificationPreferencesStore())
}
