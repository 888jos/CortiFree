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
                colors: PlanPalette.itemGradient,
                minutes: resolvedMinutes(short: short),
                imageName: PlanArtwork.breathingImage(pattern.category)
            )
        case .audio, .evening:
            let session = guidedSession(short: short)
            return PlanItemDisplay(
                title: session?.localizedTitle ?? "plan.item.audio".localized,
                subtitle: session?.localizedSubtitle ?? "",
                kindLabel: (kind == .evening ? "plan.item.evening" : "plan.item.audio").localized,
                symbol: session?.artwork.symbol ?? "headphones",
                colors: PlanPalette.itemGradient,
                minutes: session?.durationMinutes ?? resolvedMinutes(short: short),
                imageName: session.map { $0.artwork.imageName ?? PlanArtwork.sessionImage($0.category) }
            )
        case .habit:
            let info = habitVariantInfo(week: week)
            return PlanItemDisplay(
                title: info.title,
                subtitle: "plan.habit.\(refID).why".localized,
                kindLabel: "plan.item.habit".localized,
                symbol: PlanItem.habitSymbol(refID),
                colors: PlanPalette.itemGradient,
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

// MARK: - Artwork

/// One illustration per item so every plan card uses the same thumbnail treatment.
enum PlanArtwork {
    static func breathingImage(_ category: BreathingCategory) -> String {
        switch category {
        case .calm: return "guided_breathing_04"
        case .sleep: return "guided_breathing_05"
        case .focus: return "guided_breathing_01"
        case .energy: return "guided_breathing_08"
        case .sos: return "guided_breathing_06"
        }
    }

    /// Fallback for guided sessions without their own illustration.
    static func sessionImage(_ category: AudioSessionCategory) -> String {
        switch category {
        case .stressSOS: return "situation_tendu"
        case .workBreak, .focus: return "routine_focus"
        case .sleep: return "situation_dormir"
        case .morning: return "routine_morning"
        case .bodyRelax: return "routine_relaxation"
        case .anxiety: return "situation_anxiete"
        case .selfCompassion: return "routine_stress"
        }
    }
}

// MARK: - Moment of the day

/// Where an item sits in the day timeline (Plan tab and Milo context).
enum PlanDaySlot: String, CaseIterable, Identifiable {
    case morning
    case day
    case evening

    var id: String { rawValue }

    var localizedTitle: String { "plan.slot.\(rawValue)".localized }

    var symbol: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .day: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        }
    }

    static func slot(for item: PlanItem) -> PlanDaySlot {
        switch item.kind {
        case .breathing:
            return .morning
        case .audio:
            return item.guidedSession()?.category == .morning ? .morning : .day
        case .evening:
            return .evening
        case .habit:
            return ["sleep", "journal"].contains(item.refID) ? .evening : .day
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
