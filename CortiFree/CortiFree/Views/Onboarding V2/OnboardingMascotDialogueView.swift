//
//  OnboardingMascotDialogueView.swift
//  CortiFree
//

import SwiftUI

struct OnboardingMascotDialogueView: View {
    let message: String
    var prominent: Bool = false
    @State private var displayedMessage = ""

    private var mascotSize: CGFloat { prominent ? 223 : 122 }
    private var bubbleHeight: CGFloat { mascotSize * 0.8 }

    var body: some View {
        HStack(alignment: .center, spacing: prominent ? 8 : 6) {
            LottieView(filename: "sloth_meditate.json", loopMode: .loop)
                .frame(width: mascotSize, height: mascotSize)

            Text(displayedMessage)
                .font(.poppinsSemiBold(prominent ? 19 : 17))
                .foregroundStyle(Color(hex: "1A1A4E"))
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .padding(.horizontal, prominent ? 24 : 22)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: bubbleHeight, maxHeight: bubbleHeight, alignment: .center)
                .background {
                    ZStack(alignment: .leading) {
                        SpeechBubbleTail()
                            .fill(Color.white)
                            .frame(width: 22, height: 30)
                            .offset(x: -11)
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white)
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: message) {
            displayedMessage = ""
            for character in message {
                guard !Task.isCancelled else { return }
                displayedMessage.append(character)
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
        }
    }
}

private struct SpeechBubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
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
