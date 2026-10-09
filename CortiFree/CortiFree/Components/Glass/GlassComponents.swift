//
//  GlassComponents.swift
//  CortiFree
//
//  App-wide Liquid Glass layer (iOS 26) with a material fallback for earlier systems.
//
//  Usage:
//    VStack { ... }.padding().glassCard()                       // card surface
//    VStack { ... }.glassCard(cornerRadius: 24, tint: .violet)  // tinted card
//    Text("Chip").padding(...).glassCapsule()                   // chip / pill
//    Button("Continuer") { }.buttonStyle(.glassPrimary)         // CTA (label owns its padding/frame)
//    Button("Plus tard") { }.buttonStyle(.glassSecondary)       // secondary action
//    GlassGroup { ... }                                         // groups nearby glass shapes
//

import SwiftUI

// MARK: - Tokens

enum GlassTokens {
    static let accent = AppConstants.Colors.violet          // B794F6
    static let deep = Color(hex: "1E1E2E")
    static let plum = Color(hex: "2D1B4E")
    static let cardRadius: CGFloat = 22
    static let strokeOpacity: Double = 0.08
}

// MARK: - Surfaces

extension View {
    /// Liquid Glass card surface. iOS 26: `.glassEffect(.regular…)`; earlier: ultra-thin material,
    /// hairline white stroke and a soft shadow.
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = GlassTokens.cardRadius, tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(iOS 26, *) {
            let base: Glass = tint.map { Glass.regular.tint($0.opacity(0.20)) } ?? Glass.regular
            // The glass doesn't receive touches: make the whole card tappable, not just its content.
            self.contentShape(.rect(cornerRadius: cornerRadius, style: .continuous))
                .glassEffect(interactive ? base.interactive() : base,
                             in: .rect(cornerRadius: cornerRadius, style: .continuous))
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
                            LinearGradient(colors: [.white.opacity(0.16), .white.opacity(GlassTokens.strokeOpacity)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 6)
                .contentShape(.rect(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    /// Capsule glass for chips, pills and small buttons.
    @ViewBuilder
    func glassCapsule(tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(iOS 26, *) {
            let base: Glass = tint.map { Glass.regular.tint($0.opacity(0.35)) } ?? Glass.regular
            self.contentShape(.capsule)
                .glassEffect(interactive ? base.interactive() : base, in: .capsule)
        } else {
            self
                .background {
                    ZStack {
                        Capsule().fill(.ultraThinMaterial)
                        if let tint { Capsule().fill(tint.opacity(0.18)) }
                    }
                }
                .overlay(Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 1))
        }
    }

    /// Circular glass for icon buttons / avatars.
    @ViewBuilder
    func glassCircle(tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(iOS 26, *) {
            let base: Glass = tint.map { Glass.regular.tint($0.opacity(0.35)) } ?? Glass.regular
            self.contentShape(.circle)
                .glassEffect(interactive ? base.interactive() : base, in: .circle)
        } else {
            self
                .background {
                    ZStack {
                        Circle().fill(.ultraThinMaterial)
                        if let tint { Circle().fill(tint.opacity(0.18)) }
                    }
                }
                .overlay(Circle().strokeBorder(.white.opacity(0.14), lineWidth: 1))
        }
    }

    /// SwiftUI's native `.glassProminent` / `.glass` button styles on iOS 26, glass-like fallback otherwise.
    /// Prefer `.buttonStyle(.glassPrimary)` when the label already defines its own frame.
    @ViewBuilder
    func nativeGlassButton(prominent: Bool, tint: Color = GlassTokens.accent) -> some View {
        if #available(iOS 26, *) {
            if prominent {
                self.buttonStyle(.glassProminent).tint(tint)
            } else {
                self.buttonStyle(.glass)
            }
        } else {
            self.buttonStyle(NativeGlassFallbackButtonStyle(prominent: prominent, tint: tint))
        }
    }
}

/// Fallback for `nativeGlassButton`: mimics the native glass button metrics (adds its own padding).
struct NativeGlassFallbackButtonStyle: ButtonStyle {
    let prominent: Bool
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        GlassButtonBody(configuration: configuration,
                        label: AnyView(ButtonStyleConfigurationLabelPadding(label: configuration.label)),
                        prominent: prominent,
                        tint: prominent ? tint : .clear,
                        cornerRadius: nil)
    }
}

private struct ButtonStyleConfigurationLabelPadding: View {
    let label: ButtonStyleConfiguration.Label
    var body: some View {
        label.padding(.horizontal, 18).padding(.vertical, 10)
    }
}

// MARK: - Button styles

/// Prominent glass CTA. The label keeps its own padding / frame; the style supplies the surface.
/// iOS 26: accent-tinted interactive Liquid Glass. Earlier: accent gradient with a glossy hairline.
struct GlassPrimaryButtonStyle: ButtonStyle {
    var tint: Color = GlassTokens.accent
    /// `nil` → capsule, otherwise a continuous rounded rectangle.
    var cornerRadius: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        GlassButtonBody(configuration: configuration, prominent: true, tint: tint, cornerRadius: cornerRadius)
    }
}

