//
//  OnboardingMascotDialogueView.swift
//  CortiFree
//

import SwiftUI

struct OnboardingMascotDialogueView: View {
    let message: String
    var prominent: Bool = false
    /// Typewriter: how many characters are shown. The full message is always laid
    /// out, so the lines never reflow while it types.
    @State private var revealedCount = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var mascotSize: CGFloat { prominent ? 223 : 122 }
    private var bubbleHeight: CGFloat { mascotSize * 0.8 }

    var body: some View {
        HStack(alignment: .center, spacing: prominent ? 8 : 6) {
            LottieView(filename: "sloth_meditate.json", loopMode: .loop)
                .frame(width: mascotSize, height: mascotSize)

            Text(revealedMessage)
                .font(.poppinsSemiBold(prominent ? 19 : 17))
                .multilineTextAlignment(.leading)
                .lineSpacing(0)
                // Grows with larger text sizes instead of shrinking the words to an unreadable size.
                .lineLimit(nil)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
                .allowsTightening(true)
                .balancedLines(alignment: .leading)
                .padding(.horizontal, prominent ? 20 : 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: bubbleHeight, alignment: .center)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .task(id: message) {
            if reduceMotion {
                revealedCount = message.count
                return
            }
            revealedCount = 0
            for count in 1...max(message.count, 1) {
                guard !Task.isCancelled else { return }
                revealedCount = count
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
        }
    }

    /// The whole message, with the characters not typed yet left transparent.
    private var revealedMessage: AttributedString {
        let ink = Color(hex: "1A1A4E")
        let typed = message.prefix(revealedCount)
        var shown = AttributedString(String(typed))
        shown.foregroundColor = ink
        var hidden = AttributedString(String(message.dropFirst(typed.count)))
        hidden.foregroundColor = ink.opacity(0)
        return shown + hidden
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
        .accessibilityValue(Text((min(max(progress, 0), 1)).formatted(.percent.precision(.fractionLength(0)))))
    }
}

/// Back chevron shared by the onboarding screens that don't have their own header.
struct OnboardingBackButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("common.back".localized)
    }
}

extension View {
    /// Pins the onboarding back chevron to the top-leading corner (inside the safe area).
    @ViewBuilder
    func onboardingBackButton(_ action: (() -> Void)?) -> some View {
        if let action {
            overlay(alignment: .topLeading) {
                OnboardingBackButton(action: action)
                    .padding(.leading, 12)
                    .padding(.top, 4)
            }
        } else {
            self
        }
    }
}
