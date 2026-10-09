//
//  PlanAssistantAction.swift
//  CortiFree
//
//  Plan changes Milo can propose. Milo ends its reply with one <plan_action>{json}</plan_action>
//  tag; the app strips it, resolves it against the real plan (Milo never picks content ids, the
//  app does) and shows a card. Nothing changes until the user taps « Apply ».
//

import Foundation

struct PlanAssistantProposal: Equatable {
    enum Change: Equatable {
        case swap(day: Int, itemID: String, replacement: PlanItem, avoidOld: Bool)
        case remove(day: Int, itemID: String, avoid: Bool)
        case add(day: Int, item: PlanItem)
        case regenerate(goal: PlanGoal?)
    }

    let change: Change
    /// One line for the card, in the app language.
    let summary: String
    let reason: String?

    // The matching instructions for the model live on the server (convex/assistant.ts, planInstructions).

    // MARK: - Parsing

    private static let tagRegex = try! NSRegularExpression(
        pattern: "<plan_action>(.*?)</plan_action>", options: [.dotMatchesLineSeparators, .caseInsensitive]
    )

    /// Splits a raw reply into the visible text and the proposal it carries (if any, and valid).
    @MainActor
    static func extract(from response: String) -> (text: String, proposal: PlanAssistantProposal?) {
        let range = NSRange(response.startIndex..., in: response)
        let matches = tagRegex.matches(in: response, range: range)
        guard !matches.isEmpty else { return (response, nil) }
        let text = tagRegex.stringByReplacingMatches(in: response, range: range, withTemplate: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = matches.first, let jsonRange = Range(first.range(at: 1), in: response),
              let data = response[jsonRange].data(using: .utf8),
              let raw = try? JSONDecoder().decode(Raw.self, from: data) else { return (text, nil) }
        return (text, resolve(raw))
    }

    private struct Raw: Decodable {
        let type: String
        let day: Int?
        let item: String?
        let kind: String?
        let goal: String?
        let avoid: Bool?
        let reason: String?
    }

    /// Turns Milo's request into a concrete change, or nil when it can't apply to the plan as it is.
    @MainActor
    private static func resolve(_ raw: Raw) -> PlanAssistantProposal? {
        let store = PersonalPlanStore.shared
        guard let plan = store.plan else { return nil }
        let reason = raw.reason.map { String($0.prefix(120)) }
        let dayNumber = raw.day ?? plan.dayIndex()

        switch raw.type {
        case "swap":
            guard store.isEditable(dayNumber: dayNumber), let itemID = raw.item,
                  let day = plan.day(dayNumber), let item = day.items.first(where: { $0.id == itemID }),
                  let replacement = store.alternatives(dayNumber: dayNumber, itemID: itemID).first else { return nil }
            let summary = String(format: "milo.plan.swap".localized,
                                 title(item, day), title(replacement, day), dayLabel(dayNumber, plan))
            return .init(change: .swap(day: dayNumber, itemID: itemID, replacement: replacement, avoidOld: raw.avoid ?? false),
                         summary: summary, reason: reason)

        case "remove":
            guard store.isEditable(dayNumber: dayNumber), let itemID = raw.item,
                  let day = plan.day(dayNumber), day.items.count > 1,
                  let item = day.items.first(where: { $0.id == itemID }) else { return nil }
            let summary = String(format: "milo.plan.remove".localized, title(item, day), dayLabel(dayNumber, plan))
            return .init(change: .remove(day: dayNumber, itemID: itemID, avoid: raw.avoid ?? false),
                         summary: summary, reason: reason)

        case "add":
            guard store.isEditable(dayNumber: dayNumber), let day = plan.day(dayNumber) else { return nil }
            let kinds: Set<PlanItemKind> = switch raw.kind {
            case "breathing": [.breathing]
            case "habit": [.habit]
            default: [.audio, .evening]
            }
            guard let item = store.additions(dayNumber: dayNumber).first(where: { kinds.contains($0.kind) }) else { return nil }
            let summary = String(format: "milo.plan.add".localized, title(item, day), dayLabel(dayNumber, plan))
            return .init(change: .add(day: dayNumber, item: item), summary: summary, reason: reason)

        case "regenerate":
            guard store.isEditable(dayNumber: plan.dayIndex()) else { return nil }
            let goal = raw.goal.flatMap(PlanGoal.init(rawValue:))
            let summary = if let goal, goal != plan.goal {
                String(format: "milo.plan.goal".localized, goal.localizedName)
            } else {
                "milo.plan.regenerate".localized
            }
            return .init(change: .regenerate(goal: goal), summary: summary, reason: reason)

        default:
            return nil
        }
    }

    private static func title(_ item: PlanItem, _ day: PlanDay) -> String {
        item.display(week: day.week, short: false).title
    }

    private static func dayLabel(_ dayNumber: Int, _ plan: PersonalPlan) -> String {
        let offset = dayNumber - plan.dayIndex()
        switch offset {
        case 0: return "milo.plan.today".localized
        case 1: return "milo.plan.tomorrow".localized
        default: return String(format: "milo.plan.day".localized, dayNumber)
        }
    }

    // MARK: - Applying

    /// Applies the change as an assistant edit (undoable from the Plan tab and the card).
    @MainActor
    func apply() -> Bool {
        let store = PersonalPlanStore.shared
        let reason = reason ?? "milo"
        let applied: Bool
        switch change {
        case let .swap(day, itemID, replacement, avoidOld):
            applied = store.swapItem(dayNumber: day, itemID: itemID, with: replacement,
                                     source: .assistant, reason: reason, excludeOld: avoidOld)
        case let .remove(day, itemID, avoid):
            applied = store.removeItem(dayNumber: day, itemID: itemID, source: .assistant, reason: reason, exclude: avoid)
        case let .add(day, item):
            applied = store.addItem(item, dayNumber: day, source: .assistant, reason: reason)
        case let .regenerate(goal):
            applied = store.regenerate(goal: goal, source: .assistant, reason: reason)
        }
        AnalyticsManager.shared.track(event: "milo_plan_change", properties: ["applied": applied, "kind": kindName])
        return applied
    }

    var kindName: String {
        switch change {
        case .swap: "swap"
        case .remove: "remove"
        case .add: "add"
        case .regenerate: "regenerate"
        }
    }
}
