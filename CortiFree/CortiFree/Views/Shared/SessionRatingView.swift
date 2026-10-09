//
//  SessionRatingView.swift
//  CortiFree
//
//  End-of-session rating shared by meditations, breathing and exercises: a 0–5 slider
//  ("pas ouf" → "très bien"). Nothing is recorded until the user moves the slider.
//

import SwiftUI

/// Snapping 0–5 slider with a live label. `rating` stays nil until the first touch.
struct SessionRatingSlider: View {
    @Binding var rating: Int?
    var accent: Color = AudioPalette.accent

    @State private var dragValue: Double?

    private let steps = SessionRatingStore.range

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(rating.map(String.init) ?? "–")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(rating ?? 0)))
                Text("/ 5")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Text(rating.map { "session.rating.level.\($0)".localized } ?? "session.rating.hint".localized)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(rating == nil ? .white.opacity(0.55) : accent)
                .contentTransition(.opacity)
                .frame(height: 20)

            track
                .padding(.top, 6)

            HStack {
                Text("session.rating.low".localized)
                Spacer()
                Text("session.rating.high".localized)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white.opacity(0.5))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("session.rating.title".localized)
        .accessibilityValue(rating.map { "\($0) / 5, " + "session.rating.level.\($0)".localized } ?? "session.rating.hint".localized)
        .accessibilityAdjustableAction { direction in
            let current = rating ?? 3
            switch direction {
            case .increment: set(min(current + 1, steps.upperBound))
            case .decrement: set(max(current - 1, steps.lowerBound))
            @unknown default: break
            }
        }
    }

    private var track: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let thumb: CGFloat = 30
            let usable = width - thumb
            let shown = dragValue ?? Double(rating ?? 3)
            let x = usable * shown / Double(steps.upperBound)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.12))
                    .frame(height: 8)
                    .padding(.horizontal, thumb / 2)
                Capsule()
                    .fill(LinearGradient(colors: [accent.opacity(0.55), accent], startPoint: .leading, endPoint: .trailing))
                    .frame(width: rating == nil ? 0 : x + thumb / 2, height: 8)
                    .padding(.leading, thumb / 2)
                    .opacity(rating == nil ? 0 : 1)

                // Detents
                ForEach(Array(steps), id: \.self) { step in
                    Circle()
                        .fill(.white.opacity(Double(step) <= shown && rating != nil ? 0.9 : 0.3))
                        .frame(width: 5, height: 5)
                        .offset(x: usable * Double(step) / Double(steps.upperBound) + thumb / 2 - 2.5)
                }

                Circle()
                    .fill(.white)
                    .frame(width: thumb, height: thumb)
                    .shadow(color: accent.opacity(0.6), radius: rating == nil ? 0 : 10)
                    .overlay(Circle().strokeBorder(accent.opacity(rating == nil ? 0.3 : 1), lineWidth: 3))
                    .scaleEffect(dragValue == nil ? 1 : 1.12)
                    .offset(x: x)
                    .opacity(rating == nil ? 0.55 : 1)
            }
            .frame(height: thumb)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let raw = min(max(Double((value.location.x - thumb / 2) / usable), 0), 1) * Double(steps.upperBound)
                        dragValue = raw
                        set(Int(raw.rounded()))
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { dragValue = nil }
                    }
            )
        }
        .frame(height: 30)
    }

    private func set(_ value: Int) {
        guard value != rating else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { rating = value }
    }
}

/// Full end-of-session screen: check mark, title, summary line, the rating slider and the
/// primary action. Records the rating (if any) when the user leaves.
struct SessionEndView: View {
    let content: RatedContent
    let title: String
    let summary: String?
    var durationSeconds: Int?
    var accent: Color = AudioPalette.accent
    var secondaryAction: (label: String, icon: String, action: () -> Void)?
    let onDone: () -> Void

    @State private var rating: Int?
    @State private var appear = false
    @State private var recorded = false

    var body: some View {
        ZStack {
            AudioPalette.backgroundGradient.ignoresSafeArea()
            RadialGradient(colors: [accent.opacity(0.22), .clear], center: .init(x: 0.5, y: 0.22),
                           startRadius: 10, endRadius: 360)
                .ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer(minLength: 24)

                ZStack {
                    Circle()
                        .fill(accent.opacity(0.22))
                        .frame(width: 128, height: 128)
                        .blur(radius: 22)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72, weight: .regular))
                        .foregroundStyle(.white, accent)
                        .symbolEffect(.bounce, value: appear)
                        .scaleEffect(appear ? 1 : 0.6)
                }

                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    if let summary {
                        Text(summary)
                            .font(.system(size: 15))
                            .foregroundStyle(AudioPalette.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 32)

                VStack(spacing: 18) {
                    Text("session.rating.title".localized)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    SessionRatingSlider(rating: $rating, accent: accent)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 22)
                .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 24)

                Spacer(minLength: 16)

                VStack(spacing: 14) {
                    Button {
                        HapticManager.light()
                        recordIfNeeded()
                        onDone()
                    } label: {
                        Text("breathing.v2.finish".localized)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AudioPalette.backgroundDeep)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(accent, in: Capsule())
                    }
                    .buttonStyle(PressableCardStyle())

                    if let secondaryAction {
                        Button {
                            HapticManager.light()
                            recordIfNeeded()
                            secondaryAction.action()
                        } label: {
                            Label(secondaryAction.label, systemImage: secondaryAction.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { appear = true }
        }
    }

    private func recordIfNeeded() {
        guard let rating, !recorded else { return }
        recorded = true
        SessionRatingStore.record(rating, for: content, durationSeconds: durationSeconds)
    }
}
