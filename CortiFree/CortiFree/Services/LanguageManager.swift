//
//  LanguageManager.swift
//  CortiFree
//
//  Created by Claude on 01/12/2025.
//  Manages app language selection (FR/EN) with persistence
//

import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    /// Notification posted when language changes
    static let languageDidChangeNotification = Notification.Name("LanguageDidChange")

    /// Unique ID that changes on language change to force view refresh
    @Published var refreshID = UUID()

    @Published var currentLanguage: Language = .french {
        didSet {
            guard oldValue != currentLanguage else { return }
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
            UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()

            // Post notification
            NotificationCenter.default.post(name: Self.languageDidChangeNotification, object: nil)

            // Force view refresh
            refreshID = UUID()
        }
    }

    enum Language: String, CaseIterable {
        case french = "fr"
        case english = "en"

        var flag: String {
            switch self {
            case .french: return "🇫🇷"
            case .english: return "🇬🇧"
            }
        }

        var code: String {
            switch self {
            case .french: return "FRA"
            case .english: return "ENG"
            }
        }

        var locale: Locale {
            switch self {
            case .french: return Locale(identifier: "fr_FR")
            case .english: return Locale(identifier: "en_US")
            }
        }

        var displayName: String {
            switch self {
            case .french: return "Français"
            case .english: return "English"
            }
        }
    }

    /// Bundle for current language
    private(set) var bundle: Bundle = .main

    private init() {
        // Load saved language or detect from system
        if let saved = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let lang = Language(rawValue: saved) {
            currentLanguage = lang
        } else {
            // Auto-detect from system
            let systemLang = Locale.preferredLanguages.first ?? "en"
            currentLanguage = systemLang.hasPrefix("fr") ? .french : .english
        }
        updateBundle()
    }

    private func updateBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        } else {
            bundle = .main
        }
    }

    func toggle() {
        currentLanguage = currentLanguage == .french ? .english : .french
        updateBundle()
    }

    func setLanguage(_ language: Language) {
        currentLanguage = language
        updateBundle()
    }

    // Get localized string for current language
    func localizedString(for key: String) -> String {
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }

    /// Localized string with dynamic bundle (forces correct language)
    func localized(_ key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

