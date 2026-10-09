//
//  CelebrationsGalleryView.swift
//  CortiFree
//
//  DEBUG only: shows every celebration / reward screen of the app with sample data,
//  to review them side by side (Home → "🎉 Celebrations gallery").
//

#if DEBUG
import SwiftUI

struct CelebrationsGalleryView: View {
    private enum Demo: String, Identifiable {
        case newMicro, newStreakFirst, newStreak, newDayComplete, newQueue
        case checkmark, flame, firstOfDay, confetti, dayComplete
        case achievement, badgeBronze, badgeSilver, badgeGold, badgeDiamond
        case breathingEnd, exerciseCompletion, commitment, planReady, cycleFinished

        var id: String { rawValue }
    }

    private struct Entry: Identifiable {
        let demo: Demo
        let title: String
        let detail: String
        var id: String { demo.rawValue }
    }

    private let sections: [(String, [Entry])] = [
        ("✨ Nouveau système (file d'attente)", [
            Entry(demo: .newMicro, title: "Micro · validation d'un exercice", detail: "La case se remplit + anneau, plus d'overlay"),
            Entry(demo: .newStreakFirst, title: "Moment · série lancée (jour 1)", detail: "Bannière non bloquante (2,8 s dans l'app ; ici, touche-la pour la fermer)"),
            Entry(demo: .newStreak, title: "Moment · 5 jours de suite", detail: "Vrai nombre de jours de série"),
            Entry(demo: .newDayComplete, title: "Moment · journée bouclée", detail: "Bannière + confettis"),
            Entry(demo: .newQueue, title: "File d'attente · tout débloqué d'un coup", detail: "Série + journée + 2 succès + badge → un par un, grands moments d'abord")
        ]),
        ("Avant · Plan validation", [
            Entry(demo: .checkmark, title: "Coche de validation", detail: "Chaque exercice validé · SuccessCheckmarkView"),
            Entry(demo: .flame, title: "Streak +1 (flamme)", detail: "Carte centrée · semaine comme sur l'accueil · StreakCelebrationCard"),
            Entry(demo: .firstOfDay, title: "Séquence réelle : 1er exercice du jour", detail: "Coche puis carte de série (jour 1)"),
            Entry(demo: .confetti, title: "Confettis", detail: "Tous les exercices du jour faits · .confetti(isActive:)"),
            Entry(demo: .dayComplete, title: "Séquence réelle : journée bouclée", detail: "Coche + confettis + carte « Journée bouclée »")
        ]),
        ("Récompenses", [
            Entry(demo: .achievement, title: "Succès débloqué", detail: "Série de 7 jours · AchievementCelebrationView"),
            Entry(demo: .badgeBronze, title: "Badge habitude · Bronze", detail: "BadgeEvolutionView"),
            Entry(demo: .badgeSilver, title: "Badge habitude · Argent", detail: "BadgeEvolutionView"),
            Entry(demo: .badgeGold, title: "Badge habitude · Or", detail: "BadgeEvolutionView"),
            Entry(demo: .badgeDiamond, title: "Badge habitude · Diamant", detail: "BadgeEvolutionView (étoiles en orbite)")
        ]),
        ("Fin de séance", [
            Entry(demo: .breathingEnd, title: "Fin de respiration", detail: "BreathingSessionEndView"),
            Entry(demo: .exerciseCompletion, title: "Fin d'exercice anti-stress", detail: "CompletionOverlay")
        ]),
        ("Onboarding & cycle", [
            Entry(demo: .commitment, title: "Engagement (maintenir pour s'engager)", detail: "CommitmentPledgeView"),
            Entry(demo: .planReady, title: "Plan prêt (analyse)", detail: "LoadingAnalysisView"),
            Entry(demo: .cycleFinished, title: "Cycle de 28 jours terminé", detail: "PlanFinishedCard")
        ])
    ]

