//
//  CelebrationCenter.swift
//  CortiFree
//
//  Single queue for every celebration so they never stack on top of each other.
//  Three tiers:
//  - micro: each validated item animates its own checkbox (PlanItemCard, not queued)
//  - moment: non-blocking banner that dismisses itself (streak +1, day complete)
//  - milestone: full screen until dismissed (achievement, habit badge)
//  Milestones jump ahead of moments; within a tier, order of arrival is kept.
//

import SwiftUI

enum Celebration: Identifiable, Equatable {
    case streak(days: Int)
    case dayComplete(items: Int, minutes: Int)
    case achievement(Achievement)
    case badge(HabitBadge)
    /// A habit kept ≥ 80 % over a whole cycle (PlanCycleReview): it leaves the plan.
    case habitAcquired(habitID: String)

    var id: String {
        switch self {
        case .streak(let days): return "streak-\(days)"
        case .dayComplete: return "day-complete"
        case .achievement(let achievement): return "achievement-\(achievement.id)"
        case .badge(let badge): return "badge-\(badge.id ?? "\(badge.habitId)_\(badge.level.rawValue)")"
        case .habitAcquired(let habitID): return "habit-acquired-\(habitID)"
        }
    }

    var isMilestone: Bool {
        switch self {
        case .achievement, .badge: return true
        case .streak, .dayComplete, .habitAcquired: return false
        }
    }

    static func == (lhs: Celebration, rhs: Celebration) -> Bool { lhs.id == rhs.id }
}

@MainActor
final class CelebrationCenter: ObservableObject {
    static let shared = CelebrationCenter()

    @Published private(set) var current: Celebration?
    private var queue: [Celebration] = []
    private var autoDismissTask: Task<Void, Never>?

    /// How long a moment banner stays on screen.
    static let momentDuration: Duration = .seconds(2.8)

    #if DEBUG
    /// Celebrations gallery: keep banners on screen until tapped, to inspect them.
    var holdsMomentsForPreview = false
    #endif

    private init() {}

    func enqueue(_ celebration: Celebration) {
        guard current != celebration, !queue.contains(celebration) else { return }
        if celebration.isMilestone, let index = queue.firstIndex(where: { !$0.isMilestone }) {
            queue.insert(celebration, at: index)
        } else {
            queue.append(celebration)
        }
        showNextIfIdle()
    }

    func dismissCurrent() {
        autoDismissTask?.cancel()
        guard current != nil else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { current = nil }
        // Let the exit transition finish before the next one comes in.
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            showNextIfIdle()
        }
    }

    private func showNextIfIdle() {
        guard current == nil, !queue.isEmpty else { return }
        let next = queue.removeFirst()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { current = next }
        if next.isMilestone {
            HapticManager.success()
        } else {
            HapticManager.light()
            #if DEBUG
            if holdsMomentsForPreview { return }
            #endif
            autoDismissTask = Task {
                try? await Task.sleep(for: Self.momentDuration)
                guard !Task.isCancelled else { return }
                dismissCurrent()
            }
        }
    }
}
