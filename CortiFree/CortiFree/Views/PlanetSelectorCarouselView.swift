//
//  PlanetSelectorCarouselView.swift
//  CortiFree
//
//  Created by Claude on 24/10/2025.
//  Vue carousel pour sélectionner une planète avec scroll horizontal
//

import SwiftUI

struct PlanetSelectorCarouselView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var planetSettings = PlanetSettings.shared
    @State private var selectedPlanet: Planet

    init() {
        _selectedPlanet = State(initialValue: PlanetSettings.shared.selectedPlanet)
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.9)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }

                    Spacer()

                    Text("Choisir une planète")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)

                    Spacer()

                    // Bouton de confirmation
                    Button(action: {
                        HapticManager.medium()
                        withAnimation(.spring(response: 0.4)) {
                            planetSettings.selectedPlanet = selectedPlanet
                        }
                        dismiss()
                    }) {
                        Image(systemName: "checkmark")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(Color.appTheme)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.appTheme.opacity(0.2))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Description
                Text("Maintiens appuyé sur la planète pour la sélectionner")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)

                Spacer()

                // Planet carousel
                PlanetCarousel(selectedPlanet: $selectedPlanet)

                Spacer()

                // Nom de la planète sélectionnée
                VStack(spacing: 8) {
                    Text(selectedPlanet.displayName)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)

                    Text("Glisse pour explorer")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(Color(hex: "B0B8D4"))
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Planet Carousel

struct PlanetCarousel: View {
    @Binding var selectedPlanet: Planet
    @State private var haloOpacities: [Planet: Double] = [:]
    @State private var scrollOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var currentScrollViewPosition: CGFloat = 0

    private let allPlanets = Planet.allCases

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let _ = 290 // itemWidth: 280 planet + 10 spacing (not used directly)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // Boucle infinie : répéter les planètes 3 fois (avant, milieu, après)
                        ForEach(0..<3, id: \.self) { repetition in
                            ForEach(Array(allPlanets.enumerated()), id: \.element) { index, planet in
                                PlanetCarouselItem(
                                    planet: planet,
                                    isSelected: planet == selectedPlanet,
                                    haloOpacity: haloOpacities[planet] ?? 0.3
                                )
                                .id("\(repetition)-\(planet.rawValue)")
                                .onTapGesture {
                                    // Sélectionner uniquement au tap
                                    if !isDragging {
                                        HapticManager.light()
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            selectedPlanet = planet
                                        }
                                        // Centrer sur la copie la plus proche (repetition du tap)
                                        withAnimation(.easeOut(duration: 0.5)) {
                                            proxy.scrollTo("\(repetition)-\(planet.rawValue)", anchor: .center)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, (screenWidth - 280) / 2)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ScrollOffsetKey.self,
                                value: geo.frame(in: .named("scrollView")).minX
                            )
                        }
                    )
                }
                .coordinateSpace(name: "scrollView")
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    scrollOffset = value
                    currentScrollViewPosition = value
                    isDragging = true

                    // Réinitialiser isDragging après un délai
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isDragging = false
                    }
                }
                .onAppear {
                    // Initialiser les animations de halo
                    for planet in allPlanets {
                        startHaloAnimation(for: planet)
                    }

                    // Centrer la planète sélectionnée au démarrage (toujours au milieu = repetition 1)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo("1-\(selectedPlanet.rawValue)", anchor: .center)
                    }
                }
            }
        }
        .frame(height: 400)
    }

    private func startHaloAnimation(for planet: Planet) {
        haloOpacities[planet] = 0.3

        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            haloOpacities[planet] = planet == selectedPlanet ? 0.5 : 0.4
        }
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Planet Carousel Item

struct PlanetCarouselItem: View {
    let planet: Planet
    let isSelected: Bool
    let haloOpacity: Double

    @State private var animatedHaloOpacity: Double = 0.3

    var body: some View {
        ZStack {
            // Halo externe large et flou (planètes non sélectionnées)
            if !isSelected {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                planet.haloColor.opacity(0.15),
                                planet.haloColor.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
            }

            // Halo pour planète sélectionnée
            if isSelected {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                planet.haloColor.opacity(animatedHaloOpacity),
                                planet.haloColor.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 130
                        )
                    )
                    .frame(width: 260, height: 260)
                    .blur(radius: 30)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
            }

            // Planète
            Image(planet.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: isSelected ? 280 : 160,
                    height: isSelected ? 280 : 160
                )
                .opacity(isSelected ? 1.0 : 0.5)
                .scaleEffect(isSelected ? 1.0 : 0.7)
                .shadow(
                    color: planet.haloColor.opacity(isSelected ? 0.6 : 0.2),
                    radius: isSelected ? 25 : 10
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                animatedHaloOpacity = isSelected ? 0.55 : 0.4
            }
        }
        .onChange(of: isSelected) { _, newValue in
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                animatedHaloOpacity = newValue ? 0.55 : 0.4
            }
        }
    }
}

#Preview {
    PlanetSelectorCarouselView()
}
