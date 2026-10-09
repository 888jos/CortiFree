//
//  StreakCelebrationCard.swift
//  CortiFree
//
//  First validated item of the day: a centered card over a dimmed, see-through backdrop
//  (not full screen). The flame counts up to the new streak with a "+1", and the week
//  row (same day circles as the Home weekly status) shows the previous days of the
//  streak already done, then today filling in.
//

import SwiftUI

struct StreakCelebrationCard: View {
    let days: Int
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var countedDays: Int
    @State private var todayDone = false
    @State private var showPlusOne = false

    private let calendar: Calendar

    init(days: Int, calendar: Calendar = .current, onDismiss: @escaping () -> Void) {
        self.days = max(1, days)
        self.calendar = calendar
        self.onDismiss = onDismiss
        _countedDays = State(initialValue: max(0, days - 1))
    }

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            card
                .padding(.horizontal, 24)
                .scaleEffect(appeared ? 1 : 0.86)
                .opacity(appeared ? 1 : 0)
        }
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
            flame
                .padding(.top, 6)

            VStack(spacing: 6) {
                Text(title)
                    .font(.faroBold(26))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(Font.Poppins.custom(.regular, size: 14))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            weekRow
                .padding(.top, 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 26)
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "2A1752"), Color(hex: "160C2E")],
                                     startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.18), .white.opacity(0.04)],
                                             startPoint: .top, endPoint: .bottom), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.45), radius: 30, y: 16)
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
    }

    // MARK: - Flame + counter

    private var flame: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(Self.flameGradient)
                        .frame(width: 92, height: 92)
                        .blur(radius: 26)
                        .opacity(todayDone ? 0.75 : 0.35)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 60, weight: .regular))
                        .foregroundStyle(Self.flameGradient)
                        .symbolEffect(.bounce, value: todayDone)
                        .phaseAnimator([1.0, 1.04, 0.98, 1.0], trigger: appeared) { view, scale in
                            view.scaleEffect(scale, anchor: .bottom)
                        } animation: { _ in .easeInOut(duration: 0.5) }
                }
                .frame(height: 76)

                Text("\(countedDays)")
                    .font(.faroBold(40))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(countedDays)))
                    .monospacedDigit()
            }

            Text("+1")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: "FFB347"))
                .offset(x: 28, y: showPlusOne ? -18 : 18)
                .opacity(showPlusOne ? 1 : 0)
        }
    }

    // MARK: - Week row (same circles as Home)

    private var weekRow: some View {
        HStack(spacing: -2) {
            ForEach(week, id: \.index) { day in
                DayCircleView(day: DayProgress(label: day.label, status: status(of: day), dayIndex: day.index),
                              isAnimating: day.isToday && todayDone, onTap: {})
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .top) {
                        if day.isToday {
                            Circle()
                                .strokeBorder(Color(hex: "FFB347").opacity(todayDone ? 0 : 0.8), lineWidth: 1.5)
                                .frame(width: 44, height: 44)
                                .offset(y: -2)
                        }
                    }
            }
        }
        .allowsHitTesting(false)
    }

    private struct WeekDay {
        let index: Int
        let label: String
        /// Days before today (0 = today, negative = future).
        let daysAgo: Int
        var isToday: Bool { daysAgo == 0 }
    }

    /// The current week in the user's calendar order, labelled like the Home strip.
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

    /// Previous days of the current streak are done; today fills in during the animation.
    private func status(of day: WeekDay) -> DayStatus {
        if day.isToday { return todayDone ? .completed : .none }
        return day.daysAgo > 0 && day.daysAgo < days ? .completed : .none
    }

    // MARK: - Copy

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
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) { appeared = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(650))
            HapticManager.success()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                todayDone = true
                countedDays = days
                showPlusOne = true
            }
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeOut(duration: 0.5)) { showPlusOne = false }
        }
    }

    static let flameGradient = LinearGradient(
        colors: [Color(hex: "FFE08A"), Color(hex: "FF9F2E"), Color(hex: "FF5E3A")],
        startPoint: .top, endPoint: .bottom
    )
}
