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
        static let violet = Color(hex: "B794F6")
        static let violetLight = Color(hex: "9F7AEA")

        // Text colors
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "B0B8D4")
        static let textTertiary = Color(hex: "8B92B0")

        // Status colors
        static let deleteRed = Color(hex: "FF4444")
        static let successGreen = Color.appTheme
        static let warningYellow = Color(hex: "FFD700")
        static let streakOrange = Color(hex: "FF8800")

        // Anti-stress button colors
        static let antiStressBackground = Color(hex: "4A0000").opacity(0.66)
        static let antiStressBorder = Color(hex: "9B0003")

        // Task colors
        static let taskBackground1 = Color(hex: "0A0515")
        static let taskBackground2 = Color(hex: "1a0a2e")

        // Profile domain colors
        static let domainSerenity = Color(hex: "B794F6")
        static let domainSleep = Color(hex: "64B5F6")
        static let domainEnergy = Color(hex: "FFB74D")
        static let domainFocus = Color(hex: "81C784")
        static let domainBalance = Color(hex: "E57373")

        // Journal tab colors
        static let journalGratitude = Color(hex: "FF6B9D")
        static let journalReflection = Color(hex: "FFB74D")
        static let journalGoals = Color(hex: "4CAF50")

        // Overlay colors
        static let overlayDark = Color.black.opacity(0.3)
        static let overlayLight = Color.white.opacity(0.1)
        static let glassmorphicLight = Color.white.opacity(0.15)
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
        // Titles - responsive for iPad
        static var largeTitle: CGFloat { ResponsiveLayout.fontSize(base: 32) }
        static var title: CGFloat { ResponsiveLayout.fontSize(base: 28) }
        static var title2: CGFloat { ResponsiveLayout.fontSize(base: 24) }
        static var title3: CGFloat { ResponsiveLayout.fontSize(base: 20) }

        // Body - responsive for iPad
        static var body: CGFloat { ResponsiveLayout.fontSize(base: 16) }
        static var bodyLarge: CGFloat { ResponsiveLayout.fontSize(base: 18) }
        static var bodySmall: CGFloat { ResponsiveLayout.fontSize(base: 14) }

        // Caption - responsive for iPad
        static var caption: CGFloat { ResponsiveLayout.fontSize(base: 12) }
        static var caption2: CGFloat { ResponsiveLayout.fontSize(base: 10) }

        // Specific use cases - responsive for iPad
        static var badge: CGFloat { ResponsiveLayout.fontSize(base: 10) }
        static var button: CGFloat { ResponsiveLayout.fontSize(base: 16) }
        static var countdown: CGFloat { ResponsiveLayout.fontSize(base: 48) }
        static var level: CGFloat { ResponsiveLayout.fontSize(base: 36) }
    }

    // MARK: - Animation
    enum Animation {
        static let standardDuration: Double = 0.3
        static let progressDuration: Double = 0.6
        static let orbRotationDuration: Double = 20.0
        static let dayNavigationDuration: Double = 0.2
        static let confettiDuration: Double = 2.0
        static let cascadeDelay: TimeInterval = 0.05
        static let refreshDelay: UInt64 = 1_500_000_000 // 1.5 seconds in nanoseconds
        static let firebaseLoadDelay: UInt64 = 100_000_000 // 0.1 second in nanoseconds
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
        // Corner radius - responsive for iPad
        static var cornerRadius: CGFloat { ResponsiveLayout.padding(base: 16) }
        static var cornerRadiusSmall: CGFloat { ResponsiveLayout.padding(base: 12) }
        static var cornerRadiusLarge: CGFloat { ResponsiveLayout.padding(base: 20) }
        static var cornerRadiusXLarge: CGFloat { ResponsiveLayout.padding(base: 30) }

        // Padding - responsive for iPad
        static var paddingXSmall: CGFloat { ResponsiveLayout.padding(base: 4) }
        static var paddingSmall: CGFloat { ResponsiveLayout.padding(base: 8) }
        static var paddingMedium: CGFloat { ResponsiveLayout.padding(base: 16) }
        static var paddingLarge: CGFloat { ResponsiveLayout.padding(base: 24) }
        static var paddingXLarge: CGFloat { ResponsiveLayout.padding(base: 32) }

        // Spacing - responsive for iPad
        static var spacingXSmall: CGFloat { ResponsiveLayout.spacing(base: 4) }
        static var spacingSmall: CGFloat { ResponsiveLayout.spacing(base: 8) }
        static var spacingMedium: CGFloat { ResponsiveLayout.spacing(base: 12) }
        static var spacingLarge: CGFloat { ResponsiveLayout.spacing(base: 16) }
        static var spacingXLarge: CGFloat { ResponsiveLayout.spacing(base: 20) }
        static var spacingXXLarge: CGFloat { ResponsiveLayout.spacing(base: 24) }

        // Icon sizes - responsive for iPad
        static var iconSmall: CGFloat { ResponsiveLayout.cardWidth(base: 16) }
        static var iconMedium: CGFloat { ResponsiveLayout.cardWidth(base: 20) }
        static var iconLarge: CGFloat { ResponsiveLayout.cardWidth(base: 24) }
        static var iconXLarge: CGFloat { ResponsiveLayout.cardWidth(base: 32) }

        // Card dimensions - responsive for iPad
        static var cardHeight: CGFloat { ResponsiveLayout.cardHeight(base: 120) }
        static var cardHeightSmall: CGFloat { ResponsiveLayout.cardHeight(base: 80) }
        static var cardHeightLarge: CGFloat { ResponsiveLayout.cardHeight(base: 160) }

        // Button dimensions - responsive for iPad
        static var buttonHeight: CGFloat { ResponsiveLayout.cardHeight(base: 50) }
        static var buttonHeightSmall: CGFloat { ResponsiveLayout.cardHeight(base: 40) }
        static var buttonHeightLarge: CGFloat { ResponsiveLayout.cardHeight(base: 60) }
        static var antiStressButtonHeight: CGFloat { ResponsiveLayout.cardHeight(base: 54) }
        static var antiStressButtonWidth: CGFloat { ResponsiveLayout.cardWidth(base: 336) }

        // Specific widths - responsive for iPad
        static var progressBarHeight: CGFloat { ResponsiveLayout.cardHeight(base: 8) }
        static let dividerHeight: CGFloat = 1
        static var shadowRadius: CGFloat { ResponsiveLayout.padding(base: 10) }

        // Header dimensions - responsive for iPad
        static var headerHeight: CGFloat { ResponsiveLayout.cardHeight(base: 60) }
        static var bannerHeight: CGFloat { ResponsiveLayout.cardHeight(base: 220) }
        static var avatarSize: CGFloat { ResponsiveLayout.cardWidth(base: 80) }

        // Profile specific - responsive for iPad
        static var profileBannerHeight: CGFloat { ResponsiveLayout.cardHeight(base: 220) }
        static var profileAvatarSize: CGFloat { ResponsiveLayout.cardWidth(base: 80) }
        static var radarChartSize: CGFloat { ResponsiveLayout.cardWidth(base: 256) }

        // Task card dimensions - responsive for iPad
        static var taskCardSpacing: CGFloat { ResponsiveLayout.spacing(base: 16) }
        static var taskCardPadding: CGFloat { ResponsiveLayout.padding(base: 20) }

        // Journal dimensions - responsive for iPad
        static var journalHeaderHeight: CGFloat { ResponsiveLayout.cardHeight(base: 140) }
        static var journalSegmentHeight: CGFloat { ResponsiveLayout.cardHeight(base: 44) }
        static var journalStatCardHeight: CGFloat { ResponsiveLayout.cardHeight(base: 100) }

        // Task view specific - responsive for iPad
        static var taskBottomPadding: CGFloat { ResponsiveLayout.padding(base: 100) }
        static let taskSkeletonCount: Int = 5
    }

    // MARK: - Program Configuration
    enum Program {
        static let totalDays: Int = 66
        static let totalWeeks: Int = 10
        static let defaultInitialScore: Int = 45
        static let daysPerWeek: Int = 7
    }

    // MARK: - Habit Configuration
    enum Habits {
        // Habit IDs
        enum ID {
            static let sleep = "sleep"
            static let breathing = "breathing"
            static let meditation = "meditation"
            static let water = "water"
            static let sport = "sport"
            static let nature = "nature"
            static let social = "social"
            static let journal = "journal"
        }

        // Difficulty levels
        enum Difficulty {
            static let easy: Int = 1
            static let medium: Int = 2
            static let hard: Int = 3
        }

        // Default values
        static let defaultWaterQuantity = "2L"
    }

    // MARK: - Notification Names
    enum Notifications {
        static let taskValidated = NSNotification.Name("TaskValidated")
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

    static var taskBackground: LinearGradient {
        LinearGradient(
            colors: [
                AppConstants.Colors.taskBackground1,
                AppConstants.Colors.taskBackground2,
                AppConstants.Colors.taskBackground1
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
