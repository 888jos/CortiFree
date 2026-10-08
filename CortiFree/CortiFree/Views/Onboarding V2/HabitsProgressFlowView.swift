//
//  HabitsProgressFlowView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Vue montrant la progression des habitudes avec graphiques
//

import SwiftUI

struct HabitsProgressFlowView: View {
    /// Daily minutes chosen in the habits quiz; the weekly targets scale with it.
    var availableMinutes: Int? = nil
    var onBack: (() -> Void)? = nil
    let onComplete: () -> Void
    @ObservedObject var languageManager = LanguageManager.shared
    @State private var currentHabitIndex: Int = 0
    @State private var currentWeek: Int = 1
    // Charts are drawn right away: there is nothing to load.
    @State private var shouldRenderChart = true
    @State private var loadedHabits: Set<Int> = Set(0..<8)
    @State private var screenViewTime: Date?

    // Week-4 targets of the 28-day plan, scaled to the daily time chosen in the quiz.
    private var habitProgresses: [HabitProgress] {
        OnboardingHabitTargets.targets(availableMinutes: availableMinutes).map { target in
            HabitProgress(
                icon: target.icon,
                title: "onboarding_v2.habits_progress.\(target.id)_title".localized,
                yAxisLabel: "",
                yAxisValues: target.yAxisValues,
                currentValue: target.currentValue,
                weekNumber: OnboardingHabitTargets.planWeeks,
                statMessage: target.statMessage,
                maxValue: 4.0,
                currentProgress: 3.7,
                curveStyle: target.curveStyle
            )
        }
    }

    private var currentHabitProgress: HabitProgress {
        habitProgresses[currentHabitIndex]
    }

    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()

