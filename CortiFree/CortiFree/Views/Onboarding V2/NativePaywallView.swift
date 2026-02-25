//
//  NativePaywallView.swift
//  CortiFree
//
//  Native SwiftUI paywall using RevenueCat for purchases
//  Professional design matching app aesthetic
//

import SwiftUI
import RevenueCat

struct NativePaywallView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject private var rcManager = RevenueCatManager.shared

    @State private var selectedPlan: PlanType = .yearly
    @State private var enableTrialNotifications: Bool = true
    @State private var isPurchasing: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var currentReviewIndex: Int = 0

    private let reviewTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var onPurchaseComplete: (() -> Void)?

    enum PlanType {
        case monthly, yearly
    }

    var body: some View {
        ZStack {
            // PERFORMANCE: Static gradient background (no animations for better performance)
            LinearGradient(
                colors: [
                    Color(hex: "1F0140"), // Top - Purple deep
                    Color(hex: "0B011B"), // Middle - Very dark purple
                    Color(hex: "01000C")  // Bottom - Almost black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 20) { // PERFORMANCE: Use LazyVStack
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: {
                            HapticManager.light()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                    // Title
                    VStack(spacing: 8) {
                        Text("paywall.title".localized)
                            .font(.faroBold(28))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("paywall.subtitle".localized)
                            .font(.custom("Poppins-Regular", size: 15))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 28)

                    // Customer reviews carousel
                    ReviewsCarouselView(currentIndex: $currentReviewIndex)
                        .onReceive(reviewTimer) { _ in
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentReviewIndex = (currentReviewIndex + 1) % 4
                            }
                        }

                    // Product cards (side by side)
                    if rcManager.isLoading && !rcManager.productsLoaded {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.5)
                            .padding(.vertical, 60)
                    } else if rcManager.productsLoaded {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                // Yearly subscription (LEFT, with promo badge)
                                if let yearly = rcManager.yearlyPackage {
                                    PackageCard(
                                        title: "paywall.yearly".localized,
                                        price: yearly.storeProduct.localizedPriceString,
                                        period: String(format: "paywall.per_month_equivalent".localized, rcManager.yearlyMonthlyEquivalent),
                                        isSelected: selectedPlan == .yearly,
                                        showPromo: true,
                                        promoText: "paywall.save_70".localized,
                                        showTrial: rcManager.yearlyTrialPeriod != nil
                                    ) {
                                        HapticManager.light()
                                        selectedPlan = .yearly
                                    }
                                }

                                // Monthly subscription (RIGHT)
                                if let monthly = rcManager.monthlyPackage {
                                    PackageCard(
                                        title: "paywall.monthly".localized,
                                        price: monthly.storeProduct.localizedPriceString,
                                        period: "paywall.per_month".localized,
                                        isSelected: selectedPlan == .monthly,
                                        showPromo: false,
                                        showTrial: false
                                    ) {
                                        HapticManager.light()
                                        selectedPlan = .monthly
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    } else {
                        // Fallback: Show default pricing when products can't load
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                PackageCard(
                                    title: "paywall.yearly".localized,
                                    price: "39,99 €",
                                    period: String(format: "paywall.per_month_equivalent".localized, "3,33 €"),
                                    isSelected: selectedPlan == .yearly,
                                    showPromo: true,
                                    promoText: "paywall.save_70".localized,
                                    showTrial: true
                                ) {
                                    HapticManager.light()
                                    selectedPlan = .yearly
                                }

                                PackageCard(
                                    title: "paywall.monthly".localized,
                                    price: "9,99 €",
                                    period: "paywall.per_month".localized,
                                    isSelected: selectedPlan == .monthly,
                                    showPromo: false,
                                    showTrial: false
                                ) {
                                    HapticManager.light()
                                    selectedPlan = .monthly
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }

                    // Purchase button
                    Button(action: {
                        Task {
                            await purchaseSelectedProduct()
                        }
                    }) {
                        HStack(spacing: 12) {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Text(purchaseButtonText)
                                    .font(.custom("Poppins-Bold", size: 18))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "8B5CF6"), Color(hex: "7C3AED")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "8B5CF6").opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .disabled(isPurchasing)
                    .opacity(isPurchasing ? 0.7 : 1.0)
                    .padding(.horizontal, 24)

                    // Trial notification toggle - BELOW button
                    HStack(spacing: 12) {
                        Toggle(isOn: $enableTrialNotifications) {
                            Text("paywall.trial_notifications".localized)
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .tint(Color(hex: "8B5CF6"))
                    }
                    .padding(.horizontal, 32)

                    // Restore purchases
                    Button(action: {
                        Task {
                            await restorePurchases()
                        }
                    }) {
                        Text("paywall.restore_purchases".localized)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .underline()
                    }

                    // Legal links
                    HStack(spacing: 16) {
                        Button(action: {
                            LegalDocumentsHelper.openPrivacyPolicy()
                        }) {
                            Text("paywall.privacy_policy".localized)
                                .font(.custom("Poppins-Regular", size: 11))
                                .foregroundColor(.white.opacity(0.4))
                                .underline()
                        }

                        Text("•")
                            .foregroundColor(.white.opacity(0.4))

                        Button(action: {
                            LegalDocumentsHelper.openTerms()
                        }) {
                            Text("paywall.terms_of_use".localized)
                                .font(.custom("Poppins-Regular", size: 11))
                                .foregroundColor(.white.opacity(0.4))
                                .underline()
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .alert("paywall.error_title".localized, isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            // Wait for premium status to be determined before showing anything interactive
            // Prevents Apple Review edge case where state is still indeterminate
            while !rcManager.isPremiumStatusReady {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }

            // If already premium, dismiss immediately
            if rcManager.hasPremiumEntitlement {
                onPurchaseComplete?()
                dismiss()
                return
            }

            // Log full diagnostic info when paywall opens
            RevenueCatManager.shared.logDiagnostics(context: "NativePaywall opened")
            // Load offerings if not already loaded
            if !rcManager.productsLoaded {
                await rcManager.loadCurrentOffering()
            }
        }
    }

    // MARK: - Computed Properties

    private var selectedPackage: Package? {
        switch selectedPlan {
        case .yearly: return rcManager.yearlyPackage
        case .monthly: return rcManager.monthlyPackage
        }
    }

    private var purchaseButtonText: String {
        if selectedPlan == .yearly {
            return "paywall.start_trial".localized // "Start 3-Day Free Trial"
        } else {
            let price = rcManager.monthlyPackage?.storeProduct.localizedPriceString ?? "9,99 €"
            return String(format: "paywall.subscribe_for".localized, price)
        }
    }

    // MARK: - Purchase Actions

    private func purchaseSelectedProduct() async {
        isPurchasing = true
        HapticManager.medium()

        // Load offerings if not loaded
        if !rcManager.productsLoaded {
            await rcManager.loadCurrentOffering()
        }

        guard let package = selectedPackage else {
            errorMessage = "paywall.products_unavailable".localized
            showError = true
            isPurchasing = false
            return
        }

        do {
            // RevenueCat handles everything: purchase, receipt validation, entitlement activation
            let customerInfo = try await rcManager.purchase(package: package)

            // Détecter si c'est un trial : l'entitlement "pro" est en période d'essai
            let isTrial = customerInfo.entitlements["pro"]?.periodType == .trial

            // Track purchase avec Mixpanel + TikTok (StartTrial ou Subscribe selon le cas)
            MixpanelManager.shared.trackPurchase(
                productId: package.storeProduct.productIdentifier,
                price: package.storeProduct.price as Decimal,
                currency: package.storeProduct.priceFormatter?.currencyCode ?? "EUR",
                isTrial: isTrial
            )

            // Navigate ONLY if premium is confirmed by RevenueCat
            if rcManager.hasPremiumEntitlement {
                HapticManager.success()
                onPurchaseComplete?()
                dismiss()
            } else {
                #if DEBUG
                print("⚠️ Purchase completed but entitlement not active — active: \(Array(customerInfo.entitlements.active.keys))")
                #endif
                HapticManager.error()
                errorMessage = "paywall.purchase_pending".localized
                showError = true
            }
        } catch let error as NSError {
            // RevenueCat wraps cancellation as ErrorCode 1
            if error.domain == RevenueCat.ErrorCode.errorDomain,
               error.code == RevenueCat.ErrorCode.purchaseCancelledError.rawValue {
                // User cancelled — no error to show
                HapticManager.light()
            } else {
                HapticManager.error()
                errorMessage = error.localizedDescription
                showError = true
            }
        }

        isPurchasing = false
    }

    private func restorePurchases() async {
        isPurchasing = true
        HapticManager.light()

        do {
            let _ = try await rcManager.restorePurchases()
            HapticManager.success()

            // Check if user now has premium access
            if rcManager.hasPremiumEntitlement {
                onPurchaseComplete?()
                dismiss()
            } else {
                errorMessage = "paywall.no_purchases_found".localized
                showError = true
            }
        } catch {
            HapticManager.error()
            errorMessage = error.localizedDescription
            showError = true
        }

        isPurchasing = false
    }
}

// MARK: - Package Card (unified card for RC packages and fallback)

struct PackageCard: View {
    let title: String
    let price: String
    let period: String
    let isSelected: Bool
    let showPromo: Bool
    var promoText: String? = nil
    let showTrial: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Promo badge ABOVE the card
                if showPromo, let promo = promoText {
                    Text(promo)
                        .font(.custom("Poppins-Bold", size: 11))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "FF6B6B"))
                        .clipShape(Capsule())
                        .padding(.bottom, 8)
                } else {
                    // Spacer to keep cards aligned
                    Color.clear
                        .frame(height: 29)
                }

                // Card content
                VStack(spacing: 8) {
                    // Monthly/Yearly label top-left with purple bg
                    HStack {
                        Text(title)
                            .font(.custom("Poppins-SemiBold", size: 11))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "8B5CF6"))
                            .clipShape(Capsule())
                        Spacer()
                    }

                    Spacer()

                    // Price
                    Text(price)
                        .font(.faroBold(28))
                        .foregroundColor(.white)

                    // Billing period
                    Text(period)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // Free trial indicator
                    if showTrial {
                        Text("paywall.3_day_trial".localized)
                            .font(.custom("Poppins-SemiBold", size: 11))
                            .foregroundColor(Color(hex: "1F0140"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "A78BFA"), Color(hex: "8B5CF6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .padding(.top, 4)
                    }

                    Spacer()
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 180)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color(hex: "8B5CF6").opacity(0.3) : Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color(hex: "8B5CF6") : Color.white.opacity(0.2), lineWidth: isSelected ? 3 : 1)
                )
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reviews Carousel

struct ReviewsCarouselView: View {
    @Binding var currentIndex: Int

    private let reviews: [(text: String, name: String)] = [
        ("paywall.review_1", "paywall.review_1_name"),
        ("paywall.review_2", "paywall.review_2_name"),
        ("paywall.review_3", "paywall.review_3_name"),
        ("paywall.review_4", "paywall.review_4_name")
    ]

    var body: some View {
        VStack(spacing: 12) {
            TabView(selection: $currentIndex) {
                ForEach(0..<reviews.count, id: \.self) { index in
                    ReviewCardView(
                        text: reviews[index].text.localized,
                        name: reviews[index].name.localized
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 120)

            // Page dots
            HStack(spacing: 6) {
                ForEach(0..<reviews.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color(hex: "8B5CF6") : Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

struct ReviewCardView: View {
    let text: String
    let name: String

    var body: some View {
        VStack(spacing: 10) {
            // Stars
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "FFD700"))
                }
            }

            // Review text
            Text("\"\(text)\"")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            // Name
            Text("— \(name)")
                .font(.custom("Poppins-SemiBold", size: 13))
                .foregroundColor(Color(hex: "8B5CF6"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }
}

// MARK: - Preview

#Preview {
    NativePaywallView()
}
