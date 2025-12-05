//
//  StoreKitManager.swift
//  CortiFree
//
//  Created by Claude on 03/12/2025.
//  Manages In-App Purchases using StoreKit 2
//

import StoreKit
import Foundation

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    // Product IDs from App Store Connect
    static let yearlyProductID = "cortifree.yearly.sub"
    static let monthlyProductID = "cortifree.monthly.sub"

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // Computed property to check if user has active subscription
    var isSubscribed: Bool {
        !purchasedProductIDs.isEmpty
    }

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIDs = [Self.yearlyProductID, Self.monthlyProductID]
            products = try await Product.products(for: productIDs)

            #if DEBUG
            print("📦 StoreKit: Loaded \(products.count) products")
            for product in products {
                print("   - \(product.id): \(product.displayPrice)")
            }
            #endif
        } catch {
            errorMessage = "Erreur de chargement des produits: \(error.localizedDescription)"
            #if DEBUG
            print("❌ StoreKit Error: \(error)")
            #endif
        }

        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ productID: String) async -> Bool {
        guard let product = products.first(where: { $0.id == productID }) else {
            errorMessage = "Produit non trouvé"
            #if DEBUG
            print("❌ StoreKit: Product '\(productID)' not found in loaded products: \(products.map { $0.id })")
            print("💡 Tip: Make sure StoreKit Configuration file is set in scheme and products are configured")
            #endif
            return false
        }

        return await purchase(product)
    }

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Update purchased products
                await updatePurchasedProducts()

                // Finish the transaction
                await transaction.finish()

                // Track purchase in Mixpanel
                MixpanelManager.shared.trackPurchase(
                    productId: product.id,
                    price: product.price as Decimal,
                    currency: product.priceFormatStyle.currencyCode ?? "EUR"
                )

                // Save subscription status
                UserDefaults.standard.set(true, forKey: "isSubscribed")
                UserDefaults.standard.set(product.id, forKey: "subscriptionProductID")

                #if DEBUG
                print("✅ StoreKit: Purchase successful for \(product.id)")
                #endif

                isLoading = false
                return true

            case .userCancelled:
                #if DEBUG
                print("⚠️ StoreKit: User cancelled purchase")
                #endif
                isLoading = false
                return false

            case .pending:
                #if DEBUG
                print("⏳ StoreKit: Purchase pending (Ask to Buy?)")
                #endif
                isLoading = false
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            errorMessage = "Erreur d'achat: \(error.localizedDescription)"
            #if DEBUG
            print("❌ StoreKit Purchase Error: \(error)")
            #endif
            isLoading = false
            return false
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()

            #if DEBUG
            print("🔄 StoreKit: Purchases restored. Active: \(purchasedProductIDs)")
            #endif

            isLoading = false
            return !purchasedProductIDs.isEmpty
        } catch {
            errorMessage = "Erreur de restauration: \(error.localizedDescription)"
            #if DEBUG
            print("❌ StoreKit Restore Error: \(error)")
            #endif
            isLoading = false
            return false
        }
    }

    // MARK: - Update Purchased Products

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if subscription is still active
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                #if DEBUG
                print("❌ StoreKit: Failed to verify transaction")
                #endif
            }
        }

        purchasedProductIDs = purchased

        // Update UserDefaults
        let isSubscribed = !purchased.isEmpty
        UserDefaults.standard.set(isSubscribed, forKey: "isSubscribed")

        #if DEBUG
        print("📋 StoreKit: Current subscriptions: \(purchased)")
        #endif
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    #if DEBUG
                    print("❌ StoreKit: Transaction verification failed")
                    #endif
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Helper Methods

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    var yearlyProduct: Product? {
        product(for: Self.yearlyProductID)
    }

    var monthlyProduct: Product? {
        product(for: Self.monthlyProductID)
    }
}

// MARK: - Store Errors

enum StoreError: Error {
    case failedVerification
    case productNotFound
    case purchaseFailed
}
