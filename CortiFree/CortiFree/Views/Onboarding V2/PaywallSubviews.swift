//
//  PaywallSubviews.swift
//  CortiFree
//
//  Created by Claude on 30/11/2025.
//  Subviews for CustomPaywallView - separated to fix preview compilation
//

import SwiftUI

// MARK: - Previews

#Preview("Paywall") {
    CustomPaywallView(
        onComplete: {},
        onPurchase: { _ in },
        onRestore: {}
    )
}

#Preview("Gift Card") {
    PaywallGiftCardScreen(
        isPresented: .constant(true),
        onContinue: {},
        onDismiss: {}
    )
}

#Preview("Special Offer") {
    PaywallSpecialOfferPopup(
        isPresented: .constant(true),
        onPurchase: { _ in },
        onDismissToPaywall: {},
        countdownSeconds: 1799
    )
}

#Preview("Start Program") {
    PaywallStartProgramScreen(
        isPresented: .constant(true),
        userName: "Sophie",
        onPurchase: { _ in },
        onRestore: {},
        countdownSeconds: 1799
    )
}
