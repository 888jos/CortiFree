//
//  AnimationConstants.swift
//  CortiFree
//
//  Created on 21/01/2026.
//  Standardized animation durations and curves for consistent UX
//

import SwiftUI

// MARK: - Animation Durations

enum AnimationDuration {
    /// Very fast animations (0.15s) - micro interactions, button taps
    static let instant: Double = 0.15

    /// Fast animations (0.25s) - toggles, quick transitions
    static let fast: Double = 0.25

    /// Standard animations (0.35s) - most UI transitions
    static let standard: Double = 0.35

    /// Medium animations (0.5s) - page transitions, cards
    static let medium: Double = 0.5

    /// Slow animations (0.8s) - elaborate transitions, progress
    static let slow: Double = 0.8

    /// Very slow animations (1.2s) - splash, onboarding reveals
    static let verySlow: Double = 1.2
}

// MARK: - Animation Curves

enum AnimationCurve {
    /// Standard ease in-out for most animations
    static let standard: Animation = .easeInOut(duration: AnimationDuration.standard)

    /// Fast snap animation for toggles and quick interactions
    static let snap: Animation = .easeOut(duration: AnimationDuration.fast)

    /// Bouncy spring for playful interactions
    static let bounce: Animation = .spring(response: 0.4, dampingFraction: 0.6)

    /// Smooth spring for elegant transitions
    static let smooth: Animation = .spring(response: 0.5, dampingFraction: 0.8)

    /// Gentle spring for subtle animations
    static let gentle: Animation = .spring(response: 0.6, dampingFraction: 0.85)

    /// Heavy spring for impactful animations
    static let heavy: Animation = .spring(response: 0.3, dampingFraction: 0.7)

    /// Linear for progress bars
    static let linear: Animation = .linear(duration: AnimationDuration.standard)
}

// MARK: - Pre-configured Animations

extension Animation {
    /// Task completion checkmark animation
    static var taskComplete: Animation {
        .spring(response: 0.3, dampingFraction: 0.6)
    }

    /// Card appear animation
    static var cardAppear: Animation {
        .spring(response: 0.4, dampingFraction: 0.75)
    }

    /// Sheet presentation
    static var sheetPresent: Animation {
        .spring(response: 0.35, dampingFraction: 0.85)
    }

    /// Tab switching
    static var tabSwitch: Animation {
        .easeInOut(duration: AnimationDuration.fast)
    }

    /// Progress bar fill
    static var progressFill: Animation {
        .spring(response: 0.8, dampingFraction: 0.75)
    }

    /// Button press feedback
    static var buttonPress: Animation {
        .easeOut(duration: AnimationDuration.instant)
    }

    /// Page transition
    static var pageTransition: Animation {
        .spring(response: 0.45, dampingFraction: 0.85)
    }

    /// Breathing exercise animation
    static var breathingCircle: Animation {
        .easeInOut(duration: 4.0)
    }

    /// Pulse/glow effect
    static var pulse: Animation {
        .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    }

    /// Confetti/celebration
    static var celebration: Animation {
        .spring(response: 0.5, dampingFraction: 0.5)
    }
}

// MARK: - Staggered Animation Helpers

extension View {
    /// Apply staggered animation delay based on index
    func staggeredAnimation(index: Int, baseDelay: Double = 0.05) -> some View {
        self.animation(
            AnimationCurve.smooth.delay(Double(index) * baseDelay),
            value: true
        )
    }

    /// Fade in with delay based on index
    @ViewBuilder
    func fadeInStaggered(index: Int, isVisible: Bool, baseDelay: Double = 0.08) -> some View {
        self
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(
                AnimationCurve.smooth.delay(Double(index) * baseDelay),
                value: isVisible
            )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Animation Constants Demo")
            .font(.headline)

        Button("Standard Animation") {}
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

        Text("Durations: instant=\(AnimationDuration.instant)s, fast=\(AnimationDuration.fast)s, standard=\(AnimationDuration.standard)s")
            .font(.caption)
    }
    .padding()
}
