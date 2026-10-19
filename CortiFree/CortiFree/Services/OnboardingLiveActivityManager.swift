//
//  OnboardingLiveActivityManager.swift
//  CortiFree
//

import ActivityKit
import UIKit
import UserNotifications
import Foundation

struct CortiFreeWidgetAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        enum Phase: String, Codable, Hashable {
            case onboardingProgress
            case limitedOffer
            /// « Copy the AI's reply and come back » while the user is in ChatGPT & co.
            case aiQuizReturn
        }

        var phase: Phase
        var currentStep: Int
        var totalSteps: Int
        var title: String
        var subtitle: String
        var offerEndsAt: Date?
        var imageName: String
        var deepLinkPath: String
        var ctaTitle: String?
    }

    var name: String
}

@MainActor
final class OnboardingLiveActivityManager {
    static let shared = OnboardingLiveActivityManager()

    private let offerDuration: TimeInterval = 30 * 60
    private let offerDeadlineKey = "live_gift_offer_expires_at"
    private let offerStartKey = "live_gift_offer_starts_at"
    /// After a paywall decline, the gift waits a little: right away it reads as pressure.
    static let giftDelay: TimeInterval = 10 * 60
    private static let giftNotificationID = "live_gift_offer"
    private let aiQuizReturnUntilKey = "live_ai_quiz_return_until"
    private let aiQuizReturnDuration: TimeInterval = 30 * 60

    private init() {}

    func startForOnboardingDropOff(currentStep: Int, totalSteps: Int, hasSeenPaywall: Bool) {
        guard activitiesAreEnabled else {
            logUnavailable()
            return
        }

        // The user is in their AI to copy its reply: that Live Activity stays.
        guard !isAIQuizReturnActive else { return }

        // The gift (armed by a paywall decline, 10 min later) wins over the onboarding progress.
        if hasActiveGiftOffer {
            showLiveGiftOffer()
        } else {
            startOrUpdateProgress(currentStep: currentStep, totalSteps: totalSteps)
        }
    }

    func startOrUpdateProgress(currentStep: Int, totalSteps: Int) {
        guard activitiesAreEnabled else {
            logUnavailable()
            return
        }
        // Never replace a running gift offer, or the « come back » of the AI quiz, by the progress.
        guard !hasActiveGiftOffer, !isAIQuizReturnActive else { return }

        let safeTotal = max(totalSteps, 1)
        let safeStep = min(max(currentStep, 1), safeTotal)
        let remaining = max(safeTotal - safeStep, 0)
        let percentage = progressPercentage(currentStep: safeStep, totalSteps: safeTotal)
        let state = CortiFreeWidgetAttributes.ContentState(
            phase: .onboardingProgress,
            currentStep: safeStep,
            totalSteps: safeTotal,
            title: title(currentStep: safeStep, totalSteps: safeTotal),
            subtitle: remaining == 1
                ? String(format: LanguageManager.shared.localizedString(for: "live_activity.subtitle.one"), percentage)
                : String(format: LanguageManager.shared.localizedString(for: "live_activity.subtitle.other"), percentage, remaining),
            offerEndsAt: nil,
            imageName: "AppLogo",
            deepLinkPath: "onboarding",
            ctaTitle: nil
        )

        upsert(state, staleDate: nil)
    }

    /// Started (its delay passed) and not expired.
    private var hasActiveGiftOffer: Bool {
        let defaults = UserDefaults.standard
        guard let deadline = defaults.object(forKey: offerDeadlineKey) as? Date, deadline > Date() else { return false }
        let start = defaults.object(forKey: offerStartKey) as? Date ?? .distantPast
        return start <= Date()
    }

    // MARK: « My AI answers for me »: copy the reply, come back

    private var isAIQuizReturnActive: Bool {
        (UserDefaults.standard.object(forKey: aiQuizReturnUntilKey) as? Date).map { $0 > Date() } ?? false
    }

