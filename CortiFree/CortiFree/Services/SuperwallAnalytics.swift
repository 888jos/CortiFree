//
//  SuperwallAnalytics.swift
//  CortiFree
//
//  Paywalls and purchases happen inside Superwall: this delegate forwards its events to
//  Amplitude (paywall opened / closed / declined, transactions, trials, restores), so the
//  monetization funnel and the revenue live next to the rest of the product analytics.
//  Renewals, cancellations and refunds happen outside the app: they come from the
//  RevenueCat → Amplitude server integration (events « rc_* »).
//

import Foundation
import SuperwallKit

final class SuperwallAnalytics: SuperwallDelegate {
    static let shared = SuperwallAnalytics()
    private init() {}

    @MainActor
    func handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo) {
        switch eventInfo.event {
        case .paywallOpen(let paywall):
            track("paywall_open", paywall)
        case .paywallClose(let paywall):
            track("paywall_close", paywall)
        case .paywallDecline(let paywall):
            track("paywall_decline", paywall)
        case .transactionStart(let product, let paywall):
            track("transaction_start", paywall, product: product)
        case .transactionAbandon(let product, let paywall):
            track("transaction_abandon", paywall, product: product)
        case .transactionFail(let error, let paywall):
            track("transaction_fail", paywall, extra: ["error": error.localizedDescription])
        case .transactionTimeout(let paywall):
            track("transaction_timeout", paywall)
        case .transactionComplete(_, let product, let type, let paywall):
            track("transaction_complete", paywall, product: product, extra: ["transaction_type": type.description])
        case .freeTrialStart(let product, let paywall):
            track("trial_started", paywall, product: product)
            AnalyticsManager.shared.setUserProperty("subscription_period_type", value: "trial")
        case .subscriptionStart(let product, let paywall):
            track("subscription_started", paywall, product: product)
            // Paid right away (no free trial): the money is in, log it as revenue.
            AmplitudeManager.shared.logRevenue(productId: product.productIdentifier,
                                               price: NSDecimalNumber(decimal: product.price).doubleValue,
                                               currency: product.currencyCode,
                                               properties: ["placement": paywall.presentedByPlacementWithName ?? "",
                                                            "source": "app"])
        case .nonRecurringProductPurchase(let product, let paywall):
            track("non_recurring_purchase", paywall, extra: ["product_id": product.id])
        case .transactionRestore(let restoreType, let paywall):
            track("transaction_restore", paywall, extra: ["restore_type": String(describing: restoreType)])
        case .paywallResponseLoadFail(let placement), .paywallResponseLoadNotFound(let placement):
            AnalyticsManager.shared.track(event: "paywall_load_failed", properties: ["placement": placement ?? ""])
        case .surveyResponse(let survey, let selectedOption, let customResponse, let paywall):
            track("paywall_survey_response", paywall, extra: [
                "survey_id": survey.id,
                "option": selectedOption.title,
                "custom_response": customResponse ?? ""
            ])
        default:
            break
        }
    }

    private func track(_ event: String, _ paywall: PaywallInfo, product: StoreProduct? = nil, extra: [String: Any] = [:]) {
        var properties: [String: Any] = [
            "placement": paywall.presentedByPlacementWithName ?? "",
            "paywall_identifier": paywall.identifier,
            "paywall_name": paywall.name,
            "experiment_id": paywall.experiment?.id ?? "",
            "variant_id": paywall.experiment?.variant.id ?? ""
        ]
        if let product {
            properties["product_id"] = product.productIdentifier
            properties["price"] = NSDecimalNumber(decimal: product.price).doubleValue
            properties["currency"] = product.currencyCode ?? ""
            properties["period"] = product.period
        }
        properties.merge(extra) { _, new in new }
        AnalyticsManager.shared.track(event: event, properties: properties)
    }
}
