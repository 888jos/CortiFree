//
//  CancelInterceptView.swift
//  CortiFree
//
//  Auto-renew was just turned off (usually in the trial's first hours, to avoid being charged):
//  at the next app open, a drawer says the access lasts until the end date, asks why, and
//  offers either to turn renewal back on (App Store) or an offer (Superwall `cancel_intercept`,
//  configured in the dashboard; nothing shows if it has no campaign). Shown once per cancel.
//

import StoreKit
import SuperwallKit
import SwiftUI

@MainActor
enum CancelIntercept {
    private static let pendingKey = "cancel_intercept_pending_until"
    private static let periodKey = "cancel_intercept_period_type"

    /// RevenueCat saw auto-renew go off while the access is still active.
    static func markPending(until end: Date?, periodType: String) {
        UserDefaults.standard.set(end ?? Date().addingTimeInterval(3 * 86_400), forKey: pendingKey)
        UserDefaults.standard.set(periodType, forKey: periodKey)
    }

    /// Renewal turned back on, or the drawer was shown.
    static func clear() {
        UserDefaults.standard.removeObject(forKey: pendingKey)
        UserDefaults.standard.removeObject(forKey: periodKey)
    }

    static var accessEndDate: Date? { UserDefaults.standard.object(forKey: pendingKey) as? Date }
    static var periodType: String { UserDefaults.standard.string(forKey: periodKey) ?? "trial" }

    static var isDue: Bool {
        guard let end = accessEndDate, end > Date() else { return false }
        return RevenueCatManager.shared.hasPremiumEntitlement
    }
}

struct CancelInterceptView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var reason: String?

    private let reasons = ["price", "time", "not_for_me", "avoid_charge", "other"]
    private func t(_ key: String) -> String { "cancel_intercept.\(key)".localized }

    private var endDateText: String {
        (CancelIntercept.accessEndDate ?? Date()).formatted(date: .long, time: .omitted)
    }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.5)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Image("cortifree_assistant_avatar")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)

                    Text(String(format: t("title"), endDateText))
                        .font(.poppinsBold(22))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(t("subtitle"))
                        .font(.poppinsRegular(15))
                        .foregroundColor(.white.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)

                    if let reason {
                        answer(for: reason)
                    } else {
                        Text(t("question"))
                            .font(.poppinsSemiBold(16))
                            .foregroundColor(.white)
                            .padding(.top, 6)
                        VStack(spacing: 10) {
                            ForEach(reasons, id: \.self) { code in
                                Button {
                                    HapticManager.light()
                                    track("cancel_intercept_reason", ["reason": code])
                                    withAnimation { reason = code }
                                } label: {
                                    Text(t("reason.\(code)"))
                                        .font(.poppinsMedium(15))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 18)
                                        .frame(height: 50)
                                        .glassCard(cornerRadius: 25, interactive: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(22)
            }
        }
        .onAppear {
            track("cancel_intercept_viewed")
            // Once per cancel: renewal off again later marks it again.
            CancelIntercept.clear()
        }
    }

    /// « Just to avoid being charged »: the reminder before the end is the answer. Otherwise,
    /// the offer first, then turning renewal back on.
    @ViewBuilder
    private func answer(for reason: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t(reason == "avoid_charge" ? "answer.avoid_charge" : "answer.default"))
                .font(.poppinsRegular(15))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            if reason != "avoid_charge" {
                primary(t("offer")) {
                    track("cancel_intercept_offer_tapped", ["reason": reason])
                    Superwall.shared.register(placement: SuperwallPlacement.cancelIntercept,
                                              params: ["reason": reason, "period_type": CancelIntercept.periodType])
                    dismiss()
                }
            }
            secondary(t("reactivate"), filled: reason == "avoid_charge") {
                track("cancel_intercept_reactivate_tapped", ["reason": reason])
                Task {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        try? await AppStore.showManageSubscriptions(in: scene)
                    }
                }
            }
            Button(t("later")) {
                track("cancel_intercept_dismissed", ["reason": reason])
                dismiss()
            }
            .font(.poppinsMedium(14))
            .foregroundColor(.white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
        }
    }

    private func primary(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.medium()
            action()
        } label: {
            Text(title)
                .font(.poppinsSemiBold(16))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .buttonStyle(.glassPrimary)
    }

    private func secondary(_ title: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Text(title)
                .font(.poppinsSemiBold(15))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .buttonStyle(filled ? AnyButtonStyle(.glassPrimary) : AnyButtonStyle(.glassSecondary))
    }

    private func track(_ event: String, _ properties: [String: Any] = [:]) {
        AnalyticsManager.shared.track(event: event, properties: properties.merging(["period_type": CancelIntercept.periodType]) { a, _ in a })
    }
}

/// Picks one of two button styles at runtime.
private struct AnyButtonStyle: ButtonStyle {
    private let make: (Configuration) -> AnyView
    init<S: ButtonStyle>(_ style: S) { make = { AnyView(style.makeBody(configuration: $0)) } }
    func makeBody(configuration: Configuration) -> some View { make(configuration) }
}
