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
            Text(LanguageManager.shared.localizedString(for: "motivational.mood_question"))
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.white.opacity(0.8))

            GlassGroup(spacing: 8) {
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
                Color.clear
                    .frame(width: 48, height: 48)
                    .glassCircle(tint: isSelected ? Color.appTheme : nil, interactive: true)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.appTheme.opacity(0.7), lineWidth: 1.5)
                            .opacity(isSelected ? 1 : 0)
                    )

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
