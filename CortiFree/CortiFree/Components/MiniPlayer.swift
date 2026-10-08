//
//  MiniPlayer.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Docked mini player: guided audio sessions (GuidedSessionPlayer) or ambient sounds (SoundPlayer).
//  Only one of them plays at a time.
//

import SwiftUI

struct MiniPlayer: View {
    @ObservedObject private var sessionPlayer = GuidedSessionPlayer.shared
    @ObservedObject private var soundPlayer = SoundPlayer.shared

    var body: some View {
        if sessionPlayer.currentSession != nil {
            SessionMiniPlayer()
        } else if soundPlayer.currentExercise != nil {
            SoundMiniPlayer()
        }
    }
}

// MARK: - Guided session mini player

struct SessionMiniPlayer: View {
    /// Custom "open full player" action (for modal contexts). Default: global player in ContentView.
    var onOpen: (() -> Void)? = nil
    @ObservedObject private var player = GuidedSessionPlayer.shared
    @ObservedObject private var clock = GuidedSessionPlayer.shared.clock

    var body: some View {
        if let session = player.currentSession {
            HStack(spacing: 12) {
                SessionArtworkView(session: session, cornerRadius: 10)
                    .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.localizedTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(statusText(session))
                        .font(.system(size: 12, weight: .medium).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    HapticManager.light()
                    player.togglePlayPause()
                } label: {
                    Group {
                        if player.isPreparing {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: player.didFinish ? "arrow.counterclockwise" : (player.isPlaying ? "pause.fill" : "play.fill"))
                                .font(.system(size: 20, weight: .semibold))
                                .contentTransition(.symbolEffect(.replace))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(player.isPlaying ? LanguageManager.shared.localizedString(for: "audio.pause") : LanguageManager.shared.localizedString(for: "audio.play"))

                Button {
                    HapticManager.light()
                    player.stop()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 28, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(LanguageManager.shared.localizedString(for: "audio.stop_session"))
            }
            .padding(.leading, 10)
            .padding(.trailing, 10)
            .padding(.vertical, 10)
            .frame(height: 66)
            .overlay(alignment: .bottom) {
                // Progress line
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.15))
                        Capsule()
                            .fill(LinearGradient(colors: [Color.appTheme, .white], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(progress))
                    }
                }
                .frame(height: 2.5)
                .padding(.horizontal, 18)
                .padding(.bottom, 4)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                HapticManager.light()
                if let onOpen { onOpen() } else { player.isFullPlayerPresented = true }
            }
            .miniPlayerBackground()
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityElement(children: .contain)
        }
    }

    private var progress: Double {
        if player.isPreparing { return clock.preparationProgress }
        let total = player.displayDuration
        guard total > 0 else { return 0 }
        return min(1, clock.currentTime / total)
    }

    private func statusText(_ session: GuidedSession) -> String {
        if player.isPreparing {
            return LanguageManager.shared.localizedString(for: "audio.preparing") + " \(Int(clock.preparationProgress * 100))%"
        }
        if player.didFinish { return LanguageManager.shared.localizedString(for: "audio.completed") }
        let remaining = max(0, player.displayDuration - clock.currentTime)
        return "\(session.category.title.localized) · -\(PlayerFormat.time(remaining))"
    }
}

// MARK: - Shared background

extension View {
    @ViewBuilder
    func miniPlayerBackground() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular.tint(Color(hex: "17182E").opacity(0.7)).interactive(), in: .rect(cornerRadius: 22))
                .environment(\.colorScheme, .dark)
        } else {
            self
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(hex: "1A1B3A").opacity(0.92))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        }
    }
}

// MARK: - Ambient sound mini player

/// Mini player for ambient sounds (SoundPlayer), unchanged behaviour.
struct SoundMiniPlayer: View {
    @ObservedObject var soundPlayer = SoundPlayer.shared
    @State private var showDurationPicker = false

    var body: some View {
        if let exercise = soundPlayer.currentExercise {
            HStack(spacing: 16) {
                // Ambient sound photo
                Color.clear
                    .overlay { Image(exercise.soundImageName).resizable().scaledToFill() }
                    .frame(width: 46, height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Title & progress (cliquable pour ouvrir le duration picker)
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.title)
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        // Timer
                        Text(timerText())
                            .font(.custom("Poppins-Regular", size: 11))
                            .foregroundColor(Color.appTheme)
                            .monospacedDigit()

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 3)

                                // Progress (basée sur la durée ou sur le fichier audio)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.appTheme, Color.appThemeSecondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat(progressValue()), height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticManager.light()
                    showDurationPicker = true
                }

                // Play/Pause button
                Button(action: {
                    HapticManager.light()
                    if soundPlayer.isPlaying {
                        soundPlayer.pause()
                    } else {
                        soundPlayer.resume()
                    }
                }) {
                    Image(systemName: soundPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                }

                // Close button
                Button(action: {
                    HapticManager.light()
                    soundPlayer.stop()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 72)
            .miniPlayerBackground()
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: soundPlayer.currentExercise?.id)
            .sheet(isPresented: $showDurationPicker) {
                DurationPickerSheet()
            }
        }
    }

    private func timerText() -> String {
        if let duration = soundPlayer.selectedDuration {
            let remaining = max(0, duration - soundPlayer.totalPlayTime)
            return formatTime(remaining)
        } else {
            return soundPlayer.formattedTotalTime()
        }
    }

    private func progressValue() -> Double {
        if let duration = soundPlayer.selectedDuration, duration > 0 {
            return min(1.0, soundPlayer.totalPlayTime / duration)
        } else {
            return soundPlayer.progress
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

// MARK: - Duration Picker Sheet

struct DurationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var soundPlayer = SoundPlayer.shared

    var durations: [(title: String, minutes: TimeInterval?)] {
        [
            (LanguageManager.shared.localizedString(for: "duration.infinite"), nil),
            (LanguageManager.shared.localizedString(for: "duration.5min"), 5 * 60),
            (LanguageManager.shared.localizedString(for: "duration.10min"), 10 * 60),
            (LanguageManager.shared.localizedString(for: "duration.15min"), 15 * 60),
            (LanguageManager.shared.localizedString(for: "duration.30min"), 30 * 60),
            (LanguageManager.shared.localizedString(for: "duration.1hour"), 60 * 60)
        ]
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "1F0140"),
                    Color(hex: "0B011B"),
                    Color(hex: "01000C")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Spacer()
                    Text(LanguageManager.shared.localizedString(for: "duration.title"))
                        .font(.custom("Poppins-SemiBold", size: 22))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.top, 32)
                .padding(.bottom, 8)

                Text(LanguageManager.shared.localizedString(for: "duration.subtitle"))
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Durations grid (2 lignes × 3 colonnes)
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(durations, id: \.title) { duration in
                        DurationButton(
                            title: duration.title,
                            isSelected: soundPlayer.selectedDuration == duration.minutes
                        ) {
                            soundPlayer.selectedDuration = duration.minutes
                            HapticManager.light()
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

struct DurationButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "clock.fill")
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? Color.appTheme : .white)

                Text(title)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadius)
                    .fill(
                        isSelected ?
                            LinearGradient(
                                colors: [
                                    Color.appTheme.opacity(0.3),
                                    Color.appThemeSecondary.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadius)
                            .stroke(
                                isSelected ? Color.appTheme : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "1A1B3A"), Color(hex: "0D0E1F")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
            Spacer()
            MiniPlayer()
        }
    }
    .onAppear {
        SoundPlayer.shared.currentExercise = Exercise.sounds[0]
        SoundPlayer.shared.isPlaying = true
        SoundPlayer.shared.progress = 0.4
    }
}
