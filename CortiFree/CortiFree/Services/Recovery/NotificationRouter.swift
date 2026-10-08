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

    private init() {}

    func handle(userInfo: [AnyHashable: Any]) {
        guard let link = userInfo["deeplink"] as? String, let url = URL(string: link) else { return }
        pendingURL = url
    }
}
