//
//  OnboardingLiveActivityManager.swift
//  CortiFree
//

import ActivityKit
import Foundation

struct CortiFreeWidgetAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        enum Phase: String, Codable, Hashable {
            case onboardingProgress
            case limitedOffer
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

    private init() {}

    func startForOnboardingDropOff(currentStep: Int, totalSteps: Int, hasSeenPaywall: Bool) {
        guard activitiesAreEnabled else {
            logUnavailable()
            return
        }

        if hasSeenPaywall {
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
                ? "\(percentage)% complete - 1 step left"
                : "\(percentage)% complete - \(remaining) steps left",
            offerEndsAt: nil,
            imageName: "AppLogo",
            deepLinkPath: "onboarding",
            ctaTitle: nil
        )

        upsert(state, staleDate: nil)
    }

    func prepareLiveGiftOffer() {
        let defaults = UserDefaults.standard
        if let currentDeadline = defaults.object(forKey: offerDeadlineKey) as? Date,
           currentDeadline > Date() {
            return
        }
        defaults.set(Date().addingTimeInterval(offerDuration), forKey: offerDeadlineKey)
    }

    func showLiveGiftOffer() {
        guard activitiesAreEnabled else {
            logUnavailable()
            return
        }

        let defaults = UserDefaults.standard
        guard let endDate = defaults.object(forKey: offerDeadlineKey) as? Date else {
            return
        }
        guard endDate > Date() else {
            clearLiveGiftOffer()
            return
        }

        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        let state = CortiFreeWidgetAttributes.ContentState(
            phase: .limitedOffer,
            currentStep: 1,
            totalSteps: 1,
            title: isFrench ? "Un cadeau t'attend" : "A gift is waiting for you",
            subtitle: isFrench
                ? "Ton offre personnalisee expire bientot."
                : "Your personalized offer expires soon.",
            offerEndsAt: endDate,
            imageName: "AppLogo",
            deepLinkPath: SuperwallPlacement.liveGift,
            ctaTitle: isFrench ? "Ouvrir mon cadeau" : "Open my gift"
        )

        upsert(state, staleDate: endDate)
    }

    func clearLiveGiftOffer() {
        UserDefaults.standard.removeObject(forKey: offerDeadlineKey)
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
            return "Starting your plan"
        case 0.35..<0.7:
            return "Building your plan"
        default:
            return "Almost ready"
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
}
