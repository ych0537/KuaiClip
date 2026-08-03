import Foundation
import Combine
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    static let trialDuration: TimeInterval = 7 * 24 * 60 * 60

    enum AccessState: Equatable {
        case loading
        case trialAvailable
        case trial(Date)
        case lifetime
        case locked

        var hasFullAccess: Bool {
            switch self {
            case .trial, .lifetime: return true
            case .loading, .trialAvailable, .locked: return false
            }
        }
    }

    @Published private(set) var accessState: AccessState
    @Published private(set) var lifetimeProduct: Product?
    @Published private(set) var isPurchasing = false
    @Published private(set) var lastError: String?

    private var updatesTask: Task<Void, Never>?

    private var lifetimeProductID: String {
        Bundle.main.object(forInfoDictionaryKey: "KuaiClipLifetimeProductID") as? String ?? ""
    }

    private let trialStartKey = "appStoreTrialStartDate"

    private init() {
        accessState = DistributionChannel.isAppStore ? .loading : .lifetime
        guard DistributionChannel.isAppStore else { return }

        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refresh()
                }
            }
        }

        Task { await refresh() }
    }

    func refresh() async {
        guard DistributionChannel.isAppStore else {
            accessState = .lifetime
            return
        }

        lastError = nil
        await loadProducts()

        var ownsLifetime = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil else { continue }

            if transaction.productID == lifetimeProductID {
                ownsLifetime = true
            }
        }

        if ownsLifetime {
            accessState = .lifetime
        } else if let trialStartDate = UserDefaults.standard.object(forKey: trialStartKey) as? Date {
            let expiration = trialStartDate.addingTimeInterval(Self.trialDuration)
            accessState = expiration > Date() ? .trial(expiration) : .locked
        } else {
            accessState = .trialAvailable
        }
    }

    func startTrial() async {
        guard DistributionChannel.isAppStore, accessState == .trialAvailable else { return }
        let startDate = Date()
        UserDefaults.standard.set(startDate, forKey: trialStartKey)
        accessState = .trial(startDate.addingTimeInterval(Self.trialDuration))
    }
    func buyLifetime() async { await purchase(lifetimeProduct) }

    func restorePurchases() async {
        guard DistributionChannel.isAppStore else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await refresh()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func clearError() { lastError = nil }

    private func loadProducts() async {
        let identifiers = [lifetimeProductID].filter { !$0.isEmpty }
        guard !identifiers.isEmpty else {
            lifetimeProduct = nil
            return
        }

        do {
            let products = try await Product.products(for: identifiers)
            lifetimeProduct = products.first { $0.id == lifetimeProductID }
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func purchase(_ product: Product?) async {
        guard DistributionChannel.isAppStore, let product else { return }
        isPurchasing = true
        lastError = nil
        defer { isPurchasing = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    lastError = L10n.purchaseVerificationFailed
                    return
                }
                await transaction.finish()
                await refresh()
            case .pending:
                lastError = L10n.purchasePending
            case .userCancelled:
                break
            @unknown default:
                lastError = L10n.purchaseFailed
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
}
