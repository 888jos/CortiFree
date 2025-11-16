//
//  Planet.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Modèle pour les planètes du système solaire
//

import Foundation
import SwiftUI

enum Planet: String, CaseIterable, Identifiable {
    case mercury = "mercury"
    case venus = "venus"
    case earth = "earth"
    case mars = "mars"
    case jupiter = "jupiter"
    case saturn = "saturn"
    case uranus = "uranus"
    case neptune = "neptune"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mercury: return "Mercure"
        case .venus: return "Vénus"
        case .earth: return "Terre"
        case .mars: return "Mars"
        case .jupiter: return "Jupiter"
        case .saturn: return "Saturne"
        case .uranus: return "Uranus"
        case .neptune: return "Neptune"
        }
    }

    var imageName: String {
        return rawValue
    }

    var haloColor: Color {
        switch self {
        case .mercury: return Color(hex: "A46A2B") // brun doré métallique
        case .venus: return Color(hex: "E3A02F") // jaune doré lumineux
        case .earth: return Color(hex: "3BA3D4") // bleu océan équilibré
        case .mars: return Color(hex: "D45A2E") // orange terreux chaud
        case .jupiter: return Color(hex: "D8832C") // orange ambré
        case .saturn: return Color(hex: "E1A345") // beige doré chaud
        case .uranus: return Color(hex: "4FD1C5") // cyan clair turquoise
        case .neptune: return Color(hex: "1B6CD6") // bleu profond froid
        }
    }

    // Couleur secondaire pour les gradients
    var gradientSecondaryColor: Color {
        switch self {
        case .mercury: return Color(hex: "C89B5E") // or clair
        case .venus: return Color(hex: "F4C563") // jaune clair doré
        case .earth: return Color(hex: "5BC9E8") // bleu ciel
        case .mars: return Color(hex: "E88B5A") // orange clair/corail
        case .jupiter: return Color(hex: "EAA75E") // orange pêche
        case .saturn: return Color(hex: "F2C977") // or pâle
        case .uranus: return Color(hex: "7FE5DC") // turquoise clair
        case .neptune: return Color(hex: "4D9FE8") // bleu azur
        }
    }

    // Couleur principale pour le thème de l'app
    var themeColor: Color {
        return haloColor
    }

    // Couleur secondaire pour le thème
    var themeSecondaryColor: Color {
        return gradientSecondaryColor
    }

    // Association routine → planète (matches exact assignments from PlanSelectionView)
    static func planet(for routineTitle: String) -> Planet {
        let lowercased = routineTitle.lowercased()

        // Exact mappings from the 4 routines in PlanSelectionView:

        // "🧠 Maîtriser son esprit" → Earth
        if lowercased.contains("esprit") || lowercased.contains("anxiété") || lowercased.contains("pensées") {
            return .earth
        }
        // "😴 Retrouver le sommeil" → Saturn
        else if lowercased.contains("sommeil") || lowercased.contains("sleep") || lowercased.contains("fatigue") {
            return .saturn
        }
        // "⚡ Booster son énergie" → Jupiter
        else if lowercased.contains("énergie") || lowercased.contains("energy") || lowercased.contains("booster") || lowercased.contains("motivation") {
            return .jupiter
        }
        // "🎯 Gérer le stress" → Mars
        else if lowercased.contains("stress") || lowercased.contains("burn") {
            return .mars
        }

        // Par défaut: Earth
        return .earth
    }
}

// Extension pour accéder facilement à la couleur du thème
extension Color {
    static var appTheme: Color {
        return Color(hex: "B794F6") // Violet principal (same as footer selected tab)
    }

    static var appThemeSecondary: Color {
        return Color(hex: "9B59B6") // Violet secondaire complémentaire
    }
}

class PlanetSettings: ObservableObject {
    static let shared = PlanetSettings()

    @Published var selectedPlanet: Planet {
        didSet {
            UserDefaults.standard.set(selectedPlanet.rawValue, forKey: AppConstants.UserDefaultsKeys.selectedPlanet)
        }
    }

    init() {
        if let savedPlanet = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.selectedPlanet),
           let planet = Planet(rawValue: savedPlanet) {
            self.selectedPlanet = planet
        } else {
            self.selectedPlanet = .earth // Default planet
        }
    }
}
