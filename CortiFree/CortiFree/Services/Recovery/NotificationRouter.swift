//
//  NotificationRouter.swift
//  CortiFree
//
//  Hands the deep link of a tapped notification to the app root, which may not be
//  mounted yet on a cold start (the published value is replayed when it subscribes).
//

import Foundation
import Combine

@MainActor
final class NotificationRouter: ObservableObject {
    static let shared = NotificationRouter()

    @Published var pendingURL: URL?
    /// In-app destinations (plan tab, review, Milo) opened by the main app (ContentView), not the root.
    @Published var pendingAppLink: URL?

    private init() {}

    func handle(userInfo: [AnyHashable: Any]) {
        guard let link = userInfo["deeplink"] as? String, let url = URL(string: link) else { return }
        // Screen Time shield → « Breathe first »: the pause, shown full screen by ContentView.
        if userInfo["campaign"] as? String == ScreenTimeShield.campaign {
            BreathePauseCenter.shared.requestShielded()
            return
        }
        if userInfo["campaign"] as? String == PlanReminderScheduler.campaign {
            pendingAppLink = url
        } else {
            pendingURL = url
        }
    }
}
