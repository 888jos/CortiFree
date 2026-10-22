//
//  StreakCelebrationCard.swift
//  CortiFree
//
//  First validated item of the day: a compact card over the lightly blurred app (same
//  layout as LifeQuest's streak increment). « Ton rythme de la semaine » with a « +1 série »
//  pill, one flame per weekday (the previous days of the streak lit, today lighting up with
//  a check), then the streak count.
//

import SwiftUI

struct StreakCelebrationCard: View {
    let days: Int
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var todayDone = false
    @State private var pulse = false

    private let calendar: Calendar

    init(days: Int, calendar: Calendar = .current, onDismiss: @escaping () -> Void) {
        self.days = max(1, days)
        self.calendar = calendar
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            // No dark veil: the app stays visible behind, just slightly blurred.
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .opacity(appeared ? 0.55 : 0)
                .ignoresSafeArea()

            card
                .padding(.horizontal, 22)
                .scaleEffect(appeared ? 1 : 0.94)
                .opacity(appeared ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
        .onAppear(perform: animate)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(named: Text("common.close".localized), onDismiss)
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("celebration.streak.week_title".localized)
                    .font(.faroSemiBold(19))
                    .foregroundStyle(.white)

                Spacer()

                Text("celebration.streak.plus_one".localized)
                    .font(.faroBold(13))
                    .foregroundStyle(Color(hex: "1A0B2E"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule(style: .continuous).fill(Self.accent))
            }

            HStack(spacing: 0) {
                ForEach(week, id: \.index) { day in
                    let lit = isLit(day)
                    VStack(spacing: 11) {
                        Text(day.label)
                            .font(Font.Poppins.custom(.medium, size: 12))
                            .foregroundStyle(day.isToday ? AppConstants.Colors.streakOrange : .white.opacity(0.4))

                        StreakFlame(lit: lit, size: 38, isChecked: day.isToday && lit)
                            .frame(height: 44)
                            .scaleEffect(day.isToday && lit && pulse ? 1.14 : 1)
                            .shadow(color: day.isToday && lit ? Self.accent.opacity(0.44) : .clear,
                                    radius: day.isToday && lit ? 18 : 0, y: 6)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                StreakFlame(lit: true, size: 30, shadow: true)

                Text("\(todayDone ? days : days - 1)")
                    .font(.faroBold(42))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(todayDone ? days : days - 1)))
                    .monospacedDigit()

                Text(days == 1 ? "celebration.streak.unit_one".localized : "celebration.streak.unit_other".localized)
                    .font(.faroSemiBold(19))
                    .foregroundStyle(.white.opacity(0.65))

                Spacer(minLength: 0)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .frame(maxWidth: 400)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "1A1030"))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Self.accent.opacity(0.22), lineWidth: 1.2)
                )
                .shadow(color: .black.opacity(0.34), radius: 20, y: 12)
        )
    }

    // MARK: - Week

    private struct WeekDay {
        let index: Int
        let label: String
        /// Days before today (0 = today, negative = future).
        let daysAgo: Int
        var isToday: Bool { daysAgo == 0 }
    }

    /// The current week in the user's calendar order.
    private var week: [WeekDay] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let offsetFromStart = (weekday - calendar.firstWeekday + 7) % 7
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        return (0..<7).map { index in
            let symbolIndex = (calendar.firstWeekday - 1 + index) % 7
            return WeekDay(index: index, label: symbols[symbolIndex].uppercased(), daysAgo: offsetFromStart - index)
        }
    }

    /// Previous days of the current streak are lit; today lights up during the animation.
    private func isLit(_ day: WeekDay) -> Bool {
        if day.isToday { return todayDone }
        return day.daysAgo > 0 && day.daysAgo < days
    }

    // MARK: - Copy (accessibility)

    private var title: String {
        days <= 1 ? "celebration.streak.title_first".localized
                  : String(format: "celebration.streak.title".localized, days)
    }

    private var subtitle: String {
        days <= 1 ? "celebration.streak.subtitle_first".localized
                  : String(format: "celebration.streak.subtitle_next".localized, days + 1)
    }

    // MARK: - Animation

    private func animate() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { appeared = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            HapticManager.success()
            withAnimation(.spring(response: 0.48, dampingFraction: 0.72)) {
                todayDone = true
                pulse = true
            }
            try? await Task.sleep(for: .milliseconds(720))
            withAnimation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true)) { pulse = false }
        }
    }

    static let accent = Color(hex: "B794F6")
}

/// A filled flame: orange when lit, faint white otherwise, with an optional check.
private struct StreakFlame: View {
    let lit: Bool
    var size: CGFloat
    var shadow: Bool = false
    var isChecked: Bool = false

    private var color: Color { lit ? AppConstants.Colors.streakOrange : .white.opacity(0.34) }

    var body: some View {
        ZStack {
            FilledFlameShape()
                .fill(color)
                .frame(width: size * 0.72, height: size)

            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.34, weight: .black))
                    .foregroundStyle(.white)
                    .offset(y: size * 0.11)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: shadow ? color.opacity(0.42) : .clear, radius: size * 0.18, y: size * 0.08)
        .accessibilityHidden(true)
    }
}

private struct FilledFlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0.53 * w, y: 0.02 * h))
        path.addCurve(to: CGPoint(x: 0.20 * w, y: 0.43 * h),
                      control1: CGPoint(x: 0.52 * w, y: 0.18 * h), control2: CGPoint(x: 0.25 * w, y: 0.23 * h))
        path.addCurve(to: CGPoint(x: 0.05 * w, y: 0.66 * h),
                      control1: CGPoint(x: 0.12 * w, y: 0.49 * h), control2: CGPoint(x: 0.06 * w, y: 0.56 * h))
        path.addCurve(to: CGPoint(x: 0.50 * w, y: 0.99 * h),
                      control1: CGPoint(x: 0.04 * w, y: 0.84 * h), control2: CGPoint(x: 0.20 * w, y: 0.99 * h))
        path.addCurve(to: CGPoint(x: 0.95 * w, y: 0.64 * h),
                      control1: CGPoint(x: 0.80 * w, y: 0.99 * h), control2: CGPoint(x: 0.96 * w, y: 0.82 * h))
        path.addCurve(to: CGPoint(x: 0.68 * w, y: 0.30 * h),
                      control1: CGPoint(x: 0.94 * w, y: 0.49 * h), control2: CGPoint(x: 0.77 * w, y: 0.39 * h))
        path.addCurve(to: CGPoint(x: 0.53 * w, y: 0.02 * h),
                      control1: CGPoint(x: 0.60 * w, y: 0.21 * h), control2: CGPoint(x: 0.57 * w, y: 0.10 * h))
        path.closeSubpath()
        return path
    }
}
