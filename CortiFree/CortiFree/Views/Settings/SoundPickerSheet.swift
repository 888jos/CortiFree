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
            NSLocalizedString("settings.forest_rain", comment: ""),
            NSLocalizedString("settings.ocean", comment: ""),
            NSLocalizedString("settings.fireplace", comment: ""),
            NSLocalizedString("settings.gentle_wind", comment: ""),
            NSLocalizedString("settings.river", comment: ""),
            NSLocalizedString("settings.morning_birds", comment: "")
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
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Text(NSLocalizedString("settings.relaxing_sounds", comment: ""))
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
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "131146"))
                            )
                        }
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
