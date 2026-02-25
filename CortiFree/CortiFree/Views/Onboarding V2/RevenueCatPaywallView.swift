//
//  RevenueCatPaywallView.swift
//  CortiFree
//
//  Created by Claude Code on 14/01/2026.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

/// Modern RevenueCat Paywall View
/// Uses RevenueCat's built-in paywall UI configured in the dashboard
struct RevenueCatPaywallView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var revenueCatManager = RevenueCatManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared

    let onPurchaseCompleted: (() -> Void)?
    let onRestoreCompleted: (() -> Void)?

    init(
        onPurchaseCompleted: (() -> Void)? = nil,
        onRestoreCompleted: (() -> Void)? = nil
    ) {
        self.onPurchaseCompleted = onPurchaseCompleted
        self.onRestoreCompleted = onRestoreCompleted
    }

    var body: some View {
        ZStack {
            // RevenueCat's built-in paywall view
            if revenueCatManager.hasPremiumEntitlement {
                // User already has premium - show success message
                successView
            } else {
                // Show RevenueCat paywall
                PaywallView()
                    .onPurchaseCompleted { customerInfo in
                        handlePurchaseCompleted(customerInfo)
                    }
                    .onRestoreCompleted { customerInfo in
                        handleRestoreCompleted(customerInfo)
                    }
                    .onPurchaseFailure { error in
                        handlePurchaseFailure(error)
                    }
                    .onRestoreFailure { error in
                        handleRestoreFailure(error)
                    }
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Success View
    private var successView: some View {
        ZStack {
            Color(hex: "1A1A2E")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text(languageManager.currentLanguage == .french ?
                     "Vous êtes Premium !" :
                     "You're Premium!")
                    .font(.faroBold(28))
                    .foregroundColor(.white)

                Text(languageManager.currentLanguage == .french ?
                     "Profitez de toutes les fonctionnalités de CortiFree" :
                     "Enjoy all CortiFree features")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button(action: {
                    dismiss()
                }) {
                    Text(languageManager.currentLanguage == .french ?
                         "Continuer" :
                         "Continue")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color(hex: "8B5CF6"))
                        )
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
            }
        }
    }

    // MARK: - Event Handlers

    private func handlePurchaseCompleted(_ customerInfo: CustomerInfo) {
        #if DEBUG
        print("✅ Purchase completed successfully")
        #endif

        // Track purchase avec détection trial vs paid
        if let entitlement = customerInfo.entitlements["pro"] {
            let isTrial = entitlement.periodType == .trial
            MixpanelManager.shared.trackPurchase(
                productId: entitlement.productIdentifier,
                price: 0, // Prix non disponible ici (paywall natif RevenueCat)
                currency: "EUR",
                isTrial: isTrial
            )
        }

        // Haptic feedback
        HapticManager.success()

        // Delay dismiss to show success state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onPurchaseCompleted?()
            dismiss()
        }
    }

    private func handleRestoreCompleted(_ customerInfo: CustomerInfo) {
        #if DEBUG
        print("✅ Restore completed successfully")
        #endif

        // Haptic feedback
        HapticManager.success()

        // Call completion handler
        onRestoreCompleted?()

        // Dismiss if user has active entitlement
        if customerInfo.entitlements["pro"]?.isActive == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
    }

    private func handlePurchaseFailure(_ error: Error) {
        #if DEBUG
        print("⚠️ Purchase failed: \(error.localizedDescription)")
        #endif

        // Show error haptic
        HapticManager.error()

        // Track error with Mixpanel
        MixpanelManager.shared.trackError(
            errorType: "PurchaseError",
            errorMessage: error.localizedDescription,
            screen: "RevenueCatPaywall",
            userAction: "Purchase"
        )
    }

    private func handleRestoreFailure(_ error: Error) {
        #if DEBUG
        print("⚠️ Restore failed: \(error.localizedDescription)")
        #endif

        // Show error haptic
        HapticManager.error()

        // Track error with Mixpanel
        MixpanelManager.shared.trackError(
            errorType: "RestoreError",
            errorMessage: error.localizedDescription,
            screen: "RevenueCatPaywall",
            userAction: "Restore"
        )
    }
}

// MARK: - Paywall View Modifier
/// Presents paywall if user doesn't have premium entitlement
extension View {
    func presentRevenueCatPaywallIfNeeded(
        isPresented: Binding<Bool>,
        onPurchaseCompleted: (() -> Void)? = nil,
        onRestoreCompleted: (() -> Void)? = nil
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            RevenueCatPaywallView(
                onPurchaseCompleted: onPurchaseCompleted,
                onRestoreCompleted: onRestoreCompleted
            )
        }
    }

    /// Automatically presents paywall if premium entitlement is not active
    func presentRevenueCatPaywallIfNeeded(
        requiredEntitlementIdentifier: String = "pro",
        onPurchaseCompleted: ((CustomerInfo) -> Void)? = nil,
        onRestoreCompleted: ((CustomerInfo) -> Void)? = nil
    ) -> some View {
        self.presentPaywallIfNeeded(
            requiredEntitlementIdentifier: requiredEntitlementIdentifier,
            purchaseCompleted: { customerInfo in
                HapticManager.success()
                onPurchaseCompleted?(customerInfo)
            },
            restoreCompleted: { customerInfo in
                HapticManager.success()
                onRestoreCompleted?(customerInfo)
            }
        )
    }
}

// MARK: - Preview
#if DEBUG
struct RevenueCatPaywallView_Previews: PreviewProvider {
    static var previews: some View {
        RevenueCatPaywallView(
            onPurchaseCompleted: {
                print("Purchase completed")
            },
            onRestoreCompleted: {
                print("Restore completed")
            }
        )
    }
}
#endif
