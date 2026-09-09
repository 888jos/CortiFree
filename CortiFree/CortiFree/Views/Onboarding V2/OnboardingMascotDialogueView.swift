//
//  OnboardingMascotDialogueView.swift
//  CortiFree
//

import SwiftUI

struct OnboardingMascotDialogueView: View {
    let message: String
    var prominent: Bool = false

    private var mascotSize: CGFloat { prominent ? 165 : 90 }

    var body: some View {
        HStack(alignment: .center, spacing: prominent ? 8 : 6) {
            LottieView(filename: "sloth_meditate.json", loopMode: .loop)
                .frame(width: mascotSize, height: mascotSize)

            Text(message)
                .font(.poppinsSemiBold(prominent ? 19 : 17))
                .foregroundStyle(Color(hex: "1A1A4E"))
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .padding(.horizontal, prominent ? 20 : 18)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: mascotSize)
                .background {
                    SpeechBubbleShape()
                        .fill(Color.white)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SpeechBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let tailWidth: CGFloat = 15
        let tailHeight: CGFloat = 20
        let bubbleRect = CGRect(x: tailWidth, y: 0, width: max(0, rect.width - tailWidth), height: rect.height)
        let midY = rect.midY
        var path = Path(roundedRect: bubbleRect, cornerRadius: 18)
        path.move(to: CGPoint(x: tailWidth + 1, y: midY - tailHeight / 2))
        path.addLine(to: CGPoint(x: 0, y: midY))
        path.addLine(to: CGPoint(x: tailWidth + 1, y: midY + tailHeight / 2))
        path.closeSubpath()
        return path
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