            if !shouldRenderChart {
                // Loading state - show simple UI without heavy computation
                VStack(spacing: 20) {
                    Text("onboarding_v2.habits_progress.loading".localized)
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)

                    ProgressView()
                        .tint(Color(hex: "B794F6"))
                        .scaleEffect(1.5)
                }
            }

            ScrollView {
                VStack(spacing: 0) {
                // Description text
                VStack(spacing: 0) {
                    Text("onboarding_v2.habits_progress.description_part1".localized)
                        .font(.custom("Poppins-Regular", size: 17))
                        .foregroundColor(.white)
                    +
                    Text("onboarding_v2.habits_progress.description_highlight".localized)
                        .font(.custom("Poppins-SemiBold", size: 17))
                        .foregroundColor(Color(hex: "B794F6"))
                    +
                    Text("onboarding_v2.habits_progress.description_part2".localized)
                        .font(.custom("Poppins-Regular", size: 17))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
                .responsivePadding(.top, ResponsiveLayout.isIPad ? 50 : 70)
                .responsivePadding(.bottom, 28)
                .opacity(shouldRenderChart ? 1 : 0)

                // Habit icons row
                HStack(spacing: 6) {
                    ForEach(0..<habitProgresses.count, id: \.self) { index in
                        Button(action: {
                            HapticManager.light()
                            currentHabitIndex = index
                            currentWeek = 1  // Reset to week 1 when changing habit

                        }) {
                            Image(systemName: habitProgresses[index].icon)
                                .font(.system(size: 17))
                                .foregroundColor(currentHabitIndex == index ? Color(hex: "B794F6") : .white.opacity(0.5))
                                .frame(width: 35, height: 35)
                                .glassCard(cornerRadius: 10, tint: currentHabitIndex == index ? GlassTokens.accent : nil, interactive: true)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(Color(hex: "B794F6").opacity(currentHabitIndex == index ? 1 : 0), lineWidth: 1.5)
                                )
                        }
                        .disabled(!shouldRenderChart)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(shouldRenderChart ? 1 : 0)

                // Chart card
                VStack(spacing: 16) {
                    // Title with gradient
                    Text(currentHabitProgress.title)
                        .font(.faroBold(20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "B794F6")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Chart with per-habit lazy loading
                    if shouldRenderChart && loadedHabits.contains(currentHabitIndex) {
                        HabitProgressChart(
                            yAxisValues: currentHabitProgress.yAxisValues,
                            currentValue: currentHabitProgress.currentValue,
                            weekNumber: currentHabitProgress.weekNumber,
                            maxValue: currentHabitProgress.maxValue,
                            currentProgress: currentHabitProgress.currentProgress,
                            curveStyle: currentHabitProgress.curveStyle,
                            currentWeek: $currentWeek
                        )
                        .frame(height: 175)
                        .drawingGroup()
                        .animation(nil, value: currentHabitIndex)
                        .transition(.opacity)
                    } else {
                        // Loading placeholder for this specific habit
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(Color(hex: "B794F6"))
                                .scaleEffect(1.2)

                            if shouldRenderChart {
                                Text("onboarding_v2.habits_progress.loading_chart".localized)
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .frame(height: 175)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(24)
                .glassCard(cornerRadius: 24)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .animation(nil, value: currentHabitIndex)

                // Legend
                HStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: "B794F6"))
                            .frame(width: 12, height: 12)
                        Text("onboarding_v2.habits_progress.with_cortifree".localized)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white)
                    }

                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 12, height: 12)
                        Text("onboarding_v2.habits_progress.without_cortifree".localized)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .animation(nil, value: currentHabitIndex)
                .opacity(shouldRenderChart ? 1 : 0)

                // Stat message
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "B794F6"))
                        .frame(width: 20, height: 20, alignment: .top)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "onboarding_v2.habits_progress.by_week".localized, currentHabitProgress.weekNumber))
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white)
                        +
                        Text(currentHabitProgress.statMessage)
                            .font(.custom("Poppins-SemiBold", size: 14))
                            .foregroundColor(Color(hex: "B794F6"))
                    }
                }
                .padding(.horizontal, 24)
                .animation(nil, value: currentHabitIndex)
                .opacity(shouldRenderChart ? 1 : 0)

                    Spacer(minLength: ResponsiveLayout.isIPad ? 180 : 120)
                }
            }
            .opacity(shouldRenderChart ? 1 : 0)

            // Bottom button
            VStack {
                Spacer()

                Button(action: {
                    HapticManager.medium()

                    // Track continue action
                    let timeSpent = screenViewTime.map { Date().timeIntervalSince($0) } ?? 0
                    AnalyticsManager.shared.trackOnboardingProgressContinue(
                        timeSpent: timeSpent
                    )

                    onComplete()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))

                        Text(StringKeys.Common.continueButton)
                            .font(.custom("Poppins-SemiBold", size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .contentShape(Capsule())
                }
                .buttonStyle(.glassPrimary)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onboardingBackButton(onBack)
        .task {
            // Track screen view
            screenViewTime = Date()
            AnalyticsManager.shared.trackOnboardingHabitsProgressViewed()

        }
    }
}

// MARK: - Habit Progress Model

struct HabitProgress {
    let icon: String
    let title: String
    let yAxisLabel: String
    let yAxisValues: [String]
    let currentValue: String
    let weekNumber: Int
    let statMessage: String
    let maxValue: Double
    let currentProgress: Double
    let curveStyle: Int
}

// MARK: - Habit Progress Chart

struct HabitProgressChart: View {
    let yAxisValues: [String]
    let currentValue: String
    let weekNumber: Int
    let maxValue: Double
    let currentProgress: Double
    let curveStyle: Int
    @Binding var currentWeek: Int

