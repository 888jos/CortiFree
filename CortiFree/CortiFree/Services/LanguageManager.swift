//
//  LanguageManager.swift
//  CortiFree
//
//  Created by Claude on 01/12/2025.
//  Manages app language selection with persistence
//

import SwiftUI
import SuperwallKit

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    /// Notification posted when language changes
    static let languageDidChangeNotification = Notification.Name("LanguageDidChange")

    /// Unique ID that changes on language change to force view refresh
    @Published var refreshID = UUID()

    @Published var currentLanguage: Language = .french {
        didSet {
            guard oldValue != currentLanguage else { return }
            updateBundle()
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
            UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            WidgetInsightsStore.mirrorLanguage(currentLanguage.rawValue)

            // Sync Superwall paywall language immediately
            if Superwall.isInitialized {
                Superwall.shared.localeIdentifier = currentLanguage.superwallLocaleIdentifier
            }

            // Post notification
            NotificationCenter.default.post(name: Self.languageDidChangeNotification, object: nil)

            // Force view refresh
            refreshID = UUID()
        }
    }

    enum Language: String, CaseIterable {
        case french = "fr"
        case english = "en"
        case spanish = "es"
        case german = "de"
        case japanese = "ja"
        case korean = "ko"

        var flag: String {
            switch self {
            case .french: return "🇫🇷"
            case .english: return "🇬🇧"
            case .spanish: return "🇪🇸"
            case .german: return "🇩🇪"
            case .japanese: return "🇯🇵"
            case .korean: return "🇰🇷"
            }
        }

        var code: String {
            switch self {
            case .french: return "FRA"
            case .english: return "ENG"
            case .spanish: return "ESP"
            case .german: return "DEU"
            case .japanese: return "JPN"
            case .korean: return "KOR"
            }
        }

        var locale: Locale {
            switch self {
            case .french: return Locale(identifier: "fr_FR")
            case .english: return Locale(identifier: "en_US")
            case .spanish: return Locale(identifier: "es_ES")
            case .german: return Locale(identifier: "de_DE")
            case .japanese: return Locale(identifier: "ja_JP")
            case .korean: return Locale(identifier: "ko_KR")
            }
        }

        var displayName: String {
            switch self {
            case .french: return "Français"
            case .english: return "English"
            case .spanish: return "Español"
            case .german: return "Deutsch"
            case .japanese: return "日本語"
            case .korean: return "한국어"
            }
        }

        var superwallLocaleIdentifier: String {
            switch self {
            case .french: return "fr_FR"
            case .english: return "en_US"
            case .spanish: return "es_ES"
            case .german: return "de_DE"
            case .japanese: return "ja_JP"
            case .korean: return "ko_KR"
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
            currentLanguage = Language(rawValue: String(systemLang.prefix(2))) ?? .english
        }
        updateBundle()
        WidgetInsightsStore.mirrorLanguage(currentLanguage.rawValue)
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
        let languages = Language.allCases
        let currentIndex = languages.firstIndex(of: currentLanguage) ?? 0
        currentLanguage = languages[(currentIndex + 1) % languages.count]
    }

    func setLanguage(_ language: Language) {
        currentLanguage = language
    }

    // Get localized string for current language
    func localizedString(for key: String) -> String {
        let translated = bundle.localizedString(forKey: key, value: nil, table: nil)
        return translated == key ? englishBundle.localizedString(forKey: key, value: key, table: nil) : translated
    }

    /// Localized string with dynamic bundle (forces correct language)
    func localized(_ key: String) -> String {
        let translated = bundle.localizedString(forKey: key, value: nil, table: nil)
        return translated == key ? englishBundle.localizedString(forKey: key, value: key, table: nil) : translated
    }

    private lazy var englishBundle: Bundle = {
        guard let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }()
}
