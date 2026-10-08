//
//  BreathingSessionKit.swift
//  CortiFree
//
//  Shared pieces of the breathing detail sheet and the full-screen exercise:
//  artwork (with a placeholder until a real image exists), user preferences,
//  the ambience loop and the roller-coaster track.
//

import SwiftUI
import AVFoundation

// MARK: - Artwork

extension BreathingPattern {
    /// Asset name for the exercise artwork. Add an image set with this name in
    /// Assets.xcassets (e.g. `breathing_coherence`) and it replaces the placeholder.
    var artworkImageName: String { "breathing_\(key)" }
}

/// The exercise image, or a calm violet placeholder showing the rhythm when no asset exists yet.
struct BreathingArtwork: View {
    let pattern: BreathingPattern

    var body: some View {
        if UIImage(named: pattern.artworkImageName) != nil {
            Color.clear
                .overlay { Image(pattern.artworkImageName).resizable().scaledToFill() }
                .clipped()
        } else {
            ZStack {
                LinearGradient(colors: [Color(hex: "3B2470"), Color(hex: "1E1E2E")], startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [AudioPalette.accent.opacity(0.45), .clear], center: .init(x: 0.7, y: 0.25), startRadius: 10, endRadius: 260)
                BreathingPatternPreview(pattern: pattern, cycles: 2, lineWidth: 4)
                    .padding(.horizontal, 40)
                    .frame(height: 120)
                    .opacity(0.55)
                Image(systemName: pattern.symbol)
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(.white.opacity(0.85))
                    .offset(y: -70)
            }
        }
    }
}

// MARK: - Preferences

/// Remembered choices for breathing sessions (ambience, voice guide, haptics).
final class BreathingPreferences: ObservableObject {
    static let shared = BreathingPreferences()

    private let defaults = UserDefaults.standard

    var ambience: AudioAmbience? {
        get { AudioAmbience(rawValue: defaults.string(forKey: "breathing.ambience") ?? "") }
        set { objectWillChange.send(); defaults.set(newValue?.rawValue ?? "", forKey: "breathing.ambience") }
    }

    var hapticsEnabled: Bool {
        get { defaults.object(forKey: "breathing.haptics") as? Bool ?? true }
        set { objectWillChange.send(); defaults.set(newValue, forKey: "breathing.haptics") }
    }

    var ambienceVolume: Double {
        get { defaults.object(forKey: "breathing.ambienceVolume") as? Double ?? 0.5 }
        set { objectWillChange.send(); defaults.set(newValue, forKey: "breathing.ambienceVolume") }
    }
}

// MARK: - Ambience loop

/// Loops the chosen ambience under a breathing exercise, with a short fade in/out.
final class BreathingAmbiencePlayer {
    private var player: AVAudioPlayer?

    func start(_ ambience: AudioAmbience?, volume: Double) {
        stop(fade: false)
        guard let url = ambience?.url, let player = try? AVAudioPlayer(contentsOf: url) else { return }
        AudioFocus.acquire(.breathingAmbience) // mixes with the user's music
        player.numberOfLoops = -1
        player.volume = 0
        player.play()
        player.setVolume(Float(volume), fadeDuration: 2)
        self.player = player
    }

    func setVolume(_ volume: Double) {
        player?.volume = Float(volume)
    }

    func pause() { player?.pause() }
    func resume() { player?.play() }

    func stop(fade: Bool = true) {
        guard let player else { return }
        self.player = nil
        if fade {
            player.setVolume(0, fadeDuration: 1.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
                player.stop()
                if self?.player == nil { AudioFocus.release(.breathingAmbience) }
            }
        } else {
            player.stop()
            AudioFocus.release(.breathingAmbience)
        }
    }
}

// MARK: - Roller-coaster track

/// The track scrolls right-to-left under a fixed glowing marker:
/// climbing = inhale, flat = hold, going down = exhale.
struct BreathingTrack: View {
    let timeline: BreathingTimeline
    let elapsed: Double
    var accent: Color = AudioPalette.accent
    var reduceMotion = false
    /// Marker position as a fraction of the width.
    var markerRatio: CGFloat = 0.32

