//
//  BreathePause.swift
//  CortiFree
//
//  « Breathe before TikTok »: a Shortcuts personal automation (« When TikTok is opened »)
//  runs this intent, CortiFree opens on a 30-second breathing pause, then the user chooses
//  to go on or to stop there. Right after a pause, the next opening goes straight through,
//  so the automation never loops.
//

import AppIntents
import Foundation
import SwiftUI

enum PauseApp: String, AppEnum, CaseIterable, Identifiable {
    case tiktok, instagram, x, snapchat, youtube, facebook, reddit

    var id: String { rawValue }

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "App"
    static let caseDisplayRepresentations: [PauseApp: DisplayRepresentation] = [
        .tiktok: "TikTok", .instagram: "Instagram", .x: "X", .snapchat: "Snapchat",
        .youtube: "YouTube", .facebook: "Facebook", .reddit: "Reddit"
    ]

    var name: String {
        switch self {
        case .tiktok: return "TikTok"
        case .instagram: return "Instagram"
        case .x: return "X"
        case .snapchat: return "Snapchat"
        case .youtube: return "YouTube"
        case .facebook: return "Facebook"
        case .reddit: return "Reddit"
        }
    }

    /// Universal links: open the app when it is installed, the website otherwise.
    var openURL: URL {
        switch self {
        case .tiktok: return URL(string: "https://www.tiktok.com/")!
        case .instagram: return URL(string: "https://www.instagram.com/")!
        case .x: return URL(string: "https://x.com/")!
        case .snapchat: return URL(string: "https://www.snapchat.com/")!
        case .youtube: return URL(string: "https://www.youtube.com/")!
        case .facebook: return URL(string: "https://www.facebook.com/")!
        case .reddit: return URL(string: "https://www.reddit.com/")!
        }
    }
}

struct BreathePauseIntent: AppIntent {
    static let title: LocalizedStringResource = "Breathe before scrolling"
    static let description = IntentDescription("Opens CortiFree for a 30-second breathing pause before the app you were about to open.")
    static let openAppWhenRun = true

    @Parameter(title: "App", default: .tiktok)
    var app: PauseApp

    init() {}
    init(app: PauseApp) { self.app = app }

    @MainActor
    func perform() async throws -> some IntentResult {
        BreathePauseCenter.shared.request(app)
        return .result()
    }
}

struct CortiFreeAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: BreathePauseIntent(),
            phrases: ["Breathe before scrolling with \(.applicationName)"],
            shortTitle: "Breathe before scrolling",
            systemImageName: "wind"
        )
    }
}

@MainActor
final class BreathePauseCenter: ObservableObject {
    static let shared = BreathePauseCenter()
    private init() {}

    /// The pause to show (ContentView presents it full screen).
    @Published var pending: PauseApp?

    /// After a pause, openings within this window go straight to the app (no loop).
    private let passWindow: TimeInterval = 10 * 60
    private func key(_ app: PauseApp) -> String { "calm.pause.passUntil.\(app.rawValue)" }

    func request(_ app: PauseApp) {
        let passUntil = UserDefaults.standard.double(forKey: key(app))
        if Date().timeIntervalSince1970 < passUntil {
            UIApplication.shared.open(app.openURL)
            return
        }
        pending = app
        AnalyticsManager.shared.track(event: "breathe_pause_shown", properties: ["app": app.rawValue])
    }

    /// The pause is over: let the next openings through, optionally open the app now.
    func finish(_ app: PauseApp, openApp: Bool) {
        UserDefaults.standard.set(Date().timeIntervalSince1970 + passWindow, forKey: key(app))
        pending = nil
        AnalyticsManager.shared.track(event: "breathe_pause_finished", properties: ["app": app.rawValue, "opened": openApp])
        if openApp { UIApplication.shared.open(app.openURL) }
    }
}
