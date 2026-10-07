//
//  PlanItemDisplay.swift
//  CortiFree
//
//  Resolves a PlanItem (ids only) into localized, displayable content at render time,
//  using the breathing catalogue (BreathingPattern) and the audio catalogue
//  (GuidedSessionCatalog). Missing ids degrade gracefully.
//

import SwiftUI

struct PlanItemDisplay {
    let title: String
    let subtitle: String
    let kindLabel: String
    let symbol: String
    let colors: [Color]
    let minutes: Int
    let imageName: String?

    var durationLabel: String? { minutes > 0 ? "\(minutes) min" : nil }
}

extension PlanItem {

    func breathingPattern(short: Bool = false) -> BreathingPattern {
        BreathingPattern.pattern(named: resolvedRefID(short: short)) ?? .deepAbdominal
    }

    func guidedSession(short: Bool = false) -> GuidedSession? {
        GuidedSessionCatalog.session(id: resolvedRefID(short: short)) ?? GuidedSessionCatalog.session(id: refID)
    }

    func display(week: Int, short: Bool) -> PlanItemDisplay {
        switch kind {
        case .breathing:
            let pattern = breathingPattern(short: short)
            return PlanItemDisplay(
                title: pattern.localizedTitle,
                subtitle: pattern.localizedBenefit,
                kindLabel: "plan.item.breathing".localized,
                symbol: pattern.symbol,
                colors: [pattern.accentColor, pattern.accentColor.opacity(0.55)],
                minutes: resolvedMinutes(short: short),
                imageName: nil
            )
        case .audio, .evening:
            let session = guidedSession(short: short)
            return PlanItemDisplay(
                title: session?.localizedTitle ?? "plan.item.audio".localized,
                subtitle: session?.localizedSubtitle ?? "",
                kindLabel: (kind == .evening ? "plan.item.evening" : "plan.item.audio").localized,
                symbol: session?.artwork.symbol ?? "headphones",
                colors: session?.artwork.colors ?? [Color(hex: "7B5CFF"), Color(hex: "B794F6")],
                minutes: session?.durationMinutes ?? resolvedMinutes(short: short),
                imageName: session?.artwork.imageName
            )
        case .habit:
            let info = habitVariantInfo(week: week)
            return PlanItemDisplay(
                title: info.title,
                subtitle: "plan.habit.\(refID).why".localized,
                kindLabel: "plan.item.habit".localized,
                symbol: PlanItem.habitSymbol(refID),
                colors: [Color(hex: "B794F6"), Color(hex: "6D4BC4")],
                minutes: 0,
                imageName: info.imageName
            )
        }
    }

    /// Existing habit titles / illustrations, gently ramped by plan week.
    func habitVariantInfo(week: Int) -> HabitVariantInfo {
        // Plan weeks 1–4 map onto the historical 10-week ladder (1, 2, 4, 6).
        let ladderWeek = [1, 2, 4, 6][max(0, min(3, week - 1))]
        let index = variant ?? 0
        switch refID {
        case "sleep":
            return HabitVariantInfo(imageName: "habit_sleep_night", title: HabitVariantConfig.bedtimeTitle(for: ladderWeek), frequency: "frequency.daily")
        case "water":
            return HabitVariantConfig.getWaterVariant(for: ladderWeek)
        case "sport":
            let list = HabitVariantConfig.sportVariants
            return list[index % max(list.count, 1)]
        case "nature":
            let list = HabitVariantConfig.natureVariants
            return list[index % max(list.count, 1)]
        case "social":
            let list = HabitVariantConfig.socialVariants
            return list[index % max(list.count, 1)]
        case "journal":
            return HabitVariantConfig.journalVariant
        case "meditation":
            return HabitVariantConfig.meditationVariant
        default:
            return HabitVariantConfig.breathingVariant
        }
    }

    static func habitSymbol(_ habitID: String) -> String {
        switch habitID {
        case "breathing": return "wind"
        case "meditation": return "figure.mind.and.body"
        case "water": return "drop.fill"
        case "sport": return "figure.run"
        case "sleep": return "moon.zzz.fill"
        case "nature": return "leaf.fill"
        case "journal": return "book.fill"
        case "social": return "person.2.fill"
        default: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Playback routing

/// Single entry point used by the plan to start a guided audio session.
enum PlanPlaybackRouter {
    @MainActor
    static func play(sessionID: String) {
        guard let session = GuidedSessionCatalog.session(id: sessionID) else { return }
        GuidedSessionPlayer.shared.play(session, presentFullPlayer: true)
    }
}
