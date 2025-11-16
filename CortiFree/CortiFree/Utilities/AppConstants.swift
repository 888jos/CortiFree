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
        // Primary backgrounds
        static let backgroundStart = Color(hex: "1A1B3A")
        static let backgroundEnd = Color(hex: "0D0E1F")
        static let cardBackground = Color(hex: "2A2B5A")
        static let darkBackground = Color(hex: "130C57")
        static let darkBlue = Color(hex: "1F1F3F")

        // Accent colors
        static let accentStart = Color.appTheme
        static let accentEnd = Color.appThemeSecondary
        static let primaryGreen = Color.appTheme
        static let violetDark = Color(hex: "49288C")

        // Text colors
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "B0B8D4")
        static let textTertiary = Color(hex: "8B92B0")

        // Status colors
        static let deleteRed = Color(hex: "FF4444")
        static let successGreen = Color.appTheme
        static let warningYellow = Color(hex: "FFD700")
        static let streakOrange = Color(hex: "FF8800")

        // Overlay colors
        static let overlayDark = Color.black.opacity(0.3)
        static let overlayLight = Color.white.opacity(0.1)
    }

    // MARK: - Fonts
    enum Fonts {
        static let bold = "Poppins-Bold"
        static let semiBold = "Poppins-SemiBold"
        static let medium = "Poppins-Medium"
        static let regular = "Poppins-Regular"
    }

    // MARK: - Font Sizes
    enum FontSize {
        // Titles
        static let largeTitle: CGFloat = 32
        static let title: CGFloat = 28
        static let title2: CGFloat = 24
        static let title3: CGFloat = 20

        // Body
        static let body: CGFloat = 16
        static let bodyLarge: CGFloat = 18
        static let bodySmall: CGFloat = 14

        // Caption
        static let caption: CGFloat = 12
        static let caption2: CGFloat = 10

        // Specific use cases
        static let badge: CGFloat = 10
        static let button: CGFloat = 16
        static let countdown: CGFloat = 48
        static let level: CGFloat = 36
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

    // MARK: - Routine
    enum Routine {
        static let totalDays: Int = 66 // Programme de 66 jours
        static let weeksCount: Int = 10 // 10 semaines (environ)
    }

    // MARK: - Thresholds
    enum Thresholds {
        static let streakCompletionRate: Double = 0.8 // 80%
        static let confettiDelay: Double = 3.0 // seconds
    }

    // MARK: - UserDefaults Keys
    enum UserDefaultsKeys {
        static let routineStartDate = "routineStartDate"
        static let selectedRoutineTitle = "selectedRoutineTitle"
        static let selectedSymptoms = "selectedSymptoms"
        static let onboardingQuizCompleted = "onboardingQuizCompleted"
        static let selectedPlanet = "selectedPlanet"
        static let userLevel = "userLevel"
        static let userXP = "userXP"
        static let streakDays = "streakDays"
    }

    // MARK: - Layout
    enum Layout {
        // Corner radius
        static let cornerRadius: CGFloat = 16
        static let cornerRadiusSmall: CGFloat = 12
        static let cornerRadiusLarge: CGFloat = 20
        static let cornerRadiusXLarge: CGFloat = 30

        // Padding
        static let paddingXSmall: CGFloat = 4
        static let paddingSmall: CGFloat = 8
        static let paddingMedium: CGFloat = 16
        static let paddingLarge: CGFloat = 24
        static let paddingXLarge: CGFloat = 32

        // Spacing
        static let spacingXSmall: CGFloat = 4
        static let spacingSmall: CGFloat = 8
        static let spacingMedium: CGFloat = 12
        static let spacingLarge: CGFloat = 16
        static let spacingXLarge: CGFloat = 20
        static let spacingXXLarge: CGFloat = 24

        // Icon sizes
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 20
        static let iconLarge: CGFloat = 24
        static let iconXLarge: CGFloat = 32

        // Card dimensions
        static let cardHeight: CGFloat = 120
        static let cardHeightSmall: CGFloat = 80
        static let cardHeightLarge: CGFloat = 160

        // Button dimensions
        static let buttonHeight: CGFloat = 50
        static let buttonHeightSmall: CGFloat = 40
        static let buttonHeightLarge: CGFloat = 60

        // Specific widths
        static let progressBarHeight: CGFloat = 8
        static let dividerHeight: CGFloat = 1
        static let shadowRadius: CGFloat = 10
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
