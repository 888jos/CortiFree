//
//  OnboardingMascotDialogueView.swift
//  CortiFree
//

import SwiftUI

struct OnboardingMascotDialogueView: View {
    let message: String
    var prominent: Bool = false

    var body: some View {
        HStack(alignment: .bottom, spacing: prominent ? 8 : 4) {
            LottieView(filename: "sloth_meditate.json", loopMode: .loop)
                .frame(width: prominent ? 132 : 72, height: prominent ? 132 : 72)

            Text(message)
                .font(.poppinsSemiBold(prominent ? 15 : 13))
                .foregroundStyle(Color(hex: "1A1A4E"))
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .padding(.horizontal, prominent ? 16 : 12)
                .padding(.vertical, prominent ? 13 : 10)
                .background {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 15, height: 15)
                        .offset(x: -6, y: 17)
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OnboardingProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.18))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "B794F6"), Color(hex: "D4B4FF")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 8)
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}
