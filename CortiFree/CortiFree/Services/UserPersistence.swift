//
//  UserPersistence.swift
//  CortiFree
//
//  Created on 21/01/2026.
//  Centralized UserDefaults access with type-safe keys
//

import Foundation

/// Centralized UserDefaults access to avoid scattered direct calls
/// Usage: UserPersistence.streakDays or UserPersistence.set(.streakDays, value: 5)
final class UserPersistence {

    // MARK: - Keys Enum
    enum Key: String {
        // Onboarding
        case onboardingV2Completed = "onboardingV2Completed"
        case lastOnboardingCheckpoint = "last_onboarding_checkpoint"
        case sawPaywallWithoutAccepting = "saw_paywall_without_accepting"
        case userIsAuthenticated = "user_is_authenticated"

        // User Info
        case userFirstName = "userFirstName"
        case selectedGoals = "selectedGoals"

        // Streaks & Progress
        case streakDays = "streakDays"
        case bestStreak = "bestStreak"
        case currentWeek = "currentWeek"
        case currentDay = "currentDay"

        // Routine
        case selectedRoutineId = "selectedRoutineId"
        case selectedRoutineTitle = "selectedRoutineTitle"
        case routineStartDate = "routineStartDate"
        case programStartDate = "programStartDate"

        // Subscription
        case isSubscribed = "isSubscribed"
        case subscriptionProductID = "subscriptionProductID"
        case firstSubscriptionDate = "first_subscription_date"
        case currentSubscriptionStatus = "current_subscription_status"

        // Language
        case appleLanguages = "AppleLanguages"

        // Settings
        case notificationsEnabled = "notificationsEnabled"
        case hapticFeedbackEnabled = "hapticFeedbackEnabled"
    }

    // MARK: - Private
    private static let defaults = UserDefaults.standard

    // MARK: - Generic Setters

    static func set(_ key: Key, value: Any?) {
        if let value = value {
            defaults.set(value, forKey: key.rawValue)
        } else {
            defaults.removeObject(forKey: key.rawValue)
        }
    }

    static func set(_ key: Key, bool: Bool) {
        defaults.set(bool, forKey: key.rawValue)
    }

    static func set(_ key: Key, int: Int) {
        defaults.set(int, forKey: key.rawValue)
    }

    static func set(_ key: Key, string: String) {
        defaults.set(string, forKey: key.rawValue)
    }

    static func set(_ key: Key, date: Date) {
        defaults.set(date, forKey: key.rawValue)
    }

    static func set(_ key: Key, array: [Any]) {
        defaults.set(array, forKey: key.rawValue)
    }

    // MARK: - Generic Getters

    static func bool(for key: Key) -> Bool {
        defaults.bool(forKey: key.rawValue)
    }

    static func int(for key: Key) -> Int {
        defaults.integer(forKey: key.rawValue)
    }

    static func string(for key: Key) -> String? {
        defaults.string(forKey: key.rawValue)
    }

    static func date(for key: Key) -> Date? {
        defaults.object(forKey: key.rawValue) as? Date
    }

    static func array(for key: Key) -> [Any]? {
        defaults.array(forKey: key.rawValue)
    }

    static func object(for key: Key) -> Any? {
        defaults.object(forKey: key.rawValue)
    }

    static func remove(_ key: Key) {
        defaults.removeObject(forKey: key.rawValue)
    }

    // MARK: - Convenience Properties (commonly used values)

    // Onboarding
    static var hasCompletedOnboarding: Bool {
        get { bool(for: .onboardingV2Completed) }
        set { set(.onboardingV2Completed, bool: newValue) }
    }

    // User
    static var userFirstName: String? {
        get { string(for: .userFirstName) }
        set {
            if let name = newValue {
                set(.userFirstName, string: name)
            } else {
                remove(.userFirstName)
            }
        }
    }

    // Streaks
    static var streakDays: Int {
        get { int(for: .streakDays) }
        set { set(.streakDays, int: newValue) }
    }

    static var bestStreak: Int {
        get { int(for: .bestStreak) }
        set { set(.bestStreak, int: newValue) }
    }

    // Progress
    static var currentWeek: Int {
        get { int(for: .currentWeek) }
        set { set(.currentWeek, int: newValue) }
    }

    static var currentDay: Int {
        get { int(for: .currentDay) }
        set { set(.currentDay, int: newValue) }
    }

    // Routine
    static var routineStartDate: Date? {
        get { date(for: .routineStartDate) }
        set {
            if let date = newValue {
                set(.routineStartDate, date: date)
            } else {
                remove(.routineStartDate)
            }
        }
    }

    static var selectedRoutineId: String? {
        get { string(for: .selectedRoutineId) }
        set {
            if let id = newValue {
                set(.selectedRoutineId, string: id)
            } else {
                remove(.selectedRoutineId)
            }
        }
    }

    static var selectedRoutineTitle: String? {
        get { string(for: .selectedRoutineTitle) }
        set {
            if let title = newValue {
                set(.selectedRoutineTitle, string: title)
            } else {
                remove(.selectedRoutineTitle)
            }
        }
    }

    // Subscription
    static var isSubscribed: Bool {
        get { bool(for: .isSubscribed) }
        set { set(.isSubscribed, bool: newValue) }
    }

    static var firstSubscriptionDate: Date? {
        get { date(for: .firstSubscriptionDate) }
        set {
            if let date = newValue {
                set(.firstSubscriptionDate, date: date)
            } else {
                remove(.firstSubscriptionDate)
            }
        }
    }

    // MARK: - Reset Methods

    /// Reset all streak and progress data
    static func resetProgress() {
        streakDays = 0
        bestStreak = 0
        currentWeek = 1
        currentDay = 1
        routineStartDate = Date()
    }

    /// Reset onboarding state
    static func resetOnboarding() {
        hasCompletedOnboarding = false
        remove(.lastOnboardingCheckpoint)
        remove(.sawPaywallWithoutAccepting)
        remove(.userIsAuthenticated)
    }

    /// Clear all CortiFree related data
    static func clearAll() {
        Key.allCases.forEach { key in
            defaults.removeObject(forKey: key.rawValue)
        }
    }
}

// MARK: - CaseIterable for Key
extension UserPersistence.Key: CaseIterable {}
