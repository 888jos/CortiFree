//
//  MiloMenuView.swift
//  CortiFree
//
//  Milo's details sheet (top-right button of the chat): conversation actions,
//  history, memory, reply preferences, privacy and « about ».
//

import SwiftUI

/// Pages pushed from the chat's top-right button.
enum MiloRoute: Hashable {
    case menu, history, memory, about
}

/// Static background and flat cards: the chat already draws the animated galaxy,
/// a second one under pushed pages made navigation stutter.
private struct MiloPageBackground: View {
    var body: some View { AudioPalette.backgroundGradient.ignoresSafeArea() }
}

private extension View {
    func miloCard(cornerRadius: CGFloat = 18) -> some View {
        background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    func miloPage(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct MiloMenuView: View {
    let hasConversation: Bool
    let remainingMessages: Int
    let onNewConversation: () -> Void
    let onDeleteCurrent: () -> Void
    /// Pops back to the chat.
    let close: () -> Void

    @ObservedObject private var store = MiloStore.shared
    @AppStorage(MiloConsent.storageKey) private var consentStore = ""
    @State private var confirmDelete = false

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }
    private var uid: String? { UnifiedFirebaseService.shared.auth.currentUserId }

    var body: some View {
        ZStack {
                MiloPageBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        identity
                        conversationSection
                        personalizeSection
                        privacySection
                        if hasConversation {
                            Button(role: .destructive) { confirmDelete = true } label: {
                                row(icon: "trash", title: t("milo.menu.delete"), tint: Color(hex: "FF6B6B"), chevron: false)
                            }
                            .buttonStyle(.plain)
                            .miloCard()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        .miloPage("Milo")
        .alert(t("milo.menu.delete.confirm"), isPresented: $confirmDelete) {
            Button(t("milo.menu.cancel"), role: .cancel) {}
            Button(t("milo.menu.delete.action"), role: .destructive) {
                onDeleteCurrent()
                close()
            }
        } message: {
            Text(t("milo.menu.delete.message"))
        }
    }

    // MARK: Sections

    private var identity: some View {
        HStack(spacing: 14) {
            Image("cortifree_assistant_avatar")
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: "Milo")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(String(format: t("milo.menu.remaining"), remainingMessages))
                    .font(.system(size: 14))
                    .foregroundStyle(AudioPalette.secondaryText)
            }
        }
        .padding(.top, 8)
    }

    private var conversationSection: some View {
        section("milo.menu.section.conversation") {
            Button {
                onNewConversation()
                close()
            } label: {
                row(icon: "square.and.pencil", title: t("milo.menu.new"))
            }
            .buttonStyle(.plain)
            divider
            NavigationLink(value: MiloRoute.history) {
                row(icon: "clock.arrow.circlepath", title: t("milo.menu.history"), value: store.conversations.isEmpty ? nil : "\(store.conversations.count)")
            }
            .buttonStyle(.plain)
            divider
            toggleRow(icon: "lock", title: t("milo.menu.temporary"), note: t("milo.menu.temporary.note"), isOn: $store.isTemporary)
        }
    }

    private var personalizeSection: some View {
        section("milo.menu.section.personalize") {
            NavigationLink(value: MiloRoute.memory) {
                row(icon: "brain.head.profile", title: t("milo.menu.memory"), value: store.memory.isEmpty ? t("milo.menu.memory.empty") : nil)
            }
            .buttonStyle(.plain)
            divider
            VStack(alignment: .leading, spacing: 10) {
                Label(t("milo.menu.length"), systemImage: "text.alignleft")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                Picker(t("milo.menu.length"), selection: $store.replyLength) {
                    ForEach(MiloReplyLength.allCases) { Text(t($0.titleKey)).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            .padding(15)
            divider
            toggleRow(icon: "play.rectangle.on.rectangle", title: t("milo.menu.cards"), note: t("milo.menu.cards.note"), isOn: $store.showsExerciseCards)
        }
    }

    private var privacySection: some View {
        section("milo.menu.section.privacy") {
            if let uid {
                toggleRow(
                    icon: "hand.raised",
                    title: t("milo.menu.consent"),
                    note: t("milo.menu.consent.note"),
                    isOn: Binding(
                        get: { MiloConsent.isGranted(in: consentStore, uid: uid) },
                        set: { consentStore = $0 ? MiloConsent.granting(uid, in: consentStore) : MiloConsent.revoking(uid, in: consentStore) }
                    )
                )
                divider
            }
            NavigationLink(value: MiloRoute.about) {
                row(icon: "info.circle", title: t("milo.menu.about"))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Building blocks

    private func section<Content: View>(_ titleKey: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t(titleKey).uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(AudioPalette.secondaryText)
                .padding(.leading, 4)
            VStack(spacing: 0) { content() }
                .miloCard()
        }
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1).padding(.leading, 50)
    }

    private func row(icon: String, title: String, value: String? = nil, tint: Color = .white, chevron: Bool = true) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(tint == .white ? AudioPalette.accent : tint)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(tint)
            Spacer(minLength: 8)
            if let value {
                Text(value)
                    .font(.system(size: 15))
                    .foregroundStyle(AudioPalette.secondaryText)
                    .lineLimit(1)
            }
            if chevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AudioPalette.secondaryText)
            }
        }
        .padding(15)
        .contentShape(Rectangle())
    }

    private func toggleRow(icon: String, title: String, note: String, isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: isOn) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AudioPalette.accent)
                        .frame(width: 24)
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .tint(AudioPalette.accent)
            Text(note)
                .font(.system(size: 13))
                .foregroundStyle(AudioPalette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 36)
        }
        .padding(15)
    }
}

