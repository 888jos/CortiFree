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
        ("conscious-breathing", "wind", NSLocalizedString("library.meditation.conscious_breathing", comment: "")),
        ("body-scan", "figure.stand", NSLocalizedString("library.meditation.body_scan", comment: "")),
        ("mindfulness", "eye.fill", NSLocalizedString("library.meditation.mindfulness", comment: "")),
        ("grounding", "leaf.fill", NSLocalizedString("library.meditation.grounding", comment: "")),
        ("visualization", "sparkles", NSLocalizedString("library.meditation.visualization", comment: "")),
        ("compassion", "heart.fill", NSLocalizedString("library.meditation.compassion", comment: "")),
        ("focus-clarity", "brain.head.profile", NSLocalizedString("library.meditation.focus", comment: "")),
        ("yoga-nidra", "moon.stars.fill", NSLocalizedString("library.meditation.sleep", comment: ""))
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

            Text(NSLocalizedString("library.meditation.title", comment: ""))
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
            ZStack {
                // Centered icon
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(Color(hex: "F4EFFF"))

                // Title avec étoile en haut à gauche
                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)

                        Text(title)
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.leading, 12)
                    .padding(.trailing, 12)

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .aspectRatio(1, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "2A1E47"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "F4EFFF").opacity(0.3), lineWidth: 1)
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
