//
//  LanguagePickerSheet.swift
//  CortiFree
//
//  Created on 21/01/2026.
//  Extracted from SettingsView for better modularity
//

import SwiftUI

struct LanguagePickerSheet: View {
    @Binding var selectedLanguage: String
    var onLanguageChange: ((String) -> Void)?
    @Environment(\.dismiss) private var dismiss

    let languages = [
        ("fr", "Français", "🇫🇷"),
        ("en", "English", "🇬🇧")
    ]

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
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

                VStack(spacing: 8) {
                    Text(NSLocalizedString("settings.choose_language", comment: ""))
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)

                    Text(NSLocalizedString("settings.language_subtitle", comment: ""))
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Languages list
                VStack(spacing: 12) {
                    ForEach(languages, id: \.0) { language in
                        Button(action: {
                            HapticManager.medium()

                            // Don't change if it's already selected
                            if selectedLanguage == language.0 {
                                dismiss()
                                return
                            }

                            // Call the callback to handle language change
                            onLanguageChange?(language.0)
                            dismiss()
                        }) {
                            HStack(spacing: 16) {
                                Text(language.2)
                                    .font(.system(size: 32))

                                Text(language.1)
                                    .font(.custom("Poppins-SemiBold", size: 18))
                                    .foregroundColor(.white)

                                Spacer()

                                if selectedLanguage == language.0 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.appTheme)
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        selectedLanguage == language.0 ?
                                        Color.appTheme.opacity(0.15) :
                                        Color(hex: "131146")
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                selectedLanguage == language.0 ?
                                                Color.appTheme.opacity(0.5) :
                                                Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)

                Text(NSLocalizedString("settings.language_restart_note", comment: ""))
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
        }
    }
}

#Preview {
    LanguagePickerSheet(selectedLanguage: .constant("fr"))
}
