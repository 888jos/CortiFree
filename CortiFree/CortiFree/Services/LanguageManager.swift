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

    @Published var currentLanguage: Language = .french {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
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
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let lang = Language(rawValue: saved) {
            currentLanguage = lang
        }
    }

    func toggle() {
        currentLanguage = currentLanguage == .french ? .english : .french
    }

    func setLanguage(_ language: Language) {
        currentLanguage = language
    }

    // Get localized string for current language
    func localizedString(for key: String) -> String {
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
}
