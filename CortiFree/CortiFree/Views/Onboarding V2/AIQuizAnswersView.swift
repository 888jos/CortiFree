//
//  AIQuizAnswersView.swift
//  CortiFree
//
//  Before the 11 habit questions, the user chooses: answer them, or let their own AI
//  (ChatGPT, Claude, Grok, Gemini) pick, from what it already knows about them, which of
//  the five plans fits them best. The AI gets a ready-made message, replies with a fixed
//  block, the user pastes it back in Milo's conversation (AIQuizMiloChat), and the
//  onboarding goes on with that plan (stress & anxiety when the AI couldn't tell).
//

import SwiftUI

// MARK: - Entry (choice → manual quiz or AI answers)

struct HabitsQuizEntryView: View {
    /// Back from the choice screen (to Milo's reassurance).
    var onBack: (() -> Void)? = nil
    let onComplete: (HabitsQuizResult) -> Void

    /// `resumesAIQuiz`: the app was killed while the user was in their AI; back to Milo's
    /// conversation with the same AI (and its reply, if it was already pasted).
    init(onBack: (() -> Void)? = nil, resumesAIQuiz: Bool = false, onComplete: @escaping (HabitsQuizResult) -> Void) {
        self.onBack = onBack
        self.onComplete = onComplete
        if resumesAIQuiz, let app = AIQuizReturnCenter.shared.savedApp {
            _mode = State(initialValue: .waiting(app))
        }
    }

    private enum Mode: Equatable {
        case choice
        case pickApp
        case manual
        case waiting(OnboardingAIApp)
    }

    @ObservedObject private var languageManager = LanguageManager.shared
    @Environment(\.openURL) private var openURL
    @State private var mode: Mode = .choice
    @State private var startedAt = Date()
    /// The white button sits where « Start the quiz » was on the previous screen: a double tap
    /// there would skip the choice, so taps only count once the screen has settled.
    @State private var chooserReady = false

    var body: some View {
        ZStack {
            switch mode {
            case .choice:
                chooser.transition(.opacity)
            case .pickApp:
                appPicker.transition(.opacity.combined(with: .move(edge: .trailing)))
            case .manual:
                HabitsQuizView(onComplete: onComplete, onExit: { mode = .choice }).transition(.opacity)
            case .waiting(let app):
                AIQuizMiloChat(
                    app: app,
                    onBack: {
                        AnalyticsManager.shared.track(event: "onboarding_ai_quiz_cancelled", properties: ["ai_app": app.rawValue])
                        AIQuizReturnCenter.shared.cancelApp()
                        mode = .pickApp
                    },
                    onManual: {
                        AnalyticsManager.shared.track(event: "onboarding_quiz_mode_selected",
                                                      properties: ["mode": "manual", "after_ai_app": app.rawValue])
                        AnalyticsManager.shared.setOnboardingPath("ai_to_manual", aiApp: app.rawValue)
                        AIQuizReturnCenter.shared.end()
                        mode = .manual
                    },
                    onReply: { reply in complete(reply, app: app) }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: mode)
        .onAppear {
            AnalyticsManager.shared.track(event: "onboarding_quiz_mode_viewed")
        }
    }

    // MARK: Choice: the AI (app violet) or the classic quiz (white, at the bottom)

    private var chooser: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    if let onBack {
                        Button {
                            HapticManager.light()
                            onBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.custom("Poppins-Bold", size: 22))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                        }
                    }
                    Spacer()
                    LanguageSelectorButton()
                }
                .padding(.horizontal, 30)
                .frame(height: 20)
                .padding(.top, 12)

                OnboardingMascotDialogueView(message: "onboarding_v2.ai_quiz.choice.message".localized)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .padding(.bottom, 34)

                Spacer(minLength: 24)

                aiButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 14)

                manualButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
            .allowsHitTesting(chooserReady)
        }
        .onAppear {
            chooserReady = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { chooserReady = true }
        }
    }

    private var aiButton: some View {
        Button {
            HapticManager.medium()
            AnalyticsManager.shared.track(event: "onboarding_quiz_mode_selected", properties: ["mode": "ai_picker"])
            mode = .pickApp
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.appTheme)
                    .frame(width: 46, height: 46)
                    .background(Color.white, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("onboarding_v2.ai_quiz.choice.ai_title".localized)
                        .font(.poppinsSemiBold(19))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("onboarding_v2.ai_quiz.choice.ai_subtitle".localized)
                        .font(.poppinsRegular(14))
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(GlossyFill(cornerRadius: 26))
            // « New », top right, half above the card.
            .overlay(alignment: .topTrailing) {
                Text("onboarding_v2.ai_quiz.choice.ai_badge".localized)
                    .font(.poppinsSemiBold(12))
                    .foregroundColor(Color.appTheme)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.white, in: Capsule())
                    .offset(x: -18, y: -12)
            }
        }
        .buttonStyle(.plain)
    }

    private var manualButton: some View {
        Button {
            HapticManager.light()
            AnalyticsManager.shared.track(event: "onboarding_quiz_mode_selected", properties: ["mode": "manual"])
            AnalyticsManager.shared.setOnboardingPath("manual")
            mode = .manual
        } label: {
            VStack(spacing: 2) {
                Text("onboarding_v2.ai_quiz.choice.manual_title".localized)
                    .font(.poppinsSemiBold(17))
                Text("onboarding_v2.ai_quiz.choice.manual_subtitle".localized)
                    .font(.poppinsRegular(12))
                    .opacity(0.65)
            }
            .foregroundColor(Color(hex: "1A1A4E"))
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Color.white, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Pick the AI (shown after tapping the AI button)

    private var appPicker: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Button {
                            HapticManager.light()
                            mode = .choice
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.custom("Poppins-Bold", size: 22))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                        }
                        Spacer()
                        LanguageSelectorButton()
                    }
                    .frame(height: 20)
                    .padding(.top, 12)

                    OnboardingMascotDialogueView(message: "onboarding_v2.ai_quiz.picker.message".localized)
                        .padding(.top, 18)
                        .padding(.bottom, 24)

                    // Two AIs per line, « another AI » full width below.
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            AIAppRow(app: .chatgpt) { ask(.chatgpt) }
                            AIAppRow(app: .claude) { ask(.claude) }
                        }
                        HStack(spacing: 12) {
                            AIAppRow(app: .grok) { ask(.grok) }
                            AIAppRow(app: .gemini) { ask(.gemini) }
                        }
                        AIAppRow(app: .other) { ask(.other) }
                    }

                    howItWorks
                        .padding(.top, 26)

                    Label("onboarding_v2.ai_quiz.choice.privacy".localized, systemImage: "lock.fill")
                        .font(.poppinsRegular(12))
                        .foregroundColor(.white.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 18)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    /// Send → copy → paste back, as three little pictograms.
    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("onboarding_v2.ai_quiz.picker.how".localized)
                .font(.poppinsSemiBold(14))
                .foregroundColor(.white.opacity(0.75))
            HStack(alignment: .top, spacing: 0) {
                howStep("paperplane.fill", "onboarding_v2.ai_quiz.picker.step_send".localized)
                howArrow
                howStep("doc.on.doc.fill", "onboarding_v2.ai_quiz.picker.step_copy".localized)
                howArrow
                howStep("arrow.uturn.backward.circle.fill", "onboarding_v2.ai_quiz.picker.step_paste".localized)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 24)
    }

    private func howStep(_ icon: String, _ text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.08), in: Circle())
            Text(text)
                .font(.poppinsMedium(12))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var howArrow: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white.opacity(0.35))
            .padding(.top, 16)
    }

    /// The message is filled in through the app's `?q=` link when it supports one, and
    /// copied too, so it can be pasted when the link doesn't carry it (Gemini).
    /// Something copied since the last message (the AI's reply, e.g. back after an app kill)
    /// is never overwritten: then only the AIs whose link carries the message open.
    private func ask(_ app: OnboardingAIApp) {
        HapticManager.medium()
        let prompt = AIQuizPrompt.text()
        let keepsClipboard = AIQuizReturnCenter.shared.clipboardChangedSincePrompt
        if !keepsClipboard { AIQuizReturnCenter.shared.copyPrompt(prompt) }
        AnalyticsManager.shared.track(event: "onboarding_quiz_mode_selected", properties: ["mode": "ai", "ai_app": app.rawValue])
        AnalyticsManager.shared.setOnboardingPath("ai", aiApp: app.rawValue)
        startedAt = Date()
        AIQuizReturnCenter.shared.begin(app)
        mode = .waiting(app)
        app.startReturnLiveActivity()
        if !keepsClipboard || app.prefillsPrompt, let url = app.url(prompt: prompt) { openURL(url) }
    }

    /// The AI's plan (stress & anxiety when it couldn't tell) goes straight to the next step.
    private func complete(_ reply: AIQuizReply, app: OnboardingAIApp) {
        let goal = reply.goal ?? .stress
        AIQuizReturnCenter.shared.end()
        AnalyticsManager.shared.track(event: "onboarding_ai_quiz_confirmed", properties: [
            "ai_app": app.rawValue,
            "goal": goal.rawValue,
            "goal_from_ai": reply.goal != nil,
            "time_spent": Date().timeIntervalSince(startedAt)
        ])
        onComplete(HabitsQuizView.finish(answers: HabitsQuizResult.answers(leaningTo: goal),
                                         startedAt: startedAt, aiGoal: goal))
    }
}

