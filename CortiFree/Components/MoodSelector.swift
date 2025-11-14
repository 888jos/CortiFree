//
//  MoodSelector.swift
//  CortiFree
//
//  Sélecteur d'humeur pour le journal
//

import SwiftUI

struct MoodSelector: View {
    @Binding var selectedMood: Mood?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))

                Text("Comment te sens-tu ?")
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                if let mood = selectedMood {
                    Text(mood.emoji)
                        .font(.system(size: 24))
                }
            }

            // Mood options
            if isExpanded || selectedMood == nil {
                HStack(spacing: 12) {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        MoodButton(
                            mood: mood,
                            isSelected: selectedMood == mood
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedMood = mood
                                HapticManager.light()
                                // Auto-collapse after selection
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation {
                                        isExpanded = false
                                    }
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Toggle button if mood selected
            if selectedMood != nil {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                        HapticManager.light()
                    }
                }) {
                    Text(isExpanded ? "Masquer" : "Changer")
                        .font(.custom("Poppins-Medium", size: 12))
                        .foregroundColor(Color.appTheme)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1A1B3A").opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct MoodButton: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.system(size: isSelected ? 32 : 28))

                Text(mood.displayName)
                    .font(.custom("Poppins-Regular", size: 10))
                    .foregroundColor(isSelected ? Color.appTheme : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            MoodSelector(selectedMood: .constant(nil))
                .padding()

            MoodSelector(selectedMood: .constant(.good))
                .padding()
        }
    }
}