    /// Seconds of track visible on screen.
    private var window: Double { min(24, max(13, timeline.cycleDuration * 2)) }

    var body: some View {
        let timeline = timeline, elapsed = elapsed, window = window, markerRatio = markerRatio
        let accent = accent, reduceMotion = reduceMotion
        Canvas { context, size in
            let inset: CGFloat = 26
            let height = size.height - inset * 2
            let markerX = size.width * markerRatio
            func y(_ level: Double) -> CGFloat { inset + (1 - CGFloat(level)) * height }
            func point(at x: CGFloat) -> CGPoint {
                let time = elapsed + Double((x - markerX) / size.width) * window
                return CGPoint(x: x, y: y(timeline.level(at: time)))
            }
            let level = timeline.level(at: elapsed)

            // Faint rails at the top and bottom of the breath.
            for railLevel in [0.0, 1.0] {
                var rail = Path()
                rail.move(to: CGPoint(x: 0, y: y(railLevel)))
                rail.addLine(to: CGPoint(x: size.width, y: y(railLevel)))
                context.stroke(rail, with: .color(.white.opacity(0.06)), style: StrokeStyle(lineWidth: 1, dash: [3, 6]))
            }

            var past = Path(), future = Path()
            let steps = Int(size.width / 2)
            for step in 0...steps {
                let x = size.width * CGFloat(step) / CGFloat(steps)
                let p = point(at: x)
                if x <= markerX { if past.isEmpty { past.move(to: p) } else { past.addLine(to: p) } }
                if x >= markerX - size.width / CGFloat(steps) { if future.isEmpty { future.move(to: p) } else { future.addLine(to: p) } }
            }
            past.addLine(to: CGPoint(x: markerX, y: y(level)))

            // The road ahead: a faint line over a soft wash of light.
            var area = future
            area.addLine(to: CGPoint(x: size.width, y: size.height))
            area.addLine(to: CGPoint(x: markerX, y: size.height))
            area.closeSubpath()
            context.fill(area, with: .linearGradient(Gradient(colors: [accent.opacity(0.12), .clear]), startPoint: CGPoint(x: 0, y: inset), endPoint: CGPoint(x: 0, y: size.height)))
            context.stroke(future, with: .color(accent.opacity(0.32)), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

            // The road travelled: bright near the marker, fading behind it.
            var glow = context
            glow.opacity = 0.22
            glow.stroke(past, with: .linearGradient(Gradient(colors: [accent.opacity(0), accent]), startPoint: .zero, endPoint: CGPoint(x: markerX, y: 0)), style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
            context.stroke(past, with: .linearGradient(Gradient(colors: [accent.opacity(0), accent]), startPoint: .zero, endPoint: CGPoint(x: markerX, y: 0)), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))

            // The marker: a glowing orb riding the curve.
            let center = CGPoint(x: markerX, y: y(level))
            let halo = reduceMotion ? 22 : 22 + 14 * level
            context.fill(Path(ellipseIn: CGRect(x: center.x - halo, y: center.y - halo, width: halo * 2, height: halo * 2)), with: .radialGradient(Gradient(colors: [accent.opacity(0.45), .clear]), center: center, startRadius: 4, endRadius: halo))
            context.fill(Path(ellipseIn: CGRect(x: center.x - 12, y: center.y - 12, width: 24, height: 24)), with: .color(accent))
            context.fill(Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)), with: .color(.white))
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Round action (detail sheet)

/// Circle icon with its caption, the secondary actions of the detail sheet.
struct BreathingRoundAction: View {
    let title: String
    let icon: String
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) { BreathingRoundActionLabel(title: title, icon: icon, isActive: isActive) }
            .buttonStyle(PressableCardStyle())
    }
}

struct BreathingRoundActionLabel: View {
    let title: String
    let icon: String
    var isActive = false

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(isActive ? AudioPalette.accent : .white)
                .frame(width: 50, height: 50)
                .background(isActive ? AnyShapeStyle(AudioPalette.accent.opacity(0.16)) : AnyShapeStyle(Color.white.opacity(0.06)), in: Circle())
                .overlay(Circle().strokeBorder(isActive ? AudioPalette.accent.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1))
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isActive ? AudioPalette.accent : AudioPalette.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
