import Foundation
import Observation
import RevenueCat

@Observable
@MainActor
class StoreViewModel {
    var offerings: Offerings?
    var isPremium: Bool = false
    var isLoading: Bool = false
    var isPurchasing: Bool = false
    var error: String?

    private var isConfigured: Bool {
        Purchases.isConfigured
    }

    init() {
        Task { await listenForUpdates() }
        Task { await fetchOfferings() }
        Task { await checkStatus() }
    }

    private func listenForUpdates() async {
        guard isConfigured else { return }
        for await info in Purchases.shared.customerInfoStream {
            self.isPremium = info.entitlements["premium"]?.isActive == true
        }
    }

    func fetchOfferings() async {
        guard isConfigured else { return }
        isLoading = true
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func purchase(package: Package) async {
        guard isConfigured else { return }
        isPurchasing = true
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                isPremium = result.customerInfo.entitlements["premium"]?.isActive == true
            }
        } catch ErrorCode.purchaseCancelledError {
        } catch ErrorCode.paymentPendingError {
        } catch {
            self.error = error.localizedDescription
        }
        isPurchasing = false
    }

    func restore() async {
        guard isConfigured else { return }
        isLoading = true
        do {
            let info = try await Purchases.shared.restorePurchases()
            isPremium = info.entitlements["premium"]?.isActive == true
            if !isPremium {
                self.error = "No active subscription found."
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func checkStatus() async {
        guard isConfigured else { return }
        do {
            let info = try await Purchases.shared.customerInfo()
            isPremium = info.entitlements["premium"]?.isActive == true
        } catch {
            self.error = error.localizedDescription
        }
    }

    var monthlyPackage: Package? {
        offerings?.current?.availablePackages.first { $0.identifier == "$rc_monthly" }
    }

    var annualPackage: Package? {
        offerings?.current?.availablePackages.first { $0.identifier == "$rc_annual" }
    }

    var monthlySavingsText: String? {
        guard let monthly = monthlyPackage, let annual = annualPackage else { return nil }
        let monthlyTotal = NSDecimalNumber(decimal: monthly.storeProduct.price * 12)
        let annualPrice = NSDecimalNumber(decimal: annual.storeProduct.price)
        guard monthlyTotal.compare(annualPrice) == .orderedDescending else { return nil }
        let diff = monthlyTotal.subtracting(annualPrice)
        let pct = diff.dividing(by: monthlyTotal).multiplying(by: 100)
        return "Save \(pct.intValue)%"
    }
}
