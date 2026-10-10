//
//  SupportMail.swift
//  CortiFree
//
//  Contact, bug reports and feature requests all go straight to the support inbox,
//  pre-filled with the user's id and device / app info so every mail is actionable.
//

import SwiftUI
import MessageUI
import RevenueCat

enum SupportMail {
    static let address = "cortifree@driftstudio.app"

    enum Kind: String, Identifiable {
        case contact, bug, feature
        var id: String { rawValue }

        fileprivate var subjectKey: String { "support.mail.subject.\(rawValue)" }
        fileprivate var promptKey: String { "support.mail.prompt.\(rawValue)" }
    }

    struct Draft: Identifiable {
        let id = UUID()
        let subject: String
        let body: String
    }

    @MainActor
    static func draft(_ kind: Kind) -> Draft {
        let l = LanguageManager.shared
        let user = Auth.auth().currentUser
        let shortID = user.map { String($0.uid.suffix(6)) } ?? "guest"
        let subject = "[CortiFree] \(l.localizedString(for: kind.subjectKey)) · \(appVersion) · \(shortID)"
        let body = """
        \(l.localizedString(for: kind.promptKey))



        ———
        \(l.localizedString(for: "support.mail.info_header"))
        \(diagnostics())
        """
        return Draft(subject: subject, body: body)
    }

    /// Plain-text block the support inbox relies on; labels stay in English on purpose.
    @MainActor
    static func diagnostics() -> String {
        let user = Auth.auth().currentUser
        let revenueCat = RevenueCatManager.shared
        let providers = user?.providerData.map(\.providerID).joined(separator: ", ")
        let premium = revenueCat.isPremiumStatusReady
            ? (revenueCat.hasActiveSubscription ? "Premium" : "Free")
            : "Unknown"
        let product = revenueCat.customerInfo?.entitlements.active.values.first?.productIdentifier
        let device = Locale.current
        let lines: [(String, String?)] = [
            ("User ID", user?.uid ?? "Not signed in"),
            ("Email", user?.email),
            ("Sign-in", providers?.isEmpty == false ? providers : nil),
            ("RevenueCat ID", Purchases.isConfigured ? Purchases.shared.appUserID : nil),
            ("Subscription", product.map { "\(premium) (\($0))" } ?? premium),
            ("App", "\(appVersion) · \(distribution)"),
            ("iOS", UIDevice.current.systemVersion),
            ("Device", modelIdentifier),
            ("App language", LanguageManager.shared.currentLanguage.rawValue),
            ("Device locale", device.identifier),
            ("Time zone", TimeZone.current.identifier),
            ("Date", ISO8601DateFormatter().string(from: Date())),
        ]
        return lines
            .compactMap { label, value in value.map { "\(label): \($0)" } }
            .joined(separator: "\n")
    }

    /// Fallback when the Mail app has no account: hand the draft to the default mail client.
    static func mailtoURL(for draft: Draft) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = address
        components.queryItems = [
            URLQueryItem(name: "subject", value: draft.subject),
            URLQueryItem(name: "body", value: draft.body)
        ]
        return components.url
    }

    static var canUseComposer: Bool { MFMailComposeViewController.canSendMail() }

    // MARK: - Info

    private static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    private static var distribution: String {
        #if DEBUG
        return "Debug"
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" ? "TestFlight" : "App Store"
        #endif
    }

    /// Hardware identifier such as "iPhone16,2" (more useful than "iPhone").
    private static var modelIdentifier: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return "\(simulated) (Simulator)"
        }
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { buffer in
            String(decoding: buffer.prefix(while: { $0 != 0 }), as: UTF8.self)
        }
    }
}

/// Native Mail composer, addressed to support with the draft pre-filled.
struct SupportMailComposer: UIViewControllerRepresentable {
    let draft: SupportMail.Draft
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([SupportMail.address])
        controller.setSubject(draft.subject)
        controller.setMessageBody(draft.body, isHTML: false)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: { dismiss() }) }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: () -> Void
        init(dismiss: @escaping () -> Void) { self.dismiss = dismiss }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            if result == .sent { HapticManager.success() }
            dismiss()
        }
    }
}
