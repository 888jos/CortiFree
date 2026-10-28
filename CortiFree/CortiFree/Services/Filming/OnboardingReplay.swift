//
//  OnboardingReplay.swift
//  CortiFree
//
//  Testers and TestFlight builds only (TesterAccess.canForceBPM): « Replay onboarding » in
//  Settings → Filming. UGC creators already went through the onboarding but need to film it:
//  the whole flow plays again over the app, without touching their account.
//  - Local data: the app's UserDefaults are saved before and put back after (also at the next
//    launch if the app was killed mid-way), so answers, first name, checkpoints… come back as they were.
//  - Plan: built and changed in memory only (PersonalPlanStore), the real plan comes back after.
//  - Server and analytics: no Convex write (quiz baseline, profile, plan, completion), no
//    Amplitude event, no checkpoint/recovery sync, no Live Activity.
//  - Flow: no sign-in step for a signed-in account, and it ends after the feature tour: no paywall.
//

import Foundation
import os

@MainActor
final class OnboardingReplay: ObservableObject {
    static let shared = OnboardingReplay()

    @Published private(set) var isActive = false {
        didSet {
            let value = isActive
            Self.state.withLock { $0 = value }
        }
    }

    /// Same value as `isActive`, readable from any thread (analytics).
    nonisolated static var isActiveNow: Bool {
        state.withLock { $0 }
    }

    private nonisolated static let state = OSAllocatedUnfairLock(initialState: false)

    private init() {}

    private static var domainName: String { Bundle.main.bundleIdentifier ?? "" }

    /// The UserDefaults saved at the start, on disk so a killed replay is undone at the next launch.
    private static var snapshotURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("onboarding-replay-defaults.plist")
    }

    func start() {
        guard TesterAccess.shared.canForceBPM, !isActive,
              let domain = UserDefaults.standard.persistentDomain(forName: Self.domainName),
              let data = try? PropertyListSerialization.data(fromPropertyList: domain, format: .binary, options: 0) else { return }
        do {
            try FileManager.default.createDirectory(at: Self.snapshotURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: Self.snapshotURL, options: .atomic)
        } catch {
            // Nothing to restore from: no replay.
            return
        }
        PersonalPlanStore.shared.beginReplay()
        isActive = true
    }

    /// End of the feature tour (or the replay was left): everything back as before.
    func finish() {
        guard isActive else { return }
        Self.restoreDefaults()
        PersonalPlanStore.shared.endReplay()
        isActive = false
    }

    /// At launch: a replay that didn't finish (app killed) leaves its UserDefaults behind.
    static func restoreIfInterrupted() {
        guard FileManager.default.fileExists(atPath: snapshotURL.path) else { return }
        restoreDefaults()
    }

    private static func restoreDefaults() {
        defer { try? FileManager.default.removeItem(at: snapshotURL) }
        guard let data = try? Data(contentsOf: snapshotURL),
              let domain = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { return }
        UserDefaults.standard.setPersistentDomain(domain, forName: domainName)
    }
}
