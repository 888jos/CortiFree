//
//  AIQuizReturnCenter.swift
//  CortiFree
//
//  « I copied it, come back » from the AI quiz Live Activity (cortifree://ai-quiz/paste):
//  the Milo conversation of the onboarding reads the clipboard when it fires.
//  iOS often kills CortiFree while the user is in their AI: the chosen AI and, once pasted,
//  its reply are kept here (on the phone only) so the onboarding resumes on that step.
//

import UIKit

@MainActor
final class AIQuizReturnCenter: ObservableObject {
    static let shared = AIQuizReturnCenter()
    @Published private(set) var pasteRequestedAt: Date?
    private let defaults = UserDefaults.standard
    private let appKey = "onboarding_ai_quiz_app"
    private let replyKey = "onboarding_ai_quiz_reply"
    private let promptChangeCountKey = "onboarding_ai_quiz_prompt_change_count"
    private init() {}

    func requestPaste() { pasteRequestedAt = Date() }

    /// A « come back » not handled yet (on a cold launch it arrives before the conversation
    /// is on screen). Consumed once; an old one no longer counts.
    func takePendingPaste() -> Bool {
        guard let requested = pasteRequestedAt else { return false }
        pasteRequestedAt = nil
        return Date().timeIntervalSince(requested) < 2 * 60
    }

    // MARK: The step, across an app kill

    var savedApp: OnboardingAIApp? {
        defaults.string(forKey: appKey).flatMap(OnboardingAIApp.init(rawValue:))
    }

    var savedReply: AIQuizReply? {
        defaults.data(forKey: replyKey).flatMap { try? JSONDecoder().decode(AIQuizReply.self, from: $0) }
    }

    func begin(_ app: OnboardingAIApp) {
        defaults.set(app.rawValue, forKey: appKey)
        defaults.removeObject(forKey: replyKey)
    }

    func save(_ reply: AIQuizReply) {
        if let data = try? JSONEncoder().encode(reply) { defaults.set(data, forKey: replyKey) }
    }

    /// Back to the list of AIs: nothing to resume, but what was copied since stays protected.
    func cancelApp() {
        defaults.removeObject(forKey: appKey)
        defaults.removeObject(forKey: replyKey)
    }

    /// The step is over (plan chosen, or the quiz by hand).
    func end() {
        cancelApp()
        defaults.removeObject(forKey: promptChangeCountKey)
    }

    // MARK: Clipboard (never read here: reading it shows iOS's « Allow Paste »)

    func copyPrompt(_ prompt: String) {
        UIPasteboard.general.string = prompt
        defaults.set(UIPasteboard.general.changeCount, forKey: promptChangeCountKey)
    }

    /// Something was copied after our message, most likely the AI's reply: don't overwrite it.
    var clipboardChangedSincePrompt: Bool {
        guard let count = defaults.object(forKey: promptChangeCountKey) as? Int else { return false }
        return UIPasteboard.general.changeCount != count && UIPasteboard.general.hasStrings
    }
}
