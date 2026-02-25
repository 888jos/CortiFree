//
//  CommitmentPledgeView.swift
//  CortiFree
//
//  Engagement screen before paywall
//  User selects commitment duration then holds button to pledge
//  Screen background fills with purple from bottom to top during hold
//

import SwiftUI

struct CommitmentPledgeView: View {
    let onContinue: () -> Void

    @State private var selectedDuration: CommitmentDuration = .sixtySixDays
    @State private var holdProgress: CGFloat = 0.0
    @State private var isHolding: Bool = false
    @State private var isCommitted: Bool = false
    @State private var holdAttempts: Int = 0
    @State private var screenViewTime: Date?
    @State private var holdTimer: Timer?
    @State private var hapticStep: Int = 0
    @State private var showCommitted: Bool = false
    @State private var showConfetti: Bool = false

    // MARK: - Duration Options

    enum CommitmentDuration: String, CaseIterable {
        case oneWeek = "1_week"
        case twoWeeks = "2_weeks"
        case fourWeeks = "4_weeks"
        case sixtySixDays = "66_days"

        var icon: String {
            switch self {
            case .oneWeek: return "flame"
            case .twoWeeks: return "bolt.fill"
            case .fourWeeks: return "star.fill"
            case .sixtySixDays: return "crown.fill"
            }
        }

        var percentage: String {
            switch self {
            case .oneWeek: return "8%"
            case .twoWeeks: return "12%"
            case .fourWeeks: return "23%"
            case .sixtySixDays: return "57%"
            }
        }

        var localizedTitle: String {
            "onboarding_v2.commitment.\(rawValue)".localized
        }

        var localizedSubtitle: String {
            "onboarding_v2.commitment.\(rawValue)_sub".localized
        }
    }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            Color.black.opacity(0.3)
                .ignoresSafeArea()

