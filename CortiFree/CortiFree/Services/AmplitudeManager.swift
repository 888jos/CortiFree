//
//  AmplitudeManager.swift
//  CortiFree
//
//  Central Amplitude destination for the existing analytics event pipeline.
//

import Foundation
import UIKit
import AmplitudeSwift

final class AmplitudeManager {
    static let shared = AmplitudeManager()

    private var amplitude: Amplitude?
    private var isInitialized = false
    private init() {}

    func initialize() {
        guard !isInitialized, let apiKey = APIConfig.shared.amplitudeAPIKey else { return }

        amplitude = Amplitude(configuration: Configuration(
            apiKey: apiKey,
            autocapture: [.sessions, .appLifecycles],
            serverZone: .EU
        ))
        isInitialized = true

        #if DEBUG
        print("[Amplitude] ✅ Initialized")
        #endif
    }

    func identify(userId: String) {
        amplitude?.setUserId(userId: userId)
    }

    func setUserProperties(_ properties: [String: Any]) {
        guard !properties.isEmpty else { return }
        let identify = Identify()
        for (key, value) in properties {
            identify.set(property: key, value: value)
        }
        amplitude?.identify(identify: identify)
    }

    func track(event: String, properties: [String: Any]?) {
        guard let amplitude else { return }
        amplitude.track(eventType: event, eventProperties: properties)
    }

    func flush() {
        amplitude?.flush()
    }

    func reset() {
        amplitude?.setUserId(userId: nil)
    }
}
