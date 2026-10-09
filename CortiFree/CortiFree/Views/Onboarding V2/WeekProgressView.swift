//
//  WeekProgressView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Vue de progression hebdomadaire avec graphique radar
//

import SwiftUI
import Foundation

struct WeekProgressView: View {
    /// Quiz result used to start the radar from the user's own domain scores.
    var habitsQuizResult: HabitsQuizResult? = nil
    var onBack: (() -> Void)? = nil
    let onContinue: () -> Void
    @ObservedObject var languageManager = LanguageManager.shared
    @State private var currentWeek: Int = 1
    @State private var screenViewTime: Date?

    // Weeks 1, 2 and 4 of the 28-day plan. Axis order: [Global, Serenity, Sleep, Energy, Focus, Balance].
    // Week 1 is the user's own starting point from the quiz; later weeks are an indicative projection.
    private var startingLevels: [Double] {
        guard let result = habitsQuizResult else { return [0.25, 0.25, 0.25, 0.25, 0.25, 0.25] }
        return [result.globalScore, result.serenityScore, result.sleepScore,
                result.energyScore, result.focusScore, result.balanceScore]
            .map { min(0.85, max(0.15, Double($0) / 100)) }
    }

    private func projectedLevels(closingGap fraction: Double) -> [Double] {
        startingLevels.map { $0 + (0.95 - $0) * fraction }
    }

    private var weekData: [(week: Int, dateRange: String, message: String, color: Color, progress: [Double])] {
        let today = Date()
        let calendar = Calendar.current

        func range(forWeek week: Int) -> String {
            let start = calendar.date(byAdding: .day, value: (week - 1) * 7, to: today)!
            let end = calendar.date(byAdding: .day, value: 6, to: start)!
            return "\(formatter.string(from: start)) \(toSeparator) \(formatter.string(from: end))"
        }

        let formatter = DateFormatter()
        // Use language-appropriate locale
        let localeIdentifier = languageManager.currentLanguage.locale.identifier
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateFormat = "d MMM"

        let toSeparator = "onboarding_v2.week_progress.date_separator".localized

        return [
            (1, range(forWeek: 1), StringKeys.Onboarding.WeekProgress.week1Message, Color(hex: "D32F2F"), startingLevels),
            (2, range(forWeek: 2), StringKeys.Onboarding.WeekProgress.week5Message, Color(hex: "E67E22"), projectedLevels(closingGap: 0.35)),
            (4, range(forWeek: 4), StringKeys.Onboarding.WeekProgress.week10Message, Color(hex: "27AE60"), projectedLevels(closingGap: 0.7))
        ]
    }

    private var isLastWeek: Bool { currentWeek == weekData.last?.week }

    private var currentWeekData: (week: Int, dateRange: String, message: String, color: Color, progress: [Double]) {
        weekData.first { $0.week == currentWeek } ?? weekData[0]
    }

    // Week title ("Week 1", "Week 2", "Week 4")
    private func getWeekTitle() -> String {
        "onboarding.week_progress.week_number".localized(currentWeek)
    }

    // Responsive label offsets that scale with iPad
    private var labelOffsets: (vertical: CGFloat, horizontal: CGFloat) {
        let multiplier = ResponsiveLayout.sizeMultiplier
        return (
            vertical: 168 * multiplier,     // ±168 becomes ±201.6 on iPad (1.2x)
            horizontal: 148 * multiplier    // ±148 becomes ±177.6 on iPad (1.2x)
        )
    }

    private var labelOffsetsSmall: (vertical: CGFloat, horizontal: CGFloat) {
        let multiplier = ResponsiveLayout.sizeMultiplier
        return (
            vertical: 82 * multiplier,      // ±82 becomes ±98.4 on iPad (1.2x)
            horizontal: 148 * multiplier    // ±148 becomes ±177.6 on iPad (1.2x)
        )
    }

