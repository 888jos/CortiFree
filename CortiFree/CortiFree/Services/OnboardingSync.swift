//
//  OnboardingSync.swift
//  CortiFree
//
//  The two onboarding writes that must reach Convex: the habits-quiz baseline (answered before
//  the account exists) and « onboarding completed ». Each is kept on the device until the server
//  accepted it, and retried after sign-in, at launch and on every return to the app.
//  While « completed » is pending, the server's stale `false` never sends a paying user back
//  through the onboarding (which would also rebuild their plan).
//

import Foundation
import UIKit

@MainActor
enum OnboardingSync {
    private static let baselineKey = "onboardingSync.pendingBaseline.v1"
    private static let completedKey = "onboardingSync.pendingCompleted.v1"
    private static var flushTask: Task<Void, Never>?
    private static var foregroundObserver: NSObjectProtocol?

    /// Called once at launch.
    static func start() {
        guard foregroundObserver == nil else { return }
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in OnboardingSync.flush() }
        }
        flush()
    }

    static func queueBaseline(_ args: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: args) else { return }
        UserDefaults.standard.set(data, forKey: baselineKey)
        flush()
    }

    static func queueCompleted() {
        UserDefaults.standard.set(true, forKey: completedKey)
        flush()
    }

    /// Onboarding state to keep after a sign-in: the server's, unless this device finished the
    /// onboarding and the server hasn't heard about it yet.
    static func resolvedCompleted(server: Bool) -> Bool {
        server || UserDefaults.standard.bool(forKey: completedKey)
    }

    /// Sign-out: what was queued belonged to the signed-out account.
    static func clear() {
        UserDefaults.standard.removeObject(forKey: baselineKey)
        UserDefaults.standard.removeObject(forKey: completedKey)
    }

    static func flush() {
        guard flushTask == nil, Auth.auth().currentUser != nil else { return }
        let defaults = UserDefaults.standard
        let baseline = defaults.data(forKey: baselineKey)
            .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        let completed = defaults.bool(forKey: completedKey)
        guard baseline != nil || completed else { return }

        flushTask = Task {
            defer { flushTask = nil }
            if let baseline {
                do {
                    let _: JSONValue = try await ConvexBackend.shared.call(.mutation, path: "baseline:saveInitial", args: baseline)
                    defaults.removeObject(forKey: baselineKey)
                } catch {
                    #if DEBUG
                    print("⚠️ OnboardingSync: baseline not saved yet: \(error.localizedDescription)")
                    #endif
                }
            }
            if completed {
                do {
                    let _: JSONValue = try await ConvexBackend.shared.call(.mutation, path: "profile:saveOnboarding",
                                                                           args: ["completed": true])
                    defaults.removeObject(forKey: completedKey)
                } catch {
                    #if DEBUG
                    print("⚠️ OnboardingSync: completion not saved yet: \(error.localizedDescription)")
                    #endif
                }
            }
        }
    }
}