// MARK: - History

struct MiloHistoryView: View {
    let onOpen: (MiloConversation) -> Void
    @ObservedObject private var store = MiloStore.shared
    @State private var confirmClear = false

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    var body: some View {
        ZStack {
            MiloPageBackground()
            if store.conversations.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 30))
                        .foregroundStyle(AudioPalette.accent)
                    Text(t("milo.history.empty"))
                        .font(.system(size: 15))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
            } else {
                List {
                    ForEach(store.conversations) { conversation in
                        Button { onOpen(conversation) } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(conversation.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                Text(conversation.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 13))
                                    .foregroundStyle(AudioPalette.secondaryText)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    }
                    .onDelete { offsets in
                        offsets.map { store.conversations[$0].id }.forEach(store.delete)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .miloPage(t("milo.menu.history"))
        .toolbar {
            if !store.conversations.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(t("milo.history.clear"), role: .destructive) { confirmClear = true }
                }
            }
        }
        .alert(t("milo.history.clear.confirm"), isPresented: $confirmClear) {
            Button(t("milo.menu.cancel"), role: .cancel) {}
            Button(t("milo.history.clear"), role: .destructive) { store.deleteAllHistory() }
        }
    }
}

// MARK: - Memory

struct MiloMemoryView: View {
    @ObservedObject private var store = MiloStore.shared
    @State private var draft = ""
    @FocusState private var focused: Bool

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    var body: some View {
        ZStack {
            MiloPageBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(t("milo.memory.intro"))
                        .font(.system(size: 15))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    ZStack(alignment: .topLeading) {
                        if draft.isEmpty {
                            Text(t("milo.memory.placeholder"))
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.35))
                                .padding(.horizontal, 17)
                                .padding(.vertical, 20)
                        }
                        TextEditor(text: $draft)
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .scrollContentBackground(.hidden)
                            .focused($focused)
                            .frame(minHeight: 180)
                            .padding(12)
                    }
                    .miloCard()
                    HStack {
                        Text(verbatim: "\(draft.count)/\(MiloStore.memoryLimit)")
                            .font(.system(size: 12))
                            .foregroundStyle(AudioPalette.secondaryText)
                            .monospacedDigit()
                        Spacer()
                        if !store.memory.isEmpty {
                            Button(t("milo.memory.clear"), role: .destructive) {
                                draft = ""
                                store.memory = ""
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "FF6B6B"))
                        }
                    }
                    if let insight = store.insight {
                        insightCard(insight)
                    }
                    Text(t("milo.memory.privacy"))
                        .font(.system(size: 13))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
            }
        }
        .miloPage(t("milo.menu.memory"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(t("milo.memory.save")) {
                    store.memory = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    focused = false
                }
                .fontWeight(.semibold)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines) == store.memory)
            }
        }
        .onAppear { draft = store.memory }
        .onChange(of: draft) { _, value in
            if value.count > MiloStore.memoryLimit { draft = String(value.prefix(MiloStore.memoryLimit)) }
        }
    }
}

// MARK: - About

extension MiloMemoryView {
    /// What Milo learned from an imported document: readable and deletable here.
    fileprivate func insightCard(_ insight: MiloInsight) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(t("milo.memory.insight.title"), systemImage: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AudioPalette.accent)
                Spacer()
                Text(insight.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundStyle(AudioPalette.secondaryText)
            }
            Text(insight.summary)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
            if !insight.themes.isEmpty {
                MiloChipFlow(items: insight.themes)
            }
            Button(t("milo.memory.insight.delete"), role: .destructive) {
                store.insight = nil
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color(hex: "FF6B6B"))
        }
        .padding(16)
        .miloCard()
    }
}

struct MiloAboutView: View {
    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    var body: some View {
        ZStack {
            MiloPageBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Image("cortifree_assistant_avatar")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                    Text(t("milo.about.title"))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(["milo.about.not_medical", "milo.about.data", "milo.about.emergency"], id: \.self) { key in
                        Text(t(key))
                            .font(.system(size: 15))
                            .foregroundStyle(AudioPalette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(20)
            }
        }
        .miloPage(t("milo.menu.about"))
    }
}
