//
//  SoundsListView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Liste des sons relaxants depuis l'accueil
//

import SwiftUI

struct SoundsListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LibraryViewModel()
    @ObservedObject private var soundPlayer = SoundPlayer.shared

    let sounds: [(id: String, icon: String, title: String)] = [
        ("rain", "cloud.rain.fill", "Pluie"),
        ("ocean", "water.waves", "Ocean"),
        ("fire", "flame.fill", "Feu"),
        ("whitenoise", "waveform", "Bruit Blanc"),
        ("wind", "sunrise.fill", "Matinée"),
        ("forest", "leaf.fill", "Forêt"),
        ("stream", "drop.fill", "Ruisseau"),
        ("night", "moon.stars.fill", "Nuit d'été")
    ]

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)

            VStack(spacing: 0) {
                // Header
                headerSection

                // Grid des sons
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 24),
                        GridItem(.flexible(), spacing: 24)
                    ], spacing: 24) {
                        ForEach(sounds, id: \.id) { sound in
                            SoundCard(
                                icon: sound.icon,
                                title: sound.title,
                                isPlaying: soundPlayer.currentExercise?.id == sound.id && soundPlayer.isPlaying
                            ) {
                                playSound(id: sound.id, title: sound.title)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                    Spacer(minLength: 120)
                }
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

            Text("Sons Relaxants")
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private func playSound(id: String, title: String) {
        if let exercise = Exercise.sounds.first(where: { $0.id == id }) {
            viewModel.playExercise(exercise)
        }
    }
}

struct SoundCard: View {
    let icon: String
    let title: String
    let isPlaying: Bool
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
            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(isPlaying ? Color.appTheme : Color(hex: "0E0530"))
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .font(.system(size: 26))
                        .foregroundColor(.white)

                    if isPlaying {
                        Circle()
                            .stroke(Color.appTheme, lineWidth: 2)
                            .frame(width: 70, height: 70)
                    }
                }

                // Title
                Text(title)
                    .font(.custom("Poppins-Medium", size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 10)

                // Playing indicator
                if isPlaying {
                    HStack(spacing: 3) {
                        ForEach(0..<3) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.appTheme)
                                .frame(width: 3, height: 12)
                                .animation(
                                    Animation.easeInOut(duration: 0.5)
                                        .repeatForever()
                                        .delay(Double(index) * 0.15),
                                    value: isPlaying
                                )
                        }
                    }
                    .padding(.top, 6)
                } else {
                    Spacer().frame(height: 12)
                    .padding(.top, 6)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .aspectRatio(1, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isPlaying ? [
                                Color.appTheme.opacity(0.2),
                                Color.appThemeSecondary.opacity(0.3)
                            ] : [
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
                                    colors: isPlaying ? [
                                        Color.appTheme,
                                        Color.appThemeSecondary
                                    ] : [
                                        Color.appTheme.opacity(0.3),
                                        Color.appThemeSecondary.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isPlaying ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SoundsListView()
}
