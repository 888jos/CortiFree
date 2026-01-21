//
//  RevenueCatManager.swift
//  CortiFree
//
//  Created by Claude Code on 14/01/2026.
//

import Foundation
import RevenueCat
import Combine

/// Centralized manager for RevenueCat SDK operations
/// Handles subscription management, entitlement checking, and customer info
@MainActor
class RevenueCatManager: ObservableObject {

    // MARK: - Singleton
    static let shared = RevenueCatManager()

    // MARK: - Published Properties
    @Published var customerInfo: CustomerInfo?
    @Published var hasActiveSubscription: Bool = false
    @Published var hasPremiumEntitlement: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentOffering: Offering?

    // MARK: - Constants
    private let entitlementID = "CortiFree Premium"

    // Monthly and Yearly product identifiers
    private let monthlyProductID = "monthly"
    private let yearlyProductID = "yearly"

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    private init() {
        #if DEBUG
        print("🔧 RevenueCatManager initialized")
        #endif
    }

    // MARK: - Configuration

    /// Configure RevenueCat SDK with API key
    /// Should be called early in app lifecycle, ideally in AppDelegate
    func configure() {
        #if DEBUG
        Purchases.logLevel = .debug
        print("🔧 Configuring RevenueCat SDK with API key")
        #endif

        Purchases.configure(withAPIKey: APIConfig.shared.revenueCatAPIKey)

        // Start observing customer info changes
        startObservingCustomerInfo()

        // Fetch initial customer info
        Task {
            await refreshCustomerInfo()
            await loadCurrentOffering()
        }
    }

    // MARK: - User Identification