    var body: some View {
        ZStack {
            // Background with current week color gradient
            LinearGradient(
                colors: [
                    currentWeekData.color,
                    currentWeekData.color.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Week title - Force display of week number based on screen index
                    Text(getWeekTitle())
                    .font(.faroBold(40))
                    .foregroundColor(.white)
                    .responsivePadding(.top, 100)
                    .padding(.bottom, 16)

                // Date range
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                    Text(currentWeekData.dateRange)
                        .font(.custom("Poppins-Regular", size: 14))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .glassCapsule()
                .responsivePadding(.bottom, 32)

                // Motivational message - Flexible height for iPad
                Text(currentWeekData.message)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .balancedLines()
                    .lineLimit(nil)
                    .frame(minHeight: 60, maxHeight: 80, alignment: .center)
                    .padding(.horizontal, 32)
                    .responsivePadding(.bottom, 32)

                // Bottom card with radar chart
                VStack(spacing: 24) {
                    // Radar chart
                    ZStack {
                        // Background hexagon grid
                        HexagonRadarGrid()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            .responsiveFrame(width: 280, height: 280)

                        // Filled hexagon based on progress with gradient
                        HexagonRadarFill(progress: currentWeekData.progress)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        currentWeekData.color.opacity(0.7),
                                        currentWeekData.color.opacity(0.4)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .responsiveFrame(width: 280, height: 280)

                        // Stroke around the filled hexagon
                        HexagonRadarFill(progress: currentWeekData.progress)
                            .stroke(
                                currentWeekData.color.opacity(0.5),
                                lineWidth: 8
                            )
                            .responsiveFrame(width: 280, height: 280)

                        // Labels at hexagon vertices (scaled for iPad)
                        ZStack {
                            // Global - Top
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                Text(StringKeys.Common.global)
                                    .font(.faroSemiBold(16))
                            }
                            .foregroundColor(.white)
                            .offset(x: 0, y: -labelOffsets.vertical)

                            // Sérénité - Top right
                            HStack(spacing: 4) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 14))
                                Text(StringKeys.Common.serenity)
                                    .font(.faroSemiBold(16))
                            }
                            .foregroundColor(.white)
                            .offset(x: labelOffsets.horizontal, y: -labelOffsetsSmall.vertical)

                            // Sommeil - Bottom right
                            HStack(spacing: 4) {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 14))
                                Text(StringKeys.Common.sleep)
                                    .font(.faroSemiBold(16))
                            }
                            .foregroundColor(.white)
                            .offset(x: labelOffsets.horizontal, y: labelOffsetsSmall.vertical)

                            // Énergie - Bottom
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 14))
                                Text(StringKeys.Common.energy)
                                    .font(.faroSemiBold(16))
                            }
                            .foregroundColor(.white)
                            .offset(x: 0, y: labelOffsets.vertical)

                            // Focus - Bottom left
                            HStack(spacing: 4) {
                                Image(systemName: "target")
                                    .font(.system(size: 14))
                                Text(StringKeys.Common.focus)
                                    .font(.faroSemiBold(16))
                            }
                            .foregroundColor(.white)
                            .offset(x: -labelOffsets.horizontal, y: labelOffsetsSmall.vertical)

                            // Balance - Top left
                            HStack(spacing: 4) {
                                Image(systemName: "circle.lefthalf.filled")
                                    .font(.system(size: 14))
                                Text(StringKeys.Common.balance)
                                    .font(.faroSemiBold(16))
                            }
                            .foregroundColor(.white)
                            .offset(x: -labelOffsets.horizontal, y: -labelOffsetsSmall.vertical)
                        }
                    }
                    .responsivePadding(.vertical, 48)

                    Text((currentWeek == 1 ? "onboarding_v2.week_progress.start_note" : "onboarding_v2.week_progress.projection_note").localized)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .balancedLines()
                        .padding(.horizontal, 32)

                    // Button
                    Button(action: {
                        HapticManager.medium()
                        if let lastWeek = weekData.last, currentWeek < lastWeek.week {
                            // Go to next demo week
                            if let nextIndex = weekData.firstIndex(where: { $0.week > currentWeek }) {
                                withAnimation {
                                    currentWeek = weekData[nextIndex].week
                                }
                            }
                        } else {
                            // Track continue action
                            AnalyticsManager.shared.trackOnboardingWeekProgressContinue()

                            onContinue()
                        }
                    }) {
                        HStack(spacing: isLastWeek ? 4 : 8) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))

                            Text(isLastWeek ? StringKeys.Onboarding.EightHabitsFlow.howHabitsHelp : StringKeys.Common.continueButton)
                                .font(.custom("Poppins-SemiBold", size: isLastWeek ? 15 : 16))
                                .lineLimit(1)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .buttonStyle(.glassPrimary)
                    .padding(.horizontal, 32)
                    .responsivePadding(.bottom, 40)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .clipShape(RoundedCorner(radius: 40, corners: [.topLeft, .topRight]))
                }
            }
        }
        .onboardingBackButton(onBack)
        .onAppear {
            screenViewTime = Date()
            AnalyticsManager.shared.trackOnboardingWeekProgressViewed()
        }
    }
}

// MARK: - Rounded Corner Helper

struct RoundedCorner: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    WeekProgressView(onContinue: {})
}
