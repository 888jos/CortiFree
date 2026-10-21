//
//  AIQuizMiloChat.swift
//  CortiFree
//
//  « My AI answers for me », after the message was sent to the AI: a Milo conversation, in
//  the look of the Milo chat.
//  1. Milo explains what to do; the user pastes the AI's reply (read here, on the phone).
//     When the AI doesn't know the user enough to pick a plan, Milo suggests the manual quiz.
//  2. Milo asks before sending anything; with the user's OK, the real Milo (DeepSeek, see
//     OnboardingMiloService) writes the report and picks one breathing exercise, and the
//     user can talk to him. Without it, a written report and a default exercise.
//  3. The exercise (one minute) or « later », then straight on to the next onboarding step.
//  CortiFree keeps no conversation; analytics only get counts, never text.
//

import SwiftUI

struct AIQuizMiloChat: View {
    let app: OnboardingAIApp
    let onBack: () -> Void
    let onManual: () -> Void
    let onReply: (AIQuizReply) -> Void

    private enum Message {
        case milo(String)
        case user(String)
    }

    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var returnCenter = AIQuizReturnCenter.shared
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    /// The user left for their AI: how they come back is measured once.
    @State private var leftForAI = false
    @State private var returnedFromLiveActivity = false
    @State private var messages: [Message] = []
    @State private var isTyping = false
    @State private var didStart = false
    @State private var draft = ""
    @FocusState private var composerFocused: Bool

    /// The quiz answers read from the AI's reply.
    @State private var reply: AIQuizReply?
    /// The AI couldn't pick a plan: answer the quiz, or go on with the default one.
    @State private var askingUnknown = false
    /// The user agreed to talk to the real Milo.
    @State private var usesRealMilo = false
    /// « ? » next to Milo: what is sent to his AI, and what CortiFree keeps (nothing).
    @State private var showInfo = false
    /// Turns sent to the real Milo (his replies and what the user typed after the report).
    @State private var history: [(role: String, content: String)] = []
    @State private var recommended: BreathingPattern?
    @State private var runningExercise: BreathingPattern?