// MARK: - One AI, same row style as the onboarding answers

private struct AIAppRow: View {
    let app: OnboardingAIApp
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            HStack(spacing: 12) {
                AIAppLogo(app: app)
                    .frame(width: 24, height: 24)
                Text(app.rowTitle)
                    .font(.poppinsMedium(17))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                // Only « another AI » says how it works: the message is to paste.
                if app == .other {
                    Text("onboarding_v2.ai_quiz.picker.copied".localized)
                        .font(.poppinsRegular(12))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .glassCard(cornerRadius: 31, interactive: true)
        }
        .buttonStyle(.plain)
    }
}

/// The AI's logo, white, no background (assets `ai_logo_<app>`, from LobeHub icons).
struct AIAppLogo: View {
    let app: OnboardingAIApp

    var body: some View {
        if app == .other {
            Image(systemName: "ellipsis.bubble")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
        } else {
            Image(app.logoAsset)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
        }
    }
}

/// App violet with a gloss: light from the top, a thin bright rim and a shine passing by.
private struct GlossyFill: View {
    let cornerRadius: CGFloat
    @State private var shine = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(LinearGradient(colors: [Color(hex: "C6A4FF"), Color.appTheme, Color(hex: "8B5CF6")],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(
                shape.fill(LinearGradient(colors: [.white.opacity(0.38), .white.opacity(0.06), .clear],
                                          startPoint: .top, endPoint: .center))
            )
            .overlay(
                GeometryReader { proxy in
                    LinearGradient(colors: [.clear, .white.opacity(0.35), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: proxy.size.width * 0.35)
                        .rotationEffect(.degrees(18))
                        .offset(x: shine ? proxy.size.width * 1.2 : -proxy.size.width * 0.5)
                }
                .clipShape(shape)
            )
            .overlay(shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0.1)],
                                                       startPoint: .top, endPoint: .bottom), lineWidth: 1.2))
            .shadow(color: Color(hex: "8B5CF6").opacity(0.55), radius: 18, y: 8)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).delay(0.8).repeatForever(autoreverses: false)) { shine = true }
            }
    }
}

// MARK: - AI apps

enum OnboardingAIApp: String, CaseIterable, Identifiable {
    case chatgpt, claude, grok, gemini, other

    var id: String { rawValue }

    var name: String {
        switch self {
        case .chatgpt: return "ChatGPT"
        case .claude: return "Claude"
        case .grok: return "Grok"
        case .gemini: return "Gemini"
        case .other: return "onboarding_v2.ai_quiz.app.other".localized
        }
    }

    /// Label in the AI list.
    var rowTitle: String { self == .other ? "onboarding_v2.ai_quiz.picker.other".localized : name }

    var logoAsset: String { "ai_logo_\(rawValue)" }

