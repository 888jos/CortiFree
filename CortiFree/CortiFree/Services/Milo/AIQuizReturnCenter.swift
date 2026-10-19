//
//  AIQuizReturnCenter.swift
//  CortiFree
//
//  « I copied it, come back » from the AI quiz Live Activity (cortifree://ai-quiz/paste):
//  the Milo conversation of the onboarding reads the clipboard when it fires.
//

import Foundation

@MainActor
final class AIQuizReturnCenter: ObservableObject {
    static let shared = AIQuizReturnCenter()
    @Published private(set) var pasteRequestedAt: Date?
    private init() {}

    func requestPaste() { pasteRequestedAt = Date() }
}