    private func t(_ key: String) -> String { key.localized }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.85, isAnimated: false).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                conversation
                composer
            }
        }
        .onAppear {
            guard !didStart else { return }
            didStart = true
            let intro = String(format: t(app.prefillsPrompt ? "onboarding_v2.ai_quiz.milo.intro_prefilled"
                                                            : "onboarding_v2.ai_quiz.milo.intro_paste"), app.name)
            say([intro, String(format: t("onboarding_v2.ai_quiz.milo.step"), app.name)])
        }
        // « I copied it, come back » in the Live Activity: read the clipboard (iOS asks first).
        .onChange(of: returnCenter.pasteRequestedAt) { _, requested in
            guard requested != nil, reply == nil else { return }
            returnedFromLiveActivity = true
            trackReturn("live_activity")
            if let text = UIPasteboard.general.string { send(text) }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background where reply == nil:
                leftForAI = true
                returnedFromLiveActivity = false
            case .active where leftForAI:
                // The Live Activity's link arrives just after: let it count first.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    if !returnedFromLiveActivity { trackReturn("app_switch") }
                }
            default:
                break
            }
        }
        .fullScreenCover(item: $runningExercise) { pattern in
            BreathingDetailFlowView(pattern: pattern, duration: 60, recordsSession: false, onSkip: {
                // Skip: straight on to the next onboarding step, not back to the chat.
                AnalyticsManager.shared.track(event: "onboarding_milo_exercise", properties: ["action": "skipped_during", "exercise": pattern.key])
                runningExercise = nil
                finish()
            }) {
                AnalyticsManager.shared.track(event: "onboarding_milo_exercise", properties: ["action": "completed", "exercise": pattern.key])
                runningExercise = nil
                finish()
            }
        }
    }

    // MARK: Header (the Milo chat's)

    private var header: some View {
        HStack(spacing: 10) {
            // Once the AI's reply is read, there is nothing to go back to.
            if reply == nil {
                Button {
                    HapticManager.light()
                    OnboardingLiveActivityManager.shared.endAIQuizReturn()
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
            Button {
                HapticManager.light()
                AnalyticsManager.shared.track(event: "onboarding_milo_info_opened")
                showInfo = true
            } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .cfGlassCircle(interactive: false)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(t("onboarding_v2.ai_quiz.milo.info_title"))
            .alert(t("onboarding_v2.ai_quiz.milo.info_title"), isPresented: $showInfo) {
                Button(t("common.ok"), role: .cancel) {}
            } message: {
                Text(String(format: t("onboarding_v2.ai_quiz.milo.info_body"), app.name))
            }
        }
        .overlay(alignment: .bottom) {
            Label(t("onboarding_v2.ai_quiz.milo.badge"), systemImage: "lock.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "D4B4FF"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: "D4B4FF").opacity(0.14), in: Capsule())
                .offset(y: 24)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    private func avatar(size: CGFloat) -> some View {
        Image("cortifree_assistant_avatar")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }

    // MARK: Conversation

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                        Group {
                            switch message {
                            case .milo(let text):
                                miloMessage(text, showsAvatar: index == 0 || !isMilo(messages[index - 1]))
                            case .user(let text):
                                userMessage(text)
                            }
                        }
                        .id(index)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    if isTyping {
                        HStack(spacing: 10) {
                            avatar(size: 28)
                            MiloTypingDots()
                        }
                    }
                    if !isTyping {
                        actions
                            .padding(.leading, 38)
                            .transition(.opacity)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 12)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: isTyping) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            // The step's buttons appear after the last message: keep them in view.
            .onChange(of: actionsState) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }
        }
    }

    /// The step's buttons, under Milo's last message.
    @ViewBuilder
    private var actions: some View {
        if askingUnknown {
            HStack(spacing: 10) {
                pill(t("onboarding_v2.ai_quiz.milo.unknown_manual"), icon: "hand.tap", filled: true) {
                    AnalyticsManager.shared.track(event: "onboarding_ai_quiz_unknown", properties: ["ai_app": app.rawValue, "action": "manual"])
                    onManual()
                }
                pill(t("onboarding_v2.ai_quiz.milo.unknown_continue"), filled: false) { continueWithoutPlan() }
            }
        } else if let recommended {
            exerciseCard(recommended)
        }
    }

    /// The same card as Milo's recommendations in the app: illustration, kind, title, start.
    private func exerciseCard(_ pattern: BreathingPattern) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                LibraryImage(name: PlanArtwork.breathingImage(pattern.category))
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(t("assistant.card.kind.breathing").uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(AudioPalette.accent)
                    Text(pattern.localizedTitle)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(verbatim: "1 min · \(pattern.rhythmLabel)")
                        .font(.system(size: 13))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .lineLimit(1)
                        .monospacedDigit()
                }
                Spacer(minLength: 0)
            }

            Button {
                HapticManager.medium()
                AnalyticsManager.shared.track(event: "onboarding_milo_exercise", properties: ["action": "started", "exercise": pattern.key])
                runningExercise = pattern
            } label: {
                Label(t("assistant.card.start"), systemImage: "play.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AudioPalette.backgroundDeep)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(AudioPalette.accent, in: Capsule())
            }
            .buttonStyle(PressableCardStyle())

            Button {
                HapticManager.light()
                AnalyticsManager.shared.track(event: "onboarding_milo_exercise", properties: ["action": "skipped", "exercise": pattern.key])
                finish()
            } label: {
                Text(t("onboarding_v2.ai_quiz.milo.later"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .cfGlass(cornerRadius: 22)
    }

    private func pill(_ title: String, icon: String? = nil, filled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.poppinsSemiBold(14))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(filled ? Color.appTheme : Color.white.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func isMilo(_ message: Message) -> Bool {
        if case .milo = message { return true }
        return false
    }

    private func miloMessage(_ text: String, showsAvatar: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Group {
                if showsAvatar { avatar(size: 28) } else { Color.clear }
            }
            .frame(width: 28, height: 28)
            // Milo's messages sit in a violet bubble, the user's in a grey one.
            Text(text)
                .font(.system(size: 16))
                .lineSpacing(4)
                .foregroundStyle(.white.opacity(0.94))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(hex: "8B5CF6").opacity(0.22), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            Spacer(minLength: 32)
        }
    }

    private func userMessage(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 56)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .lineLimit(4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    // MARK: Composer (the Milo chat's): write or paste, then send

    private var composer: some View {
        VStack(spacing: 10) {
            if reply == nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        shortcut(app == .other ? t("onboarding_v2.ai_quiz.milo.copy_again")
                                               : String(format: t("onboarding_v2.ai_quiz.waiting.reopen"), app.name),
                                 icon: app == .other ? "doc.on.doc" : "arrow.up.forward.app") {
                            let prompt = AIQuizPrompt.text()
                            UIPasteboard.general.string = prompt
                            app.startReturnLiveActivity()
                            if let url = app.url(prompt: prompt) { openURL(url) }
                        }
                        shortcut(t("onboarding_v2.ai_quiz.choice.manual_title"), icon: "hand.tap") {
                            OnboardingLiveActivityManager.shared.endAIQuizReturn()
                            onManual()
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }

            HStack(alignment: .bottom, spacing: 4) {
                // System paste: reads the clipboard without the « Allow Paste » alert, sends it at once.
                PasteButton(payloadType: String.self) { strings in
                    let text = strings.joined(separator: "\n")
                    Task { @MainActor in send(text) }
                }
                .labelStyle(.iconOnly)
                .buttonBorderShape(.circle)
                .tint(Color.appTheme)
                .disabled(!canType)
                .padding(5)

                TextField(t("onboarding_v2.ai_quiz.milo.placeholder"), text: $draft, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .lineLimit(1...5)
                    .focused($composerFocused)
                    .padding(.vertical, 11)

                Button {
                    send(draft)
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(canSend ? Color(hex: "1A1530") : .white.opacity(0.5))
                        .frame(width: 34, height: 34)
                        .background(canSend ? Color(hex: "D4B4FF") : Color.white.opacity(0.12), in: Circle())
                        .animation(.easeOut(duration: 0.15), value: canSend)
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .padding(5)
            }
            .background(Color(hex: "1A1530").opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 12)
    }

    private var canType: Bool { !isTyping && !askingUnknown }

    private var actionsState: String { "\(askingUnknown)-\(recommended?.key ?? "")" }

    private var canSend: Bool {
        canType && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func shortcut(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.10), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Actions

    /// Milo's messages, one after the other, with the typing dots in between.
    private func say(_ texts: [String], then done: (() -> Void)? = nil) {
        guard let first = texts.first else { done?(); return }
        isTyping = true
        let delay = min(1.4, 0.5 + Double(first.count) / 120)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.25)) {
                isTyping = false
                messages.append(.milo(first))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                say(Array(texts.dropFirst()), then: done)
            }
        }
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canType else { return }
        draft = ""
        // Shown shortened, and only in this screen's memory.
        let preview = trimmed.count > 160 ? String(trimmed.prefix(160)) + "…" : trimmed
        withAnimation(.easeOut(duration: 0.25)) { messages.append(.user(preview)) }

        if reply != nil {
            talk(trimmed)
        } else {
            readReply(text, trimmed: trimmed)
        }
    }

    /// Before the report: the AI's reply, read on the phone (never sent anywhere).
    /// A long text without the CORTIFREE block is an AI that didn't play along (it often
    /// says it doesn't know the user): treated like « I can't tell ».
    private func readReply(_ text: String, trimmed: String) {
        guard let parsed = AIQuizPrompt.parse(text) ?? (trimmed.count > 120 ? AIQuizReply(goal: nil, analysis: "") : nil) else {
            // A short message is a question to Milo.
            say([String(format: t("onboarding_v2.ai_quiz.milo.help"), app.name)])
            return
        }
        composerFocused = false
        OnboardingLiveActivityManager.shared.endAIQuizReturn()
        AnalyticsManager.shared.track(event: "onboarding_ai_quiz_pasted", properties: [
            "ai_app": app.rawValue,
            "success": parsed.goal != nil,
            "goal": parsed.goal?.rawValue ?? "unknown",
            "has_block": AIQuizPrompt.parse(text) != nil,
            "has_analysis": !parsed.analysis.isEmpty,
            "length": text.count
        ])
        reply = parsed
        guard let goal = parsed.goal else {
            HapticManager.warning()
            say([String(format: t("onboarding_v2.ai_quiz.milo.unknown"), app.name)]) {
                withAnimation { askingUnknown = true }
            }
            return
        }
        HapticManager.success()
        say([String(format: t("onboarding_v2.ai_quiz.milo.found_plan"), goal.localizedName)]) {
            startReport()
        }
    }

    /// The AI couldn't pick a plan and the user goes on anyway: the default one (stress & anxiety).
    private func continueWithoutPlan() {
        AnalyticsManager.shared.track(event: "onboarding_ai_quiz_unknown", properties: ["ai_app": app.rawValue, "action": "continue"])
        withAnimation {
            askingUnknown = false
            messages.append(.user(t("onboarding_v2.ai_quiz.milo.unknown_continue")))
        }
        say([String(format: t("onboarding_v2.ai_quiz.milo.default_plan"), PlanGoal.stress.localizedName)]) {
            startReport()
        }
    }

    /// The report from the real Milo (what is sent is explained behind « ? »), in short bubbles.
    private func startReport() {
        guard let reply else { return }
        usesRealMilo = true
        isTyping = true
        Task { @MainActor in
            do {
                let answer = try await OnboardingMiloService.report(reply: reply, app: app)
                AnalyticsManager.shared.track(event: "onboarding_milo_report", properties: ["success": true, "exercise": answer.exerciseId ?? "none"])
                history = [(role: "assistant", content: answer.content)]
                isTyping = false
                let pattern = OnboardingMiloService.pattern(answer.exerciseId) ?? OnboardingMiloService.exercises.first
                say(Self.bubbles(answer.content)) {
                    withAnimation { recommended = pattern }
                }
            } catch {
                AnalyticsManager.shared.track(event: "onboarding_milo_report", properties: ["success": false])
                isTyping = false
                usesRealMilo = false
                writtenReport(reply)
            }
        }
    }

    /// Without the real Milo (declined, or unavailable): the AI's analysis and cardiac coherence.
    private func writtenReport(_ reply: AIQuizReply) {
        let pattern = OnboardingMiloService.pattern("coherence") ?? OnboardingMiloService.exercises.first
        var texts = [String]()
        if !reply.analysis.isEmpty {
            texts.append(t("onboarding_v2.ai_quiz.milo.thanks"))
            texts.append(contentsOf: Self.bubbles(reply.analysis))
        }
        if let pattern {
            texts.append(String(format: t("onboarding_v2.ai_quiz.milo.local_pick"), pattern.localizedTitle, pattern.localizedBenefit))
        }
        say(texts) {
            guard let pattern else { finish(); return }
            withAnimation { recommended = pattern }
        }
    }

    /// After the report: what the user types goes to the real Milo (if they agreed).
    private func talk(_ text: String) {
        guard usesRealMilo, let reply else {
            say([t("onboarding_v2.ai_quiz.milo.unavailable")])
            return
        }
        history.append((role: "user", content: text))
        AnalyticsManager.shared.track(event: "onboarding_milo_message_sent", properties: ["count": history.filter { $0.role == "user" }.count])
        isTyping = true
        Task { @MainActor in
            do {
                let answer = try await OnboardingMiloService.chat(reply: reply, app: app, messages: history)
                history.append((role: "assistant", content: answer.content))
                isTyping = false
                say(Self.bubbles(answer.content)) {
                    if let other = OnboardingMiloService.pattern(answer.exerciseId), other != recommended {
                        withAnimation { recommended = other }
                    }
                }
            } catch {
                history.removeLast()
                isTyping = false
                say([t("onboarding_v2.ai_quiz.milo.unavailable")])
            }
        }
    }

    /// A long answer as 2–3 short bubbles (about 4–5 lines each): paragraphs first, then
    /// sentences grouped up to ~240 characters, never more than 3 bubbles.
    static func bubbles(_ text: String, limit: Int = 240, maxBubbles: Int = 3) -> [String] {
        let paragraphs = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var result: [String] = []
        for paragraph in paragraphs {
            guard paragraph.count > limit else { result.append(paragraph); continue }
            var sentences: [String] = []
            paragraph.enumerateSubstrings(in: paragraph.startIndex..., options: .bySentences) { sentence, _, _, _ in
                if let sentence = sentence?.trimmingCharacters(in: .whitespaces), !sentence.isEmpty { sentences.append(sentence) }
            }
            var current = ""
            for sentence in sentences {
                if !current.isEmpty, current.count + sentence.count + 1 > limit {
                    result.append(current)
                    current = sentence
                } else {
                    current = current.isEmpty ? sentence : current + " " + sentence
                }
            }
            if !current.isEmpty { result.append(current) }
        }
        guard result.count > maxBubbles else { return result.isEmpty ? [text] : result }
        // Too many: the extra ones are joined into the last bubble.
        return Array(result.prefix(maxBubbles - 1)) + [result.dropFirst(maxBubbles - 1).joined(separator: " ")]
    }

    private func trackReturn(_ source: String) {
        guard leftForAI else { return }
        leftForAI = false
        AnalyticsManager.shared.track(event: "onboarding_ai_quiz_return", properties: ["ai_app": app.rawValue, "source": source])
    }

    /// After the exercise (or « later »): on to the next onboarding step.
    private func finish() {
        guard let reply else { return }
        HapticManager.medium()
        onReply(reply)
    }
}

private struct MiloTypingDots: View {
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