    var body: some View {
        let normalizedProgress = currentProgress / maxValue

        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) {
                // Y-axis labels - positioned exactly at grid line levels with top and bottom padding
                GeometryReader { labelGeometry in
                    let topPadding: CGFloat = 20
                    let bottomPadding: CGFloat = 10
                    let availableHeight = labelGeometry.size.height - topPadding - bottomPadding

                    ForEach(Array(yAxisValues.reversed().enumerated()), id: \.offset) { index, value in
                        let yPosition = topPadding + (availableHeight * CGFloat(index) / CGFloat(yAxisValues.count - 1))

                        Text(value)
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .position(x: 30, y: yPosition)
                    }
                }
                .frame(width: 60)

                Spacer()
                    .frame(width: 8)

                // Chart area
                ZStack(alignment: .bottomLeading) {
                    // Grid lines - one per value, aligned with labels with top and bottom padding
                    GeometryReader { chartGeometry in
                        let topPadding: CGFloat = 20
                        let bottomPadding: CGFloat = 10
                        let availableHeight = chartGeometry.size.height - topPadding - bottomPadding

                        ForEach(Array(yAxisValues.enumerated()), id: \.offset) { index, _ in
                            let yPosition = availableHeight * CGFloat(index) / CGFloat(yAxisValues.count - 1)

                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 1)
                                .position(x: chartGeometry.size.width / 2, y: chartGeometry.size.height - bottomPadding - yPosition)
                        }
                    }

                    // Without CortiFree curve (gray) - full
                    InteractiveHabitCurve(
                        progress: 0.25,
                        color: Color.gray.opacity(0.3),
                        fillGradient: false,
                        topPadding: 20,
                        bottomPadding: 10,
                        curveStyle: 0
                    )

                    // CortiFree curve stroke (purple line) - always full
                    InteractiveHabitCurve(
                        progress: normalizedProgress,
                        color: Color(hex: "B794F6"),
                        fillGradient: false,
                        topPadding: 20,
                        bottomPadding: 10,
                        curveStyle: curveStyle
                    )

                    // CortiFree gradient fill - only up to currentWeek
                    GeometryReader { chartGeometry in
                        let normalizedX = Double(currentWeek - 1) / Double(max(weekNumber - 1, 1))  // Maps weeks 1...weekNumber to 0.0-1.0

                        PartialGradientFill(
                            progress: normalizedProgress,
                            cutoffX: normalizedX,
                            color: Color(hex: "B794F6"),
                            topPadding: 20,
                            bottomPadding: 10,
                            curveStyle: curveStyle
                        )
                    }

                    // Current value indicator and week line
                    GeometryReader { chartGeometry in
                        let normalizedX = Double(currentWeek - 1) / Double(max(weekNumber - 1, 1))  // Maps weeks 1...weekNumber to 0.0-1.0
                        let topPadding: CGFloat = 20
                        let availableHeight = chartGeometry.size.height - topPadding
                        let curveX = chartGeometry.size.width * CGFloat(normalizedX)
                        let curveY = topPadding + calculateYOnCurve(
                            normalizedX: normalizedX,
                            progress: normalizedProgress,
                            height: availableHeight,
                            curveStyle: curveStyle
                        )

                        // Vertical dotted line from point to bottom
                        Path { path in
                            path.move(to: CGPoint(x: curveX, y: curveY))
                            path.addLine(to: CGPoint(x: curveX, y: chartGeometry.size.height))
                        }
                        .stroke(
                            Color(hex: "B794F6"),
                            style: StrokeStyle(lineWidth: 2, dash: [5, 5])
                        )

                        // Week indicator below the line
                        Text(String(format: "onboarding_v2.habits_progress.week_number".localized, currentWeek))
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .foregroundColor(Color(hex: "B794F6"))
                            .position(x: curveX, y: chartGeometry.size.height + 20)

                        // Circle indicator (draggable) - white with purple stroke and glow
                        ZStack {
                            // Main circle - white
                            Circle()
                                .fill(Color.white)
                                .frame(width: 18, height: 18)
                                .shadow(color: Color(hex: "B794F6").opacity(0.6), radius: 8, x: 0, y: 0)

                            // Purple stroke
                            Circle()
                                .stroke(Color(hex: "B794F6"), lineWidth: 2.25)
                                .frame(width: 18, height: 18)
                        }
                        .position(x: curveX, y: curveY)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newX = value.location.x
                                    let normalizedX = max(0.0, min(1.0, newX / chartGeometry.size.width))
                                    let newWeek = Int(round(normalizedX * Double(weekNumber - 1))) + 1  // Maps 0.0-1.0 to weeks 1...weekNumber
                                    currentWeek = max(1, min(weekNumber, newWeek))
                                }
                        )

