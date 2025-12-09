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
    let onContinue: () -> Void
    @ObservedObject var languageManager = LanguageManager.shared
    @State private var currentWeek: Int = 1
    @State private var screenViewTime: Date?

    // Configuration des semaines avec progrès individuels pour chaque catégorie
    // Ordre: [Global, Sérénité, Sommeil, Énergie, Focus, Équilibre]
    private var weekData: [(week: Int, dateRange: String, message: String, color: Color, progress: [Double])] {
        let today = Date()
        let calendar = Calendar.current

        // Week 1: Today to Today + 7 days
        let week1Start = today
        let week1End = calendar.date(byAdding: .day, value: 7, to: today)!

        // Week 5: Today + 5 weeks to Today + 5 weeks + 7 days
        let week5Start = calendar.date(byAdding: .weekOfYear, value: 5, to: today)!
        let week5End = calendar.date(byAdding: .day, value: 7, to: week5Start)!

        // Week 10: Today + 10 weeks to Today + 10 weeks + 7 days
        let week10Start = calendar.date(byAdding: .weekOfYear, value: 10, to: today)!
        let week10End = calendar.date(byAdding: .day, value: 7, to: week10Start)!

        let formatter = DateFormatter()
        // Use language-appropriate locale
        let localeIdentifier = languageManager.currentLanguage == .french ? "fr_FR" : "en_US"
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateFormat = "d MMM"

        let toSeparator = "onboarding_v2.week_progress.date_separator".localized

        return [
            (1, "\(formatter.string(from: week1Start)) \(toSeparator) \(formatter.string(from: week1End))", StringKeys.Onboarding.WeekProgress.week1Message, Color(hex: "D32F2F"), [0.18, 0.25, 0.22, 0.15, 0.20, 0.24]),
            (5, "\(formatter.string(from: week5Start)) \(toSeparator) \(formatter.string(from: week5End))", StringKeys.Onboarding.WeekProgress.week5Message, Color(hex: "E67E22"), [0.52, 0.48, 0.55, 0.45, 0.50, 0.53]),
            (10, "\(formatter.string(from: week10Start)) \(toSeparator) \(formatter.string(from: week10End))", StringKeys.Onboarding.WeekProgress.week10Message, Color(hex: "27AE60"), [0.95, 0.92, 0.98, 0.90, 0.94, 0.96])
        ]
    }

    private var currentWeekData: (week: Int, dateRange: String, message: String, color: Color, progress: [Double]) {
        weekData.first { $0.week == currentWeek } ?? weekData[0]
    }

    // Force week titles to display correctly (Week 1, Week 5, Week 10)
    private func getWeekTitle() -> String {
        let isFrench = languageManager.currentLanguage == .french
        switch currentWeek {
        case 1:
            return isFrench ? "Semaine 1" : "Week 1"
        case 5:
            return isFrench ? "Semaine 5" : "Week 5"
        case 10:
            return isFrench ? "Semaine 10" : "Week 10"
        default:
            return isFrench ? "Semaine \(currentWeek)" : "Week \(currentWeek)"
        }
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

            VStack(spacing: 0) {
                // Week title - Force display of week number based on screen index
                Text(getWeekTitle())
                    .font(Font.Poppins.custom(.bold, size: 40))
                    .foregroundColor(.white)
                    .padding(.top, 100)
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
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                        )
                )
                .padding(.bottom, 32)

                // Motivational message - Fixed height
                Text(currentWeekData.message)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .frame(height: 60, alignment: .center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)

                // Bottom card with radar chart
                VStack(spacing: 24) {
                    // Radar chart
                    ZStack {
                        // Background hexagon grid
                        HexagonRadarGrid()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            .frame(width: 280, height: 280)

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
                            .frame(width: 280, height: 280)

                        // Stroke around the filled hexagon
                        HexagonRadarFill(progress: currentWeekData.progress)
                            .stroke(
                                currentWeekData.color.opacity(0.5),
                                lineWidth: 8
                            )
                            .frame(width: 280, height: 280)

                        // Labels at hexagon vertices
                        ZStack {
                            // Global - Top
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                Text(StringKeys.Common.global)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                            }
                            .foregroundColor(.white)
                            .offset(x: 0, y: -168)

                            // Sérénité - Top right
                            HStack(spacing: 4) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 14))
                                Text(StringKeys.Common.serenity)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                            }
                            .foregroundColor(.white)
                            .offset(x: 148, y: -82)

                            // Sommeil - Bottom right
                            HStack(spacing: 4) {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 14))
                                Text(StringKeys.Common.sleep)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                            }
                            .foregroundColor(.white)
                            .offset(x: 148, y: 82)

                            // Énergie - Bottom
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 14))
                                Text(StringKeys.Common.energy)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                            }
                            .foregroundColor(.white)
                            .offset(x: 0, y: 168)

                            // Focus - Bottom left
                            HStack(spacing: 4) {
                                Image(systemName: "target")
                                    .font(.system(size: 14))
                                Text(StringKeys.Common.focus)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                            }
                            .foregroundColor(.white)
                            .offset(x: -148, y: 82)

                            // Équilibre - Top left
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 14))
                                Text(StringKeys.Common.balance)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                            }
                            .foregroundColor(.white)
                            .offset(x: -148, y: -82)
                        }
                    }
                    .padding(.vertical, 48)

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
                            MixpanelManager.shared.trackOnboardingWeekProgressContinue()

                            onContinue()
                        }
                    }) {
                        HStack(spacing: currentWeek == 10 ? 4 : 8) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))

                            Text(currentWeek == 10 ? StringKeys.Onboarding.EightHabitsFlow.howHabitsHelp : StringKeys.Common.continueButton)
                                .font(.custom("Poppins-SemiBold", size: currentWeek == 10 ? 15 : 16))
                                .lineLimit(1)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .clipShape(RoundedCorner(radius: 40, corners: [.topLeft, .topRight]))
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .onAppear {
            screenViewTime = Date()
            MixpanelManager.shared.trackOnboardingWeekProgressViewed()
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