/// Secondary glass button (neutral glass, white label by default).
struct GlassSecondaryButtonStyle: ButtonStyle {
    var tint: Color? = nil
    var cornerRadius: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        GlassButtonBody(configuration: configuration, prominent: false, tint: tint ?? .clear, cornerRadius: cornerRadius)
    }
}

extension ButtonStyle where Self == GlassPrimaryButtonStyle {
    static var glassPrimary: GlassPrimaryButtonStyle { GlassPrimaryButtonStyle() }
    static func glassPrimary(tint: Color = GlassTokens.accent, cornerRadius: CGFloat? = nil) -> GlassPrimaryButtonStyle {
        GlassPrimaryButtonStyle(tint: tint, cornerRadius: cornerRadius)
    }
}

extension ButtonStyle where Self == GlassSecondaryButtonStyle {
    static var glassSecondary: GlassSecondaryButtonStyle { GlassSecondaryButtonStyle() }
    static func glassSecondary(tint: Color? = nil, cornerRadius: CGFloat? = nil) -> GlassSecondaryButtonStyle {
        GlassSecondaryButtonStyle(tint: tint, cornerRadius: cornerRadius)
    }
}

private struct GlassButtonBody: View {
    let configuration: ButtonStyleConfiguration
    var label: AnyView? = nil
    let prominent: Bool
    let tint: Color
    let cornerRadius: CGFloat?

    @Environment(\.isEnabled) private var isEnabled

    private var shape: AnyShape {
        if let cornerRadius {
            AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            AnyShape(Capsule())
        }
    }

    var body: some View {
        surface
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.5)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }

    @ViewBuilder
    private var labelView: some View {
        if let label { label } else { configuration.label }
    }

    @ViewBuilder
    private var surface: some View {
        if #available(iOS 26, *) {
            if prominent {
                labelView
                    .foregroundStyle(.white)
                    .glassEffect(.regular.tint(tint.opacity(isEnabled ? 0.85 : 0.35)).interactive(), in: shape)
            } else {
                labelView
                    .glassEffect(tint == .clear ? .regular.interactive() : .regular.tint(tint.opacity(0.3)).interactive(),
                                 in: shape)
            }
        } else {
            if prominent {
                labelView
                    .foregroundStyle(.white)
                    .background(
                        shape.fill(LinearGradient(colors: [tint, tint.opacity(0.72)],
                                                  startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .overlay(shape.stroke(.white.opacity(0.25), lineWidth: 1))
                    .shadow(color: tint.opacity(0.35), radius: 12, x: 0, y: 6)
            } else {
                labelView
                    .background(shape.fill(.ultraThinMaterial))
                    .background(shape.fill(tint.opacity(0.15)))
                    .overlay(shape.stroke(.white.opacity(0.14), lineWidth: 1))
            }
        }
    }
}

// MARK: - Container

/// Wraps nearby glass elements so they blend and morph together on iOS 26 (plain content otherwise).
struct GlassGroup<Content: View>: View {
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

// MARK: - Icon button

/// Round glass icon button (close, back, settings…).
struct GlassIconButton: View {
    let systemName: String
    var size: CGFloat = 44
    var accessibilityLabel: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassCircle(interactive: true)
        .accessibilityLabel(accessibilityLabel)
    }
}