                        // Swipe indicator - follows the circle, positioned top right of it
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "B794F6").opacity(0.7))
                            .rotationEffect(.degrees(-135))
                            .position(x: curveX + 15, y: curveY - 20)
                    }
                }
            }
        }
    }

    private func calculateYOnCurve(normalizedX: Double, progress: Double, height: CGFloat, curveStyle: Int) -> CGFloat {
        // Different curve exponents for each habit
        let exponent: Double
        switch curveStyle {
        case 0: exponent = 1.0   // Linear - Respiration
        case 1: exponent = 0.6   // Fast start - Méditation
        case 2: exponent = 0.85  // Moderate - Journal
        case 3: exponent = 1.3   // Slow start - Sport
        case 4: exponent = 1.0   // Linear smooth - Eau
        case 5: exponent = 0.7   // Fast start - Nature
        case 6: exponent = 0.9   // Moderate fast - Sommeil
        case 7: exponent = 1.5   // Very slow start - Social
        default: exponent = 0.85
        }

        let baseProgress = pow(normalizedX, exponent) * progress

        // Adjust wave amplitudes based on curve style
        let waveMultiplier: Double = (curveStyle == 4) ? 0.5 : 1.0
        let wave1 = sin(normalizedX * .pi * 3.2 + 0.5) * 0.03 * progress * waveMultiplier
        let wave2 = sin(normalizedX * .pi * 7.1 + 1.2) * 0.02 * progress * waveMultiplier
        let wave3 = sin(normalizedX * .pi * 11.5 + 2.1) * 0.01 * progress * waveMultiplier

        let waveEffect = (wave1 + wave2 + wave3) * (1 - normalizedX * 0.3)
        let finalProgress = baseProgress + waveEffect
        let clampedProgress = max(normalizedX * progress * 0.1, min(progress, finalProgress))

        return height * (1 - clampedProgress)
    }

    private func calculateYOnCurveForLabel(normalizedX: Double, progress: Double, height: CGFloat, curveStyle: Int) -> CGFloat {
        // Same logic as calculateYOnCurve
        let exponent: Double
        switch curveStyle {
        case 0: exponent = 1.0   // Linear - Respiration
        case 1: exponent = 0.6   // Fast start - Méditation
        case 2: exponent = 0.85  // Moderate - Journal
        case 3: exponent = 1.3   // Slow start - Sport
        case 4: exponent = 1.0   // Linear smooth - Eau
        case 5: exponent = 0.7   // Fast start - Nature
        case 6: exponent = 0.9   // Moderate fast - Sommeil
        case 7: exponent = 1.5   // Very slow start - Social
        default: exponent = 0.85
        }

        let baseProgress = pow(normalizedX, exponent) * progress

        let waveMultiplier: Double = (curveStyle == 4) ? 0.5 : 1.0
        let wave1 = sin(normalizedX * .pi * 3.2 + 0.5) * 0.03 * progress * waveMultiplier
        let wave2 = sin(normalizedX * .pi * 7.1 + 1.2) * 0.02 * progress * waveMultiplier
        let wave3 = sin(normalizedX * .pi * 11.5 + 2.1) * 0.01 * progress * waveMultiplier

        let waveEffect = (wave1 + wave2 + wave3) * (1 - normalizedX * 0.3)
        let finalProgress = baseProgress + waveEffect
        let clampedProgress = max(normalizedX * progress * 0.1, min(progress, finalProgress))

        return height * (1 - clampedProgress)
    }
}

// MARK: - Interactive Habit Curve

struct InteractiveHabitCurve: View {
    let progress: Double
    let color: Color
    let fillGradient: Bool
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let curveStyle: Int

    var body: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height - topPadding - bottomPadding

