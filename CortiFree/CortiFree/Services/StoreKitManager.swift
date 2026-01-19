//
//  StoreKitManager.swift
//  CortiFree
//
//  Manages In-App Purchases using StoreKit 2
//  Connects to real App Store Connect products (not StoreKit Configuration)
//
//  Guidelines Apple respectées:
//  - Utilise displayPrice pour afficher les vrais prix localisés
//  - Aucun prix hardcodé dans l'UI
//  - Gestion complète du cycle de vie des transactions
//

import StoreKit
import Foundation

/// Manager singleton pour gérer les achats in-app avec StoreKit 2
/// Utilise les vrais produits App Store Connect
@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    // MARK: - Product IDs (App Store Connect)

    /// Identifiants des produits configurés sur App Store Connect
    static let yearlyProductID = "cortifree.yearly.sub"
    static let monthlyProductID = "cortifree.monthly.sub"

    private static let allProductIDs: Set<String> = [
        yearlyProductID,
        monthlyProductID
    ]

    // MARK: - Published Properties

    /// Liste des produits chargés depuis l'App Store
    @Published private(set) var products: [Product] = []

    /// IDs des produits actuellement achetés/actifs
    @Published private(set) var purchasedProductIDs: Set<String> = []

    /// Indicateur de chargement
    @Published private(set) var isLoading = false

    /// Message d'erreur éventuel
    @Published private(set) var errorMessage: String?

    /// État premium de l'utilisateur
    @Published private(set) var isPremium: Bool = false

    /// Indique si les produits ont été chargés avec succès
    @Published private(set) var productsLoaded: Bool = false

    // MARK: - Computed Properties

    /// Vérifie si l'utilisateur a un abonnement actif
    var isSubscribed: Bool {
        !purchasedProductIDs.isEmpty
    }

    /// Produit abonnement annuel
    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyProductID }
    }

    /// Produit abonnement mensuel
    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductID }
    }

    // MARK: - Dynamic Price Display (Guidelines Apple)

    /// Prix mensuel formaté (ex: "9,99 €")
    var monthlyDisplayPrice: String {
        monthlyProduct?.displayPrice ?? "—"
    }

    /// Prix annuel formaté (ex: "39,99 €")
    var yearlyDisplayPrice: String {
        yearlyProduct?.displayPrice ?? "—"
    }

    /// Prix mensuel équivalent pour l'abonnement annuel
    var yearlyMonthlyEquivalent: String {
        guard let yearly = yearlyProduct else { return "—" }
        let monthlyEquivalent = yearly.price / 12
        return yearly.priceFormatStyle.format(monthlyEquivalent)
    }

    /// Prix journalier pour l'abonnement annuel
    var yearlyDailyEquivalent: String {
        guard let yearly = yearlyProduct else { return "—" }
        let dailyEquivalent = yearly.price / 365
        return yearly.priceFormatStyle.format(dailyEquivalent)
    }

    /// Pourcentage d'économie de l'annuel vs mensuel
    var yearlySavingsPercentage: Int {
        guard let monthly = monthlyProduct, let yearly = yearlyProduct else { return 0 }
        let monthlyTotal = monthly.price * 12
        guard monthlyTotal > 0 else { return 0 }
        let savings = (monthlyTotal - yearly.price) / monthlyTotal * 100
        return Int(NSDecimalNumber(decimal: savings).doubleValue.rounded())
    }

    /// Période d'essai gratuit pour l'abonnement annuel (si disponible)
    var yearlyTrialPeriod: String? {
        guard let yearly = yearlyProduct,
              let subscription = yearly.subscription,
              let introOffer = subscription.introductoryOffer,
              introOffer.paymentMode == .freeTrial else {
            return nil
        }

        let period = introOffer.period
        let value = period.value

        switch period.unit {
        case .day:
            return "\(value) " + (value == 1 ? "jour" : "jours")
        case .week:
            return "\(value) " + (value == 1 ? "semaine" : "semaines")
        case .month:
            return "\(value) mois"
        case .year:
            return "\(value) " + (value == 1 ? "an" : "ans")
        @unknown default:
            return nil
        }
    }

    // MARK: - Private Properties

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    private init() {
        // Démarrer l'écoute des transactions en arrière-plan
        updateListenerTask = listenForTransactions()

        // Charger les produits et vérifier l'état des achats
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products from App Store

    /// Charge les produits depuis App Store Connect
    func loadProducts() async {
        guard !isLoading else {
            #if DEBUG
            print("⚠️ StoreKit: loadProducts() appelé alors qu'un chargement est déjà en cours")
            #endif
            return
        }

        isLoading = true
        errorMessage = nil
        productsLoaded = false

        #if DEBUG
        print("🔄 StoreKit: Début du chargement des produits...")
        print("   📋 Product IDs demandés: \(Self.allProductIDs)")
        print("   🌐 Environnement: \(AppStore.canMakePayments ? "Paiements autorisés" : "⚠️ PAIEMENTS DÉSACTIVÉS")")
        #endif

        do {
            // Requête vers l'App Store pour récupérer les vrais produits
            #if DEBUG
            print("   🔍 Envoi de la requête vers App Store Connect...")
            #endif

            products = try await Product.products(for: Self.allProductIDs)

            #if DEBUG
            print("   ✅ Réponse reçue: \(products.count) produit(s)")

            // Si aucun produit n'est retourné, diagnostiquer
            if products.isEmpty {
                print("   ⚠️ AUCUN PRODUIT RETOURNÉ - Vérifications nécessaires:")
                print("      1. Les Product IDs existent-ils dans App Store Connect?")
                print("         • \(Self.yearlyProductID)")
                print("         • \(Self.monthlyProductID)")
                print("      2. Les produits sont-ils en statut 'Ready to Submit'?")
                print("      3. Êtes-vous connecté avec un compte Sandbox?")
                print("      4. Les Product IDs correspondent-ils exactement (casse sensible)?")
            }
            #endif

            // Trier: annuel en premier
            products.sort { product1, product2 in
                if product1.id == Self.yearlyProductID { return true }
                if product2.id == Self.yearlyProductID { return false }
                return product1.price < product2.price
            }

            productsLoaded = !products.isEmpty

            #if DEBUG
            print("📦 StoreKit: Chargé \(products.count) produits depuis App Store Connect")
            for product in products {
                print("   ✓ \(product.id): \(product.displayPrice)")
                print("     └─ Prix brut: \(product.price)")
                print("     └─ Devise: \(product.priceFormatStyle.currencyCode ?? "N/A")")
                if let subscription = product.subscription {
                    print("     └─ Période: \(subscription.subscriptionPeriod.value) \(subscription.subscriptionPeriod.unit)")
                    if let intro = subscription.introductoryOffer {
                        print("     └─ Offre intro: \(intro.period.value) \(intro.period.unit) (\(intro.paymentMode))")
                    }
                }
            }
            #endif
        } catch {
            errorMessage = error.localizedDescription
            productsLoaded = false

            #if DEBUG
            print("❌ StoreKit: ERREUR de chargement des produits")
            print("   📝 Description: \(error.localizedDescription)")
            print("   🔍 Type d'erreur: \(type(of: error))")
            print("   💡 Erreur complète: \(error)")

            // Erreurs StoreKit courantes
            if let storeError = error as? StoreKitError {
                print("   🛠️ StoreKitError détecté:")
                switch storeError {
                case .networkError:
                    print("      → Problème de connexion réseau")
                case .userCancelled:
                    print("      → Utilisateur a annulé")
                case .notAvailableInStorefront:
                    print("      → Produits non disponibles dans ce storefront")
                case .notEntitled:
                    print("      → Pas de droit d'accès")
                case .unknown:
                    print("      → Erreur inconnue")
                @unknown default:
                    print("      → Erreur non gérée: \(storeError)")
                }
            }

            print("   ⚠️ DIAGNOSTICS RECOMMANDÉS:")
            print("      • Vérifier la connexion Internet")
            print("      • Se déconnecter/reconnecter du compte Sandbox")
            print("      • Vérifier que les produits existent dans App Store Connect")
            print("      • Vérifier que les Product IDs correspondent exactement")
            #endif
        }

        isLoading = false

        #if DEBUG
        print("🏁 StoreKit: Fin du chargement - isLoading: false, productsLoaded: \(productsLoaded)")
        #endif
    }

    // MARK: - Purchase

    /// Achète un produit par son ID
    func purchase(_ productID: String) async -> PurchaseResult {
        #if DEBUG
        print("🛒 StoreKit: Tentative d'achat pour Product ID: \(productID)")
        print("   📦 Produits disponibles: \(products.map { $0.id })")
        print("   🔢 Nombre de produits: \(products.count)")
        #endif

        guard let product = products.first(where: { $0.id == productID }) else {
            errorMessage = "Produit non trouvé"
            #if DEBUG
            print("❌ StoreKit: Produit '\(productID)' NON TROUVÉ dans la liste des produits chargés")
            print("   ⚠️ Raison probable: loadProducts() n'a pas réussi à charger les produits")
            print("   💡 productsLoaded: \(productsLoaded)")
            #endif
            return .failed(StoreError.productNotFound)
        }

        #if DEBUG
        print("   ✅ Produit trouvé: \(product.displayName) - \(product.displayPrice)")
        #endif

        return await purchase(product)
    }

    /// Achète un produit
    func purchase(_ product: Product) async -> PurchaseResult {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Mettre à jour l'état des achats
                await updatePurchasedProducts()

                // Finaliser la transaction
                await transaction.finish()

                // Tracking analytics
                MixpanelManager.shared.trackPurchase(
                    productId: product.id,
                    price: product.price as Decimal,
                    currency: product.priceFormatStyle.currencyCode ?? "EUR"
                )

                // SKAN Conversion Value Update (iOS 14.5+)
                if #available(iOS 16.1, *) {
                    // For paid subscriptions (high value = 63)
                    SKAdNetwork.updatePostbackConversionValue(
                        63, // Max value for paid subscription
                        coarseValue: .high,
                        lockWindow: false
                    ) { error in
                        if let error = error {
                            print("❌ SKAN update error: \(error.localizedDescription)")
                        } else {
                            print("✅ SKAN conversion value updated: 63 (high)")
                            MixpanelManager.shared.track(
                                event: "skan_conversion_value_updated",
                                properties: [
                                    "value": 63,
                                    "coarse": "high",
                                    "product_id": product.id
                                ]
                            )
                        }
                    }
                } else if #available(iOS 14.0, *) {
                    // iOS 14-16: Legacy SKAN
                    SKAdNetwork.updateConversionValue(63)
                    print("✅ SKAN (legacy) conversion value updated: 63")
                }

                // Update subscription status in Mixpanel
                let subscriptionType: MixpanelManager.SubscriptionType = product.id.contains("yearly") ? .yearly : .monthly
                MixpanelManager.shared.updateSubscriptionStatus(
                    status: .trial, // Initially trial (3 days)
                    type: subscriptionType,
                    expiryDate: transaction.expirationDate
                )

                // Save first subscription date if first time
                if UserDefaults.standard.object(forKey: "first_subscription_date") == nil {
                    UserDefaults.standard.set(Date(), forKey: "first_subscription_date")
                    print("✅ First subscription date saved")
                }

                // Notifier le changement d'état premium
                NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)

                #if DEBUG
                print("✅ StoreKit: Achat réussi pour \(product.id)")
                #endif

                isLoading = false
                return .success

            case .userCancelled:
                #if DEBUG
                print("⚠️ StoreKit: Achat annulé par l'utilisateur")
                #endif
                isLoading = false
                return .cancelled

            case .pending:
                #if DEBUG
                print("⏳ StoreKit: Achat en attente (Ask to Buy)")
                #endif
                isLoading = false
                return .pending

            @unknown default:
                isLoading = false
                return .failed(StoreError.purchaseFailed)
            }
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ StoreKit: Erreur d'achat - \(error)")
            #endif
            isLoading = false
            return .failed(error)
        }
    }

    // MARK: - Restore Purchases

    /// Restaure les achats précédents
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            // Synchroniser avec l'App Store
            try await AppStore.sync()

            // Mettre à jour l'état des achats
            await updatePurchasedProducts()

            // Notifier le changement
            NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)

            #if DEBUG
            print("🔄 StoreKit: Restauration terminée. Actifs: \(purchasedProductIDs)")
            #endif

            isLoading = false
            return !purchasedProductIDs.isEmpty
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ StoreKit: Erreur de restauration - \(error)")
            #endif
            isLoading = false
            return false
        }
    }

    // MARK: - Update Purchased Products

    /// Met à jour la liste des produits achetés actifs
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        var latestTransaction: Transaction?

        // Parcourir toutes les transactions actives
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Vérifier que la transaction n'est pas révoquée
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                    latestTransaction = transaction
                }
            } catch {
                #if DEBUG
                print("❌ StoreKit: Échec de vérification d'une transaction")
                #endif
            }
        }

        purchasedProductIDs = purchased
        isPremium = !purchased.isEmpty

        // Sauvegarder dans UserDefaults pour accès synchrone
        UserDefaults.standard.set(isPremium, forKey: "isSubscribed")
        if let firstProductID = purchased.first {
            UserDefaults.standard.set(firstProductID, forKey: "subscriptionProductID")
        }

        // Update subscription status in Mixpanel
        if isPremium, let transaction = latestTransaction {
            // Determine if trial or active
            let isTrial = isInTrialPeriod(transaction: transaction)
            let status: MixpanelManager.SubscriptionStatus = isTrial ? .trial : .active

            // Determine subscription type
            let subscriptionType: MixpanelManager.SubscriptionType = transaction.productID.contains("yearly") ? .yearly : .monthly

            MixpanelManager.shared.updateSubscriptionStatus(
                status: status,
                type: subscriptionType,
                expiryDate: transaction.expirationDate
            )
        } else {
            // No active subscription
            MixpanelManager.shared.updateSubscriptionStatus(
                status: .expired,
                type: nil,
                expiryDate: nil
            )
        }

        #if DEBUG
        print("📋 StoreKit: État mis à jour - Premium: \(isPremium), Abonnements: \(purchased)")
        #endif
    }

    /// Check if transaction is still in trial period (3 days)
    private func isInTrialPeriod(transaction: Transaction) -> Bool {
        let purchaseDate = transaction.purchaseDate // purchaseDate is not optional in Transaction

        let trialDurationDays = 3
        let daysSincePurchase = Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0

        return daysSincePurchase <= trialDurationDays
    }

    // MARK: - Transaction Listener

    /// Écoute les mises à jour de transactions en arrière-plan
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }

                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()

                    // Notifier le changement
                    await MainActor.run {
                        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
                    }

                    #if DEBUG
                    print("🔔 StoreKit: Transaction mise à jour - \(transaction.productID)")
                    #endif
                } catch {
                    #if DEBUG
                    print("❌ StoreKit: Échec de vérification de transaction")
                    #endif
                }
            }
        }
    }

    // MARK: - Verification

    /// Vérifie la signature d'une transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            #if DEBUG
            print("❌ StoreKit: Transaction non vérifiée - \(error)")
            #endif
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Subscription Info

    /// Récupère la date d'expiration de l'abonnement actif
    func getSubscriptionExpirationDate() async -> Date? {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    return transaction.expirationDate
                }
            } catch {
                continue
            }
        }
        return nil
    }

    /// Récupère les informations détaillées de l'abonnement actif
    func getActiveSubscriptionInfo() async -> SubscriptionInfo? {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil,
                   let expirationDate = transaction.expirationDate {
                    return SubscriptionInfo(
                        productID: transaction.productID,
                        purchaseDate: transaction.purchaseDate,
                        expirationDate: expirationDate,
                        isActive: expirationDate > Date()
                    )
                }
            } catch {
                continue
            }
        }
        return nil
    }

    // MARK: - Helper Methods

    /// Récupère un produit par son ID
    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    /// Recharge les produits si nécessaire
    func reloadProductsIfNeeded() async {
        if products.isEmpty {
            await loadProducts()
        }
    }
}

// MARK: - Supporting Types

/// Résultat d'un achat
enum PurchaseResult {
    case success
    case cancelled
    case pending
    case failed(Error)

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

/// Informations sur un abonnement actif
struct SubscriptionInfo {
    let productID: String
    let purchaseDate: Date
    let expirationDate: Date
    let isActive: Bool

    var isYearly: Bool {
        productID == StoreKitManager.yearlyProductID
    }

    var isMonthly: Bool {
        productID == StoreKitManager.monthlyProductID
    }
}

/// Erreurs StoreKit
enum StoreError: LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed
    case networkError

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "La vérification de l'achat a échoué"
        case .productNotFound:
            return "Produit non trouvé"
        case .purchaseFailed:
            return "L'achat a échoué"
        case .networkError:
            return "Erreur de connexion"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
}
