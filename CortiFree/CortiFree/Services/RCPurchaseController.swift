//
//  RCPurchaseController.swift
//  CortiFree
//
//  Superwall PurchaseController that delegates purchases to RevenueCat
//  Based on: https://superwall.com/docs/ios/guides/using-revenuecat
//

import SuperwallKit
import RevenueCat
import StoreKit

enum PurchasingError: LocalizedError {
    case sk2ProductNotFound

    var errorDescription: String? {
        switch self {
        case .sk2ProductNotFound:
            return "Superwall didn't pass a StoreKit 2 product to purchase."
        }
    }
}

final class RCPurchaseController: PurchaseController {

    // MARK: - Sync Subscription Status

    func syncSubscriptionStatus() {
        assert(Purchases.isConfigured, "RevenueCat must be configured before calling this method.")
        Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                let superwallEntitlements = customerInfo.entitlements
                    .activeInCurrentEnvironment.keys.map { Entitlement(id: $0) }
                await MainActor.run { [superwallEntitlements] in
                    Superwall.shared.subscriptionStatus = .active(Set(superwallEntitlements))
                }
            }
        }
    }

    // MARK: - Handle Purchases

    func purchase(product: SuperwallKit.StoreProduct) async -> PurchaseResult {
        do {
            guard let sk2Product = product.sk2Product else {
                throw PurchasingError.sk2ProductNotFound
            }
            let storeProduct = RevenueCat.StoreProduct(sk2Product: sk2Product)
            let revenueCatResult = try await Purchases.shared.purchase(product: storeProduct)

            if revenueCatResult.userCancelled {
                return .cancelled
            } else {
                // Also update RevenueCatManager state
                await RevenueCatManager.shared.refreshCustomerInfo(forceServerFetch: true)

                // Track conversion events avec détection trial vs paid
                let productId = product.productIdentifier
                let price = product.price as Decimal
                let currency = product.currencyCode ?? "EUR"
                let customerInfoForTracking = RevenueCatManager.shared.customerInfo
                let isTrial = customerInfoForTracking?.entitlements["pro"]?.periodType == .trial
                await MainActor.run {
                    MixpanelManager.shared.trackPurchase(
                        productId: productId,
                        price: price,
                        currency: currency,
                        isTrial: isTrial
                    )
                }

                return .purchased
            }
        } catch let error as ErrorCode {
            if error == .paymentPendingError {
                return .pending
            } else {
                return .failed(error)
            }
        } catch {
            return .failed(error)
        }
    }

    // MARK: - Handle Restores

    func restorePurchases() async -> RestorationResult {
        do {
            _ = try await Purchases.shared.restorePurchases()
            await RevenueCatManager.shared.refreshCustomerInfo(forceServerFetch: true)
            return .restored
        } catch {
            return .failed(error)
        }
    }
}
