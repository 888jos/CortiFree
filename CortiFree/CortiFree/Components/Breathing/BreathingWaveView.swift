//
//  BreathingWaveView.swift
//  CortiFree
//
//  "Roller coaster" breathing curve: a smooth path scrolls right-to-left past a
//  fixed marker. Rises on inhale, flat on holds, descends on exhale.
//

import SwiftUI

// MARK: - Timeline math (pure, elapsed-time driven)

struct BreathingTimeline {
    let steps: [BreathingStep]
    let cycleDuration: Double

    init(pattern: BreathingPattern) {
        let s = pattern.steps
        self.steps = s.isEmpty
            ? [BreathingStep(kind: .inhale, duration: 4, fromLevel: 0, toLevel: 1, labelKey: "breathing.wave.inhale"),
               BreathingStep(kind: .exhale, duration: 4, fromLevel: 1, toLevel: 0, labelKey: "breathing.wave.exhale")]
            : s
        self.cycleDuration = max(0.5, self.steps.reduce(0) { $0 + $1.duration })
    }

    struct Position {
        let cycle: Int
        let stepIndex: Int
        let step: BreathingStep
        let stepElapsed: Double

        var stepRemaining: Double { max(0, step.duration - stepElapsed) }
        var stepProgress: Double { step.duration > 0 ? min(1, stepElapsed / step.duration) : 1 }
        /// Unique token for each phase occurrence (drives haptics / announcements).
        var token: Int { cycle * 16 + stepIndex }
    }

    func position(at t: Double) -> Position {
        let clamped = max(0, t)
        let cycle = Int(floor(clamped / cycleDuration))
        var local = clamped - Double(cycle) * cycleDuration
        for (index, step) in steps.enumerated() {
            if local < step.duration || index == steps.count - 1 {
                return Position(cycle: cycle, stepIndex: index, step: step, stepElapsed: min(local, step.duration))
            }
            local -= step.duration
        }
        return Position(cycle: cycle, stepIndex: 0, step: steps[0], stepElapsed: 0)
    }

    /// Lung level in 0...1 at time t (t < 0 = resting, empty).
    func level(at t: Double) -> Double {
        guard t >= 0 else { return 0 }
        let p = position(at: t)
        let eased = 0.5 - 0.5 * cos(Double.pi * p.stepProgress)
        return p.step.fromLevel + (p.step.toLevel - p.step.fromLevel) * eased
    }
}

// MARK: - Wave view

struct BreathingWaveView: View {
    let timeline: BreathingTimeline
    /// Session elapsed time in seconds (may be negative during the lead-in).
    let elapsed: Double
    let accent: Color
    /// When true, the curve is static (one cycle) and only the marker moves.
    var reduceMotion: Bool = false
    /// Horizontal position of the fixed marker (0...1).
    var markerPosition: CGFloat = 0.5

    private var secondsVisible: Double {
        min(24, max(9, timeline.cycleDuration * 1.6))
    }

