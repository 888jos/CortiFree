//
//  UndoToast.swift
//  CortiFree
//
//  Created by Claude on 22/11/2025.
//  Reusable toast component with undo functionality and progress countdown
//

import SwiftUI

struct UndoToast: View {
    let message: String
    let undoAction: () -> Void
    let duration: Double

    @State private var progress: Double = 1.0

    init(message: String, duration: Double = 5.0, undoAction: @escaping () -> Void) {
        self.message = message
        self.duration = duration
        self.undoAction = undoAction
    }

    var body: some View {
        VStack {
            Spacer()

            HStack(spacing: 12) {
                // Icon
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.appTheme)

                // Message
                Text(message)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Spacer()

                // Undo button
                Button(action: {
                    HapticManager.light()
                    undoAction()
                }) {
                    Text("Annuler")
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(Color.appTheme)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appTheme.opacity(0.15))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                ZStack(alignment: .leading) {
                    // Base background
                    Color(hex: "2A2B5A")

                    // Progress bar background
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.appTheme.opacity(0.2))
                            .frame(width: geo.size.width * progress)
                            .animation(.linear(duration: duration), value: progress)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Clear TabBar area
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            // Start countdown animation
            withAnimation(.linear(duration: duration)) {
                progress = 0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        GalaxyBackgroundView(intensity: 1.0)

        VStack {
            Spacer()

            UndoToast(
                message: "Entrée de journal supprimée",
                duration: 5.0,
                undoAction: {
                    print("Undo tapped")
                }
            )
        }
    }
}
