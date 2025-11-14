//
//  HapticManager.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import UIKit

enum HapticManager {
    static func trigger(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    static func light() {
        trigger(.light)
    }

    static func medium() {
        trigger(.medium)
    }

    static func heavy() {
        trigger(.heavy)
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}
