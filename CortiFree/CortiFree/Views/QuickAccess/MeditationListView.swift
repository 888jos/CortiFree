//
//  MeditationListView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Liste des exercices de méditation depuis l'accueil
//

import SwiftUI

struct MeditationListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showMeditationSupport = false
    @State private var selectedMeditationSupport: MeditationSupport?

    let meditations: [(id: String, icon: String, title: String)] = [
        ("conscious-breathing", "wind", "Respiration consciente"),
        ("body-scan", "figure.stand", "Body Scan express"),
        ("mindfulness", "eye.fill", "Mindfulness de base"),
        ("grounding", "leaf.fill", "Ancrage corporel / Grounding"),
        ("visualization", "sparkles", "Visualisation lieu sûr"),
        ("compassion", "heart.fill", "Auto-compassion"),
        ("focus-clarity", "brain.head.profile", "Méditation focus/clarté"),
        ("yoga-nidra", "moon.stars.fill", "Méditation sommeil / Yoga Nidra")
    ]

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)

            VStack(spacing: 0) {
                // Header
                headerSection

                // Grid des méditations
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 24),
                        GridItem(.flexible(), spacing: 24)
                    ], spacing: 24) {
                        ForEach(meditations, id: \.id) { meditation in
                            MeditationCard(
                                icon: meditation.icon,
                                title: meditation.title
                            ) {
                                if let support = MeditationSupport.support(for: meditation.id) {
                                    selectedMeditationSupport = support
                                    showMeditationSupport = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showMeditationSupport) {
            if let support = selectedMeditationSupport {
                MeditationSupportView(support: support)
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }

            Spacer()

            Text("Exercices de Méditation")
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

struct MeditationCard: View {
    let icon: String
    let title: String
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
            VStack {
                // Title avec étoile en haut
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)

                    Text(title)
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.top, 12)
                .padding(.leading, 12)

                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .aspectRatio(1, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "49288C").opacity(0.4),
                                Color(hex: "2A2B5A").opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.appTheme.opacity(0.3),
                                        Color.appThemeSecondary.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MeditationListView()
}
