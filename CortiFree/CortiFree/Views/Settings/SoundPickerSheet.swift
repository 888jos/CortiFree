//
//  SoundPickerSheet.swift
//  CortiFree
//
//  Created on 21/01/2026.
//  Extracted from SettingsView for better modularity
//

import SwiftUI

struct SoundPickerSheet: View {
    @Binding var selectedSound: String
    @Environment(\.dismiss) private var dismiss

    var sounds: [String] {
        [
            LanguageManager.shared.localizedString(for: "settings.forest_rain"),
            LanguageManager.shared.localizedString(for: "settings.ocean"),
            LanguageManager.shared.localizedString(for: "settings.fireplace"),
            LanguageManager.shared.localizedString(for: "settings.gentle_wind"),
            LanguageManager.shared.localizedString(for: "settings.river"),
            LanguageManager.shared.localizedString(for: "settings.morning_birds")
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1F0140"), Color(hex: "01000C")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 36, height: 36)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassCircle(interactive: true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Text(LanguageManager.shared.localizedString(for: "settings.relaxing_sounds"))
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                VStack(spacing: 12) {
                    ForEach(sounds, id: \.self) { sound in
                        Button(action: {
                            HapticManager.medium()
                            selectedSound = sound
                            dismiss()
                        }) {
                            HStack {
                                Text(sound)
                                    .font(.custom("Poppins-Regular", size: 16))
                                    .foregroundColor(.white)

                                Spacer()

                                if selectedSound == sound {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color.appTheme)
                                }
                            }
                            .padding(16)
                            .glassCard(
                                cornerRadius: 18,
                                tint: selectedSound == sound ? Color.appTheme : nil,
                                interactive: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }
}

#Preview {
    SoundPickerSheet(selectedSound: .constant("Ocean"))
}
