//
//  TesterAccess.swift
//  CortiFree
//
//  The debug tools (Home debug buttons, Settings debug section, onboarding skip buttons…)
//  are compiled in every build but only shown to testers: always in DEBUG, and in Release
//  only for a build run from Xcode. TestFlight and App Review (both .sandbox), App Store builds
//  (.production), and any failure or unverified receipt, stay locked.
//  Never persisted: resolved again at each launch, false until then.
//

import Foundation
import StoreKit
import os

@MainActor
final class TesterAccess: ObservableObject {
    static let shared = TesterAccess()

    /// Debug tools shown right now: a tester, and not in video mode.
    @Published private(set) var isEnabled: Bool {
        didSet {
            let value = isEnabled
            Self.state.withLock { $0 = value }
        }
    }

    /// This build may show the debug tools (DEBUG or run from Xcode), video mode or not.
    @Published private(set) var isTester: Bool {
        didSet { refresh() }
    }

    /// « Mode vidéo »: hides every debug tool (Home buttons, onboarding skip buttons, Settings debug
    /// section…) so creators can film the app as users see it. Kept across launches.
    @Published var videoMode: Bool = UserDefaults.standard.bool(forKey: TesterAccess.videoModeKey) {
        didSet {
            UserDefaults.standard.set(videoMode, forKey: Self.videoModeKey)
            refresh()
        }
    }

    private static let videoModeKey = "tester.video_mode"

    private func refresh() {
        isEnabled = isTester && !videoMode
    }

    /// Same value as `isEnabled`, readable from any thread (non-view code).
    nonisolated static var isEnabledNow: Bool {
        state.withLock { $0 }
    }

    #if DEBUG
    private nonisolated static let state = OSAllocatedUnfairLock(initialState: true)
    #else
    private nonisolated static let state = OSAllocatedUnfairLock(initialState: false)
    #endif

    private var didResolve = false

    private init() {
        #if DEBUG
        let tester = true
        #else
        let tester = false
        #endif
        let enabled = tester && !UserDefaults.standard.bool(forKey: Self.videoModeKey)
        isTester = tester
        isEnabled = enabled
        Self.state.withLock { $0 = enabled }
    }

    /// Release only: unlocks for TestFlight / Xcode builds. Called once at launch.
    func resolve() async {
        #if !DEBUG
        guard !didResolve else { return }
        didResolve = true
        guard let result = try? await AppTransaction.shared,
              case .verified(let transaction) = result else { return }
        // Not .sandbox: App Review installs builds in the sandbox environment too, and must
        // never see the tester tools (onboarding skip, debug buttons). TestFlight builds stay locked.
        if transaction.environment == .xcode { isTester = true }
        #endif
    }
}