    /// Identify user with RevenueCat
    /// Call this after user authentication with Firebase
    func identifyUser(userId: String) async {
        #if DEBUG
        print("🔧 Identifying user with RevenueCat: \(userId)")
        #endif

        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userId)
            await MainActor.run {
                self.customerInfo = customerInfo
                self.updateSubscriptionStatus()
            }
            #if DEBUG
            print("✅ User identified successfully")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to identify user: \(error.localizedDescription)")
            #endif
        }
    }

    /// Logout current user from RevenueCat
    func logout() async {
        #if DEBUG
        print("🔧 Logging out user from RevenueCat")
        #endif

        do {
            let customerInfo = try await Purchases.shared.logOut()
            await MainActor.run {
                self.customerInfo = customerInfo
                self.updateSubscriptionStatus()
            }
            #if DEBUG
            print("✅ User logged out successfully")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to logout user: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Customer Info

    /// Refresh customer info from RevenueCat
    func refreshCustomerInfo() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await MainActor.run {
                self.customerInfo = customerInfo
                self.updateSubscriptionStatus()
            }
            #if DEBUG
            print("✅ Customer info refreshed")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to refresh customer info: \(error.localizedDescription)")
            #endif
        }
    }

    /// Start observing customer info changes in real-time
    private func startObservingCustomerInfo() {
        Task {
            for try await customerInfo in Purchases.shared.customerInfoStream {
                await MainActor.run {
                    self.customerInfo = customerInfo
                    self.updateSubscriptionStatus()
                    #if DEBUG
                    print("🔄 Customer info updated via stream")
                    #endif
                }
            }
        }
    }

    /// Update subscription status based on current customer info
    private func updateSubscriptionStatus() {
        guard let customerInfo = customerInfo else {
            hasActiveSubscription = false
            hasPremiumEntitlement = false
            return
        }

        // Check if user has any active entitlements
        hasActiveSubscription = !customerInfo.entitlements.active.isEmpty

        // Check specifically for premium entitlement
        hasPremiumEntitlement = customerInfo.entitlements[entitlementID]?.isActive == true

        #if DEBUG
        print("📊 Subscription Status:")
        print("   - Has Active Subscription: \(hasActiveSubscription)")
        print("   - Has Premium Entitlement: \(hasPremiumEntitlement)")
        if hasPremiumEntitlement {
            print("   - Premium Expiration: \(customerInfo.entitlements[entitlementID]?.expirationDate?.description ?? "N/A")")
        }
        #endif
    }

    // MARK: - Price Display Properties (for UI)

    /// Monthly package from current offering
    var monthlyPackage: Package? {
        currentOffering?.package(identifier: "$rc_monthly") ?? currentOffering?.monthly
    }

    /// Yearly package from current offering
    var yearlyPackage: Package? {
        currentOffering?.package(identifier: "$rc_annual") ?? currentOffering?.annual
    }

    /// Monthly display price (e.g., "9,99 €")
    var monthlyDisplayPrice: String {
        monthlyPackage?.storeProduct.localizedPriceString ?? "—"
    }

    /// Yearly display price (e.g., "39,99 €")
    var yearlyDisplayPrice: String {
        yearlyPackage?.storeProduct.localizedPriceString ?? "—"
    }

    /// Monthly equivalent for yearly subscription
    var yearlyMonthlyEquivalent: String {
        guard let yearly = yearlyPackage else { return "—" }
        let monthlyEquivalent = yearly.storeProduct.price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearly.storeProduct.priceFormatter?.locale ?? Locale.current
        return formatter.string(from: monthlyEquivalent as NSNumber) ?? "—"
    }

    /// Daily equivalent for yearly subscription
    var yearlyDailyEquivalent: String {
        guard let yearly = yearlyPackage else { return "—" }
        let dailyEquivalent = yearly.storeProduct.price / 365
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearly.storeProduct.priceFormatter?.locale ?? Locale.current
        return formatter.string(from: dailyEquivalent as NSNumber) ?? "—"
    }

    /// Savings percentage of yearly vs monthly
    var yearlySavingsPercentage: Int {
        guard let monthly = monthlyPackage, let yearly = yearlyPackage else { return 0 }
        let monthlyTotal = monthly.storeProduct.price * 12
        guard monthlyTotal > 0 else { return 0 }
        let savings = (monthlyTotal - yearly.storeProduct.price) / monthlyTotal * 100
        return Int(NSDecimalNumber(decimal: savings).doubleValue.rounded())
    }

    /// Free trial period for yearly (if available)
    var yearlyTrialPeriod: String? {
        guard let yearly = yearlyPackage,
              let intro = yearly.storeProduct.introductoryDiscount,
              intro.paymentMode == .freeTrial else {
            return nil
        }

        let value = intro.subscriptionPeriod.value
        let isFr = Locale.preferredLanguages.first?.hasPrefix("fr") ?? false

        switch intro.subscriptionPeriod.unit {
        case .day:
            return "\(value) " + (isFr ? (value == 1 ? "jour" : "jours") : (value == 1 ? "day" : "days"))
        case .week:
            return "\(value) " + (isFr ? (value == 1 ? "semaine" : "semaines") : (value == 1 ? "week" : "weeks"))
        case .month:
            return "\(value) " + (isFr ? "mois" : (value == 1 ? "month" : "months"))
        case .year:
            return "\(value) " + (isFr ? (value == 1 ? "an" : "ans") : (value == 1 ? "year" : "years"))
        @unknown default:
            return nil
        }
    }

    /// Whether products are loaded and ready
    var productsLoaded: Bool {
        currentOffering != nil && !(currentOffering?.availablePackages.isEmpty ?? true)
    }

    // MARK: - Offerings

    /// Load current offering from RevenueCat
    func loadCurrentOffering() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            await MainActor.run {
                self.currentOffering = offerings.current
            }

            #if DEBUG
            if let offering = offerings.current {
                print("✅ Current offering loaded: \(offering.identifier)")
                print("   Available packages:")
                for package in offering.availablePackages {
                    print("   - \(package.identifier): \(package.storeProduct.localizedPriceString)")
                }
            } else {
                print("⚠️ No current offering available")
            }
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to load offerings: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Purchase

    /// Purchase a package
    func purchase(package: Package) async throws -> CustomerInfo {
        #if DEBUG
        print("🛒 Attempting to purchase: \(package.identifier)")
        #endif

        isLoading = true
        defer { isLoading = false }

        do {
            let (_, customerInfo, _) = try await Purchases.shared.purchase(package: package)

            await MainActor.run {
                self.customerInfo = customerInfo
                self.updateSubscriptionStatus()
            }

            #if DEBUG
            print("✅ Purchase successful!")
            #endif

            // Track purchase with Mixpanel
            MixpanelManager.shared.trackPurchase(
                productId: package.storeProduct.productIdentifier,
                price: package.storeProduct.price as Decimal,
                currency: package.storeProduct.priceFormatter?.currencyCode ?? "USD"
            )

            return customerInfo
        } catch {
            #if DEBUG
            print("⚠️ Purchase failed: \(error.localizedDescription)")
            #endif
            throw error
        }
    }

    /// Restore purchases
    func restorePurchases() async throws -> CustomerInfo {
        #if DEBUG
        print("🔄 Restoring purchases")
        #endif

        isLoading = true
        defer { isLoading = false }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()

            await MainActor.run {
                self.customerInfo = customerInfo
                self.updateSubscriptionStatus()
            }

            #if DEBUG
            print("✅ Purchases restored successfully")
            #endif

            return customerInfo
        } catch {
            #if DEBUG
            print("⚠️ Restore failed: \(error.localizedDescription)")
            #endif
            throw error
        }
    }

    // MARK: - Entitlement Helpers

    /// Check if user has premium access
    func checkPremiumAccess() -> Bool {
        return hasPremiumEntitlement
    }

    /// Get subscription expiration date
    func getSubscriptionExpirationDate() -> Date? {
        guard let entitlement = customerInfo?.entitlements[entitlementID] else {
            return nil
        }
        return entitlement.expirationDate
    }

    /// Get subscription type (monthly or yearly)
    func getSubscriptionType() -> String? {
        guard let entitlement = customerInfo?.entitlements[entitlementID],
              entitlement.isActive else {
            return nil
        }

        let productId = entitlement.productIdentifier

        if productId.contains("monthly") || productId == monthlyProductID {
            return "monthly"
        } else if productId.contains("yearly") || productId == yearlyProductID {
            return "yearly"
        }

        return nil
    }

    /// Check if subscription will renew
    func willRenew() -> Bool {
        guard let entitlement = customerInfo?.entitlements[entitlementID] else {
            return false
        }
        return entitlement.willRenew
    }

    // MARK: - Promotional Offers

    /// Check if user is eligible for introductory offer
    func isEligibleForIntro() async -> Bool {
        guard let offering = currentOffering else {
            return false
        }

        // Check if any package has introductory pricing
        for package in offering.availablePackages {
            if package.storeProduct.introductoryDiscount != nil {
                return true
            }
        }

        return false
    }
}