    var body: some View {
        Canvas { context, size in
            if reduceMotion {
                drawStatic(context: &context, size: size)
            } else {
                drawScrolling(context: &context, size: size)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: Geometry helpers

    private func yFor(level: Double, in size: CGSize) -> CGFloat {
        let pad: CGFloat = 26
        return size.height - pad - CGFloat(level) * (size.height - pad * 2)
    }

    private func drawGuides(context: inout GraphicsContext, size: CGSize) {
        for level in [0.0, 1.0] {
            var guide = Path()
            let y = yFor(level: level, in: size)
            guide.move(to: CGPoint(x: 0, y: y))
            guide.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(guide, with: .color(.white.opacity(0.08)), style: StrokeStyle(lineWidth: 1, dash: [3, 6]))
        }
    }

    private func drawMarker(context: inout GraphicsContext, at point: CGPoint) {
        // Glow
        var glow = context
        glow.addFilter(.blur(radius: 14))
        glow.fill(Path(ellipseIn: CGRect(x: point.x - 18, y: point.y - 18, width: 36, height: 36)),
                  with: .color(accent.opacity(0.9)))
        // Ring + core
        context.fill(Path(ellipseIn: CGRect(x: point.x - 12, y: point.y - 12, width: 24, height: 24)),
                     with: .color(accent))
        context.fill(Path(ellipseIn: CGRect(x: point.x - 6.5, y: point.y - 6.5, width: 13, height: 13)),
                     with: .color(.white))
    }

    // MARK: Scrolling roller coaster

    private func drawScrolling(context: inout GraphicsContext, size: CGSize) {
        drawGuides(context: &context, size: size)

        let markerX = size.width * markerPosition
        let pxPerSecond = size.width / CGFloat(secondsVisible)
        let step: CGFloat = 2

        var line = Path()
        var x: CGFloat = 0
        var first = true
        while x <= size.width + step {
            let t = elapsed + Double((x - markerX) / pxPerSecond)
            let point = CGPoint(x: x, y: yFor(level: timeline.level(at: t), in: size))
            if first { line.move(to: point); first = false } else { line.addLine(to: point) }
            x += step
        }

        var fill = line
        fill.addLine(to: CGPoint(x: size.width + step, y: size.height))
        fill.addLine(to: CGPoint(x: 0, y: size.height))
        fill.closeSubpath()

        let fillShading = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [accent.opacity(0.30), accent.opacity(0.0)]),
            startPoint: CGPoint(x: 0, y: yFor(level: 1, in: size)),
            endPoint: CGPoint(x: 0, y: size.height)
        )

        // Past (left of marker): dimmed
        var past = context
        past.clip(to: Path(CGRect(x: 0, y: 0, width: markerX, height: size.height)))
        past.fill(fill, with: .color(.white.opacity(0.04)))
        past.stroke(line, with: .color(.white.opacity(0.28)), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

        // Upcoming (right of marker): bright accent
        var future = context
        future.clip(to: Path(CGRect(x: markerX, y: 0, width: size.width - markerX, height: size.height)))
        future.fill(fill, with: fillShading)
        var glowLayer = future
        glowLayer.addFilter(.blur(radius: 8))
        glowLayer.stroke(line, with: .color(accent.opacity(0.6)), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
        future.stroke(
            line,
            with: .linearGradient(
                Gradient(colors: [.white, accent, accent.opacity(0.35)]),
                startPoint: CGPoint(x: markerX, y: 0),
                endPoint: CGPoint(x: size.width, y: 0)
            ),
            style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round)
        )

        // Fixed vertical marker line
        var marker = Path()
        marker.move(to: CGPoint(x: markerX, y: 8))
        marker.addLine(to: CGPoint(x: markerX, y: size.height - 8))
        context.stroke(marker, with: .color(.white.opacity(0.10)), lineWidth: 1)

        drawMarker(context: &context, at: CGPoint(x: markerX, y: yFor(level: timeline.level(at: elapsed), in: size)))
    }

    // MARK: Reduce Motion: static single cycle, moving marker

    private func drawStatic(context: inout GraphicsContext, size: CGSize) {
        drawGuides(context: &context, size: size)
        let inset: CGFloat = 20
        let width = size.width - inset * 2
        let cycle = timeline.cycleDuration

        var line = Path()
        var x: CGFloat = 0
        while x <= width {
            let t = Double(x / width) * cycle
            let point = CGPoint(x: inset + x, y: yFor(level: timeline.level(at: min(t, cycle - 0.0001)), in: size))
            if x == 0 { line.move(to: point) } else { line.addLine(to: point) }
            x += 2
        }
        context.stroke(line, with: .color(accent.opacity(0.85)), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

        let local = elapsed < 0 ? 0 : elapsed.truncatingRemainder(dividingBy: cycle)
        let markerX = inset + CGFloat(local / cycle) * width
        drawMarker(context: &context, at: CGPoint(x: markerX, y: yFor(level: timeline.level(at: max(0, elapsed)), in: size)))
    }
}

// MARK: - Mini static preview (catalogue cards / detail)

struct BreathingPatternPreview: View {
    let pattern: BreathingPattern
    var cycles: Int = 2
    var lineWidth: CGFloat = 2.5

    var body: some View {
        let timeline = BreathingTimeline(pattern: pattern)
        Canvas { context, size in
            let pad: CGFloat = lineWidth + 2
            let total = timeline.cycleDuration * Double(cycles)
            var line = Path()
            var x: CGFloat = 0
            while x <= size.width {
                let t = min(Double(x / size.width) * total, total - 0.0001)
                let y = size.height - pad - CGFloat(timeline.level(at: t)) * (size.height - pad * 2)
                if x == 0 { line.move(to: CGPoint(x: x, y: y)) } else { line.addLine(to: CGPoint(x: x, y: y)) }
                x += 1.5
            }
            context.stroke(
                line,
                with: .linearGradient(Gradient(colors: [pattern.accentColor.opacity(0.5), pattern.accentColor]),
                                      startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )
        }
        .accessibilityHidden(true)
    }
}
