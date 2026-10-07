//
//  PlayerStyle.swift
//  CortiFree
//
//  Shared visuals for the audio player & library: artwork, Liquid Glass helpers
//  (iOS 26) with material fallbacks, time formatting.
//

import SwiftUI

// MARK: - Palette

enum AudioPalette {
    static let accent = Color(hex: "B794F6")
    static let background = Color(hex: "1E1E2E")
    static let backgroundDeep = Color(hex: "2D1B4E")
    static let secondaryText = Color.white.opacity(0.65)

    static var backgroundGradient: LinearGradient {
        LinearGradient(colors: [backgroundDeep, background, Color(hex: "120F1F")],
                       startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Glass helpers

extension View {
    /// Liquid Glass surface on iOS 26, ultra-thin material fallback before.
    @ViewBuilder
    func cfGlass(cornerRadius: CGFloat = 24, interactive: Bool = false) -> some View {
        if #available(iOS 26, *) {
            if interactive {
                self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
    }

    /// Circular Liquid Glass surface (buttons).
    @ViewBuilder
    func cfGlassCircle(interactive: Bool = true) -> some View {
        if #available(iOS 26, *) {
            if interactive {
                self.glassEffect(.regular.interactive(), in: .circle)
            } else {
                self.glassEffect(.regular, in: .circle)
            }
        } else {
            self
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }

    /// Capsule Liquid Glass surface (chips).
    @ViewBuilder
    func cfGlassCapsule(tint: Color? = nil) -> some View {
        if #available(iOS 26, *) {
            if let tint {
                self.glassEffect(.regular.tint(tint).interactive(), in: .capsule)
            } else {
                self.glassEffect(.regular.interactive(), in: .capsule)
            }
        } else {
            self
                .background((tint ?? Color.white.opacity(0.08)).opacity(tint == nil ? 1 : 0.55), in: Capsule())
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }

    /// `.buttonStyle(.glass)` on iOS 26, a soft material button before.
    @ViewBuilder
    func cfGlassButtonStyle() -> some View {
        if #available(iOS 26, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(MaterialPillButtonStyle())
        }
    }
}

struct MaterialPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Press feedback for large tappable cards.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Artwork

struct SessionArtworkView: View {
    let session: GuidedSession
    var cornerRadius: CGFloat = 20
    var showsSymbol: Bool = true

    var body: some View {
        ZStack {
            LinearGradient(colors: session.artwork.colors, startPoint: .topLeading, endPoint: .bottomTrailing)

            if let name = session.artwork.imageName, UIImage(named: name) != nil {
                // Overlay on a flexible shape so the image takes the proposed size (no overflow).
                Color.clear
                    .overlay {
                        Image(name)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            } else {
                // Soft orbs for depth on symbol artworks.
                GeometryReader { geo in
                    let size = min(geo.size.width, geo.size.height)
                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: size * 0.9, height: size * 0.9)
                        .blur(radius: size * 0.12)
                        .offset(x: size * 0.35, y: -size * 0.3)
                    Circle()
                        .fill(Color.black.opacity(0.18))
                        .frame(width: size * 0.8, height: size * 0.8)
                        .blur(radius: size * 0.15)
                        .offset(x: -size * 0.3, y: size * 0.45)
                    if showsSymbol {
                        Image(systemName: session.artwork.symbol)
                            .font(.system(size: size * 0.32, weight: .medium))
                            .foregroundStyle(.white.opacity(0.92))
                            .shadow(color: .black.opacity(0.25), radius: size * 0.04, y: size * 0.02)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Formatting

enum PlayerFormat {
    static func time(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded(.down))
        let h = total / 3600, m = (total / 60) % 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}

/// Animated equalizer bars ("now playing" indicator).
struct EqualizerBars: View {
    var isAnimating: Bool
    var color: Color = AudioPalette.accent
    @State private var phase = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 3, height: isAnimating ? (phase ? [12, 6, 10][index] : [5, 12, 7][index]) : 4)
            }
        }
        .frame(height: 12, alignment: .bottom)
        .animation(isAnimating ? .easeInOut(duration: 0.45).repeatForever(autoreverses: true) : .default, value: phase)
        .onAppear { phase.toggle() }
    }
}
