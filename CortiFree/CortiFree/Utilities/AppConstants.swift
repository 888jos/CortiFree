//
//  AppConstants.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import Foundation
import SwiftUI

enum AppConstants {
    // MARK: - Colors
    enum Colors {
        static let backgroundStart = Color(hex: "1A1B3A")
        static let backgroundEnd = Color(hex: "0D0E1F")
        static let accentStart = Color.appTheme
        static let accentEnd = Color.appThemeSecondary
        static let primaryGreen = Color.appTheme
    }

    // MARK: - Fonts
    enum Fonts {
        static let bold = "Poppins-Bold"
        static let semiBold = "Poppins-SemiBold"
        static let medium = "Poppins-Medium"
        static let regular = "Poppins-Regular"
    }

    // MARK: - Animation
    enum Animation {
        static let standardDuration: Double = 0.3
        static let progressDuration: Double = 0.6
        static let orbRotationDuration: Double = 20.0
    }

    // MARK: - XP System
    enum XP {
        static let perTask: Int = 5
        static let perLevel: Int = 100

        static func level(for xp: Int) -> Int {
            return (xp / perLevel) + 1
        }

        static func progress(for xp: Int) -> Double {
            let xpInCurrentLevel = xp % perLevel
            return Double(xpInCurrentLevel) / Double(perLevel)
        }
    }

    // MARK: - Thresholds
    enum Thresholds {
        static let streakCompletionRate: Double = 0.8 // 80%
        static let confettiDelay: Double = 3.0 // seconds
    }

    // MARK: - Layout
    enum Layout {
        static let cornerRadius: CGFloat = 16
        static let largePadding: CGFloat = 24
        static let mediumPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
    }
}

// MARK: - Gradient Extensions

extension LinearGradient {
    static var appBackground: LinearGradient {
        LinearGradient(
            colors: [AppConstants.Colors.backgroundStart, AppConstants.Colors.backgroundEnd],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var accent: LinearGradient {
        LinearGradient(
            colors: [AppConstants.Colors.accentStart, AppConstants.Colors.accentEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var orbGradient: LinearGradient {
        LinearGradient(
            colors: [
                AppConstants.Colors.accentStart,
                AppConstants.Colors.accentEnd,
                AppConstants.Colors.primaryGreen
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
