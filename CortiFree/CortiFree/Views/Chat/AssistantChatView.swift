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

    private let dailyLimit = 12

    private let systemPrompt = """
    You are the CortiFree wellness assistant. Respond in concise, formal prose with no markdown, bold text, or bullet lists. Use at most three short sentences. Give practical wellbeing guidance about stress, breathing, meditation, sleep, sounds, focus, energy, habits, journaling, and the CortiFree plan. Recommend only content that exists in CortiFree. Never diagnose cortisol, anxiety, or medical conditions, interpret a face scan as medical evidence, or claim to measure cortisol. For urgent danger, self-harm, chest pain, severe breathing trouble, or other emergencies, tell the user to contact local emergency services. Politely redirect unrelated requests back to wellbeing.
    """

    init() {
        _messages = State(initialValue: Self.openingMessages(for: Date()))
    }

    private static func openingMessages(for date: Date) -> [DeepSeekChatMessage] {
        let hour = Calendar.current.component(.hour, from: date)
        if hour < 12 {
            return [
                DeepSeekChatMessage(role: "assistant", content: "Good morning. How does your body feel after waking up?"),
                DeepSeekChatMessage(role: "assistant", content: "We can keep today gentle and practical."),
                DeepSeekChatMessage(role: "assistant", content: "Would you like a short breathing reset, a plan check-in, or help getting started?")
            ]
        } else if hour < 18 {
            return [
                DeepSeekChatMessage(role: "assistant", content: "Hey. How is your stress level treating you today?"),
                DeepSeekChatMessage(role: "assistant", content: "I can look at your CortiFree plan and suggest a small exercise for right now.")
            ]
        }
        return [
            DeepSeekChatMessage(role: "assistant", content: "Good evening. Is your mind ready to slow down, or still carrying the day?"),
            DeepSeekChatMessage(role: "assistant", content: "I can guide a wind-down, breathing exercise, relaxing sound, or journal check-in."),
            DeepSeekChatMessage(role: "assistant", content: "What would feel most useful tonight?")
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
            .accessibilityLabel("Close Milo")

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

                            if let recommendations = recommendationsByMessage[index] {
                                ForEach(recommendations) { recommendation in
                                    recommendationButton(recommendation)
                                }
                            }
                        }
                        .id(index)
                    }
                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView().tint(.white)
                            Text("Thinking...")
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
                TextField("Write a message...", text: $draft, axis: .vertical)
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
                .accessibilityLabel("Send message")
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
                quickAction("3-minute breathing", message: "Recommend a three-minute breathing exercise from my plan.")
                quickAction("Check my plan", message: "Read my current CortiFree plan and tell me the best next step.")
                quickAction("Wind down", message: "Give me a short evening wind-down using CortiFree.")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
        }
    }

    private func quickAction(_ title: String, message: String) -> some View {
        Button {
            draft = message
        } label: {
            Text(title)
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
            messages.append(DeepSeekChatMessage(role: "assistant", content: "I’m sorry you’re dealing with this. Please contact your local emergency services or a trusted person now. CortiFree cannot provide emergency or medical care."))
            return
        }

        if !isWithinWellbeingScope(text) {
            messages.append(DeepSeekChatMessage(role: "assistant", content: "I’m here for wellbeing support: stress, sleep, breathing, meditation, focus, energy, habits, journaling, and your CortiFree plan. What would you like help with there?"))
            return
        }

        if isPlanCheckRequest(text) {
            let responseIndex = messages.count
            messages.append(DeepSeekChatMessage(role: "assistant", content: planCheckResponse))
            recommendationsByMessage[responseIndex] = planRecommendations
            return
        }

        guard assistantDailyUsage < dailyLimit else {
            messages.append(DeepSeekChatMessage(role: "assistant", content: "I can continue helping later. For now, choose one of the exercises already available in CortiFree."))
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
            return "Your CortiFree plan is ready to personalize. Choose a routine in CortiFree, then I can guide you through its next step."
        }
        let firstStep = routine.steps.first?.localizedInstruction ?? "your first planned exercise"
        return "Your current plan is \(routine.localizedName), lasting \(routine.formattedDuration). It includes \(routine.steps.count) steps for \(routine.impactDomains.joined(separator: ", ")). Your next step is \(firstStep)."
    }

    private var planRecommendations: [AssistantRecommendation] {
        [breathingRecommendation(.coherence), meditationRecommendation("mindfulness"), soundRecommendation("forest")]
    }

    private func isPlanCheckRequest(_ text: String) -> Bool {
        let normalized = text.lowercased()
        return normalized.contains("check my plan") || normalized.contains("current plan") || normalized.contains("mon plan") || normalized.contains("plan actuel")
    }

    private func isWithinWellbeingScope(_ text: String) -> Bool {
        let normalized = text.lowercased()
        let terms = ["stress", "stressed", "anxiety", "anxious", "sleep", "tired", "energy", "focus", "calm", "relax", "breath", "breathe", "meditat", "journal", "habit", "routine", "plan", "cortifree", "cortisol", "mood", "panic", "overwhelm", "wellbeing", "well-being", "exercise", "sound"]
        return terms.contains { normalized.contains($0) }
    }

    private func isEmergency(_ text: String) -> Bool {
        let normalized = text.lowercased()
        let terms = ["suicide", "kill myself", "self harm", "self-harm", "hurt myself", "can't breathe", "cannot breathe", "chest pain", "overdose"]
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
        let normalized = text.lowercased()

        if normalized.contains("sleep") || normalized.contains("sommeil") || normalized.contains("insomnia") || normalized.contains("dormir") {
            return [breathingRecommendation(.fourSevenEight), meditationRecommendation("yoga-nidra"), soundRecommendation("night")]
        }

        if normalized.contains("sound") || normalized.contains("son") || normalized.contains("noise") || normalized.contains("bruit") || normalized.contains("rain") || normalized.contains("pluie") {
            return [soundRecommendation("rain"), soundRecommendation("ocean"), soundRecommendation("fire")]
        }

        if normalized.contains("focus") || normalized.contains("concentr") {
            return [breathingRecommendation(.coherence), meditationRecommendation("focus-clarity"), soundRecommendation("whitenoise")]
        }

        return planRecommendations
    }

    private func breathingRecommendation(_ pattern: BreathingPattern) -> AssistantRecommendation {
        AssistantRecommendation(id: "breathing-\(pattern.name)", title: pattern.displayName, subtitle: "Une respiration guidée adaptée à votre état du moment.", kind: .breathing(pattern))
    }

    private func meditationRecommendation(_ id: String) -> AssistantRecommendation {
        let support = MeditationSupport.support(for: id)
        return AssistantRecommendation(id: "meditation-\(id)", title: support?.localizedTitle ?? id, subtitle: support?.benefit ?? "Une méditation guidée pour retrouver un état plus stable.", kind: .meditation(id))
    }

    private func soundRecommendation(_ id: String) -> AssistantRecommendation {
        let exercise = Exercise.sounds.first(where: { $0.id == id })
        return AssistantRecommendation(id: "sound-\(id)", title: exercise?.title ?? id.capitalized, subtitle: exercise?.description ?? "Un son continu pour créer une ambiance calme.", kind: .sound(id))
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
