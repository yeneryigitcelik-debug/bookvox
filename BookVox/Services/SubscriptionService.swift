import Foundation
import StoreKit

// MARK: - StoreKit 2 abonelik servisi
// Premium plan yonetimi, satin alma ve yetkilendirme

@Observable
final class SubscriptionService {
    static let shared = SubscriptionService()

    // Urun ID'leri (App Store Connect'te tanimlanacak)
    enum ProductID: String, CaseIterable {
        case monthlyPremium = "com.bookvox.premium.monthly"
        case yearlyPremium = "com.bookvox.premium.yearly"

        var displayName: String {
            switch self {
            case .monthlyPremium: "Aylik Premium"
            case .yearlyPremium: "Yillik Premium"
            }
        }
    }

    // Mevcut durum
    private(set) var products: [Product] = []
    private(set) var isPremium = false
    private(set) var currentSubscription: Product.SubscriptionInfo.RenewalInfo?
    private(set) var expirationDate: Date?
    private(set) var isLoading = false

    private var updateTask: Task<Void, Never>?

    private init() {
        updateTask = Task { await listenForTransactions() }
        Task { await loadProducts() }
        Task { await checkEntitlement() }
    }

    deinit {
        updateTask?.cancel()
    }

    // MARK: - Urunleri Yukle

    func loadProducts() async {
        isLoading = true
        do {
            let ids = ProductID.allCases.map(\.rawValue)
            products = try await Product.products(for: Set(ids))
                .sorted { $0.price < $1.price }
        } catch {
            print("StoreKit urun yukleme hatasi: \(error)")
        }
        isLoading = false
    }

    // MARK: - Satin Alma

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await checkEntitlement()
            HapticService.importComplete()
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Yetkilendirme Kontrolu

    func checkEntitlement() async {
        var foundPremium = false
        var foundExpDate: Date?

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if ProductID.allCases.map(\.rawValue).contains(transaction.productID) {
                    foundPremium = true
                    foundExpDate = transaction.expirationDate
                }
            }
        }

        let premium = foundPremium
        let expiry = foundExpDate
        await MainActor.run {
            isPremium = premium
            expirationDate = expiry
        }
    }

    // Abonelik restore (geri yukleme)
    func restore() async {
        try? await AppStore.sync()
        await checkEntitlement()
    }

    // MARK: - Premium Ozelliklere Erisim

    // Ton erisim kontrolu
    func canUseTone(_ tone: TTSService.Tone) -> Bool {
        if isPremium { return true }
        return Constants.App.freeTones.contains(tone.rawValue)
    }

    // Kitap limiti kontrolu
    func canAddBook(currentCount: Int) -> Bool {
        if isPremium { return true }
        return currentCount < Constants.App.freeBookLimit
    }

    // Offline dinleme erisimi
    var canUseOfflinePlayback: Bool {
        isPremium
    }

    // MARK: - Fiyat Gosterimi

    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.monthlyPremium.rawValue }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == ProductID.yearlyPremium.rawValue }
    }

    var monthlySavingsPercent: Int? {
        guard let monthly = monthlyProduct,
              let yearly = yearlyProduct
        else { return nil }

        let monthlyAnnual = monthly.price * 12
        let savings = (monthlyAnnual - yearly.price) / monthlyAnnual * 100
        return Int(truncating: savings as NSNumber)
    }

    // MARK: - Private

    // Transaction dogrulama
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let value):
            return value
        }
    }

    // Arka planda transaction dinle (yenileme, iptal vb.)
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                await transaction.finish()
                await checkEntitlement()
            }
        }
    }

    enum SubscriptionError: LocalizedError {
        case verificationFailed
        case purchaseFailed

        var errorDescription: String? {
            switch self {
            case .verificationFailed: "Satin alma dogrulanamadi"
            case .purchaseFailed: "Satin alma basarisiz"
            }
        }
    }
}
