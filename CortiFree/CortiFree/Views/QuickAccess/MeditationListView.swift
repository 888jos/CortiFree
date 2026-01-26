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
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var showMeditationSupport = false
    @State private var selectedMeditationSupport: MeditationSupport?

    private var meditations: [(id: String, icon: String, titleKey: String)] {
        [
            ("conscious-breathing", "wind", "library.meditation.conscious_breathing"),
            ("body-scan", "figure.stand", "library.meditation.body_scan"),
            ("mindfulness", "eye.fill", "library.meditation.mindfulness"),
            ("grounding", "leaf.fill", "library.meditation.grounding"),
            ("visualization", "sparkles", "library.meditation.visualization"),
            ("compassion", "heart.fill", "library.meditation.compassion"),
            ("focus-clarity", "brain.head.profile", "library.meditation.focus"),
            ("yoga-nidra", "moon.stars.fill", "library.meditation.sleep")
        ]
    }

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
                                title: languageManager.localized(meditation.titleKey)
                            ) {
                                if let support = MeditationSupport.support(for: meditation.id) {
                                    selectedMeditationSupport = support
                                    showMeditationSupport = true
                                }
                            }
                        }
                    }
                    .id(languageManager.refreshID)
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

            Text(languageManager.localized("library.meditation.title"))
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
