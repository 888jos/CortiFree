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

    private var languages: [(String, String, String)] {
        LanguageManager.Language.allCases.map { ($0.rawValue, $0.displayName, $0.flag) }
    }

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

                VStack(spacing: 8) {
                    Text(LanguageManager.shared.localizedString(for: "settings.choose_language"))
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)

                    Text(LanguageManager.shared.localizedString(for: "settings.language_subtitle"))
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
                            .glassCard(
                                cornerRadius: 20,
                                tint: selectedLanguage == language.0 ? Color.appTheme : nil,
                                interactive: true
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(
                                        selectedLanguage == language.0 ?
                                        Color.appTheme.opacity(0.6) :
                                        Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)

                Text(LanguageManager.shared.localizedString(for: "settings.language_restart_note"))
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
