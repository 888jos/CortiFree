//
//  BreathingGlass.swift
//  CortiFree
//
//  Liquid Glass helpers (iOS 26) with material fallback for the breathing screens.
//

import SwiftUI

// MARK: - Palette

enum BreathingPalette {
    static let violet = Color(hex: "B794F6")
    static let deep = Color(hex: "1E1E2E")
    static let plum = Color(hex: "2D1B4E")
}

// MARK: - Glass modifiers

extension View {
    /// Liquid Glass surface on iOS 26, ultra-thin material on earlier systems.
    @ViewBuilder
    func breathingGlass(cornerRadius: CGFloat = 24, tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(iOS 26, *) {
            let base: Glass = tint.map { Glass.regular.tint($0.opacity(0.22)) } ?? Glass.regular
            self.glassEffect(interactive ? base.interactive() : base, in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                        if let tint {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(tint.opacity(0.10))
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0.04)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
        }
    }

    /// Circular / capsule glass (for icon buttons and chips).
    @ViewBuilder
    func breathingGlassCapsule(tint: Color? = nil, interactive: Bool = true) -> some View {
        if #available(iOS 26, *) {
            let base: Glass = tint.map { Glass.regular.tint($0) } ?? Glass.regular
            self.glassEffect(interactive ? base.interactive() : base, in: .capsule)
        } else {
            self
                .background {
                    ZStack {
                        Capsule().fill(.ultraThinMaterial)
                        if let tint { Capsule().fill(tint) }
                    }
                }
                .overlay(Capsule().strokeBorder(.white.opacity(0.16), lineWidth: 1))
        }
    }

    /// `.glassProminent` / `.glass` button style with a gradient-capsule fallback.
    @ViewBuilder
    func breathingGlassButtonStyle(prominent: Bool, tint: Color = BreathingPalette.violet) -> some View {
        if #available(iOS 26, *) {
            if prominent {
                self.buttonStyle(.glassProminent).tint(tint)
            } else {
                self.buttonStyle(.glass)
            }
        } else {
            self.buttonStyle(BreathingFallbackButtonStyle(prominent: prominent, tint: tint))
        }
    }
}

struct BreathingFallbackButtonStyle: ButtonStyle {
    let prominent: Bool
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background {
                if prominent {
                    Capsule().fill(
                        LinearGradient(colors: [tint, tint.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                } else {
                    Capsule().fill(.ultraThinMaterial)
                }
            }
            .overlay(Capsule().strokeBorder(.white.opacity(prominent ? 0.25 : 0.14), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Glass container

struct BreathingGlassGroup<Content: View>: View {
    var spacing: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}

// MARK: - Background

struct BreathingBackground: View {
    var accent: Color = BreathingPalette.violet
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.6, isAnimated: !reduceMotion)

            LinearGradient(
                colors: [BreathingPalette.plum.opacity(0.55), BreathingPalette.deep.opacity(0.35), .black.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [accent.opacity(0.28), .clear],
                center: .init(x: 0.5, y: 0.18),
                startRadius: 10,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Close / icon button

struct BreathingIconButton: View {
    let systemName: String
    var accessibilityLabel: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .breathingGlassCapsule()
        .accessibilityLabel(accessibilityLabel)
    }
}
