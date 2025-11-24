//
//  MoodSelector.swift
//  CortiFree
//
//  Created by Claude on 24/11/2025.
//  Interactive mood selector widget with 6 emoji options
//

import SwiftUI

struct MoodSelector: View {
    @Binding var selectedMood: Mood?
    let onMoodSelected: (Mood) -> Void

    private let moods: [Mood] = [.awful, .angry, .low, .okay, .good, .amazing]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("motivational.mood_question", comment: ""))
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.white.opacity(0.8))

            HStack(spacing: 8) {
                ForEach(moods, id: \.self) { mood in
                    MoodButton(
                        mood: mood,
                        isSelected: selectedMood == mood,
                        action: {
                            onMoodSelected(mood)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Mood Button

private struct MoodButton: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [
                                    Color.appTheme.opacity(0.3),
                                    Color.appThemeSecondary.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color(hex: "1A1B3A").opacity(0.5),
                                    Color(hex: "2A2B5A").opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected
                                    ? Color.appTheme.opacity(0.6)
                                    : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .frame(width: 48, height: 48)

                // Emoji
                Text(mood.emoji)
                    .font(.system(size: 24))
            }
            .scaleEffect(isPressed ? 0.85 : 1.0)
            .scaleEffect(isSelected ? 1.1 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        VStack {
            MoodSelector(selectedMood: .constant(.good)) { mood in
                print("Selected mood: \(mood)")
            }
        }
        .padding()
    }
}
