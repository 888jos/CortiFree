//
//  RevenueCatManager.swift
//  CortiFree
//
//  Created by Claude Code on 14/01/2026.
//

import Foundation
import RevenueCat
import Combine
import FirebaseFirestore
import FirebaseAuth

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
    /// True once we've received at least one customerInfo response from RevenueCat
    @Published var isPremiumStatusReady: Bool = false

    // MARK: - Constants
    // Entitlement ID - must match Superwall and App Store Connect
    private let entitlementID = "pro"

    // Product IDs - must match App Store Connect exactly
    private let monthlyProductID = "cortifree_monthly"
    private let yearlyProductID = "cortifree_year"

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

        // Premium is NOT considered active until identifyUser() or getCustomerInfo() returns
        // isPremiumStatusReady stays false until then
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
            print("✅ User identified successfully with UID: \(userId)")
            logDiagnostics(context: "After identifyUser")
            #endif

            // Load offerings AFTER login so they're tied to the correct user
            await loadCurrentOffering()
        } catch {
            #if DEBUG
            print("⚠️ Failed to identify user: \(error.localizedDescription)")
            #endif
        }
    }

    /// Logout current user from RevenueCat
    /// Resets ALL premium state — no local cache survives logout
    func logout() async {
        #if DEBUG
        print("🔧 Logging out user from RevenueCat")
        #endif

        // Reset all local state IMMEDIATELY before async call
        await MainActor.run {
            self.customerInfo = nil
            self.hasActiveSubscription = false
            self.hasPremiumEntitlement = false
            self.isPremiumStatusReady = false
            self.currentOffering = nil
        }

        do {
            let customerInfo = try await Purchases.shared.logOut()
            await MainActor.run {
                self.customerInfo = customerInfo
                self.updateSubscriptionStatus()
            }
            #if DEBUG
            print("✅ User logged out successfully — AppUserID: \(Purchases.shared.appUserID)")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to logout user: \(error.localizedDescription)")
            #endif
            // Even on failure, ensure premium is false
            await MainActor.run {
                self.hasPremiumEntitlement = false
                self.hasActiveSubscription = false
                self.isPremiumStatusReady = true
            }
        }
    }

    // MARK: - Customer Info

    /// Refresh customer info from RevenueCat
    /// - Parameter forceServerFetch: When true, bypasses cache and fetches from server
    func refreshCustomerInfo(forceServerFetch: Bool = false) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let customerInfo: CustomerInfo
            if forceServerFetch {
                customerInfo = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
                #if DEBUG
                print("🔄 Customer info fetched from SERVER (forced)")
                #endif
            } else {
                customerInfo = try await Purchases.shared.customerInfo()
                #if DEBUG
                print("✅ Customer info refreshed (may be cached)")
                #endif
            }
            await MainActor.run {
                self.customerInfo = customerInfo
                self.updateSubscriptionStatus()
            }
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
    /// This is the SINGLE SOURCE OF TRUTH for premium access
    private func updateSubscriptionStatus() {
        guard let customerInfo = customerInfo else {
            hasActiveSubscription = false
            hasPremiumEntitlement = false
            isPremiumStatusReady = true // We know: no info = no premium
            return
        }

        // Check if user has any active entitlements
        hasActiveSubscription = !customerInfo.entitlements.active.isEmpty

        // STRICT CHECK: only entitlements["pro"]?.isActive == true grants premium
        hasPremiumEntitlement = customerInfo.entitlements[entitlementID]?.isActive == true

        // Mark that we've received a definitive answer from RevenueCat
        isPremiumStatusReady = true

        // Sync isPaid status to Firestore
        if let userId = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            db.collection("users").document(userId)
                .setData(["isPaid": hasPremiumEntitlement], merge: true)
        }

        #if DEBUG
        print("📊 Subscription Status:")
        print("   - AppUserID: \(Purchases.shared.appUserID)")
        print("   - Has Active Subscription: \(hasActiveSubscription)")
        print("   - Has Premium Entitlement (\(entitlementID)): \(hasPremiumEntitlement)")
        print("   - Active Entitlements: \(Array(customerInfo.entitlements.active.keys))")
        if hasPremiumEntitlement {
            print("   - Premium Expiration: \(customerInfo.entitlements[entitlementID]?.expirationDate?.description ?? "N/A")")
            print("   - Product ID: \(customerInfo.entitlements[entitlementID]?.productIdentifier ?? "N/A")")
        }
        #endif
    }

    // MARK: - Price Display Properties (for UI)

    /// Monthly package from current offering
    var monthlyPackage: Package? {
        currentOffering?.package(identifier: "$rc_monthly") ?? currentOffering?.monthly
    }

    /// Yearly package — 3d trial (original)
    var yearlyPackage: Package? {
        currentOffering?.package(identifier: "$rc_annual") ?? currentOffering?.annual
    }

    /// Yearly package — 7d trial (A/B test variant)
    var yearlyV2Package: Package? {
        currentOffering?.package(identifier: "cortifree_yearly_v2")
    }

    /// Exit intent offer — 30€ 3d trial
    var exitIntentV1Package: Package? {
        currentOffering?.package(identifier: "cortifree_offer_v1")
    }

    /// Exit intent offer — 30€ 7d trial
    var exitIntentV2Package: Package? {
        currentOffering?.package(identifier: "cortifree_offer_v2")
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
            let (_, _, _) = try await Purchases.shared.purchase(package: package)

            // FORCE SERVER REFRESH — never trust the customerInfo returned by purchase()
            let refreshedInfo = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)

            await MainActor.run {
                self.customerInfo = refreshedInfo
                self.updateSubscriptionStatus()
            }

            #if DEBUG
            print("✅ Purchase successful!")
            #endif

            // NE PAS tracker ici — le tracking est fait au niveau du call site (vue)
            // pour éviter le double-fire (RevenueCatManager + NativePaywallView)

            return refreshedInfo
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
            let _ = try await Purchases.shared.restorePurchases()

            // FORCE SERVER REFRESH — never trust restore's returned customerInfo
            let refreshedInfo = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)

            await MainActor.run {
                self.customerInfo = refreshedInfo
                self.updateSubscriptionStatus()
            }

            #if DEBUG
            print("✅ Purchases restored successfully")
            #endif

            return refreshedInfo
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

    // MARK: - Diagnostics

    /// Log full subscription diagnostic info — call when paywall opens
    func logDiagnostics(context: String = "Paywall") {
        #if DEBUG
        print("🔍 [\(context)] RevenueCat Diagnostics:")
        print("   - AppUserID: \(Purchases.shared.appUserID)")
        print("   - Is Anonymous: \(Purchases.shared.isAnonymous)")
        print("   - Premium Status Ready: \(isPremiumStatusReady)")
        print("   - Has Premium Entitlement (\(entitlementID)): \(hasPremiumEntitlement)")
        print("   - Has Active Subscription: \(hasActiveSubscription)")
        if let info = customerInfo {
            print("   - Active Entitlements: \(Array(info.entitlements.active.keys))")
            for (key, entitlement) in info.entitlements.active {
                print("     → \(key): productID=\(entitlement.productIdentifier), expires=\(entitlement.expirationDate?.description ?? "never")")
            }
        } else {
            print("   - CustomerInfo: nil (not yet loaded)")
        }
        #endif
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
