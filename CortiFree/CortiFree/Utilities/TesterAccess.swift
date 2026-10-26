//
//  TesterAccess.swift
//  CortiFree
//
//  The debug tools (Home debug buttons, Settings debug section, onboarding skip buttons…)
//  are compiled in every build but only shown to testers: always in DEBUG, and in Release
//  only for a build run from Xcode. TestFlight and App Review (both .sandbox), App Store builds
//  (.production), and any failure or unverified receipt, stay locked.
//  One exception, the filming aid for UGC creators (forced BPM, `canForceBPM`): also unlocked in
//  TestFlight (.sandbox), App Review included (accepted: hidden behind the Version taps, no debug tool).
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

    /// This build may force the BPM of pulse checks (testers and TestFlight), video mode or not.
    @Published private(set) var canForceBPM: Bool {
        didSet {
            let value = canForceBPM
            Self.forceBPMState.withLock { $0 = value }
        }
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

    /// Same value as `canForceBPM`, readable from any thread. Ignores video mode: the forced BPM
    /// must keep working while video mode hides the debug tools.
    nonisolated static var canForceBPMNow: Bool {
        forceBPMState.withLock { $0 }
    }

    #if DEBUG
    private nonisolated static let state = OSAllocatedUnfairLock(initialState: true)
    private nonisolated static let forceBPMState = OSAllocatedUnfairLock(initialState: true)
    #else
    private nonisolated static let state = OSAllocatedUnfairLock(initialState: false)
    private nonisolated static let forceBPMState = OSAllocatedUnfairLock(initialState: false)
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
        canForceBPM = tester
        isEnabled = enabled
        Self.state.withLock { $0 = enabled }
    }

    /// Release only: unlocks for Xcode builds (forced BPM: TestFlight too). Called once at launch.
    func resolve() async {
        #if !DEBUG
        guard !didResolve else { return }
        didResolve = true
        guard let result = try? await AppTransaction.shared,
              case .verified(let transaction) = result else { return }
        // Not .sandbox: App Review installs builds in the sandbox environment too, and must
        // never see the tester tools (onboarding skip, debug buttons). TestFlight builds stay locked.
        if transaction.environment == .xcode { isTester = true }
        // Except the forced BPM: UGC creators film from TestFlight builds.
        if transaction.environment == .xcode || transaction.environment == .sandbox { canForceBPM = true }
        #endif
    }
}
