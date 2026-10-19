//
//  ReassuranceView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Reassurance: Milo's chat, one message per paragraph, read only (tap shows them all)
//

import SwiftUI

struct ReassuranceView: View {
    let overallData: OverallQuizData?
    let onBack: (() -> Void)?
    let onStartQuiz: () -> Void

    @ObservedObject var languageManager = LanguageManager.shared
    @State private var shownCount = 0
    @State private var isTyping = false
    @State private var showButton: Bool = false
    @State private var screenViewTime: Date?

    /// Short on purpose (2–3 bubbles): thanks with the first name when known, one sentence on the
    /// main reason, one on how long it lasts, then what comes next. Age is not repeated back.
    private var messages: [String] {
        let name = OnboardingPersonalization.firstName
        let thanks = name.isEmpty
            ? "onboarding_v2.reassurance.brief.thanks".localized
            : String(format: "onboarding_v2.reassurance.brief.thanks_name".localized, name)
        var first = thanks
        if let data = overallData, let reason = Self.mainReason(data.reasonCodes) {
            let line = brief("reason_\(reason)")
            first += line.isEmpty ? "" : " " + line
        }
        if first == thanks { first += " " + "onboarding_v2.reassurance.brief.default".localized }
        var result = [first]
        if let data = overallData {
            let duration = brief("duration_\(data.durationCode)")
            if !duration.isEmpty { result.append(duration) }
        }
        result.append("onboarding_v2.reassurance.brief.next".localized)
        if needsSupportMessage {
            result.append("onboarding_v2.reassurance.support".localized)
        }
        return result
    }

    /// Localised short sentence, or "" when an answer has none (unknown code).
    private func brief(_ key: String) -> String {
        let fullKey = "onboarding_v2.reassurance.brief.\(key)"
        let value = fullKey.localized
        return value == fullKey ? "" : value
    }

    /// Several reasons can be ticked: speak to the heaviest one only.
    private static func mainReason(_ codes: [String]) -> String? {
        let priority = ["difficult", "anxiety", "sleep", "energy", "focus", "mental", "habits"]
        return priority.first(where: codes.contains) ?? codes.first
    }

    /// Minors and people going through a hard time get a pointer to real help.
    private var needsSupportMessage: Bool {
        guard let data = overallData else { return false }
        return data.ageCode == "under_18" || data.reasonCodes.contains("difficult")
    }

    init(overallData: OverallQuizData? = nil, onBack: (() -> Void)? = nil, onStartQuiz: @escaping () -> Void) {
        self.overallData = overallData
        self.onBack = onBack
        self.onStartQuiz = onStartQuiz
    }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.85, isAnimated: false).ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(messages.prefix(shownCount).enumerated()), id: \.offset) { index, text in
                                miloMessage(text, showsAvatar: index == 0)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                            if isTyping {
                                HStack(spacing: 10) {
                                    avatar(size: 28)
                                    ReassuranceTypingDots()
                                }
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 12)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .onChange(of: shownCount) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                }
                // Tapping shows every message at once.
                .contentShape(Rectangle())
                .onTapGesture { revealAll() }

                if showButton { startButton.transition(.move(edge: .bottom).combined(with: .opacity)) }
            }
        }
        .onAppear {
            guard screenViewTime == nil else { return }
            screenViewTime = Date()
            AnalyticsManager.shared.trackOnboardingReassuranceViewed(userName: "")
            showNext()
        }
    }

    // MARK: Milo chat look (as in the Milo conversation of the app)

    private var header: some View {
        HStack(spacing: 10) {
            if let onBack {
                Button {
                    HapticManager.light()
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .cfGlassCircle(interactive: false)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 40, height: 40)
            }
            Spacer()
            HStack(spacing: 8) {
                avatar(size: 28)
                Text(verbatim: "Milo")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private func avatar(size: CGFloat) -> some View {
        Image("cortifree_assistant_avatar")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }

    private func miloMessage(_ text: String, showsAvatar: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Group {
                if showsAvatar { avatar(size: 28) } else { Color.clear }
            }
            .frame(width: 28, height: 28)
            // Milo's messages sit in a violet bubble, the user's in a grey one.
            Text(text)
                .font(.system(size: 17))
                .lineSpacing(4)
                .foregroundStyle(.white.opacity(0.94))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(hex: "8B5CF6").opacity(0.22), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            Spacer(minLength: 32)
        }
    }

    private var startButton: some View {
        VStack(spacing: 10) {
            Button {
                HapticManager.medium()
                if let startTime = screenViewTime {
                    AnalyticsManager.shared.trackOnboardingReassuranceContinue(timeSpent: Date().timeIntervalSince(startTime))
                }
                onStartQuiz()
            } label: {
                HStack(spacing: 12) {
                    Text("onboarding_v2.reassurance.start_quiz".localized)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.2), in: Circle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.glassPrimary)

            Text("onboarding_v2.reassurance.time_estimate".localized)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: Messages, one after the other

    private func showNext() {
        guard shownCount < messages.count else {
            withAnimation(.easeInOut(duration: 0.3)) { showButton = true }
            return
        }
        isTyping = true
        let text = messages[shownCount]
        // Short: the message lands as a whole, the dots carry the « Milo is writing ».
        let delay = min(1.1, 0.4 + Double(text.count) / 220)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard isTyping else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                isTyping = false
                shownCount += 1
            }
            HapticManager.light()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showNext() }
        }
    }

    private func revealAll() {
        guard shownCount < messages.count else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            isTyping = false
            shownCount = messages.count
            showButton = true
        }
    }
}

private struct ReassuranceTypingDots: View {
    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 7, height: 7)
                        .opacity(0.3 + 0.6 * max(0, sin(time * 4 - Double(index) * 0.7)))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.10), in: Capsule())
        }
    }
}

#Preview {
    ReassuranceView(onStartQuiz: {})
}
