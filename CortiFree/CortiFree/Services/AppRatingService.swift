//
//  AppRatingService.swift
//  CortiFree
//
//  Created by Claude on 24/01/2026.
//  Service to request App Store ratings at strategic moments
//

import StoreKit
import SwiftUI

final class AppRatingService {
    static let shared = AppRatingService()

    private init() {}

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let hasRequestedRating = "hasRequestedAppRating"
        static let lastRatingRequestDate = "lastRatingRequestDate"
        static let routineCompletionCount = "routineCompletionCount"
        static let appSessionCount = "appSessionCount"
    }

    // MARK: - Tracking Properties

    private var hasRequestedRating: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasRequestedRating) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasRequestedRating) }
    }

    private var lastRatingRequestDate: Date? {
        get { UserDefaults.standard.object(forKey: Keys.lastRatingRequestDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastRatingRequestDate) }
    }

    private var routineCompletionCount: Int {
        get { UserDefaults.standard.integer(forKey: Keys.routineCompletionCount) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.routineCompletionCount) }
    }

    private var appSessionCount: Int {
        get { UserDefaults.standard.integer(forKey: Keys.appSessionCount) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.appSessionCount) }
    }

    // MARK: - Request Rating

    /// Request App Store rating using Apple's native SKStoreReviewController
    /// Apple limits to 3 requests per year, so we track internally too
    func requestRatingIfAppropriate() {
        // Don't request too frequently (minimum 30 days between requests)
        if let lastDate = lastRatingRequestDate,
           Date().timeIntervalSince(lastDate) < 30 * 24 * 60 * 60 {
            return
        }

        requestRating()
    }

    /// Force request rating (for onboarding where we always want to ask)
    func requestRating() {
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
                self.hasRequestedRating = true
                self.lastRatingRequestDate = Date()
            }
        }
    }

    // MARK: - Trigger Points

    /// Call when user completes a routine
    func trackRoutineCompletion() {
        routineCompletionCount += 1

        // Request rating on 3rd routine completion
        if routineCompletionCount == 3 {
            requestRatingIfAppropriate()
        }
    }

    /// Call when user reaches a 7-day streak
    func trackSevenDayStreak() {
        requestRatingIfAppropriate()
    }

    /// Call when user unlocks an achievement
    func trackAchievementUnlock() {
        requestRatingIfAppropriate()
    }

    /// Call when user reaches day 7 of the program
    func trackProgramDay7() {
        requestRatingIfAppropriate()
    }

    /// Call on app launch to track sessions
    func trackAppSession() {
        appSessionCount += 1

        // Request rating on 3rd session
        if appSessionCount == 3 {
            requestRatingIfAppropriate()
        }
    }
}
