//
//  MotivationalMessageViewModel.swift
//  CortiFree
//
//  Created by Claude on 24/11/2025.
//  Generates personalized motivational messages that rotate each app open
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class MotivationalMessageViewModel: ObservableObject {
    @Published var currentMessage: String = ""
    @Published var greeting: String = ""
    @Published var timeBasedTitle: String = ""
    @Published private var firstName: String = ""

    private let db = Firestore.firestore()

    private var lastShownMessageIndex: Int {
        get { UserDefaults.standard.integer(forKey: "lastMotivationalMessageIndex") }
        set { UserDefaults.standard.set(newValue, forKey: "lastMotivationalMessageIndex") }
    }

    init() {
        Task {
            await loadUserFirstName()
            generateMessage()
        }
    }

    // MARK: - User Data Loading

    private func loadUserFirstName() async {
        guard let user = Auth.auth().currentUser else {
            firstName = NSLocalizedString(StringKeys.Common.defaultUserName, comment: "")
            return
        }

        // Get from Firebase Auth displayName (same as ProfileCardView)
        if let displayName = user.displayName, !displayName.isEmpty {
            firstName = displayName.components(separatedBy: " ").first ?? displayName
            print("✅ MotivationalMessageViewModel: Loaded firstName = '\(firstName)' from Firebase Auth")
        } else {
            // Fallback to email username if displayName not available
            if let email = user.email {
                firstName = email.components(separatedBy: "@").first ?? NSLocalizedString(StringKeys.Common.defaultUserName, comment: "")
                print("✅ MotivationalMessageViewModel: Loaded firstName = '\(firstName)' from email")
            } else {
                firstName = NSLocalizedString(StringKeys.Common.defaultUserName, comment: "")
                print("⚠️ MotivationalMessageViewModel: No displayName or email, using default")
            }
        }
    }

    // MARK: - Message Generation

    func generateMessage() {
        timeBasedTitle = generateTimeBasedTitle()
        greeting = generateGreeting()
        currentMessage = getNextMotivationalMessage()
    }

    // Reload user name and regenerate message (call when returning from profile edit)
    func refreshMessage() {
        Task {
            await loadUserFirstName()
            generateMessage()
        }
    }

    private func generateTimeBasedTitle() -> String {
        let name = firstName.isEmpty ? NSLocalizedString(StringKeys.Common.defaultUserName, comment: "") : firstName
        let hour = Calendar.current.component(.hour, from: Date())

        let timeKey: String
        if hour >= 5 && hour < 9 {
            timeKey = "motivational.title.morning"
        } else if hour >= 9 && hour < 18 {
            timeKey = "motivational.title.afternoon"
        } else if hour >= 18 && hour < 22 {
            timeKey = "motivational.title.evening"
        } else {
            timeKey = "motivational.title.night"
        }

        return String(format: NSLocalizedString(timeKey, comment: ""), name)
    }

    private func generateGreeting() -> String {
        // Not used anymore, kept for compatibility
        return ""
    }

    private func getNextMotivationalMessage() -> String {
        // Total number of message variants (30)
        let totalMessages = 30

        // Get a new random index different from last shown
        var newIndex: Int
        repeat {
            newIndex = Int.random(in: 0..<totalMessages)
        } while newIndex == lastShownMessageIndex && totalMessages > 1

        lastShownMessageIndex = newIndex

        // Get the message key
        let messageKey = "motivational.message.\(newIndex)"
        return NSLocalizedString(messageKey, comment: "")
    }
}
