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

    var sounds: [(id: String, icon: String, title: String, imageName: String)] {
        [
            ("rain", "cloud.rain.fill", NSLocalizedString("sounds.rain", comment: ""), "sound_rain"),
            ("ocean", "water.waves", NSLocalizedString("sounds.ocean", comment: ""), "sound_ocean"),
            ("fire", "flame.fill", NSLocalizedString("sounds.fire", comment: ""), "sound_fire"),
            ("whitenoise", "waveform", NSLocalizedString("sounds.whitenoise", comment: ""), "sound_whitenoise"),
            ("wind", "sunrise.fill", NSLocalizedString("sounds.morning", comment: ""), "sound_morning"),
            ("forest", "leaf.fill", NSLocalizedString("sounds.forest", comment: ""), "sound_forest"),
            ("stream", "drop.fill", NSLocalizedString("sounds.stream", comment: ""), "sound_stream"),
            ("night", "moon.stars.fill", NSLocalizedString("sounds.night", comment: ""), "sound_night")
        ]
    }

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
                                imageName: sound.imageName,
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

            Text(NSLocalizedString("sounds.title", comment: ""))
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
    let imageName: String
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
            ZStack {
                // Background image
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .aspectRatio(1, contentMode: .fit)
                    .clipped()

                // Dark overlay for readability
                Rectangle()
                    .fill(Color.black.opacity(isPlaying ? 0.3 : 0.4))

                // Content overlay
                VStack(spacing: 0) {
                    // Title avec étoile en haut
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)

                        Text(title)
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)

                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.leading, 12)

                    Spacer()

                    // Playing indicator
                    if isPlaying {
                        HStack(spacing: 3) {
                            ForEach(0..<3) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 3, height: 12)
                                    .animation(
                                        Animation.easeInOut(duration: 0.5)
                                            .repeatForever()
                                            .delay(Double(index) * 0.15),
                                        value: isPlaying
                                    )
                            }
                        }
                        .padding(.bottom, 16)
                    } else {
                        Spacer().frame(height: 12)
                            .padding(.bottom, 16)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isPlaying ? Color.white : Color.white.opacity(0.3),
                        lineWidth: isPlaying ? 2 : 1
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
