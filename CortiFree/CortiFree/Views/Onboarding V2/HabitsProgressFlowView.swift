//
//  HabitsProgressFlowView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Vue montrant la progression des habitudes avec graphiques
//

import SwiftUI

struct HabitsProgressFlowView: View {
    let onComplete: () -> Void
    @ObservedObject var languageManager = LanguageManager.shared
    @State private var currentHabitIndex: Int = 0
    @State private var currentWeek: Int = 1
    @State private var shouldRenderChart = false
    @State private var loadedHabits: Set<Int> = [] // Track which habits have been loaded
    @State private var screenViewTime: Date?

    // Les habitudes avec leurs statistiques de progression
    private var habitProgresses: [HabitProgress] {
        [
            HabitProgress(
                icon: "wind",
                title: "onboarding_v2.habits_progress.breathing_title".localized,
                yAxisLabel: "",
                yAxisValues: ["15 min", "30 min", "45 min", "1h"],
                currentValue: "1h",
                weekNumber: 10,
                statMessage: "onboarding_v2.habits_progress.breathing_stat".localized,
                maxValue: 4.0,
                currentProgress: 3.7,
                curveStyle: 0
            ),
            HabitProgress(
                icon: "figure.mind.and.body",
                title: "onboarding_v2.habits_progress.meditation_title".localized,
                yAxisLabel: "",
                yAxisValues: ["20 min", "40 min", "1h", "1h20", "1h40"],
                currentValue: "1h30",
                weekNumber: 10,
                statMessage: "onboarding_v2.habits_progress.meditation_stat".localized,
                maxValue: 4.0,
                currentProgress: 3.7,
                curveStyle: 1
            ),
            HabitProgress(
                icon: "book.pages",
                title: "onboarding_v2.habits_progress.journal_title".localized,
                yAxisLabel: "",
                yAxisValues: ["2x", "3x", "5x", "7x"],
                currentValue: "7x",
                weekNumber: 10,
                statMessage: "onboarding_v2.habits_progress.journal_stat".localized,
                maxValue: 4.0,
                currentProgress: 3.7,
                curveStyle: 2
            ),
            HabitProgress(
                icon: "figure.walk",
                title: "onboarding_v2.habits_progress.sport_title".localized,
                yAxisLabel: "",
                yAxisValues: ["45 min", "1h30", "2h15", "3h", "3h45"],
                currentValue: "3h30",
                weekNumber: 10,
                statMessage: "onboarding_v2.habits_progress.sport_stat".localized,
                maxValue: 4.0,
                currentProgress: 3.7,
                curveStyle: 3
            ),
            HabitProgress(
                icon: "drop.fill",
                title: "onboarding_v2.habits_progress.water_title".localized,
                yAxisLabel: "",
                yAxisValues: ["1.5L", "2L", "2.5L", "3L"],
                currentValue: "2,5L",
                weekNumber: 10,
                statMessage: "onboarding_v2.habits_progress.water_stat".localized,
                maxValue: 4.0,
                currentProgress: 3.7,
                curveStyle: 4
            ),
            HabitProgress(
                icon: "tree.fill",
                title: "onboarding_v2.habits_progress.nature_title".localized,
                yAxisLabel: "",
                yAxisValues: ["45 min", "1h30", "2h15", "3h", "3h45"],
                currentValue: "3h30",
                weekNumber: 10,
                statMessage: "onboarding_v2.habits_progress.nature_stat".localized,
                maxValue: 4.0,
                currentProgress: 3.7,
                curveStyle: 5
            ),
            HabitProgress(
                icon: "moon.zzz.fill",
                title: "onboarding_v2.habits_progress.sleep_title".localized,
                yAxisLabel: "",
                yAxisValues: ["6h", "6.5h", "7h", "7.5h", "8h"],
                currentValue: "8h",
                weekNumber: 10,
                statMessage: "onboarding_v2.habits_progress.sleep_stat".localized,
                maxValue: 4.0,
                currentProgress: 3.7,
                curveStyle: 6
            ),
            HabitProgress(
                icon: "person.2.fill",
                title: "onboarding_v2.habits_progress.social_title".localized,
                yAxisLabel: "",
                yAxisValues: ["3x", "4x", "5x", "6x"],
                currentValue: "4x",
                weekNumber: 10,
                statMessage: "onboarding_v2.habits_progress.social_stat".localized,
                maxValue: 4.0,
                currentProgress: 3.7,
                curveStyle: 7
            )
        ]
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

                            // Load this habit's chart if not already loaded
                            if !loadedHabits.contains(index) {
                                Task {
                                    try? await Task.sleep(nanoseconds: 150_000_000) // 0.15s delay
                                    withAnimation(.easeIn(duration: 0.2)) {
                                        loadedHabits.insert(index)
                                    }
                                }
                            }
                        }) {
                            Image(systemName: habitProgresses[index].icon)
                                .font(.system(size: 17))
                                .foregroundColor(currentHabitIndex == index ? Color(hex: "B794F6") : .white.opacity(0.5))
                                .frame(width: 35, height: 35)
                                .background(
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(currentHabitIndex == index ? Color(hex: "B794F6").opacity(0.2) : Color.white.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9)
                                        .stroke(currentHabitIndex == index ? Color(hex: "B794F6") : Color.white.opacity(0.2), lineWidth: 2)
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
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.05))
                )
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
                    MixpanelManager.shared.trackOnboardingProgressContinue(
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
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color(hex: "B794F6"))
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .task {
            // Track screen view
            screenViewTime = Date()
            MixpanelManager.shared.trackOnboardingHabitsProgressViewed()

            // Initial load: show UI first
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second
            withAnimation(.easeIn(duration: 0.2)) {
                shouldRenderChart = true
            }

            // Then load only the first habit's chart
            try? await Task.sleep(nanoseconds: 150_000_000) // Additional 0.15s
            withAnimation(.easeIn(duration: 0.2)) {
                loadedHabits.insert(0) // Load first habit (Respirer consciemment)
            }
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
                        let normalizedX = Double(currentWeek - 1) / 9.0  // Maps weeks 1-10 to 0.0-1.0

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
                        let normalizedX = Double(currentWeek - 1) / 9.0  // Maps weeks 1-10 to 0.0-1.0
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
                                    let newWeek = Int(round(normalizedX * 9)) + 1  // Maps 0.0-1.0 to weeks 1-10
                                    currentWeek = max(1, min(10, newWeek))
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
