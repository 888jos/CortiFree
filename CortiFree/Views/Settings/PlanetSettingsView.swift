//
//  PlanetSettingsView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Vue pour sélectionner la planète dans les exercices de respiration
//

import SwiftUI

struct PlanetSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var planetSettings = PlanetSettings.shared

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.8)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.custom("Poppins-SemiBold", size: 20))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Text("Choix de la planète")
                        .font(.custom("Poppins-SemiBold", size: 20))
                        .foregroundColor(.white)

                    Spacer()

                    // Invisible button for balance
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.custom("Poppins-SemiBold", size: 20))
                            .foregroundColor(.clear)
                    }
                    .disabled(true)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Description
                Text("Choisissez quelle planète apparaîtra dans vos exercices de respiration")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 32)

                Spacer()

                // Horizontal ScrollView with planets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Planet.allCases) { planet in
                            PlanetCard(
                                planet: planet,
                                isSelected: planetSettings.selectedPlanet == planet,
                                onSelect: {
                                    HapticManager.light()
                                    withAnimation(.spring(response: 0.3)) {
                                        planetSettings.selectedPlanet = planet
                                    }
                                }
                            )
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                }
                .frame(height: 280)

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Planet Card

struct PlanetCard: View {
    let planet: Planet
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var haloOpacity: Double = 0.25

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                ZStack {
                    // Halo coloré personnalisé pour chaque planète avec animation d'opacité
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    planet.haloColor.opacity(haloOpacity),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 70,
                                endRadius: 82
                            )
                        )
                        .frame(width: 90, height: 90)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                                haloOpacity = isSelected ? 0.5 : 0.4
                            }
                        }

                    // Planet image
                    Image(planet.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160, height: 160)
                        .shadow(color: planet.haloColor.opacity(0.6), radius: 20)

                    // Selection checkmark
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.appTheme)
                                    .background(
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 20, height: 20)
                                    )
                            }
                            Spacer()
                        }
                        .frame(width: 160, height: 160)
                    }
                }
                .frame(height: 190)

                // Planet name
                Text(planet.displayName)
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.white)
            }
            .frame(width: 200)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PlanetSettingsView()
}
