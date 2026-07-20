import FamilyControls
import SwiftUI

struct ScreenTimeSelectionView: View {
    let title: String
    let continueButtonTitle: String
    let onSave: () -> Void

    @Environment(ScreenTimeSelectionStore.self) private var store
    @State private var draftSelection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @State private var deviceActivityService = DeviceActivityService()

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            Text(title)
                .font(.title2.bold())

            Text("Wybierz aplikacje i kategorie, które mają być liczone do Twojego dziennego limitu. Jeśli system na to pozwala, możesz też wskazać strony internetowe.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button {
                isPickerPresented = true
            } label: {
                Label("Wybierz aplikacje i kategorie", systemImage: "checklist")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            summary

            Spacer(minLength: 0)

            Button(continueButtonTitle) {
                store.save()
                startMonitoring()
                onSave()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!store.hasSelection)
        }
        .padding()
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $draftSelection)
        .task {
            draftSelection = store.selection
        }
        .onChange(of: draftSelection) { _, newValue in
            store.updateSelection(newValue)
        }
    }

    private func startMonitoring() {
        do {
            try deviceActivityService.startDailyMonitoring(selection: store.selection)
        } catch {
            // Oczekiwany błąd na koncie bez entitlementu Family Controls —
            // to POC, patrz docs/DEVICE_ACTIVITY_SETUP.md.
            #if DEBUG
            print("[ScreenTimeSelectionView] Nie udało się uruchomić monitoringu: \(error)")
            #endif
        }
    }

    @ViewBuilder
    private var summary: some View {
        if store.hasSelection {
            Text("Wybrano: \(store.selection.applicationTokens.count) aplikacji, \(store.selection.categoryTokens.count) kategorii, \(store.selection.webDomainTokens.count) domen")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            Text("Nie wybrano jeszcze żadnych aplikacji ani kategorii.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ScreenTimeSelectionView(title: "Choose what to track", continueButtonTitle: "Zapisz i kontynuuj", onSave: {})
        .environment(ScreenTimeSelectionStore())
}
