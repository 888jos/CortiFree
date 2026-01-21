//
//  AccessibilityHelpers.swift
//  CortiFree
//
//  Created on 21/01/2026.
//  Accessibility helpers and modifiers for VoiceOver support
//

import SwiftUI

// MARK: - Accessibility Modifiers

extension View {
    /// Makes a button accessible with proper label, hint, and traits
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }

    /// Makes an image accessible with description
    func accessibleImage(_ description: String) -> some View {
        self
            .accessibilityLabel(description)
            .accessibilityAddTraits(.isImage)
    }

    /// Makes a header accessible
    func accessibleHeader(_ text: String) -> some View {
        self
            .accessibilityLabel(text)
            .accessibilityAddTraits(.isHeader)
    }

    /// Groups elements for VoiceOver navigation
    func accessibilityGrouped(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }

    /// Minimum touch target (44x44pt per Apple guidelines)
    func accessibleTouchTarget(minSize: CGFloat = 44) -> some View {
        self
            .frame(minWidth: minSize, minHeight: minSize)
            .contentShape(Rectangle())
    }
}

// MARK: - Localized Accessibility Labels

struct AccessibilityLabels {
    // Navigation
    static var back: String { NSLocalizedString("accessibility.back", comment: "Go back") }
    static var close: String { NSLocalizedString("accessibility.close", comment: "Close") }
    static var menu: String { NSLocalizedString("accessibility.menu", comment: "Menu") }
    static var settings: String { NSLocalizedString("accessibility.settings", comment: "Settings") }
    static var profile: String { NSLocalizedString("accessibility.profile", comment: "Profile") }

    // Actions
    static var play: String { NSLocalizedString("accessibility.play", comment: "Play") }
    static var pause: String { NSLocalizedString("accessibility.pause", comment: "Pause") }
    static var stop: String { NSLocalizedString("accessibility.stop", comment: "Stop") }
    static var refresh: String { NSLocalizedString("accessibility.refresh", comment: "Refresh") }
    static var retry: String { NSLocalizedString("accessibility.retry", comment: "Retry") }

    // Tasks
    static func taskComplete(_ name: String) -> String {
        String(format: NSLocalizedString("accessibility.task_complete", comment: "Mark %@ as complete"), name)
    }

    static func taskProgress(_ completed: Int, _ total: Int) -> String {
        String(format: NSLocalizedString("accessibility.task_progress", comment: "%d of %d tasks completed"), completed, total)
    }

    // Streaks
    static func currentStreak(_ days: Int) -> String {
        let format = days == 1
            ? NSLocalizedString("accessibility.streak_day", comment: "%d day streak")
            : NSLocalizedString("accessibility.streak_days", comment: "%d days streak")
        return String(format: format, days)
    }

    // Progress
    static func progressPercent(_ value: Int) -> String {
        String(format: NSLocalizedString("accessibility.progress_percent", comment: "%d percent progress"), value)
    }

    // Breathing
    static var breatheIn: String { NSLocalizedString("accessibility.breathe_in", comment: "Breathe in") }
    static var breatheOut: String { NSLocalizedString("accessibility.breathe_out", comment: "Breathe out") }
    static var hold: String { NSLocalizedString("accessibility.hold", comment: "Hold") }

    // Subscription
    static var subscribePremium: String { NSLocalizedString("accessibility.subscribe_premium", comment: "Subscribe to premium") }
    static var restorePurchases: String { NSLocalizedString("accessibility.restore_purchases", comment: "Restore purchases") }
}

// MARK: - Accessible Button Style

struct AccessibleButtonStyle: ButtonStyle {
    let minSize: CGFloat

    init(minSize: CGFloat = 44) {
        self.minSize = minSize
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: minSize, minHeight: minSize)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

extension ButtonStyle where Self == AccessibleButtonStyle {
    static var accessible: AccessibleButtonStyle { AccessibleButtonStyle() }
    static func accessible(minSize: CGFloat) -> AccessibleButtonStyle {
        AccessibleButtonStyle(minSize: minSize)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Button("Test Button") {}
            .accessibleButton(label: "Test", hint: "Double tap to activate")

        Image(systemName: "star.fill")
            .accessibleImage("Star icon")

        Text("Header")
            .accessibleHeader("Section header")
    }
    .padding()
}