            // Screen fill — organic wave rising from bottom
            if holdProgress > 0 {
                GeometryReader { geo in
                    WaveRiseShape(progress: holdProgress)
                        .fill(Color(hex: "8B5CF6").opacity(0.45))
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)

                // Title
                Text("onboarding_v2.commitment.title".localized)
                    .font(.faroBold(24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)

                // Subtitle
                Text("onboarding_v2.commitment.subtitle".localized)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 8)

                // Duration options
                VStack(spacing: 10) {
                    ForEach(CommitmentDuration.allCases, id: \.self) { duration in
                        durationCard(duration)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)

                Spacer()

                // Hold to commit section OR committed message
                if !isCommitted {
                    holdToCommitSection
                        .padding(.bottom, 50)
                } else if showCommitted {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "B794F6"))

                        Text("onboarding_v2.commitment.committed".localized)
                            .font(.faroSemiBold(22))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "B794F6"), Color(hex: "8B5CF6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .padding(.bottom, 50)
                }
            }
            // Confetti overlay
            if showConfetti {
                LottieView(filename: "confetti", loopMode: .playOnce)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            screenViewTime = Date()
            MixpanelManager.shared.track(event: "onboarding_commitment_viewed", properties: [:])
        }
    }

    // MARK: - Duration Card

    private func durationCard(_ duration: CommitmentDuration) -> some View {
        let isSelected = selectedDuration == duration
        let isRecommended = duration == .sixtySixDays

        return Button(action: {
            HapticManager.light()
            withAnimation(.easeOut(duration: 0.2)) {
                selectedDuration = duration
            }
        }) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color(hex: "B794F6").opacity(0.25) : Color.white.opacity(0.06))
                        .frame(width: 44, height: 44)

                    Image(systemName: duration.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? Color(hex: "B794F6") : .white.opacity(0.4))
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(duration.localizedTitle)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                            .fixedSize()

                        if isRecommended {
                            Text("onboarding_v2.commitment.recommended".localized)
                                .font(.custom("Poppins-Bold", size: 10))
                                .foregroundColor(Color(hex: "B794F6"))
                                .fixedSize()
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: "B794F6").opacity(0.15))
                                )
                        }
                    }

                    Text(duration.localizedSubtitle)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer()

                // Percentage badge
                VStack(spacing: 1) {
                    Text(duration.percentage)
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(isSelected ? Color(hex: "B794F6") : .white.opacity(0.35))
                    Text("onboarding_v2.commitment.chose".localized)
                        .font(.custom("Poppins-Regular", size: 9))
                        .foregroundColor(isSelected ? Color(hex: "B794F6").opacity(0.6) : .white.opacity(0.2))
                }
                .frame(width: 52)

                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(hex: "B794F6") : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(Color(hex: "B794F6"))
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, isRecommended ? 16 : 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected
                          ? Color(hex: "B794F6").opacity(0.08)
                          : Color(hex: "131146").opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color(hex: "B794F6").opacity(0.5) : Color.white.opacity(0.06),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
    }

    // MARK: - Hold to Commit Section

    private var holdToCommitSection: some View {
        VStack(spacing: 16) {
            Text("onboarding_v2.commitment.hold_instruction".localized)
                .font(.custom("Poppins-Medium", size: 15))
                .foregroundColor(.white.opacity(0.6))

            // Hold button
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color(hex: "B794F6").opacity(0.25), lineWidth: 3)
                    .frame(width: 110, height: 110)

                // Inner circle
                Circle()
                    .fill(Color(hex: "B794F6").opacity(isHolding ? 0.25 : 0.12))
                    .frame(width: 100, height: 100)

                // Progress ring on top
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(Color(hex: "B794F6"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))

                // Icon
                Image(systemName: isHolding ? "hand.raised.fill" : "hand.tap.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isHolding && !isCommitted {
                            startHolding()
                        }
                    }
                    .onEnded { _ in
                        if isHolding {
                            stopHolding()
                        }
                    }
            )
        }
    }

    // MARK: - Hold Logic

    private func startHolding() {
        isHolding = true
        holdAttempts += 1
        hapticStep = 0
        HapticManager.light()

        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            let increment: CGFloat = 0.03 / 3.0 // 3 seconds total
            holdProgress = min(holdProgress + increment, 1.0)

            // Continuous haptic — interval shrinks from ~20 ticks to ~4 ticks as progress rises
            // At progress=0: fires every 20 frames (~600ms), at progress=1: every 4 frames (~120ms)
            let interval = Int(max(4, 20 - holdProgress * 16))
            hapticStep += 1
            if hapticStep % interval == 0 {
                if holdProgress < 0.4 {
                    HapticManager.light()
                } else if holdProgress < 0.75 {
                    HapticManager.medium()
                } else {
                    HapticManager.heavy()
                }
            }

            if holdProgress >= 1.0 {
                timer.invalidate()
                holdTimer = nil
                commitCompleted()
            }
        }
    }

    private func stopHolding() {
        isHolding = false
        holdTimer?.invalidate()
        holdTimer = nil

        if holdProgress < 1.0 {
            withAnimation(.easeOut(duration: 0.3)) {
                holdProgress = 0
            }
        }
    }

    private func commitCompleted() {
        isHolding = false
        HapticManager.success()

        withAnimation(.easeOut(duration: 0.4)) {
            isCommitted = true
            showConfetti = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                showCommitted = true
            }
        }

        // Track
        if let startTime = screenViewTime {
            let timeSpent = Date().timeIntervalSince(startTime)
            MixpanelManager.shared.track(
                event: "onboarding_commitment_completed",
                properties: [
                    "selected_duration": selectedDuration.rawValue,
                    "time_spent": timeSpent,
                    "hold_attempts": holdAttempts
                ]
            )
        }

        // Auto-transition after 1.2s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onContinue()
        }
    }
}

// MARK: - Wave Rise Shape

/// Fills from the bottom up with an organic, non-uniform wave top edge.
/// At progress=0 → empty. At progress=1 → full screen covered.
private struct WaveRiseShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        // The fill top sits at y = h * (1 - progress), rising from bottom.
        // We add a sinusoidal wave on the top edge for organic feel.
        // Wave amplitude shrinks near 0 and 1 so the edges look clean.
        let baseY = h * (1.0 - progress)
        let amplitude: CGFloat = 18 * sin(progress * .pi) // peaks in mid-hold
        let frequency: CGFloat = 2.5 // number of wave cycles across width

        var path = Path()
        path.move(to: CGPoint(x: 0, y: h))          // bottom-left
        path.addLine(to: CGPoint(x: w, y: h))        // bottom-right
        path.addLine(to: CGPoint(x: w, y: baseY))    // top-right (straight)

        // Draw wave top edge right→left
        let steps = 60
        for i in stride(from: steps, through: 0, by: -1) {
            let x = w * CGFloat(i) / CGFloat(steps)
            let angle = CGFloat(i) / CGFloat(steps) * frequency * 2 * .pi
            let y = baseY - amplitude * sin(angle)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.closeSubpath()
        return path
    }
}

#Preview {
    CommitmentPledgeView(onContinue: {})
}
