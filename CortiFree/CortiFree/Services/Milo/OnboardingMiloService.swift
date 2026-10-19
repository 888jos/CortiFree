//
//  OnboardingMiloService.swift
//  CortiFree
//
//  The real Milo during onboarding, before any account (convex/onboardingMilo.ts).
//  Sent: the plan the other AI picked, its short analysis, and what the user types in that
//  conversation. Never the whole reply pasted from the other AI. Nothing is kept.
//

import UIKit

struct OnboardingMiloReply: Decodable {
    let content: String
    let exerciseId: String?
}

@MainActor
enum OnboardingMiloService {
    /// Calming techniques Milo may pick from (no stimulating ones, no long holds for a first try).
    static let exerciseKeys = ["coherence", "physiological_sigh", "four_seven_eight", "extended_exhale",
                               "box", "sos_214", "slow66", "sleep_wave"]

    static var exercises: [BreathingPattern] {
        exerciseKeys.compactMap { key in BreathingPattern.allPatterns.first { $0.key == key } }
    }

    static func pattern(_ key: String?) -> BreathingPattern? {
        guard let key else { return nil }
        return exercises.first { $0.key == key }
    }

    static func report(reply: AIQuizReply, app: OnboardingAIApp) async throws -> OnboardingMiloReply {
        try await call(kind: "report", reply: reply, app: app, messages: [])
    }

    static func chat(reply: AIQuizReply, app: OnboardingAIApp,
                     messages: [(role: String, content: String)]) async throws -> OnboardingMiloReply {
        try await call(kind: "chat", reply: reply, app: app, messages: messages)
    }

    private static func call(kind: String, reply: AIQuizReply, app: OnboardingAIApp,
                             messages: [(role: String, content: String)]) async throws -> OnboardingMiloReply {
        let result: OnboardingMiloReply = try await ConvexBackend.shared.call(
            .action,
            path: "onboardingMilo:reply",
            args: [
                "kind": kind,
                "deviceId": deviceID,
                "language": languageName,
                "context": context(reply: reply, app: app),
                "exercises": exercises.map {
                    ["id": $0.key, "name": $0.localizedTitle, "benefit": String($0.localizedBenefit.prefix(200))]
                },
                // The last 8 turns, each cut to the server's limit.
                "messages": messages.suffix(8).map { ["role": $0.role, "content": String($0.content.prefix(800))] },
            ],
            authenticated: false
        )
        return result
    }

    /// The plan the other AI picked (or the default one), then its analysis.
    private static func context(reply: AIQuizReply, app: OnboardingAIApp) -> String {
        let assistant = app == .other ? "their AI assistant" : app.name
        var lines: [String]
        if let goal = reply.goal {
            lines = ["Plan picked by \(assistant) among CortiFree's five plans: \(goal.localizedName) (\(goal.localizedPromise))"]
        } else {
            lines = ["\(assistant) did not know them well enough to pick a plan; they start with the default one: "
                     + "\(PlanGoal.stress.localizedName) (\(PlanGoal.stress.localizedPromise))"]
        }
        if !reply.analysis.isEmpty {
            lines.append("")
            lines.append("Analysis written by \(assistant): \(reply.analysis)")
        }
        return String(lines.joined(separator: "\n").prefix(3000))
    }

    private static var languageName: String {
        switch LanguageManager.shared.currentLanguage {
        case .french: return "French"
        case .english: return "English"
        case .spanish: return "Spanish"
        case .german: return "German"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        }
    }

    /// Only for the server's daily limit per device.
    private static var deviceID: String {
        if let id = UIDevice.current.identifierForVendor?.uuidString { return id }
        let key = "onboarding_milo_device_id"
        if let saved = UserDefaults.standard.string(forKey: key) { return saved }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
    }
}
