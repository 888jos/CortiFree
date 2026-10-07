//
//  DurationPill.swift
//  CortiFree
//
//  Created by Claude on 23/11/2025.
//  Shared component for duration selection pills
//

import SwiftUI

struct DurationPill: View {
    let duration: Int
    let isSelected: Bool
    let action: () -> Void

    private var displayText: String {
        let minutes = duration / 60
        return "\(minutes)'"
    }

    var body: some View {
        Button(action: action) {
            Text(displayText)
                .font(.custom("Poppins-SemiBold", size: 15))
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .glassCard(cornerRadius: 12, tint: isSelected ? Color.appTheme : nil, interactive: true)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.appTheme, lineWidth: 1.5)
                        .opacity(isSelected ? 1 : 0)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