            ZStack {
                // Fill gradient (if enabled)
                if fillGradient {
                    Path { path in
                        let width = geometry.size.width
                        let height = availableHeight

                        path.move(to: CGPoint(x: 0, y: topPadding + height))

                        let segments = 8
                        for i in 0..<segments {
                            let startX = Double(i) / Double(segments)
                            let endX = Double(i + 1) / Double(segments)
                            let midX = (startX + endX) / 2

                            let endY = calculateWavyY(normalizedX: endX, progress: progress, height: height, curveStyle: curveStyle)
                            let midY = calculateWavyY(normalizedX: midX, progress: progress, height: height, curveStyle: curveStyle)

                            let controlX1 = width * CGFloat(startX + (endX - startX) * 0.33)
                            let controlY1 = midY - height * 0.02

                            let controlX2 = width * CGFloat(startX + (endX - startX) * 0.67)
                            let controlY2 = midY + height * 0.02

                            let endPoint = CGPoint(x: width * CGFloat(endX), y: topPadding + endY)

                            path.addCurve(
                                to: endPoint,
                                control1: CGPoint(x: controlX1, y: topPadding + controlY1),
                                control2: CGPoint(x: controlX2, y: topPadding + controlY2)
                            )
                        }

                        path.addLine(to: CGPoint(x: width, y: topPadding + height))
                        path.addLine(to: CGPoint(x: 0, y: topPadding + height))
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.4), color.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                // Stroke curve only (without closing lines)
                Path { path in
                    let width = geometry.size.width
                    let height = availableHeight

                    path.move(to: CGPoint(x: 0, y: topPadding + height))

                    let segments = 8
                    for i in 0..<segments {
                        let startX = Double(i) / Double(segments)
                        let endX = Double(i + 1) / Double(segments)
                        let midX = (startX + endX) / 2

                        let endY = calculateWavyY(normalizedX: endX, progress: progress, height: height, curveStyle: curveStyle)
                        let midY = calculateWavyY(normalizedX: midX, progress: progress, height: height, curveStyle: curveStyle)

                        let controlX1 = width * CGFloat(startX + (endX - startX) * 0.33)
                        let controlY1 = midY - height * 0.02

                        let controlX2 = width * CGFloat(startX + (endX - startX) * 0.67)
                        let controlY2 = midY + height * 0.02

                        let endPoint = CGPoint(x: width * CGFloat(endX), y: topPadding + endY)

                        path.addCurve(
                            to: endPoint,
                            control1: CGPoint(x: controlX1, y: topPadding + controlY1),
                            control2: CGPoint(x: controlX2, y: topPadding + controlY2)
                        )
                    }
                }
                .stroke(color, lineWidth: 3)
            }
        }
    }

    private func calculateWavyY(normalizedX: Double, progress: Double, height: CGFloat, curveStyle: Int) -> CGFloat {
        // Different curve exponents for each habit
        let exponent: Double
        switch curveStyle {
        case 0: exponent = 1.0   // Linear - Respiration
        case 1: exponent = 0.6   // Fast start - Méditation
        case 2: exponent = 0.85  // Moderate - Journal
        case 3: exponent = 1.3   // Slow start - Sport
        case 4: exponent = 1.0   // Linear smooth - Eau
        case 5: exponent = 0.7   // Fast start - Nature
        case 6: exponent = 0.9   // Moderate fast - Sommeil
        case 7: exponent = 1.5   // Very slow start - Social
        default: exponent = 0.85
        }

        let baseProgress = pow(normalizedX, exponent) * progress

        // Adjust wave amplitudes based on curve style
        let waveMultiplier: Double = (curveStyle == 4) ? 0.5 : 1.0
        let wave1 = sin(normalizedX * .pi * 3.2 + 0.5) * 0.03 * progress * waveMultiplier
        let wave2 = sin(normalizedX * .pi * 7.1 + 1.2) * 0.02 * progress * waveMultiplier
        let wave3 = sin(normalizedX * .pi * 11.5 + 2.1) * 0.01 * progress * waveMultiplier

        let waveEffect = (wave1 + wave2 + wave3) * (1 - normalizedX * 0.3)
        let finalProgress = baseProgress + waveEffect
        let clampedProgress = max(normalizedX * progress * 0.1, min(progress, finalProgress))

        return height * (1 - clampedProgress)
    }
}