    /// The logo in the Live Activity: the asset, or an SF Symbol (« sf: ») for another AI.
    var liveActivityLogo: String { self == .other ? "sf:ellipsis.bubble" : logoAsset }

    /// While the user is in their AI: « copy the reply and come back ».
    @MainActor
    func startReturnLiveActivity() {
        OnboardingLiveActivityManager.shared.startAIQuizReturn(appName: name, logo: liveActivityLogo)
    }

    /// Gemini's links can't carry a message: the user pastes the copied one.
    var prefillsPrompt: Bool { self != .gemini && self != .other }

    /// Universal links: they open the app when it's installed, the website otherwise.
    /// nil for « another AI »: the message is only copied.
    func url(prompt: String) -> URL? {
        let base: String
        switch self {
        case .chatgpt: base = "https://chatgpt.com/"
        case .claude: base = "https://claude.ai/new"
        case .grok: base = "https://grok.com/"
        case .gemini: base = "https://gemini.google.com/app"
        case .other: return nil
        }
        var components = URLComponents(string: base)!
        if prefillsPrompt {
            components.queryItems = [URLQueryItem(name: "q", value: prompt)]
        }
        return components.url ?? URL(string: base)
    }
}

// MARK: - Prompt and reply

struct AIQuizReply: Equatable, Codable {
    /// The plan the AI picked; nil when it said it doesn't know the user well enough
    /// (or replied without the CORTIFREE block).
    var goal: PlanGoal?
    var analysis: String
}

enum AIQuizPrompt {
    /// The five plans, numbered 1…5 in the prompt.
    static let goals = PlanGoal.allCases

    /// Built from the plans themselves, so the prompt always matches them and the language.
    static func text() -> String {
        var lines = ["onboarding_v2.ai_quiz.prompt.intro".localized, ""]
        for (number, goal) in goals.enumerated() {
            lines.append("\(number + 1). \(goal.localizedName): \(goal.localizedPromise)")
        }
        lines.append("")
        lines.append("onboarding_v2.ai_quiz.prompt.format".localized)
        lines.append("```")
        lines.append("CORTIFREE")
        lines.append("PLAN: <n>")
        lines.append("ANALYSIS: ...")
        lines.append("```")
        return lines.joined(separator: "\n")
    }

    /// Reads « PLAN: 2 » (tolerating markdown and other separators) and the text after
    /// « ANALYSIS: ». Only what follows the last « CORTIFREE » line counts, so pasting the
    /// prompt itself, or a reply that repeats it, never reads the template as a plan.
    /// nil without that block: a question to Milo, or an AI that didn't play along.
    static func parse(_ raw: String) -> AIQuizReply? {
        var lines = raw.components(separatedBy: .newlines)
        guard let marker = lines.lastIndex(where: { $0.trimmingCharacters(in: .whitespaces).uppercased().hasSuffix("CORTIFREE") }) else {
            return nil
        }
        lines = Array(lines[(marker + 1)...])

        let planLine = #/^PLAN[\s*_]*[:=–-]?[\s*_]*(\d)/#
        var goal: PlanGoal?
        var analysis: [String] = []
        var inAnalysis = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") { if inAnalysis { break } else { continue } }

            let bare = trimmed.drop(while: { "*_#> -".contains($0) })
            if bare.uppercased().hasPrefix("ANALYSIS") {
                inAnalysis = true
                let rest = bare.dropFirst("ANALYSIS".count).drop(while: { ":*_ ".contains($0) })
                if !rest.isEmpty { analysis.append(String(rest)) }
                continue
            }
            if inAnalysis {
                if !trimmed.isEmpty { analysis.append(trimmed) }
                continue
            }
            if let match = String(bare).uppercased().firstMatch(of: planLine),
               let number = Int(match.1), goals.indices.contains(number - 1) {
                goal = goals[number - 1]
            }
        }

        let text = analysis.joined(separator: " ")
            .replacingOccurrences(of: "**", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return AIQuizReply(goal: goal, analysis: String(text.prefix(700)))
    }
}

#Preview {
    HabitsQuizEntryView { _ in }
}
