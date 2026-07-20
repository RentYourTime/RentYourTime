import Observation
import StoreKit

@MainActor
@Observable
final class StoreKitService {
    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case purchased
        case userCancelled
        case pending
        case verificationFailed(String)
        case failed(String)
    }

    enum RestoreState: Equatable {
        case idle
        case restoring
        case succeeded
        case failed(String)
    }

    private(set) var products: [Product] = []
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var restoreState: RestoreState = .idle
    private(set) var isProActive = false

    // nonisolated: tylko po to, żeby deinit (nonisolated) mógł anulować
    // Task — zapisywany raz w init, czytany tylko przy anulowaniu. Domyślne
    // `nil` w deklaracji (nie w ciele init) jest wymagane, żeby `self` było
    // uznane za w pełni zainicjalizowane, zanim domkniemy się nad nim niżej.
    @ObservationIgnored
    nonisolated(unsafe) private var transactionUpdatesTask: Task<Void, Never>?

    init() {
        // Długożyjący listener Transaction.updates (wymóg 8) — obsługuje
        // odnowienia, zmiany zdalne (np. zakup na innym urządzeniu) i
        // dokończenia transakcji `.pending`, niezależnie od bieżącego ekranu.
        transactionUpdatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self?.refreshEntitlement()
            }
        }

        Task { [weak self] in
            await self?.loadProducts()
            await self?.refreshEntitlement()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    /// Ładuje produkty po product ID (wymóg 2) — cena/nazwa/okres zawsze
    /// pochodzą z tego, co zwróci StoreKit, nigdy nie są wpisane na sztywno.
    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: SubscriptionProductID.all)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            #if DEBUG
            print("[StoreKitService] Nie udało się wczytać produktów: \(error)")
            #endif
        }
    }

    func purchase(_ product: Product) async {
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verification: verification)
            case .userCancelled:
                purchaseState = .userCancelled
            case .pending:
                purchaseState = .pending
            @unknown default:
                purchaseState = .failed("Nieznany wynik zakupu.")
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    func restorePurchases() async {
        restoreState = .restoring
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            restoreState = .succeeded
        } catch {
            restoreState = .failed(error.localizedDescription)
        }
    }

    /// Jedyne źródło prawdy o aktywnym Pro: Transaction.currentEntitlements
    /// (wymóg 9) — StoreKit sam filtruje do aktualnie ważnych transakcji
    /// (odnowienia/wygaśnięcia/zwroty), nie liczymy dat ręcznie.
    func refreshEntitlement() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if SubscriptionProductID.all.contains(transaction.productID), transaction.revocationDate == nil {
                active = true
            }
        }
        isProActive = active
    }

    private func handle(verification: VerificationResult<Transaction>) async {
        switch verification {
        case .verified(let transaction):
            await transaction.finish()
            await refreshEntitlement()
            purchaseState = .purchased
        case .unverified(_, let error):
            // Nie ufamy niezweryfikowanej transakcji — nie nadajemy Pro.
            purchaseState = .verificationFailed(error.localizedDescription)
        }
    }
}