// MARK: - Partial Gradient Fill (only fills up to cutoffX)

struct PartialGradientFill: View {
    let progress: Double
    let cutoffX: Double
    let color: Color
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let curveStyle: Int

    var body: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height - topPadding - bottomPadding

            Path { path in
                let width = geometry.size.width
                let height = availableHeight

                path.move(to: CGPoint(x: 0, y: topPadding + height))

                // Create smooth wavy curve with Bezier curves, but only up to cutoffX
                let segments = 8
                for i in 0..<segments {
                    let startX = Double(i) / Double(segments)
                    let endX = Double(i + 1) / Double(segments)

                    // Stop if we've reached the cutoff
                    if startX >= cutoffX {
                        break
                    }

                    let actualEndX = min(endX, cutoffX)
                    let midX = (startX + actualEndX) / 2

                    let endY = calculateWavyY(normalizedX: actualEndX, progress: progress, height: height, curveStyle: curveStyle)
                    let midY = calculateWavyY(normalizedX: midX, progress: progress, height: height, curveStyle: curveStyle)

                    let controlX1 = width * CGFloat(startX + (actualEndX - startX) * 0.33)
                    let controlY1 = midY - height * 0.02

                    let controlX2 = width * CGFloat(startX + (actualEndX - startX) * 0.67)
                    let controlY2 = midY + height * 0.02

                    let endPoint = CGPoint(x: width * CGFloat(actualEndX), y: topPadding + endY)

                    path.addCurve(
                        to: endPoint,
                        control1: CGPoint(x: controlX1, y: topPadding + controlY1),
                        control2: CGPoint(x: controlX2, y: topPadding + controlY2)
                    )

                    if actualEndX < endX {
                        break
                    }
                }

                // Close the path for fill (to bottom, then back to start)
                path.addLine(to: CGPoint(x: width * CGFloat(cutoffX), y: topPadding + height))
                path.addLine(to: CGPoint(x: 0, y: topPadding + height))
            }
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.4), color.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private func calculateWavyY(normalizedX: Double, progress: Double, height: CGFloat, curveStyle: Int) -> CGFloat {
        // Different curve exponents for each habit
        let exponent: Double
        switch curveStyle {
        case 0: exponent = 1.0   // Linear - Respiration
        case 1: exponent = 0.6   // Fast start - Méditation
        case 2: exponent = 0.85  // Moderate - Journal
        case 3: exponent = 1.3   // Slow start - Sport
        case 4: exponent = 1.0   // Linear smooth - Eau
        case 5: exponent = 0.7   // Fast start - Nature
        case 6: exponent = 0.9   // Moderate fast - Sommeil
        case 7: exponent = 1.5   // Very slow start - Social
        default: exponent = 0.85
        }

        let baseProgress = pow(normalizedX, exponent) * progress

        // Adjust wave amplitudes based on curve style
        let waveMultiplier: Double = (curveStyle == 4) ? 0.5 : 1.0
        let wave1 = sin(normalizedX * .pi * 3.2 + 0.5) * 0.03 * progress * waveMultiplier
        let wave2 = sin(normalizedX * .pi * 7.1 + 1.2) * 0.02 * progress * waveMultiplier
        let wave3 = sin(normalizedX * .pi * 11.5 + 2.1) * 0.01 * progress * waveMultiplier

        let waveEffect = (wave1 + wave2 + wave3) * (1 - normalizedX * 0.3)
        let finalProgress = baseProgress + waveEffect
        let clampedProgress = max(normalizedX * progress * 0.1, min(progress, finalProgress))

        return height * (1 - clampedProgress)
    }
}

#Preview {
    HabitsProgressFlowView(onComplete: {})
}
