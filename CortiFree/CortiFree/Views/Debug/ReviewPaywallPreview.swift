//
//  ReviewPaywallPreview.swift
//  CortiFree
//
//  Debug only: a static annual-plan paywall at a given price, used for the App Store
//  review screenshot of each in-app purchase. Nothing is bought from here.
//

#if DEBUG
import SwiftUI

struct ReviewPaywallPreview: View {
    struct Price: Identifiable {
        let yearly: Decimal
        var id: String { "\(yearly)" }

        static let all: [Price] = [49.99, 59.99, 39.99, 34.99].map { Price(yearly: Decimal($0)) }

        var yearlyText: String { Self.format(yearly) }
        /// Per-month equivalent, rounded down to the cent.
        var monthlyText: String {
            var monthly = yearly / 12
            var rounded = Decimal()
            NSDecimalRound(&rounded, &monthly, 2, .down)
            return Self.format(rounded)
        }

        private static func format(_ value: Decimal) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.locale = Locale(identifier: "en_US")
            return formatter.string(from: value as NSDecimalNumber) ?? "$\(value)"
        }
    }

    let price: Price
    @Environment(\.dismiss) private var dismiss

    private let features: [(icon: String, text: String)] = [
        ("calendar", "A personalized 28-day plan to lower stress"),
        ("wind", "Guided breathing, meditations and sleep sounds"),
        ("bubble.left.and.text.bubble.right.fill", "Milo, your calm companion, any time"),
        ("chart.line.uptrend.xyaxis", "Track your progress, streaks and heart rate")
    ]

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 0)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Color(hex: "B794F6").opacity(0.35), radius: 20, y: 8)

                        VStack(spacing: 8) {
                            Text("CortiFree Premium")
                                .font(.faroBold(26))
                                .foregroundStyle(.white)
                            Text("Feel calmer in 28 days, a few minutes a day.")
                                .font(.poppinsRegular(14))
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(features, id: \.text) { feature in
                                HStack(spacing: 12) {
                                    Image(systemName: feature.icon)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Color(hex: "B794F6"))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(hex: "B794F6").opacity(0.15)))
                                    Text(feature.text)
                                        .font(.poppinsRegular(13))
                                        .foregroundStyle(.white.opacity(0.9))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white.opacity(0.08)))

                        planCard
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 4)
                }

                footer
            }
        }
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Annual")
                    .font(.poppinsSemiBold(17))
                    .foregroundStyle(.white)
                Spacer()
                Text("7-DAY FREE TRIAL")
                    .font(.poppinsSemiBold(11))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(Color(hex: "8B5CF6")))
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(price.yearlyText)
                    .font(.faroBold(28))
                    .foregroundStyle(.white)
                Text("/ year")
                    .font(.poppinsRegular(14))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(price.monthlyText) / month")
                    .font(.poppinsRegular(13))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Text("Free for 7 days, then \(price.yearlyText) per year.")
                .font(.poppinsRegular(13))
                .foregroundStyle(Color(hex: "B794F6"))
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(hex: "8B5CF6").opacity(0.14)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color(hex: "B794F6"), lineWidth: 2))
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button {} label: {
                Text("Start my 7-day free trial")
                    .font(.poppinsSemiBold(17))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
            .buttonStyle(.glassPrimary)

            Text("No payment due now. After the 7-day free trial, your subscription automatically renews at \(price.yearlyText) per year unless canceled at least 24 hours before the end of the trial or the current period. Payment is charged to your Apple ID account. Manage or cancel anytime in your App Store account settings.")
                .font(.poppinsRegular(10))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 18) {
                ForEach(["Restore Purchases", "Terms of Use", "Privacy Policy"], id: \.self) { link in
                    Text(link)
                        .font(.poppinsRegular(11))
                        .foregroundStyle(.white.opacity(0.6))
                        .underline()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
}

#Preview {
    ReviewPaywallPreview(price: ReviewPaywallPreview.Price.all[0])
}
#endif