    @State private var presented: Demo?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(sections, id: \.0) { section in
                    Section(section.0) {
                        ForEach(section.1) { entry in
                            Button {
                                presented = entry.demo
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(entry.title).font(.system(size: 15, weight: .semibold))
                                    Text(entry.detail).font(.system(size: 12)).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Célébrations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $presented) { demo in
            DemoHost(onClose: { presented = nil }) { close in
                content(for: demo, close: close)
            }
        }
    }

    @ViewBuilder
    private func content(for demo: Demo, close: @escaping () -> Void) -> some View {
        switch demo {
        case .newMicro:
            MicroDemo()
        case .newStreakFirst:
            QueueDemo(celebrations: [.streak(days: 1)])
        case .newStreak:
            QueueDemo(celebrations: [.streak(days: 5)])
        case .newDayComplete:
            QueueDemo(celebrations: [.dayComplete(items: 5, minutes: 18)])
        case .newQueue:
            QueueDemo(celebrations: [
                .streak(days: 5),
                .dayComplete(items: 5, minutes: 18),
                .achievement(Self.sampleAchievement),
                .achievement(Self.achievement("streak_14")),
                .badge(Self.sampleBadge)
            ])
        case .checkmark:
            CheckmarkDemo(onDone: close)
        case .flame:
            FlameDemo(onDone: close)
        case .firstOfDay:
            SequenceDemo(withFlame: true, withConfetti: false)
        case .confetti:
            ConfettiDemo()
        case .dayComplete:
            SequenceDemo(withFlame: false, withConfetti: true)
        case .achievement:
            AchievementCelebrationView(achievement: Self.sampleAchievement, onContinue: close)
        case .badgeBronze:
            BadgeDemo(level: 0, onDone: close)
        case .badgeSilver:
            BadgeDemo(level: 1, onDone: close)
        case .badgeGold:
            BadgeDemo(level: 2, onDone: close)
        case .badgeDiamond:
            BadgeDemo(level: 3, onDone: close)
        case .breathingEnd:
            BreathingSessionEndView(pattern: .physiologicalSigh, breathedSeconds: 180, cycles: 12, onDone: close, onRestart: {})
        case .exerciseCompletion:
            CompletionOverlay(
                content: RatedContent(type: .exercise, id: AntiStressExerciseType.grounding5Senses.rawValue,
                                      title: AntiStressExerciseType.grounding5Senses.displayName),
                onDismiss: close
            )
        case .commitment:
            CommitmentPledgeView(onContinue: close)
        case .planReady:
            LoadingAnalysisView(onComplete: close)
        case .cycleFinished:
            ScrollView {
                PlanFinishedCard(plan: Self.finishedPlan, onContinue: close, onChangeGoal: close)
                    .padding(20)
                    .padding(.top, 80)
            }
        }
    }

    private static var sampleAchievement: Achievement { achievement("streak_7") }

    private static func achievement(_ id: String) -> Achievement {
        var achievement = Achievement.allAchievements.first { $0.id == id } ?? Achievement.allAchievements[0]
        achievement.progress = achievement.requirement
        achievement.unlockedAt = Date()
        return achievement
    }

    private static var sampleBadge: HabitBadge {
        var badge = HabitBadge.badgesForHabit("breathing")[1]
        badge.progress = badge.requirement
        badge.unlockedAt = Date()
        return badge
    }

    private static var finishedPlan: PersonalPlan {
        PersonalPlanGenerator.generate(profile: PlanProfile(), startDate: Date().addingTimeInterval(-30 * 86_400))
    }
}

// MARK: - Host (plan background + close button)

private struct DemoHost<Content: View>: View {
    let onClose: () -> Void
    @ViewBuilder let content: (_ close: @escaping () -> Void) -> Content

    var body: some View {
        ZStack {
            PlanBackground(goal: nil)
            content(onClose)
        }
        .overlay(alignment: .bottom) {
            Button(action: onClose) {
                Label("Fermer la démo", systemImage: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.black.opacity(0.45)))
            }
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Demos

/// Enqueues celebrations in the real CelebrationCenter and shows them with a local host
/// (the app's host lives under this full-screen cover).
private struct QueueDemo: View {
    let celebrations: [Celebration]

    var body: some View {
        ZStack(alignment: .top) {
            ReplayButton { play() }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            CelebrationHost()
        }
        .onAppear {
            CelebrationCenter.shared.holdsMomentsForPreview = true
            play()
        }
        .onDisappear {
            CelebrationCenter.shared.holdsMomentsForPreview = false
            CelebrationCenter.shared.dismissCurrent()
        }
    }

    private func play() {
        celebrations.forEach { CelebrationCenter.shared.enqueue($0) }
    }
}

/// A real plan card: tap the circle to see the micro celebration.
private struct MicroDemo: View {
    @State private var done = false
    private let item = PlanItem(id: "breathing", kind: .breathing, refID: "extended_exhale", minutes: 3,
                                shortRefID: nil, shortMinutes: nil, variant: nil)

    var body: some View {
        VStack(spacing: 24) {
            PlanItemCard(
                item: item,
                display: item.display(week: 1, short: false),
                status: done ? .done : .todo,
                isShort: false,
                isEditable: true,
                onOpen: {},
                onToggleDone: {
                    if !done { HapticManager.success() }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { done.toggle() }
                },
                onSkip: {}
            )
            .padding(.horizontal, 20)
            Text("Touche le cercle pour valider")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

private struct CheckmarkDemo: View {
    let onDone: () -> Void
    @State private var show = true

    var body: some View {
        ZStack {
            if show {
                SuccessCheckmarkView { show = false }
                    .transition(.scale.combined(with: .opacity))
            } else {
                ReplayButton { withAnimation { show = true } }
            }
        }
    }
}

private struct FlameDemo: View {
    let onDone: () -> Void
    @State private var show = true

    var body: some View {
        ZStack {
            if show {
                StreakCelebrationCard(days: 5) { show = false }
            } else {
                ReplayButton { show = true }
            }
        }
    }
}

private struct ConfettiDemo: View {
    @State private var active = false

    var body: some View {
        ReplayButton { replay() }
            .confetti(isActive: active)
            .onAppear { replay() }
    }

    private func replay() {
        active = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { active = false }
    }
}

/// What the Plan tab really shows when an item is validated (overlays stacked at once).
private struct SequenceDemo: View {
    let withFlame: Bool
    let withConfetti: Bool
    @State private var checkmark = false
    @State private var flame = false
    @State private var confetti = false

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                if withConfetti {
                    Label("plan.next.all_done".localized, systemImage: "checkmark.seal.fill")
                        .font(Font.Poppins.custom(.semiBold, size: 15))
                        .foregroundStyle(PlanPalette.done)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .planGlass(cornerRadius: 22, tint: PlanPalette.done)
                        .padding(.horizontal, 20)
                }
                ReplayButton { replay() }
            }
            if checkmark {
                SuccessCheckmarkView { checkmark = false }
                    .transition(.scale.combined(with: .opacity))
            }
            if flame {
                StreakCelebrationCard(days: 1) { flame = false }
                    .transition(.opacity)
            }
        }
        .confetti(isActive: confetti)
        .onAppear { replay() }
    }

    private func replay() {
        HapticManager.success()
        withAnimation { checkmark = true }
        // In the app the streak card comes from the celebration queue, after the check mark.
        if withFlame { DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { withAnimation { flame = true } } }
        if withConfetti {
            confetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { confetti = false }
        }
    }
}

private struct BadgeDemo: View {
    let level: Int
    let onDone: () -> Void
    @State private var isPresented = true

    private var badge: HabitBadge {
        let badges = HabitBadge.badgesForHabit("meditation")
        var badge = badges[min(level, badges.count - 1)]
        badge.progress = badge.requirement
        badge.unlockedAt = Date()
        return badge
    }

    var body: some View {
        ZStack {
            if isPresented {
                BadgeEvolutionView(badge: badge, isPresented: $isPresented)
            } else {
                ReplayButton { isPresented = true }
            }
        }
    }
}

private struct ReplayButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Rejouer", systemImage: "arrow.counterclockwise")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(.white.opacity(0.15)))
        }
    }
}
#endif