    /// Started when the user leaves for their AI (the app must still be in the foreground).
    /// Shows the AI's logo; « I copied it » opens cortifree://ai-quiz/paste.
    func startAIQuizReturn(appName: String, logo: String) {
        guard activitiesAreEnabled else {
            logUnavailable()
            return
        }
        let until = Date().addingTimeInterval(aiQuizReturnDuration)
        UserDefaults.standard.set(until, forKey: aiQuizReturnUntilKey)
        let text = LanguageManager.shared
        let state = CortiFreeWidgetAttributes.ContentState(
            phase: .aiQuizReturn,
            currentStep: 1,
            totalSteps: 1,
            title: String(format: text.localizedString(for: "live_activity.ai_quiz.title"), appName),
            subtitle: text.localizedString(for: "live_activity.ai_quiz.subtitle"),
            offerEndsAt: nil,
            imageName: logo,
            deepLinkPath: "ai-quiz/paste",
            ctaTitle: text.localizedString(for: "live_activity.ai_quiz.cta")
        )
        upsert(state, staleDate: until)
        alertOnceInBackground(state, until: until)
    }

    /// On iPhones without a Dynamic Island the activity is only on the Lock Screen: one banner,
    /// once the user is in their AI, so they know where to come back.
    private func alertOnceInBackground(_ state: CortiFreeWidgetAttributes.ContentState, until: Date) {
        guard #available(iOS 16.2, *) else { return }
        var task: UIBackgroundTaskIdentifier = .invalid
        task = UIApplication.shared.beginBackgroundTask { UIApplication.shared.endBackgroundTask(task) }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if let activity = Activity<CortiFreeWidgetAttributes>.activities.first,
               activity.content.state.phase == .aiQuizReturn {
                let alert = AlertConfiguration(
                    title: LocalizedStringResource(stringLiteral: state.title),
                    body: LocalizedStringResource(stringLiteral: state.subtitle),
                    sound: .default
                )
                await activity.update(ActivityContent(state: state, staleDate: until), alertConfiguration: alert)
            }
            UIApplication.shared.endBackgroundTask(task)
        }
    }

    /// The reply was read, or the user answers by hand / went back.
    func endAIQuizReturn() {
        guard UserDefaults.standard.object(forKey: aiQuizReturnUntilKey) != nil else { return }
        UserDefaults.standard.removeObject(forKey: aiQuizReturnUntilKey)
        guard #available(iOS 16.2, *) else { return }
        Task {
            for activity in Activity<CortiFreeWidgetAttributes>.activities where activity.content.state.phase == .aiQuizReturn {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    /// Arms the gift right away (debug, launch argument).
    func prepareLiveGiftOffer() {
        scheduleLiveGiftOffer(after: 0)
    }

    /// After a Superwall decline: the gift starts `delay` later and lasts 30 min. A local
    /// notification announces it (« Psss, Milo wants to give you a gift! » → the gift paywall);
    /// once started, it is the Live Activity shown when the user leaves the app.
    func scheduleLiveGiftOffer(after delay: TimeInterval = OnboardingLiveActivityManager.giftDelay) {
        let defaults = UserDefaults.standard
        if let deadline = defaults.object(forKey: offerDeadlineKey) as? Date, deadline > Date() { return }
        let start = Date().addingTimeInterval(delay)
        defaults.set(start, forKey: offerStartKey)
        defaults.set(start.addingTimeInterval(offerDuration), forKey: offerDeadlineKey)
        guard delay > 0 else { return }

        let text = LanguageManager.shared
        let content = UNMutableNotificationContent()
        content.title = text.localizedString(for: "inline.onboardingliveactivitymanager.00")
        content.body = text.localizedString(for: "inline.onboardingliveactivitymanager.01")
        content.sound = .default
        content.userInfo = ["deeplink": "cortifree://\(SuperwallPlacement.liveGift)", "campaign": "live_gift"]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: Self.giftNotificationID, content: content, trigger: trigger)
        )
        AnalyticsManager.shared.track(event: "live_gift_scheduled", properties: ["delay_minutes": Int(delay / 60)])
    }

    func showLiveGiftOffer() {
        guard activitiesAreEnabled else {
            logUnavailable()
            return
        }

        let defaults = UserDefaults.standard
        // Not before its delay has passed.
        guard hasActiveGiftOffer, let endDate = defaults.object(forKey: offerDeadlineKey) as? Date else {
            return
        }
        guard endDate > Date() else {
            clearLiveGiftOffer()
            return
        }

        let state = CortiFreeWidgetAttributes.ContentState(
            phase: .limitedOffer,
            currentStep: 1,
            totalSteps: 1,
            title: LanguageManager.shared.localizedString(for: "inline.onboardingliveactivitymanager.00"),
            subtitle: LanguageManager.shared.localizedString(for: "inline.onboardingliveactivitymanager.01"),
            offerEndsAt: endDate,
            imageName: "LiveGift",
            deepLinkPath: SuperwallPlacement.liveGift,
            ctaTitle: LanguageManager.shared.localizedString(for: "inline.onboardingliveactivitymanager.02")
        )

        upsert(state, staleDate: endDate)
    }

    func clearLiveGiftOffer() {
        UserDefaults.standard.removeObject(forKey: offerDeadlineKey)
        UserDefaults.standard.removeObject(forKey: offerStartKey)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.giftNotificationID])
        end()
    }

    func end() {
        guard #available(iOS 16.2, *) else { return }

        Task {
            for activity in Activity<CortiFreeWidgetAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    private var activitiesAreEnabled: Bool {
        guard #available(iOS 16.2, *) else { return false }
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }

    private func upsert(_ state: CortiFreeWidgetAttributes.ContentState, staleDate: Date?) {
        guard #available(iOS 16.2, *) else { return }

        let content = ActivityContent(state: state, staleDate: staleDate)
        if let activity = Activity<CortiFreeWidgetAttributes>.activities.first {
            Task {
                await activity.update(content)
                #if DEBUG
                print("Live Activity updated: \(state.phase.rawValue)")
                #endif
            }
            return
        }

        do {
            _ = try Activity.request(
                attributes: CortiFreeWidgetAttributes(name: "CortiFree"),
                content: content,
                pushType: nil
            )
            #if DEBUG
            print("Live Activity requested: \(state.phase.rawValue)")
            #endif
        } catch {
            #if DEBUG
            print("Live Activity request failed: \(error)")
            #endif
        }
    }

    private func title(currentStep: Int, totalSteps: Int) -> String {
        switch Double(progressPercentage(currentStep: currentStep, totalSteps: totalSteps)) / 100 {
        case 0..<0.35:
            return LanguageManager.shared.localizedString(for: "live_activity.title.starting")
        case 0.35..<0.7:
            return LanguageManager.shared.localizedString(for: "live_activity.title.building")
        default:
            return LanguageManager.shared.localizedString(for: "live_activity.title.almost_ready")
        }
    }

    private func progressPercentage(currentStep: Int, totalSteps: Int) -> Int {
        guard totalSteps > 1 else { return 100 }
        let completedIntervals = max(currentStep - 1, 0)
        return Int((Double(completedIntervals) / Double(totalSteps - 1) * 100).rounded())
    }

    private func logUnavailable() {
        #if DEBUG
        if #available(iOS 16.2, *) {
            print("Live Activity unavailable: areActivitiesEnabled=false")
        } else {
            print("Live Activity unavailable: requires iOS 16.2+")
        }
        #endif
    }
}

enum SuperwallPlacement {
    static let onboarding = "campaign_trigger"
    static let liveGift = "live_gift"
    /// Auto-renew just turned off, access still active (CancelInterceptView).
    static let cancelIntercept = "cancel_intercept"
}
