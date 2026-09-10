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

    private var meditations: [(id: String, imageName: String, titleKey: String)] {
        [
            ("conscious-breathing", "meditation_01", "library.meditation.conscious_breathing"),
            ("body-scan", "meditation_02", "library.meditation.body_scan"),
            ("mindfulness", "meditation_03", "library.meditation.mindfulness"),
            ("grounding", "meditation_04", "library.meditation.grounding"),
            ("visualization", "meditation_05", "library.meditation.visualization"),
            ("compassion", "meditation_06", "library.meditation.compassion"),
            ("focus-clarity", "meditation_07", "library.meditation.focus"),
            ("yoga-nidra", "meditation_08", "library.meditation.sleep")
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
                                imageName: meditation.imageName,
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
                .font(.faroSemiBold(20))
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
    let imageName: String
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
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                LinearGradient(
                    colors: [.black.opacity(0.62), .clear, .black.opacity(0.52)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Title avec étoile en haut à gauche
                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)

                        Text(title)
                            .font(.faroSemiBold(12))
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
                RoundedRectangle(cornerRadius: 16).fill(Color(hex: "2A1E47"))
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MeditationListView()
}
