import SwiftUI
import Foundation

struct AssistantChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [DeepSeekChatMessage]
    @State private var draft = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedRecommendation: AssistantRecommendation?
    @State private var recommendationsByMessage: [Int: [AssistantRecommendation]] = [:]
    @AppStorage("assistant.daily.date") private var assistantDailyDate = ""
    @AppStorage("assistant.daily.usage") private var assistantDailyUsage = 0
    @AppStorage("assistant.recommendation.rotation") private var recommendationRotation = 0

    private let dailyLimit = 12

    private let systemPrompt = """
    You are Milo, the CortiFree assistant. Help with wellbeing and general everyday questions; do not reject a safe request just because it is outside wellbeing. When useful, connect general advice to stress, breathing, meditation, sleep, focus, habits, journaling, or the user's CortiFree plan. Recommend only exercises and content that actually exist in CortiFree, and never pretend to see data that was not provided. Be concise, warm, and clear; use at most three short sentences and avoid markdown. For health topics, offer general information, not a diagnosis, treatment decision, or medication dosage; be clear about uncertainty and suggest a qualified professional for personal medical concerns. Never claim a face scan measures cortisol or diagnoses a condition. If the user may be in immediate danger, expresses intent to self-harm, or reports emergency symptoms such as chest pain or severe trouble breathing, respond empathetically and direct them to local emergency services or an appropriate crisis service. Do not provide instructions that facilitate self-harm, violence, or dangerous wrongdoing; offer a safer alternative. Ask a brief clarifying question when needed, and avoid requesting sensitive personal information.
    """

    init() {
        _messages = State(initialValue: Self.openingMessages(for: Date()))
    }

    private static func openingMessages(for date: Date) -> [DeepSeekChatMessage] {
        let hour = Calendar.current.component(.hour, from: date)
        if hour < 12 {
            return [
                DeepSeekChatMessage(role: "assistant", content: LanguageManager.shared.localizedString(for: "assistant.opening.morning.1")),
                DeepSeekChatMessage(role: "assistant", content: LanguageManager.shared.localizedString(for: "assistant.opening.morning.2")),
                DeepSeekChatMessage(role: "assistant", content: LanguageManager.shared.localizedString(for: "assistant.opening.morning.3"))
            ]
        } else if hour < 18 {
            return [
                DeepSeekChatMessage(role: "assistant", content: LanguageManager.shared.localizedString(for: "assistant.opening.afternoon.1")),
                DeepSeekChatMessage(role: "assistant", content: LanguageManager.shared.localizedString(for: "assistant.opening.afternoon.2"))
            ]
        }
        return [
            DeepSeekChatMessage(role: "assistant", content: LanguageManager.shared.localizedString(for: "assistant.opening.evening.1")),
            DeepSeekChatMessage(role: "assistant", content: LanguageManager.shared.localizedString(for: "assistant.opening.evening.2")),
            DeepSeekChatMessage(role: "assistant", content: LanguageManager.shared.localizedString(for: "assistant.opening.evening.3"))
        ]
    }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.85)

            VStack(spacing: 0) {
                header
                messagesView
                quickActions
                composer
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { refreshDailyQuotaIfNeeded() }
        .sheet(item: $selectedRecommendation) { recommendation in
            recommendationDestination(for: recommendation)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
            }
            .accessibilityLabel(LanguageManager.shared.localizedString(for: "assistant.close"))

            Image("cortifree_assistant_avatar")
                .resizable()
                .scaledToFit()
                .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text("Milo")
                    .font(.custom("Poppins-SemiBold", size: 17))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                        VStack(alignment: .leading, spacing: 8) {
                            messageBubble(message)

                            if let recommendation = recommendationsByMessage[index]?.first {
                                recommendationButton(recommendation)
                            }
                        }
                        .id(index)
                    }
                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView().tint(.white)
                            Text(LanguageManager.shared.localizedString(for: "assistant.thinking"))
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, count in
                withAnimation { proxy.scrollTo(count - 1, anchor: .bottom) }
            }
        }
    }

    private func messageBubble(_ message: DeepSeekChatMessage) -> some View {
        HStack {
            if message.role == "user" { Spacer(minLength: 42) }
            Text(message.content)
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundStyle(.white)
                .textSelection(.enabled)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(
                    message.role == "user" ? Color.appTheme.opacity(0.88) : Color.white.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
            if message.role != "user" { Spacer(minLength: 42) }
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                TextField(LanguageManager.shared.localizedString(for: "assistant.composer.placeholder"), text: $draft, axis: .vertical)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundStyle(.white)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.appTheme, in: Circle())
                }
                .disabled(isLoading || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(isLoading || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                .accessibilityLabel(LanguageManager.shared.localizedString(for: "assistant.send"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial)
    }

    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                quickAction("assistant.quick.breathing.title", message: "assistant.quick.breathing.message")
                quickAction("assistant.quick.sleep.title", message: "assistant.quick.sleep.message")
                quickAction("assistant.quick.focus.title", message: "assistant.quick.focus.message")
                quickAction("assistant.quick.journal.title", message: "assistant.quick.journal.message")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
        }
    }

    private func quickAction(_ titleKey: String, message messageKey: String) -> some View {
        Button {
            draft = LanguageManager.shared.localizedString(for: messageKey)
        } label: {
            Text(LanguageManager.shared.localizedString(for: titleKey))
                .font(.custom("Poppins-Medium", size: 12))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        refreshDailyQuotaIfNeeded()

        draft = ""
        errorMessage = nil
        messages.append(DeepSeekChatMessage(role: "user", content: text))

        if isEmergency(text) {
            messages.append(DeepSeekChatMessage(role: "assistant", content: LanguageManager.shared.localizedString(for: "assistant.emergency")))
            return
        }

        if isPlanCheckRequest(text) {
            let responseIndex = messages.count
            messages.append(DeepSeekChatMessage(role: "assistant", content: planCheckResponse))
            recommendationsByMessage[responseIndex] = recommendations(for: text)
            return
        }

        guard assistantDailyUsage < dailyLimit else {
            messages.append(DeepSeekChatMessage(role: "assistant", content: LanguageManager.shared.localizedString(for: "assistant.quota.reached")))
            return
        }

        assistantDailyUsage += 1

        isLoading = true

        Task {
            do {
                let requestMessages = [
                    DeepSeekChatMessage(role: "system", content: systemPrompt),
                    DeepSeekChatMessage(role: "system", content: appContext)
                ] + messages
                let response = try await DeepSeekChatService.shared.reply(to: requestMessages)
                await MainActor.run {
                    let responseIndex = messages.count
                    messages.append(DeepSeekChatMessage(role: "assistant", content: cleanAssistantResponse(response)))
                    let recommendations = recommendations(for: text)
                    if !recommendations.isEmpty {
                        recommendationsByMessage[responseIndex] = recommendations
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private var appContext: String {
        let defaults = UserDefaults.standard
        let routineID = defaults.string(forKey: "selectedRoutineId") ?? ""
        let selectedRoutine = Routine.routine(for: routineID)
        let routine = selectedRoutine?.localizedName ?? defaults.string(forKey: "selectedRoutineTitle") ?? "No routine selected"
        let goal = defaults.string(forKey: "selected_goal") ?? defaults.string(forKey: "selectedGoal") ?? "No goal recorded"
        let steps = selectedRoutine?.steps.map { step in
            let reference = step.referenceId.map { " [\($0)]" } ?? ""
            return "\(step.type.rawValue)\(reference), \(max(1, step.duration / 60)) min"
        }.joined(separator: "; ") ?? "No routine steps recorded"
        return "Current local CortiFree plan: routine=\(routine); routine_id=\(routineID.isEmpty ? "none" : routineID); goal=\(goal); week=\(max(1, UserPersistence.currentWeek)); day=\(max(1, UserPersistence.currentDay)); steps=\(steps). This is the user's actual in-app plan context. Use it when answering plan questions. Never say the plan details are unavailable when this context is present. Do not invent progress."
    }

    private var selectedRoutine: Routine? {
        guard let id = UserDefaults.standard.string(forKey: "selectedRoutineId") else { return nil }
        return Routine.routine(for: id)
    }

    private var planCheckResponse: String {
        guard let routine = selectedRoutine else {
            return LanguageManager.shared.localizedString(for: "assistant.plan.unavailable")
        }
        let firstStep = routine.steps.first?.localizedInstruction ?? "your first planned exercise"
        return String(format: LanguageManager.shared.localizedString(for: "assistant.plan.summary"), routine.localizedName, routine.formattedDuration, routine.steps.count, routine.impactDomains.joined(separator: ", "), firstStep)
    }

    private func isPlanCheckRequest(_ text: String) -> Bool {
        let normalized = text.lowercased()
        return normalized.contains("check my plan") || normalized.contains("current plan") || normalized.contains("mon plan") || normalized.contains("plan actuel")
    }

    private func isEmergency(_ text: String) -> Bool {
        let normalized = text.lowercased()
        let terms = [
            "suicide", "suicid", "kill myself", "end my life", "self harm", "self-harm", "hurt myself", "can't breathe", "cannot breathe", "chest pain", "overdose",
            "me tuer", "mettre fin à mes jours", "me faire du mal", "me blesser", "douleur thoracique", "douleur à la poitrine", "j'arrive pas à respirer", "difficulté à respirer", "surdose",
            "matarme", "quitarme la vida", "hacerme daño", "hacerme dano", "dolor en el pecho", "no puedo respirar", "sobredosis",
            "umbringen", "mir etwas antun", "selbstmord", "brustschmerzen", "ich kann nicht atmen", "atemnot", "überdosis", "ueberdosis"
        ]
        return terms.contains { normalized.contains($0) }
    }

    private func refreshDailyQuotaIfNeeded() {
        let today = Self.dateKeyFormatter.string(from: Date())
        guard assistantDailyDate != today else { return }
        assistantDailyDate = today
        assistantDailyUsage = 0
    }

    private func cleanAssistantResponse(_ response: String) -> String {
        let lines = response
            .replacingOccurrences(of: "**", with: "")
            .components(separatedBy: .newlines)
            .map { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                    return String(trimmed.dropFirst(2))
                }
                return trimmed
            }
            .filter { !$0.isEmpty }
        return String(lines.joined(separator: " ").prefix(520))
    }

    private func recommendations(for text: String) -> [AssistantRecommendation] {
        [nextRecommendation(for: text)]
    }

    private func nextRecommendation(for text: String) -> AssistantRecommendation {
        let normalized = text.lowercased()
        let breathing = BreathingPattern.allPatterns
        let meditations = Exercise.meditations
        let sounds = Exercise.sounds
        let index = recommendationRotation
        if containsAny(normalized, ["sound", "son", "music", "musique", "noise", "bruit"]), let item = sounds[safe: index % max(1, sounds.count)] {
            recommendationRotation += 1
            return soundRecommendation(item.id)
        }
        if containsAny(normalized, ["meditat", "mindful", "pleine conscience", "journal", "focus", "concentr", "concentration"]), let item = meditations[safe: index % max(1, meditations.count)] {
            recommendationRotation += 1
            return meditationRecommendation(item.id)
        }
        let sleepRequest = containsAny(normalized, ["sleep", "dormir", "sommeil"])
        let breathingIndex = sleepRequest ? (breathing.firstIndex(where: { $0.name.lowercased().contains("slow") }) ?? index % max(1, breathing.count)) : index % max(1, breathing.count)
        if let item = breathing[safe: breathingIndex] {
            recommendationRotation += 1
            return breathingRecommendation(item)
        }
        if let item = meditations[safe: index % max(1, meditations.count)] { return meditationRecommendation(item.id) }
        if let item = sounds[safe: index % max(1, sounds.count)] { return soundRecommendation(item.id) }
        return breathingRecommendation(breathing[0])
    }

    private func containsAny(_ text: String, _ terms: [String]) -> Bool {
        terms.contains { text.contains($0) }
    }

    private func breathingRecommendation(_ pattern: BreathingPattern) -> AssistantRecommendation {
        AssistantRecommendation(id: "breathing-\(pattern.name)", title: pattern.displayName, subtitle: LanguageManager.shared.localizedString(for: "assistant.recommendation.breathing"), kind: .breathing(pattern))
    }

    private func meditationRecommendation(_ id: String) -> AssistantRecommendation {
        let support = MeditationSupport.support(for: id)
        return AssistantRecommendation(id: "meditation-\(id)", title: support?.localizedTitle ?? id, subtitle: support?.benefit ?? LanguageManager.shared.localizedString(for: "assistant.recommendation.meditation"), kind: .meditation(id))
    }

    private func soundRecommendation(_ id: String) -> AssistantRecommendation {
        let exercise = Exercise.sounds.first(where: { $0.id == id })
        return AssistantRecommendation(id: "sound-\(id)", title: exercise?.title ?? id.capitalized, subtitle: exercise?.description ?? LanguageManager.shared.localizedString(for: "assistant.recommendation.sound"), kind: .sound(id))
    }

    private func recommendationButton(_ recommendation: AssistantRecommendation) -> some View {
        Button {
            if case .sound(let id) = recommendation.kind,
               let exercise = Exercise.sounds.first(where: { $0.id == id }) {
                SoundPlayer.shared.play(exercise: exercise)
            } else {
                selectedRecommendation = recommendation
            }
        } label: {
            HStack(spacing: 12) {
                Image("cortifree_assistant_avatar")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(recommendation.title)
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundStyle(.white)
                    Text(recommendation.subtitle)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(.white.opacity(0.68))
                        .multilineTextAlignment(.leading)
                }

                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(Color.appTheme)
            }
            .padding(12)
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 0)
    }

    @ViewBuilder
    private func recommendationDestination(for recommendation: AssistantRecommendation) -> some View {
        switch recommendation.kind {
        case .breathing(let pattern):
            BreathingExerciseDetailView(pattern: pattern)
        case .meditation(let id):
            if let support = MeditationSupport.support(for: id) {
                MeditationSupportView(support: support)
            } else {
                MeditationListView()
            }
        case .sound:
            SoundsListView()
        }
    }

    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct AssistantRecommendation: Identifiable {
    enum Kind {
        case breathing(BreathingPattern)
        case meditation(String)
        case sound(String)
    }

    let id: String
    let title: String
    let subtitle: String
    let kind: Kind
}

#Preview {
    AssistantChatView()
}
