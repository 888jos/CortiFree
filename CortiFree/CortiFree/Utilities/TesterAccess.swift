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

    @Published private(set) var isEnabled: Bool {
        didSet {
            let value = isEnabled
            Self.state.withLock { $0 = value }
        }
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
        isEnabled = true
        #else
        isEnabled = false
        #endif
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
        if transaction.environment == .xcode { isEnabled = true }
        #endif
    }
}
