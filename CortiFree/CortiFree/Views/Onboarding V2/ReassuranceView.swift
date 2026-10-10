//
//  ReassuranceView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Reassurance screen with animated text (tap to show it all)
//

import SwiftUI

struct ReassuranceView: View {
    let overallData: OverallQuizData?
    let onStartQuiz: () -> Void

    private let textSpeedMultiplier = 1.875

    @ObservedObject var languageManager = LanguageManager.shared
    @State private var displayedText: String = ""
    @State private var currentCharacterIndex: Int = 0
    @State private var showButton: Bool = false
    @State private var screenViewTime: Date?

    /// One hand-written sentence per answer, never the answers pasted back into a template:
    /// the main reason, then the age (« in your thirties », not « 25–34 »), then how long.
    private var fullText: String {
        var paragraphs: [String] = []
        if let data = overallData {
            if let reason = Self.mainReason(data.reasonCodes) {
                paragraphs.append(text("reason_\(reason)"))
            }
            let context = [text("age_\(data.ageCode)"), text("duration_\(data.durationCode)")]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            if !context.isEmpty { paragraphs.append(context) }
        }
        if paragraphs.isEmpty {
            paragraphs.append("onboarding_v2.reassurance.message_part2".localized)
        }
        paragraphs.append(text("next"))
        if needsSupportMessage {
            paragraphs.append("onboarding_v2.reassurance.support".localized)
        }
        return paragraphs.joined(separator: "\n\n")
    }

    /// Several reasons can be ticked: speak to the heaviest one only.
    private static func mainReason(_ codes: [String]) -> String? {
        let priority = ["difficult", "anxiety", "sleep", "energy", "focus", "mental", "habits"]
        return priority.first(where: codes.contains) ?? codes.first
    }

    /// Localised sentence, or "" when an answer has none (unknown code).
    private func text(_ key: String) -> String {
        let fullKey = "onboarding_v2.reassurance.text.\(key)"
        let value = fullKey.localized
        return value == fullKey ? "" : value
    }

    /// Minors and people going through a hard time get a pointer to real help.
    private var needsSupportMessage: Bool {
        guard let data = overallData else { return false }
        return data.ageCode == "under_18" || data.reasonCodes.contains("difficult")
    }

    init(overallData: OverallQuizData? = nil, onStartQuiz: @escaping () -> Void) {
        self.overallData = overallData
        self.onStartQuiz = onStartQuiz
    }

    var body: some View {
        ZStack {
            GalaxyBackgroundView()
                .ignoresSafeArea()

            // Dark overlay for readability
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    LottieView(filename: "sloth_meditate.json", loopMode: .loop)
                .frame(width: 156, height: 156)
                        .padding(.bottom, 8)

                    // Animated text at top (centered)
                    VStack(spacing: 32) {
                    Text(displayedText)
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .frame(minHeight: 200, alignment: .top)
                        .padding(.horizontal, 40)
                        .contentShape(Rectangle())
                        .onTapGesture { revealFullText() }
                        .accessibilityAction(named: Text("common.continue".localized)) { revealFullText() }

                }
                // Keep the copy visible after the larger mascot artwork.
                .padding(.top, 20)

                    Spacer(minLength: 48)

                    // Bottom button section (appear after badges)
                    if showButton {
                    VStack(spacing: 12) {
                        Button(action: {
                            HapticManager.medium()

                            // Track button click with time spent
                            if let startTime = screenViewTime {
                                let timeSpent = Date().timeIntervalSince(startTime)
                                AnalyticsManager.shared.trackOnboardingReassuranceContinue(timeSpent: timeSpent)
                            }

                            onStartQuiz()
                        }) {
                            HStack(spacing: 12) {
                                Text("onboarding_v2.reassurance.start_quiz".localized)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                    .foregroundColor(.white)

                                // White arrow in dark circle
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 32, height: 32)

                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.leading, 24)
                            .padding(.trailing, 12)
                        }
                        .buttonStyle(.glassPrimary)

                        // Time estimate (centered below button)
                        Text("onboarding_v2.reassurance.time_estimate".localized)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .onAppear {
            // Track screen view
            screenViewTime = Date()
            AnalyticsManager.shared.trackOnboardingReassuranceViewed(userName: "")

            startTextAnimation()
        }
    }

    // MARK: - Text Animation

    private func startTextAnimation() {
        // Start animation after short delay (reduced by 50%)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            animateNextCharacter()
        }
    }

    /// Tapping the text shows it all at once (the typewriter effect is optional).
    private func revealFullText() {
        guard currentCharacterIndex < fullText.count else { return }
        currentCharacterIndex = fullText.count
        displayedText = fullText
        withAnimation(.easeInOut(duration: 0.3)) {
            showButton = true
        }
    }

    private func animateNextCharacter() {
        guard currentCharacterIndex < fullText.count else {
            // Text animation complete, show button after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showButton = true
                }
            }
            return
        }

        let index = fullText.index(fullText.startIndex, offsetBy: currentCharacterIndex)
        displayedText.append(fullText[index])
        currentCharacterIndex += 1

        // Haptic feedback only every 10 characters to avoid rate-limit (32hz)
        if currentCharacterIndex % 10 == 0 {
            HapticManager.light()
        }

        // Reveal the text 1.25x faster than the previous timing.
        let baseDelay: Double = fullText[index].isWhitespace ? 0.0096 : 0.048
        let delay = baseDelay / textSpeedMultiplier
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            animateNextCharacter()
        }
    }
}

#Preview {
    ReassuranceView(onStartQuiz: {})
}
