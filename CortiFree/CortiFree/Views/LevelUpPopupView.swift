//
//  LevelUpPopupView.swift
//  CortiFree
//
//  Popup de célébration au passage de niveau
//

import SwiftUI

struct LevelUpPopupView: View {
    let level: Level
    @Binding var isPresented: Bool
    @ObservedObject private var planetSettings = PlanetSettings.shared

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPopup()
                }

            // Popup card
            VStack(spacing: 20) {
                // Celebration icon with halo
                ZStack {
                    // Halo effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    planetSettings.selectedPlanet.haloColor.opacity(0.6),
                                    planetSettings.selectedPlanet.haloColor.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)

                    // Trophy icon
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 50))
                        .foregroundColor(planetSettings.selectedPlanet.haloColor)
                        .scaleEffect(scale)
                }
                .padding(.top, 16)

                // Congratulations text
                Text("Bravo !")
                    .font(Font.Poppins.custom(.bold, size: 32))
                    .foregroundColor(.white)

                // Level info
                VStack(spacing: 8) {
                    Text("Tu passes au niveau \(level.id)")
                        .font(Font.Poppins.custom(.semiBold, size: 20))
                        .foregroundColor(.white)

                    Text(level.name)
                        .font(.custom("Poppins-Medium", size: 18))
                        .foregroundColor(planetSettings.selectedPlanet.haloColor)

                    Text(level.description)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                }

                // Continue button
                Button(action: {
                    dismissPopup()
                }) {
                    Text("Continuer")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(planetSettings.selectedPlanet.haloColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .frame(width: 340)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1A1B3A"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(planetSettings.selectedPlanet.haloColor.opacity(0.3), lineWidth: 2)
            )
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }

            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                dismissPopup()
            }
        }
    }

    private func dismissPopup() {
        HapticManager.light()
        withAnimation(.easeInOut(duration: AppConstants.Animation.standardDuration)) {
            scale = 0.8
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        LevelUpPopupView(
            level: Level.allLevels[7],
            isPresented: .constant(true)
        )
    }
}
