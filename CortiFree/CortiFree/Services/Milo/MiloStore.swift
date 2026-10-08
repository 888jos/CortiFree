//
//  MiloStore.swift
//  CortiFree
//
//  Milo's on-device settings and history, per signed-in account: past
//  conversations, what the user asked Milo to remember, what Milo learned from an
//  imported document, and reply preferences.
//  Everything lives in UserDefaults, so deleting the account wipes it too.
//

import Foundation
import Combine

struct MiloConversation: Codable, Identifiable, Equatable {
    let id: UUID
    var updatedAt: Date
    var messages: [DeepSeekChatMessage]

    /// First thing the user wrote, used as the title in the history.
    var title: String {
        messages.first { $0.role == "user" }?.content ?? ""
    }
}

extension DeepSeekChatMessage: Equatable {
    static func == (lhs: DeepSeekChatMessage, rhs: DeepSeekChatMessage) -> Bool {
        lhs.role == rhs.role && lhs.content == rhs.content
    }
}

enum MiloReplyLength: String, CaseIterable, Identifiable {
    case short, detailed
    var id: String { rawValue }
    var titleKey: String { "milo.menu.length.\(rawValue)" }
}

@MainActor
final class MiloStore: ObservableObject {
    static let shared = MiloStore()

    static let memoryLimit = 600
    private static let historyLimit = 30

    @Published private(set) var conversations: [MiloConversation] = []
    @Published var memory = "" {
        didSet { if memory != oldValue { defaults.set(memory, forKey: key("memory")) } }
    }
    @Published var replyLength: MiloReplyLength {
        didSet { defaults.set(replyLength.rawValue, forKey: "milo.replyLength") }
    }
    @Published var showsExerciseCards: Bool {
        didSet { defaults.set(showsExerciseCards, forKey: "milo.showsCards") }
    }
    /// Summary of the last document the user brought to Milo (chat with another AI, Health PDF…).
    @Published var insight: MiloInsight? {
        didSet {
            guard insight != oldValue else { return }
            if let insight, let data = try? JSONEncoder().encode(insight) {
                defaults.set(data, forKey: key("insight"))
            } else {
                defaults.removeObject(forKey: key("insight"))
            }
        }
    }
    /// Temporary conversations are never written to the history. Reset with each new conversation.
    @Published var isTemporary = false

    private let defaults = UserDefaults.standard
    private var loadedUID: String?

    private init() {
        replyLength = MiloReplyLength(rawValue: defaults.string(forKey: "milo.replyLength") ?? "") ?? .short
        showsExerciseCards = defaults.object(forKey: "milo.showsCards") as? Bool ?? true
    }

    private var uid: String { UnifiedFirebaseService.shared.auth.currentUserId ?? "local" }
    private func key(_ name: String) -> String { "milo.\(name).\(uid)" }

    /// Loads the current account's history and memory (call when Milo opens).
    func reload() {
        guard loadedUID != uid else { return }
        loadedUID = uid
        if let data = defaults.data(forKey: key("history")),
           let decoded = try? JSONDecoder().decode([MiloConversation].self, from: data) {
            conversations = decoded
        } else {
            conversations = []
        }
        memory = defaults.string(forKey: key("memory")) ?? ""
        insight = defaults.data(forKey: key("insight")).flatMap { try? JSONDecoder().decode(MiloInsight.self, from: $0) }
    }

    // MARK: History

    func save(id: UUID, messages: [DeepSeekChatMessage]) {
        guard !isTemporary, messages.contains(where: { $0.role == "user" }) else { return }
        conversations.removeAll { $0.id == id }
        conversations.insert(MiloConversation(id: id, updatedAt: Date(), messages: messages), at: 0)
        if conversations.count > Self.historyLimit { conversations.removeLast(conversations.count - Self.historyLimit) }
        persistHistory()
    }

    func delete(_ id: UUID) {
        conversations.removeAll { $0.id == id }
        persistHistory()
    }

    func deleteAllHistory() {
        conversations = []
        persistHistory()
    }

    private func persistHistory() {
        if let data = try? JSONEncoder().encode(conversations) {
            defaults.set(data, forKey: key("history"))
        }
    }
}
