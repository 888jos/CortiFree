import SwiftUI
import Foundation

/// Milo, the in-app companion: a calm welcome with time-of-day suggestions written as
/// full sentences, plain-text replies, and one exercise card when a reply calls for it.
struct AssistantChatView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var soundPlayer = SoundPlayer.shared
    @ObservedObject private var store = MiloStore.shared
    @ObservedObject private var importCenter = MiloImportCenter.shared
    @ObservedObject private var planStore = PersonalPlanStore.shared
    @State private var conversationID = UUID()
    @State private var menuPath: [MiloRoute] = []
    @State private var appeared = false
    @State private var messages: [DeepSeekChatMessage] = []
    @State private var draft = ""
    @State private var isLoading = false
    /// The request whose reply the screen is waiting for; a reply to an older one only refreshes the quota.
    @State private var activeRequestID: UUID?
    @State private var errorMessage: String?
    @State private var cardsByMessage: [Int: AssistantRecommendation] = [:]
    /// Plan changes Milo proposed, by message, and what the user did with them.
    @State private var planProposals: [Int: PlanAssistantProposal] = [:]
    @State private var planProposalStates: [Int: PlanProposalState] = [:]
    @State private var openedBreathing: BreathingPattern?
    @State private var runningBreathing: BreathingPattern?
    /// Pulse check: the sheet, the last reading and the messages that offer to measure again.
    @State private var showPulse = false
    @State private var lastPulse: MiloPulseReading?
    @State private var pulseMessages: Set<Int> = []
    @State private var awaitingPulseFollowUp = false
    /// Intent of the suggestion the user tapped, so the card matches it in every language.
    @State private var pendingIntent: MiloIntent?
    @AppStorage("assistant.daily.date") private var assistantDailyDate = ""
    @AppStorage("assistant.daily.usage") private var assistantDailyUsage = 0
    @AppStorage("assistant.recommendation.rotation") private var recommendationRotation = 0
    @AppStorage(MiloConsent.storageKey) private var consentStore = ""
    @State private var showConsent = false
    @State private var pendingConsentText: String?
    /// « Bring your story to Milo » sheet, with the document shared from another app if any.
    @State private var importRequest: MiloImportRequest?
    @State private var pendingImportAfterConsent: MiloImportRequest?
    /// « Decode this message » sheet (screenshot or pasted text).
    @State private var decodeRequest: MiloDecodeRequest?
    @State private var pendingDecodeAfterConsent: MiloDecodeRequest?
    @FocusState private var composerFocused: Bool

    private let dailyLimit = 12
    private let moment = MiloMoment.current

    // Milo's system prompts are built on the server (convex/assistant.ts).

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    var body: some View {
        // Details pages are pushed (slide in from the right), not stacked as another sheet.
        NavigationStack(path: $menuPath) {
            chat
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: MiloRoute.self) { route in
                    switch route {
                    case .menu:
                        MiloMenuView(
                            hasConversation: !messages.isEmpty,
                            remainingMessages: max(0, dailyLimit - assistantDailyUsage),
                            onNewConversation: newConversation,
                            onDeleteCurrent: deleteCurrentConversation,
                            close: { menuPath = [] }
                        )
                    case .history:
                        MiloHistoryView { conversation in
                            open(conversation)
                            menuPath = []
                        }
                    case .memory:
                        MiloMemoryView()
                    case .about:
                        MiloAboutView()
                    }
                }
        }
        .tint(AudioPalette.accent)
        .preferredColorScheme(.dark)
        // The keyboard of the composer must not follow the user into the menu / history pages.
        .onChange(of: menuPath) { _, path in
            if !path.isEmpty { composerFocused = false }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
    }

    /// Closes Milo without the slide-down animation (it is presented without one too).
    private func close() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { dismiss() }
    }

    private var chat: some View {
        ZStack {
            // Still sky: animated stars refracted through the glass made the composer flicker.
            GalaxyBackgroundView(intensity: 0.85, isAnimated: false)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                conversation
                composer
            }
        }
        .onAppear {
            refreshDailyQuotaIfNeeded()
            store.reload()
            // Weekly check-in from the Plan tab: Milo opens with the question of the week.
            if let opener = MiloWeeklyCheckIn.shared.consumeOpener() {
                if !messages.isEmpty { newConversation() }
                messages.append(DeepSeekChatMessage(role: "assistant", content: opener))
            }
            consumeSharedDocument()
        }
        .onChange(of: importCenter.pendingDocument) { _, _ in consumeSharedDocument() }
        .onChange(of: importCenter.pendingLink) { _, _ in consumeSharedDocument() }
        .onChange(of: importCenter.pendingDecode) { _, _ in consumeSharedDocument() }
        .sheet(item: $decodeRequest) { request in
            MiloDecodeView(
                initialDocument: request.document,
                isQuotaReached: assistantDailyUsage >= dailyLimit,
                onAnalyzed: syncDailyUsageFromServer,
                onBreathe: startQuickReset,
                onTalk: decodeDiscussed
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: importCenter.pendingError) { _, error in
            guard let error else { return }
            errorMessage = error
            importCenter.pendingError = nil
        }
        .sheet(item: $importRequest) { request in
            MiloImportView(
                initialDocument: request.document,
                initialLink: request.link,
                isQuotaReached: assistantDailyUsage >= dailyLimit,
                onAnalyzed: syncDailyUsageFromServer,
                onFinish: insightKept
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }

        .sheet(item: $openedBreathing) { BreathingExerciseDetailView(pattern: $0) }
        .fullScreenCover(item: $runningBreathing, onDismiss: pulseFollowUp) { pattern in
            BreathingDetailFlowView(pattern: pattern, duration: TimeInterval(pattern.defaultMinutes * 60)) {
                runningBreathing = nil
            }
        }
        .sheet(isPresented: $showPulse) {
            MiloPulseSheet(onResult: handlePulse)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showConsent, onDismiss: {
            pendingConsentText = nil
            // Open the import only once the consent sheet is gone (one sheet at a time).
            let granted = MiloConsent.isGranted(in: consentStore, uid: UnifiedFirebaseService.shared.auth.currentUserId)
            if let request = pendingImportAfterConsent, granted {
                importRequest = request
            } else if let request = pendingDecodeAfterConsent, granted {
                decodeRequest = request
            }
            pendingImportAfterConsent = nil
            pendingDecodeAfterConsent = nil
        }) {
            MiloConsentSheet(
                onAccept: acceptConsent,
                onDecline: { showConsent = false }
            )
            .presentationDetents([.large])
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Button { close() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    // Interactive glass inside a Button eats the first tap: plain glass here.
                    .cfGlassCircle(interactive: false)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(t("assistant.close"))

            Spacer()

            if !messages.isEmpty {
                HStack(spacing: 8) {
                    avatar(size: 28)
                    Text(verbatim: "Milo")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            Spacer()

            Button {
                HapticManager.light()
                composerFocused = false
                menuPath = [.menu]
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .cfGlassCircle(interactive: false)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(t("milo.menu.open"))
        }
        .overlay(alignment: .bottom) {
            if store.isTemporary {
                Label(t("milo.menu.temporary"), systemImage: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AudioPalette.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AudioPalette.accent.opacity(0.14), in: Capsule())
                    .offset(y: 22)
            }
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

    // MARK: - Conversation

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    if messages.isEmpty {
                        welcome
                    }
                    ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                        VStack(alignment: .leading, spacing: 12) {
                            if message.role == "user" {
                                userMessage(message.content)
                            } else {
                                miloMessage(message.content, showsAvatar: index == 0 || messages[index - 1].role == "user")
                            }
                            if let card = cardsByMessage[index] {
                                recommendationCard(card)
                                    .padding(.leading, 38)
                            }
                            if let proposal = planProposals[index] {
                                planProposalCard(proposal, index: index)
                                    .padding(.leading, 38)
                            }
                            if index == pulseMessages.max() {
                                measureAgainButton
                                    .padding(.leading, 38)
                            }
                        }
                        .id(index)
                    }
                    if isLoading {
                        HStack(alignment: .center, spacing: 10) {
                            avatar(size: 28)
                            TypingDots()
                        }
                        .id("typing")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            // Stays still while everything fits on screen.
            .scrollBounceBehavior(.basedOnSize)
            .onChange(of: messages.count) { _, count in
                withAnimation { proxy.scrollTo(count - 1, anchor: .top) }
            }
            .onChange(of: isLoading) { _, loading in
                if loading { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
            }
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
                avatar(size: 64)
                Text(t(moment.greetingKey))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(t("assistant.welcome.subtitle"))
                    .font(.system(size: 16))
                    .foregroundStyle(AudioPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 12)

            VStack(spacing: 10) {
                ForEach(moment.suggestions) { suggestion in
                    suggestionRow(suggestion)
                }
            }

            decodeBanner
            importBanner
        }
        .padding(.bottom, 8)
    }

    private var measureAgainButton: some View {
        Button {
            HapticManager.light()
            showPulse = true
        } label: {
            Label(t("milo.pulse.measure_again"), systemImage: "heart.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "FF6B8A"))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color(hex: "FF6B8A").opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pulse

    /// A reading comes back from the sheet: Milo answers locally (no network needed) with a
    /// breathing exercise chosen for that heart rate, and compares with the previous reading.
    private func handlePulse(_ bpm: Int, _ source: MiloPulseSource) {
        let previous = lastPulse
        lastPulse = MiloPulseReading(bpm: bpm, source: source, date: Date())
        messages.append(DeepSeekChatMessage(role: "user", content: String(format: t("milo.pulse.user.\(source.rawValue)"), bpm)))

        let band = MiloPulseReading.band(for: bpm)
        var reply = String(format: t("milo.pulse.reply.\(band)"), bpm)
        if let previous, Date().timeIntervalSince(previous.date) < 2 * 3600 {
            let change = bpm - previous.bpm
            let comparison = change < 0
                ? String(format: t("milo.pulse.compare.lower"), previous.bpm, bpm, -change)
                : String(format: t("milo.pulse.compare.same"), previous.bpm, bpm)
            reply = comparison + " " + reply
        }
        let index = messages.count
        messages.append(DeepSeekChatMessage(role: "assistant", content: reply))
        cardsByMessage[index] = AssistantRecommendation(kind: .breathing(MiloPulseReading.exercise(for: bpm)))
        pulseMessages.insert(index)
        awaitingPulseFollowUp = true
        store.save(id: conversationID, messages: messages)
    }

    /// After a breathing exercise started from a pulse card: invite to measure again.
    private func pulseFollowUp() {
        guard awaitingPulseFollowUp else { return }
        awaitingPulseFollowUp = false
        let index = messages.count
        messages.append(DeepSeekChatMessage(role: "assistant", content: t("milo.pulse.followup")))
        pulseMessages.insert(index)
        store.save(id: conversationID, messages: messages)
    }

    /// Entry point to « Decode this message ».
    private var decodeBanner: some View {
        Button {
            HapticManager.light()
            openDecode()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AudioPalette.accent)
                    .frame(width: 40, height: 40)
                    .background(AudioPalette.accent.opacity(0.16), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(t("milo.decode.banner.title"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                    Text(t("milo.decode.banner.subtitle"))
                        .font(.system(size: 13))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AudioPalette.secondaryText)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cfGlass(cornerRadius: 20)
        }
        .buttonStyle(PressableCardStyle())
        .disabled(isLoading)
    }

    /// Entry point to « Bring your story to Milo » (chat with another AI, Health PDF…).
    private var importBanner: some View {
        Button {
            HapticManager.light()
            openImport()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: store.insight == nil ? "sparkles" : "checkmark.seal.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AudioPalette.backgroundDeep)
                    .frame(width: 40, height: 40)
                    .background(AudioPalette.accent, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(t(store.insight == nil ? "milo.import.banner.title" : "milo.import.banner.title_known"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                    Text(t("milo.import.banner.subtitle"))
                        .font(.system(size: 13))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AudioPalette.secondaryText)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [AudioPalette.accent.opacity(0.22), AudioPalette.accent.opacity(0.06)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(AudioPalette.accent.opacity(0.4)))
        }
        .buttonStyle(PressableCardStyle())
        .disabled(isLoading)
    }

    private func suggestionRow(_ suggestion: MiloSuggestion) -> some View {
        Button {
            HapticManager.light()
            pendingIntent = suggestion.intent
            draft = t(suggestion.textKey)
            send()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: suggestion.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AudioPalette.accent)
                    .frame(width: 36, height: 36)
                    .background(AudioPalette.accent.opacity(0.14), in: Circle())
                Text(t(suggestion.textKey))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AudioPalette.secondaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cfGlass(cornerRadius: 18)
        }
        .buttonStyle(PressableCardStyle())
        .disabled(isLoading)
    }

    private func miloMessage(_ text: String, showsAvatar: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Group {
                if showsAvatar { avatar(size: 28) } else { Color.clear }
            }
            .frame(width: 28, height: 28)
            Text(text)
                .font(.system(size: 16))
                .lineSpacing(4)
                .foregroundStyle(.white.opacity(0.94))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 3)
        }
    }

    private func userMessage(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 56)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .textSelection(.enabled)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    // MARK: - Composer

    private var composer: some View {
        VStack(spacing: 8) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
            }

            HStack(alignment: .bottom, spacing: 4) {
                Button {
                    HapticManager.light()
                    openImport()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .padding(5)
                .accessibilityLabel(t("milo.import.title"))

                Button {
                    HapticManager.light()
                    showPulse = true
                } label: {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "FF6B8A"))
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .padding(.vertical, 5)
                .accessibilityLabel(t("milo.pulse.banner.title"))

                TextField(t("assistant.composer.placeholder"), text: $draft, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .lineLimit(1...5)
                    .focused($composerFocused)
                    .padding(.vertical, 11)

                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(canSend ? AudioPalette.backgroundDeep : .white.opacity(0.5))
                        .frame(width: 34, height: 34)
                        .background(canSend ? AudioPalette.accent : Color.white.opacity(0.12), in: Circle())
                        .animation(.easeOut(duration: 0.15), value: canSend)
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .padding(5)
                .accessibilityLabel(t("assistant.send"))
            }
            // Steady surface: Liquid Glass re-morphed at every keystroke / line change.
            .background(Color(hex: "1A1530").opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 12)
    }

    private var canSend: Bool {
        !isLoading && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Sending

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let intent = pendingIntent
        pendingIntent = nil
        guard !text.isEmpty, !isLoading else { return }

        refreshDailyQuotaIfNeeded()
        errorMessage = nil

        // Crisis replies stay local: they never need sign-in, consent or the network.
        if isEmergency(text) {
            draft = ""
            messages.append(DeepSeekChatMessage(role: "user", content: text))
            messages.append(DeepSeekChatMessage(role: "assistant", content: t("assistant.emergency")))
            store.save(id: conversationID, messages: messages)
            return
        }

        guard let uid = UnifiedFirebaseService.shared.auth.currentUserId else {
            draft = ""
            messages.append(DeepSeekChatMessage(role: "user", content: text))
            messages.append(DeepSeekChatMessage(role: "assistant", content: t("assistant.signin.required")))
            return
        }

        guard MiloConsent.isGranted(in: consentStore, uid: uid) else {
            pendingConsentText = text
            pendingIntent = intent
            showConsent = true
            return
        }

        draft = ""
        composerFocused = false
        messages.append(DeepSeekChatMessage(role: "user", content: text))

        guard assistantDailyUsage < dailyLimit else {
            messages.append(DeepSeekChatMessage(role: "assistant", content: t("assistant.quota.reached")))
            return
        }

        // Pick the card first so Milo's reply can introduce it instead of naming something else.
        let card = store.showsExerciseCards ? recommendation(for: text, intent: intent) : nil
        let currentID = conversationID
        let requestID = UUID()
        activeRequestID = requestID
        isLoading = true

        Task {
            do {
                let request = MiloRequestKind.chat(
                    context: appContext,
                    replyLength: store.replyLength,
                    hasPlan: planStore.plan != nil,
                    card: card.map { (title: $0.title, kind: $0.kindLabel, meta: $0.meta) }
                )
                let response = try await DeepSeekChatService.shared.reply(request, messages: messages)
                await MainActor.run {
                    syncDailyUsageFromServer()
                    // The user may have started or opened another conversation (and sent there) meanwhile.
                    guard requestID == activeRequestID else { return }
                    activeRequestID = nil
                    guard currentID == conversationID else { isLoading = false; return }
                    let responseIndex = messages.count
                    let (reply, proposal) = PlanAssistantProposal.extract(from: response)
                    messages.append(DeepSeekChatMessage(role: "assistant", content: cleanAssistantResponse(reply)))
                    if let card { cardsByMessage[responseIndex] = card }
                    if let proposal { planProposals[responseIndex] = proposal }
                    store.save(id: conversationID, messages: messages)
                    isLoading = false
                }
            } catch DeepSeekChatError.quotaExceeded {
                await MainActor.run {
                    // Server quota (12/day per account, UTC day): Milo says so instead of an error banner.
                    refreshDailyQuotaIfNeeded()
                    assistantDailyUsage = dailyLimit
                    guard requestID == activeRequestID else { return }
                    activeRequestID = nil
                    guard currentID == conversationID else { isLoading = false; return }
                    messages.append(DeepSeekChatMessage(role: "assistant", content: t("assistant.quota.reached")))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    guard requestID == activeRequestID else { return }
                    activeRequestID = nil
                    guard currentID == conversationID else { isLoading = false; return }
                    // Give the text back so the user can retry without retyping.
                    if messages.last?.role == "user", messages.last?.content == text {
                        messages.removeLast()
                        if draft.isEmpty { draft = text }
                    }
                    errorMessage = (error as? DeepSeekChatError)?.errorDescription
                        ?? t("assistant.error.unavailable")
                    isLoading = false
                }
            }
        }
    }

    private func acceptConsent() {
        guard let uid = UnifiedFirebaseService.shared.auth.currentUserId else {
            showConsent = false
            return
        }
        consentStore = MiloConsent.granting(uid, in: consentStore)
        let text = pendingConsentText
        let intent = pendingIntent
        showConsent = false
        if let text {
            draft = text
            pendingIntent = intent
            send()
        }
    }

    private var appContext: String {
        let time = Date().formatted(date: .omitted, time: .shortened)
        var context = PlanAssistantContext.current() + "\nUser's local time: \(time)."
        if let insight = store.insight {
            context += "\n" + insight.contextLine
        }
        if let lastPulse, lastPulse.date > Date().addingTimeInterval(-2 * 3600) {
            context += "\nHeart rate measured in Milo \(lastPulse.date.formatted(date: .omitted, time: .shortened)): \(lastPulse.bpm) bpm (\(lastPulse.source == .watch ? "Apple Watch" : "phone camera"), wellness estimate, not medical)."
        }
        if let signals = HealthKitService.shared.latestBodySignals {
            context += "\n" + signals.contextLine
        }
        if let face = FaceScanStore.shared.contextLine {
            context += "\n" + face
        }
        if let pulse = PulseCheckRecord.last, pulse.date > Date().addingTimeInterval(-3 * 86_400) {
            context += "\n" + pulse.contextLine
        }
        if !store.memory.isEmpty {
            context += "\nWhat the user asked Milo to remember about them (use it naturally, never quote it back): \(store.memory)"
        }
        return context
    }

    // MARK: - Import

    /// Sign-in and consent come first: the document is sent to the AI provider.
    private func openImport(with document: MiloImportDocument? = nil, link: URL? = nil) {
        let request = MiloImportRequest(document: document, link: link)
        guard let uid = UnifiedFirebaseService.shared.auth.currentUserId else {
            messages.append(DeepSeekChatMessage(role: "assistant", content: t("assistant.signin.required")))
            return
        }
        guard MiloConsent.isGranted(in: consentStore, uid: uid) else {
            pendingImportAfterConsent = request
            showConsent = true
            return
        }
        importRequest = request
    }

    private func consumeSharedDocument() {
        if let document = importCenter.pendingDecode {
            importCenter.pendingDecode = nil
            openDecode(with: document)
        } else if let link = importCenter.pendingLink {
            importCenter.pendingLink = nil
            openImport(link: link)
        } else if let document = importCenter.pendingDocument {
            importCenter.pendingDocument = nil
            openImport(with: document)
        }
    }

    /// Same gates as the import: the message is sent to the AI provider.
    private func openDecode(with document: MiloImportDocument? = nil) {
        let request = MiloDecodeRequest(document: document)
        guard let uid = UnifiedFirebaseService.shared.auth.currentUserId else {
            messages.append(DeepSeekChatMessage(role: "assistant", content: t("assistant.signin.required")))
            return
        }
        guard MiloConsent.isGranted(in: consentStore, uid: uid) else {
            pendingDecodeAfterConsent = request
            showConsent = true
            return
        }
        decodeRequest = request
    }

    /// A short round of physiological sighs once the decode sheet is gone.
    private func startQuickReset() {
        let pattern = BreathingPattern.allPatterns.first { $0.name == "PhysiologicalSigh" } ?? BreathingPattern.allPatterns.first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { runningBreathing = pattern }
    }

    /// Milo continues in the chat with its read of the message, so the user can answer back.
    private func decodeDiscussed(_ result: MiloDecodeResult) {
        if !messages.isEmpty { newConversation() }
        let text = [result.meaning, result.reassurance].filter { !$0.isEmpty }.joined(separator: " ")
        messages.append(DeepSeekChatMessage(role: "assistant", content: text))
    }

    /// Milo opens a new conversation from what it learned, so the user can answer right away.
    private func insightKept(_ insight: MiloInsight) {
        if !messages.isEmpty { newConversation() }
        var text = insight.summary
        if !insight.firstStep.isEmpty { text += " " + insight.firstStep }
        messages.append(DeepSeekChatMessage(role: "assistant", content: text))
        // The card follows the first step Milo suggested, or the main theme, or the time of day.
        guard store.showsExerciseCards else { return }
        let step = insight.firstStep.lowercased()
        let themes = insight.themes.joined(separator: " ").lowercased()
        // A breathing exercise Milo named (« 4-7-8 », « box breathing »…) wins.
        if let named = BreathingPattern.allPatterns.first(where: {
            step.contains($0.name.lowercased()) || step.contains($0.localizedTitle.lowercased())
        }) {
            cardsByMessage[0] = AssistantRecommendation(kind: .breathing(named))
            return
        }
        let fallback = MiloIntent.session(sessionCategory(for: themes) ?? moment.defaultCategory)
        if let card = recommendation(for: step, intent: nil) ?? recommendation(for: step, intent: fallback) {
            cardsByMessage[0] = card
        }
    }

    // MARK: - Conversations

    private func newConversation() {
        conversationID = UUID()
        messages = []
        cardsByMessage = [:]
        planProposals = [:]
        planProposalStates = [:]
        pulseMessages = []
        lastPulse = nil
        awaitingPulseFollowUp = false
        draft = ""
        errorMessage = nil
        isLoading = false
        store.isTemporary = false
    }

    private func open(_ conversation: MiloConversation) {
        conversationID = conversation.id
        messages = conversation.messages
        cardsByMessage = [:]
        planProposals = [:]
        planProposalStates = [:]
        pulseMessages = []
        lastPulse = nil
        awaitingPulseFollowUp = false
        errorMessage = nil
        isLoading = false
        store.isTemporary = false
    }

    private func deleteCurrentConversation() {
        store.delete(conversationID)
        newConversation()
    }

    private func isEmergency(_ text: String) -> Bool {
        let normalized = text.lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
        return Self.emergencyTerms.contains { normalized.contains($0) }
    }

    /// Lowercased phrases (straight apostrophes) for suicidal ideation, self-harm, overdose and acute symptoms.
    private static let emergencyTerms: [String] = [
        // English
        "suicide", "suicid", "kill myself", "killing myself", "end my life", "end it all", "take my own life", "want to die", "wanna die",
        "wish i was dead", "wish i were dead", "better off dead", "don't want to live", "dont want to live", "don't want to be alive",
        "no reason to live", "self harm", "self-harm", "selfharm", "hurt myself", "harm myself", "cut myself", "cutting myself",
        "overdose", "overdosing", "took too many pills", "chest pain", "pain in my chest", "heart attack",
        "can't breathe", "cant breathe", "cannot breathe", "can't catch my breath", "struggling to breathe", "trouble breathing",
        // French
        "me tuer", "me suicider", "suicidaire", "mettre fin à mes jours", "mettre fin a mes jours", "envie d'en finir", "veux en finir", "vais en finir", "veux mourir", "envie de mourir",
        "plus envie de vivre", "pas envie de vivre", "marre de vivre", "je préfère mourir", "me faire du mal", "me blesser", "me scarifier", "me mutiler",
        "automutilation", "surdose", "trop de médicaments", "trop de cachets", "douleur thoracique", "douleur à la poitrine",
        "mal à la poitrine", "crise cardiaque", "j'arrive pas à respirer", "j'arrive plus à respirer", "je n'arrive pas à respirer",
        "je n'arrive plus à respirer", "je ne peux pas respirer", "difficulté à respirer", "du mal à respirer", "j'étouffe",
        // German
        "umbringen", "selbstmord", "suizid", "mir das leben nehmen", "will sterben", "möchte sterben", "nicht mehr leben", "keinen sinn mehr zu leben",
        "mir etwas antun", "mich verletzen", "ritzen", "selbstverletzung", "überdosis", "ueberdosis", "zu viele tabletten",
        "brustschmerzen", "schmerzen in der brust", "herzinfarkt", "schlaganfall", "kann nicht atmen", "kann nicht mehr atmen", "bekomme keine luft",
        "kriege keine luft", "atemnot",
        // Spanish
        "matarme", "suicidarme", "quitarme la vida", "acabar con mi vida", "quiero morir", "quiero morirme", "no quiero vivir", "ganas de morir",
        "no tengo ganas de vivir", "hacerme daño", "hacerme dano", "lastimarme", "cortarme", "autolesión", "autolesion", "sobredosis",
        "demasiadas pastillas", "dolor en el pecho", "dolor de pecho", "infarto", "no puedo respirar", "me cuesta respirar", "me ahogo",
        // Japanese
        "死にたい", "自殺", "消えたい", "生きていたくない", "生きたくない", "命を絶", "自分を傷つけ", "自傷", "リストカット", "リスカ",
        "過剰摂取", "オーバードーズ", "薬を飲みすぎ", "胸が痛", "胸の痛み", "心臓発作", "脳卒中", "息ができない", "呼吸ができない", "息が苦しい", "呼吸が苦しい",
        // Korean
        "죽고 싶", "죽고싶", "자살", "목숨을 끊", "살고 싶지 않", "살고싶지않", "사라지고 싶", "자해", "나를 해치", "손목을 긋",
        "과다복용", "약을 너무 많이", "가슴이 아파", "가슴 통증", "흉통", "심장마비", "뇌졸중", "숨을 못 쉬", "숨을 쉴 수 없", "숨이 안 쉬어", "호흡곤란"
    ]

    /// The local counter only drives the UI; the server enforces the quota and returns what is left.
    private func syncDailyUsageFromServer() {
        refreshDailyQuotaIfNeeded()
        if let remaining = DeepSeekChatService.shared.remainingToday {
            assistantDailyUsage = max(0, dailyLimit - remaining)
        } else {
            assistantDailyUsage += 1
        }
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

    // MARK: - Recommendation

    /// The exercise card for a message: from the tapped suggestion, or from what the user wrote.
    /// Returns nil for small talk, so not every reply ends with an exercise.
    private func recommendation(for text: String, intent: MiloIntent?) -> AssistantRecommendation? {
        let index = recommendationRotation
        let normalized = text.lowercased()
        let resolved: MiloIntent
        if let intent {
            resolved = intent
        } else if containsAny(normalized, ["sound", "son ", "sons", "music", "musique", "noise", "bruit", "geräusch", "sonido", "音", "소리"]) {
            resolved = .sound
        } else if containsAny(normalized, ["breath", "respir", "atem", "呼吸", "호흡"]) {
            resolved = .breathing(slow: moment == .night || containsAny(normalized, ["sleep", "dormir", "sommeil", "schlaf", "睡眠", "잠"]))
        } else if let category = sessionCategory(for: normalized) {
            resolved = .session(category)
        } else {
            return nil
        }
        recommendationRotation += 1

        switch resolved {
        case .sound:
            let sounds = moment == .night ? Exercise.sounds.filter { ["rain", "ocean", "night", "whitenoise"].contains($0.id) } : Exercise.sounds
            guard let sound = sounds[safe: index % max(1, sounds.count)] else { return nil }
            return .init(kind: .sound(sound))
        case .breathing(let slow):
            // Techniques the user rated badly (average < 2) are never proposed first.
            let all = BreathingPattern.allPatterns
            let liked = all.filter { !SessionRatingStore.isDisliked(.breathing, id: $0.key) }
            let patterns = liked.isEmpty ? all : liked
            let pattern = slow
                ? patterns.first { $0.name.lowercased().contains("slow") || $0.category == .sleep }
                : patterns[safe: index % max(1, patterns.count)]
            guard let pattern = pattern ?? patterns.first else { return nil }
            return .init(kind: .breathing(pattern))
        case .session(let category):
            // Badly rated sessions last, then sessions not finished yet first, then the shortest,
            // rotating between replies.
            let sessions = GuidedSessionCatalog.sessions(in: category).sorted { lhs, rhs in
                let ld = SessionRatingStore.isDisliked(.meditation, id: lhs.id), rd = SessionRatingStore.isDisliked(.meditation, id: rhs.id)
                if ld != rd { return !ld }
                let l = GuidedSessionProgressStore.isCompleted(lhs.id), r = GuidedSessionProgressStore.isCompleted(rhs.id)
                return l == r ? lhs.durationMinutes < rhs.durationMinutes : !l
            }
            guard let session = sessions[safe: index % max(1, min(3, sessions.count))] else { return nil }
            return .init(kind: .session(session))
        }
    }

    /// Guided-session category matching the request, or the plan goal for a generic meditation request.
    private func sessionCategory(for text: String) -> AudioSessionCategory? {
        let rules: [([String], AudioSessionCategory)] = [
            (["sleep", "dormir", "sommeil", "insomn", "schlaf", "睡眠", "잠"], .sleep),
            (["focus", "concentr", "fokus", "集中", "집중"], .focus),
            (["anxi", "angoiss", "panic", "panique", "angst", "racing", "tourne en boucle", "不安", "불안"], .anxiety),
            (["morning", "matin", "energy", "énergie", "energie", "fatigue", "tired", "morgen"], .morning),
            (["work", "travail", "boulot", "bureau", "arbeit", "trabajo"], .workBreak),
            (["body", "corps", "tension", "tense", "muscle", "dos", "nuque", "körper", "cuerpo"], .bodyRelax),
            (["sad", "triste", "compassion", "lonely", "seul", "difficile", "traurig"], .selfCompassion),
            (["stress", "estrés", "ストレス", "스트레스"], .stressSOS)
        ]
        if let match = rules.first(where: { containsAny(text, $0.0) }) { return match.1 }
        guard containsAny(text, ["meditat", "médit", "mindful", "pleine conscience", "séance", "session", "exercise", "exercice"]) else { return nil }
        switch PersonalPlanStore.shared.plan?.goal {
        case .sleep: return moment == .night ? .sleep : .stressSOS
        case .energy: return .morning
        case .focus: return .focus
        case .emotional: return .selfCompassion
        default: return moment.defaultCategory
        }
    }

    private func containsAny(_ text: String, _ terms: [String]) -> Bool {
        terms.contains { text.contains($0) }
    }

    // MARK: - Plan change card

    enum PlanProposalState { case applied, declined, failed }

    private func planProposalCard(_ proposal: PlanAssistantProposal, index: Int) -> some View {
        let state = planProposalStates[index]
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: state == .applied ? "checkmark.circle.fill" : "calendar.badge.clock")
                    .font(.system(size: 22))
                    .foregroundStyle(AudioPalette.accent)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 3) {
                    Text(t("milo.plan.card.title").uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(AudioPalette.accent)
                    Text(proposal.summary)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            switch state {
            case .none:
                HStack(spacing: 10) {
                    Button {
                        HapticManager.light()
                        planProposalStates[index] = .declined
                        AnalyticsManager.shared.track(event: "milo_plan_change_declined", properties: ["kind": proposal.kindName])
                    } label: {
                        Text(t("milo.plan.card.decline"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.white.opacity(0.14), in: Capsule())
                    }
                    Button {
                        HapticManager.light()
                        planProposalStates[index] = proposal.apply() ? .applied : .failed
                    } label: {
                        Text(t("milo.plan.card.apply"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AudioPalette.backgroundDeep)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(AudioPalette.accent, in: Capsule())
                    }
                }
                .buttonStyle(PressableCardStyle())
            case .applied:
                HStack {
                    Text(t("plan.edit.updated"))
                        .font(.system(size: 13))
                        .foregroundStyle(AudioPalette.secondaryText)
                    Spacer()
                    // Only the latest edit can be undone: hide the button once the plan moved on.
                    if planStore.undoSnapshot != nil, index == planProposalStates.filter({ $0.value == .applied }).keys.max() {
                        Button(t("plan.edit.undo")) {
                            HapticManager.light()
                            planStore.undoLastEdit()
                            planProposalStates[index] = .declined
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AudioPalette.accent)
                    }
                }
            case .declined:
                Text(t("milo.plan.card.declined"))
                    .font(.system(size: 13))
                    .foregroundStyle(AudioPalette.secondaryText)
            case .failed:
                Text(t("milo.plan.card.failed"))
                    .font(.system(size: 13))
                    .foregroundStyle(AudioPalette.secondaryText)
            }
        }
        .padding(14)
        .cfGlass(cornerRadius: 22)
    }

    // MARK: - Exercise card

    private func recommendationCard(_ card: AssistantRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                cardArtwork(card)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(card.kindLabel.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(AudioPalette.accent)
                    Text(card.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(card.meta)
                        .font(.system(size: 13))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .lineLimit(1)
                        .monospacedDigit()
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if case .breathing(let pattern) = card.kind { openedBreathing = pattern }
            }

            Button {
                HapticManager.light()
                start(card)
            } label: {
                Label(startTitle(card), systemImage: isPlaying(card) ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AudioPalette.backgroundDeep)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(AudioPalette.accent, in: Capsule())
            }
            .buttonStyle(PressableCardStyle())
        }
        .padding(14)
        .cfGlass(cornerRadius: 22)
    }

    @ViewBuilder
    private func cardArtwork(_ card: AssistantRecommendation) -> some View {
        switch card.kind {
        case .session(let session): SessionArtworkView(session: session, cornerRadius: 14, showsSymbol: false)
        case .breathing(let pattern): LibraryImage(name: PlanArtwork.breathingImage(pattern.category))
        case .sound(let sound): LibraryImage(name: sound.soundImageName)
        }
    }

    private func isPlaying(_ card: AssistantRecommendation) -> Bool {
        if case .sound(let sound) = card.kind { return soundPlayer.currentExercise?.id == sound.id && soundPlayer.isPlaying }
        return false
    }

    private func startTitle(_ card: AssistantRecommendation) -> String {
        isPlaying(card) ? t("assistant.card.pause") : t("assistant.card.start")
    }

    private func start(_ card: AssistantRecommendation) {
        switch card.kind {
        case .sound(let sound):
            soundPlayer.play(exercise: sound)
        case .breathing(let pattern):
            runningBreathing = pattern
        case .session(let session):
            // The full player is presented from the root view: close the chat first.
            close()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                GuidedSessionPlayer.shared.play(session, presentFullPlayer: true)
            }
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

// MARK: - Models

private struct MiloDecodeRequest: Identifiable {
    let id = UUID()
    let document: MiloImportDocument?
}

private struct MiloImportRequest: Identifiable {
    let id = UUID()
    let document: MiloImportDocument?
    var link: URL? = nil
}

/// A heart rate measured from Milo, and the exercise it calls for.
struct MiloPulseReading {
    let bpm: Int
    let source: MiloPulseSource
    let date: Date

    /// calm < 70 ≤ normal < 85 ≤ elevated < 100 ≤ high (resting heart rate, wellness ranges).
    static func band(for bpm: Int) -> String {
        switch bpm {
        case ..<70: return "calm"
        case ..<85: return "normal"
        case ..<100: return "elevated"
        default: return "high"
        }
    }

    /// The faster the heart, the more direct the technique: sighs first, then slow paced breathing.
    static func exercise(for bpm: Int) -> BreathingPattern {
        switch bpm {
        case ..<70: return .humming
        case ..<85: return .extendedExhale
        case ..<100: return .coherence
        default: return .physiologicalSigh
        }
    }
}

private struct AssistantRecommendation: Identifiable {
    enum Kind {
        case breathing(BreathingPattern)
        case session(GuidedSession)
        case sound(Exercise)
    }

    let kind: Kind

    var id: String {
        switch kind {
        case .breathing(let pattern): return "breathing-\(pattern.name)"
        case .session(let session): return "session-\(session.id)"
        case .sound(let sound): return "sound-\(sound.id)"
        }
    }

    var title: String {
        switch kind {
        case .breathing(let pattern): return pattern.localizedTitle
        case .session(let session): return session.localizedTitle
        case .sound(let sound): return sound.title
        }
    }

    var kindLabel: String {
        let key: String
        switch kind {
        case .breathing: key = "assistant.card.kind.breathing"
        case .session: key = "assistant.card.kind.meditation"
        case .sound: key = "assistant.card.kind.sound"
        }
        return LanguageManager.shared.localizedString(for: key)
    }

    var meta: String {
        switch kind {
        case .breathing(let pattern): return "\(pattern.defaultMinutes) min · \(pattern.rhythmLabel)"
        case .session(let session): return "\(session.durationMinutes) min · \(session.category.title.localized)"
        case .sound: return LanguageManager.shared.localizedString(for: "library.downloads.sound_loop")
        }
    }
}

/// What a tapped suggestion asks for, independent of the language it is written in.
enum MiloIntent: Equatable {
    case session(AudioSessionCategory)
    case breathing(slow: Bool)
    case sound
}

private struct MiloSuggestion: Identifiable {
    let textKey: String
    let icon: String
    let intent: MiloIntent
    var id: String { textKey }
}

/// Part of the day: drives the greeting and which suggestions make sense right now
/// (no « sleep better » at 2 pm).
private enum MiloMoment: Equatable {
    case morning, day, evening, night

    static var current: MiloMoment {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<11: return .morning
        case 11..<18: return .day
        case 18..<21: return .evening
        default: return .night
        }
    }

    var greetingKey: String {
        switch self {
        case .morning: return "assistant.greeting.morning"
        case .day: return "assistant.greeting.day"
        case .evening: return "assistant.greeting.evening"
        case .night: return "assistant.greeting.night"
        }
    }

    var defaultCategory: AudioSessionCategory {
        switch self {
        case .morning: return .morning
        case .day: return .stressSOS
        case .evening: return .bodyRelax
        case .night: return .sleep
        }
    }

    var suggestions: [MiloSuggestion] {
        switch self {
        case .morning:
            return [
                MiloSuggestion(textKey: "assistant.suggest.start_calm", icon: "sunrise.fill", intent: .session(.morning)),
                MiloSuggestion(textKey: "assistant.suggest.woke_anxious", icon: "cloud.sun.fill", intent: .session(.anxiety)),
                MiloSuggestion(textKey: "assistant.suggest.focus_today", icon: "scope", intent: .session(.focus))
            ]
        case .day:
            return [
                MiloSuggestion(textKey: "assistant.suggest.stressed_now", icon: "wind", intent: .breathing(slow: false)),
                MiloSuggestion(textKey: "assistant.suggest.work_break", icon: "cup.and.saucer.fill", intent: .session(.workBreak)),
                MiloSuggestion(textKey: "assistant.suggest.cant_focus", icon: "scope", intent: .session(.focus)),
                MiloSuggestion(textKey: "assistant.suggest.body_tense", icon: "figure.mind.and.body", intent: .session(.bodyRelax))
            ]
        case .evening:
            return [
                MiloSuggestion(textKey: "assistant.suggest.unwind", icon: "sunset.fill", intent: .session(.bodyRelax)),
                MiloSuggestion(textKey: "assistant.suggest.racing_mind", icon: "tornado", intent: .session(.anxiety)),
                MiloSuggestion(textKey: "assistant.suggest.hard_day", icon: "heart.fill", intent: .session(.selfCompassion))
            ]
        case .night:
            return [
                MiloSuggestion(textKey: "assistant.suggest.sleep_better", icon: "moon.stars.fill", intent: .session(.sleep)),
                MiloSuggestion(textKey: "assistant.suggest.cant_fall_asleep", icon: "bed.double.fill", intent: .breathing(slow: true)),
                MiloSuggestion(textKey: "assistant.suggest.calm_sound", icon: "cloud.rain.fill", intent: .sound)
            ]
        }
    }
}

/// Three softly pulsing dots while Milo writes.
private struct TypingDots: View {
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
        .accessibilityLabel(LanguageManager.shared.localizedString(for: "assistant.thinking"))
    }
}

#Preview {
    AssistantChatView()
}
