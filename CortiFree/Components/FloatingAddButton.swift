//
//  FloatingAddButton.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Floating action button for adding custom tasks
//

import SwiftUI

struct FloatingAddButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.light()

            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }

            action()
        }) {
            ZStack {
                // Background gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appTheme,
                                Color.appThemeSecondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(
                        color: Color.appTheme.opacity(0.4),
                        radius: 8,
                        x: 0,
                        y: 4
                    )

                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(hex: "1F0140"),
                Color(hex: "0B011B")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingAddButton {
                    print("Add task tapped")
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
    }
}
