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
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(alignment: .bottomLeading) {
                    Triangle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(45))
                        .offset(x: -4, y: 4)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
