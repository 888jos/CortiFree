import SwiftUI

struct AssistantChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [DeepSeekChatMessage]
    @State private var draft = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let systemPrompt = """
    You are the CortiFree wellness assistant. Be warm, concise, and practical. Your scope is broad everyday wellbeing: stress regulation, breathing, meditation, sleep routines, journaling, focus, energy, habits, and using the user's CortiFree plan. You may recommend exercises from CortiFree such as breathing, meditation, relaxing sounds, journaling, and the anti-stress flow. Never diagnose cortisol, anxiety, or medical conditions, interpret a face scan as medical evidence, or claim to measure cortisol. For urgent danger, self-harm, chest pain, severe breathing trouble, or other emergencies, tell the user to contact local emergency services. Politely redirect unrelated requests back to wellbeing.
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
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
            }
            .accessibilityLabel("Close assistant")

            Image("cortifree_assistant_avatar")
                .resizable()
                .scaledToFit()
                .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text("CortiFree Assistant")
                    .font(.custom("Poppins-SemiBold", size: 17))
                    .foregroundStyle(.white)
                Text("A calmer next step")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundStyle(.white.opacity(0.62))
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
                        messageBubble(message)
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

        isLoading = true

        Task {
            do {
                let requestMessages = [
                    DeepSeekChatMessage(role: "system", content: systemPrompt),
                    DeepSeekChatMessage(role: "system", content: appContext)
                ] + messages
                let response = try await DeepSeekChatService.shared.reply(to: requestMessages)
                await MainActor.run {
                    messages.append(DeepSeekChatMessage(role: "assistant", content: response))
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
        let routine = defaults.string(forKey: "selectedRoutineTitle") ?? "No routine title recorded"
        let goal = defaults.string(forKey: "selected_goal") ?? defaults.string(forKey: "selectedGoal") ?? "No goal recorded"
        return "Current local CortiFree context: routine=\(routine); goal=\(goal). Use this context only to personalize suggestions. Do not invent missing progress or plan details."
    }

    private func isWithinWellbeingScope(_ text: String) -> Bool {
        let normalized = text.lowercased()
        let terms = ["stress", "stressed", "anxiety", "anxious", "sleep", "tired", "energy", "focus", "calm", "relax", "breath", "breathe", "meditat", "journal", "habit", "routine", "plan", "cortifree", "cortisol", "mood", "panic", "overwhelm", "wellbeing", "well-being", "exercise", "sound"]
        return terms.contains { normalized.contains($0) }
    }

    private func isEmergency(_ text: String) -> Bool {
        let normalized = text.lowercased()
        let terms = ["suicide", "kill myself", "self harm", "self-harm", "can't breathe", "cannot breathe", "chest pain", "overdose"]
        return terms.contains { normalized.contains($0) }
    }
}

#Preview {
    AssistantChatView()
}
