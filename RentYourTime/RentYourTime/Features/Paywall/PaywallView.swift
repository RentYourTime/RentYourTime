import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(StoreKitService.self) private var storeKitService
    @Environment(\.dismiss) private var dismiss

    private let termsURL = URL(string: "https://rentyourtime.app/terms")
    private let privacyURL = URL(string: "https://rentyourtime.app/privacy")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    plansSection
                    statusMessages

                    Button("Przywróć zakupy") {
                        Task { await storeKitService.restorePurchases() }
                    }
                    .font(.subheadline)

                    disclosure
                    legalLinks
                }
                .padding()
            }
            .navigationTitle("RentYourTime Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zamknij") { dismiss() }
                }
            }
        }
        .task {
            await storeKitService.loadProducts()
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundStyle(.yellow)
            Text("Odblokuj RentYourTime Pro")
                .font(.title2.bold())
            Text("Wybierz plan poniżej. Ceny pobierane bezpośrednio z App Store.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var plansSection: some View {
        if storeKitService.products.isEmpty {
            ProgressView("Wczytywanie planów…")
                .padding(.vertical, 24)
        } else {
            VStack(spacing: 12) {
                ForEach(storeKitService.products) { product in
                    PlanCard(
                        product: product,
                        isPurchasing: storeKitService.purchaseState == .purchasing,
                        action: { Task { await storeKitService.purchase(product) } }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var statusMessages: some View {
        switch storeKitService.purchaseState {
        case .purchased:
            Label("Zakup zakończony — RentYourTime Pro aktywne.", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .userCancelled:
            Text("Zakup anulowany.")
                .foregroundStyle(.secondary)
        case .pending:
            Label("Zakup oczekuje na zatwierdzenie (np. przez rodzica).", systemImage: "clock")
                .foregroundStyle(.orange)
        case .verificationFailed(let message):
            Label("Nie udało się zweryfikować zakupu: \(message)", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        case .failed(let message):
            Label("Zakup nie powiódł się: \(message)", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        case .idle, .purchasing:
            EmptyView()
        }

        switch storeKitService.restoreState {
        case .succeeded:
            Label("Przywrócono zakupy.", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed(let message):
            Label("Nie udało się przywrócić zakupów: \(message)", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        case .idle, .restoring:
            EmptyView()
        }
    }

    private var disclosure: some View {
        Text("Subskrypcja odnawia się automatycznie, chyba że zostanie anulowana co najmniej 24 godziny przed końcem bieżącego okresu rozliczeniowego. Możesz zarządzać lub anulować subskrypcję w Ustawieniach konta Apple ID.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    private var legalLinks: some View {
        HStack(spacing: 16) {
            if let termsURL {
                Link("Warunki korzystania", destination: termsURL)
            }
            if let privacyURL {
                Link("Polityka prywatności", destination: privacyURL)
            }
        }
        .font(.caption)
    }
}
