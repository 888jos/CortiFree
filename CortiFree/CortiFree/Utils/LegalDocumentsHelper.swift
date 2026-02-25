//
//  LegalDocumentsHelper.swift
//  CortiFree
//
//  Helper to open legal documents via web URLs
//

import Foundation
import UIKit

enum LegalDocument {
    case privacy
    case terms
    case legalNotice

    var url: URL? {
        switch self {
        case .privacy:
            return URL(string: "https://cortifreeapp.framer.website/legal-pages/privacy-policy")
        case .terms:
            return URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
        case .legalNotice:
            return URL(string: "https://cortifreeapp.framer.website/legal-pages/privacy-policy")
        }
    }

    var displayName: String {
        let isFrench = Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
        switch self {
        case .privacy:
            return isFrench ? "Politique de Confidentialité" : "Privacy Policy"
        case .terms:
            return isFrench ? "Conditions Générales d'Utilisation" : "Terms of Use"
        case .legalNotice:
            return isFrench ? "Mentions Légales" : "Legal Notice"
        }
    }
}

struct LegalDocumentsHelper {

    /// Opens a legal document in Safari
    static func openDocument(_ document: LegalDocument) {
        guard let url = document.url else {
            #if DEBUG
            print("❌ Invalid URL for document: \(document)")
            #endif
            return
        }

        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }

    /// Opens privacy policy
    static func openPrivacyPolicy() {
        openDocument(.privacy)
    }

    /// Opens terms of use (CGU)
    static func openTerms() {
        openDocument(.terms)
    }

    /// Opens legal notice (Mentions Légales)
    static func openLegalNotice() {
        openDocument(.legalNotice)
    }
}
