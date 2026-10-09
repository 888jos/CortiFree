//
//  CelebrationHost.swift
//  CortiFree
//
//  Renders CelebrationCenter.current: a top banner for moments (the screen stays usable)
//  and a full-screen view for milestones. Placed once at the root (ContentView).
//

import SwiftUI

struct CelebrationHost: View {
    @ObservedObject private var center = CelebrationCenter.shared

    var body: some View {
        ZStack(alignment: .top) {
            switch center.current {
            case .streak(let days):
                // Centered card over a dimmed backdrop (not full screen), see StreakCelebrationCard.
                StreakCelebrationCard(days: days) { center.dismissCurrent() }
                    .transition(.opacity)
            case .dayComplete(let items, let minutes):
                ZStack(alignment: .top) {
                    FullScreenConfetti()
                    CelebrationBanner(kind: .dayComplete(items: items, minutes: minutes)) { center.dismissCurrent() }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            case .achievement(let achievement):
                AchievementCelebrationView(achievement: achievement) { center.dismissCurrent() }
                    .id(achievement.id)
                    .transition(.opacity)
            case .badge(let badge):
                BadgeEvolutionView(badge: badge, isPresented: Binding(
                    get: { true },
                    set: { if !$0 { center.dismissCurrent() } }
                ))
                    .id(badge.id)
                    .transition(.opacity)
            case .habitAcquired(let habitID):
                ZStack(alignment: .top) {
                    Color.clear.confetti(isActive: true)
                    CelebrationBanner(kind: .habitAcquired(habitID: habitID)) { center.dismissCurrent() }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            case nil:
                EmptyView()
            }
        }
        // Only the milestone takes the whole screen; a banner lets touches through around it.
        .allowsHitTesting(center.current != nil)
    }
}

// MARK: - Moment banner

struct CelebrationBanner: View {
    enum Kind {
        case streak(days: Int)
        case dayComplete(items: Int, minutes: Int)
        case habitAcquired(habitID: String)
    }

    let kind: Kind
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            icon
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.faroBold(20))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(Font.Poppins.custom(.regular, size: 13))
                    .foregroundStyle(PlanPalette.secondaryText)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .planGlass(cornerRadius: 24)
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
        .gesture(DragGesture(minimumDistance: 10).onEnded { value in
            if value.translation.height < -10 { onDismiss() }
        })
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    @ViewBuilder
    private var icon: some View {
        switch kind {
        case .streak:
            badge("flame.fill", foreground: .white, fill: AppConstants.Colors.streakOrange)
        case .dayComplete:
            badge("checkmark.seal.fill", foreground: PlanPalette.deep, fill: PlanPalette.done)
        case .habitAcquired(let habitID):
            badge(PlanItem.habitSymbol(habitID), foreground: PlanPalette.deep, fill: PlanPalette.done)
        }
    }

    private func badge(_ symbol: String, foreground: Color, fill: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(width: 48, height: 48)
            .background(Circle().fill(fill))
            .background(Circle().fill(fill.opacity(0.35)).blur(radius: 10))
            .phaseAnimator([1.0, 1.15, 1.0], trigger: true) { view, scale in
                view.scaleEffect(scale)
            } animation: { _ in .spring(response: 0.3, dampingFraction: 0.5) }
            .accessibilityHidden(true)
    }

    private var title: String {
        switch kind {
        case .streak(let days):
            return days <= 1 ? "celebration.streak.title_first".localized
                             : String(format: "celebration.streak.title".localized, days)
        case .dayComplete:
            return "celebration.day.title".localized
        case .habitAcquired:
            return "celebration.habit_acquired.title".localized
        }
    }

    private var subtitle: String {
        switch kind {
        case .streak:
            return "celebration.streak.subtitle".localized
        case .dayComplete(let items, let minutes):
            return String(format: "celebration.day.subtitle".localized, items, minutes)
        case .habitAcquired(let habitID):
            return String(format: "celebration.habit_acquired.subtitle".localized, "plan.habit.\(habitID).name".localized)
        }
    }
}
