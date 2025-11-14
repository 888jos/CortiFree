//
//  RoutinePlan.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//

import Foundation
import SwiftUI

enum RoutinePlan: String, Codable, CaseIterable, Identifiable {
    case balanced = "balanced"
    case intensive = "intensive"
    case gentle = "gentle"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balanced:
            return "Équilibré"
        case .intensive:
            return "Intensif"
        case .gentle:
            return "Doux"
        }
    }

    var displayName: String {
        return title
    }

    var description: String {
        switch self {
        case .balanced:
            return "Programme équilibré adapté au quotidien"
        case .intensive:
            return "Programme intensif pour résultats rapides"
        case .gentle:
            return "Programme doux et progressif"
        }
    }

    var planetAsset: String {
        switch self {
        case .balanced:
            return "planet_earth"
        case .intensive:
            return "planet_mars"
        case .gentle:
            return "planet_moon"
        }
    }

    var color: Color {
        switch self {
        case .balanced:
            return Color.appTheme
        case .intensive:
            return Color(hex: "FF6B6B")
        case .gentle:
            return Color(hex: "A8D8EA")
        }
    }

    static var allPlans: [RoutinePlan] {
        return RoutinePlan.allCases
    }
}
