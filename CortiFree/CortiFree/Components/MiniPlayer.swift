//
//  MiniPlayer.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import SwiftUI

struct MiniPlayer: View {
    @ObservedObject var soundPlayer = SoundPlayer.shared
    @State private var showDurationPicker = false

    var body: some View {
        if let exercise = soundPlayer.currentExercise {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: exercise.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color.appTheme)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

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
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1A1B3A"))
                    .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
            )
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
            (NSLocalizedString("duration.infinite", comment: ""), nil),
            (NSLocalizedString("duration.5min", comment: ""), 5 * 60),
            (NSLocalizedString("duration.10min", comment: ""), 10 * 60),
            (NSLocalizedString("duration.15min", comment: ""), 15 * 60),
            (NSLocalizedString("duration.30min", comment: ""), 30 * 60),
            (NSLocalizedString("duration.1hour", comment: ""), 60 * 60)
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
                    Text(NSLocalizedString("duration.title", comment: ""))
                        .font(.custom("Poppins-SemiBold", size: 22))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.top, 32)
                .padding(.bottom, 8)

                Text(NSLocalizedString("duration.subtitle", comment: ""))
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
