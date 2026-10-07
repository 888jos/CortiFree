//
//  LanguageSelectorButton.swift
//  CortiFree
//
//  Created by Claude on 01/12/2025.
//  Language selector button for onboarding (FR/EN toggle)
//

import SwiftUI

struct LanguageSelectorButton: View {
    @ObservedObject var languageManager = LanguageManager.shared

    var body: some View {
        Button(action: {
            HapticManager.light()
            withAnimation(.easeInOut(duration: 0.3)) {
                languageManager.toggle()
            }
        }) {
            Text("\(languageManager.currentLanguage.flag) \(languageManager.currentLanguage.code)")
                .font(.custom("Poppins-Medium", size: 10))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassCapsule(interactive: true)
    }
}

#Preview {
    ZStack {
        Color.black
        LanguageSelectorButton()
    }
}
