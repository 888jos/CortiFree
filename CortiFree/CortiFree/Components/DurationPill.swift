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
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.appTheme.opacity(0.3) : Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? Color.appTheme : Color.white.opacity(0.1),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
