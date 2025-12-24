//
//  ResponsiveLayout.swift
//  CortiFree
//
//  Created by Claude on 11/12/2025.
//  Système de design responsive centralisé pour support iPad
//

import SwiftUI
import UIKit

struct ResponsiveLayout {
    // MARK: - Device Detection

    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var isLandscape: Bool {
        UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }

    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }

    // MARK: - Responsive Sizing Multipliers

    static var sizeMultiplier: CGFloat {
        isIPad ? 1.2 : 1.0
    }

    static var paddingMultiplier: CGFloat {
        isIPad ? 1.3 : 1.0
    }

    static var fontMultiplier: CGFloat {
        isIPad ? 1.15 : 1.0
    }

    // MARK: - Adaptive Values

    static func cardWidth(base: CGFloat) -> CGFloat {
        base * sizeMultiplier
    }

    static func cardHeight(base: CGFloat) -> CGFloat {
        base * sizeMultiplier
    }

    static func padding(base: CGFloat) -> CGFloat {
        base * paddingMultiplier
    }

    static func spacing(base: CGFloat) -> CGFloat {
        base * paddingMultiplier
    }

    static func fontSize(base: CGFloat) -> CGFloat {
        base * fontMultiplier
    }

    // MARK: - Grid Layout

    static var gridColumns: Int {
        if isIPad {
            return isLandscape ? 3 : 2
        }
        return 1
    }

    static func gridColumns(base: Int) -> Int {
        if isIPad {
            return isLandscape ? base + 1 : base
        }
        return 1
    }

    // MARK: - Content Layout

    /// Max width pour centrer le contenu sur iPad
    static var contentMaxWidth: CGFloat {
        isIPad ? 800 : .infinity
    }

    /// Max width pour les modals/forms sur iPad
    static var modalMaxWidth: CGFloat {
        isIPad ? 600 : .infinity
    }

    /// Horizontal padding adaptatif pour les écrans
    static var horizontalPadding: CGFloat {
        isIPad ? 40 : 24
    }

    /// Vertical padding adaptatif
    static var verticalPadding: CGFloat {
        isIPad ? 32 : 20
    }
}

// MARK: - View Extensions

extension View {
    /// Applique un frame responsive basé sur les dimensions de base iPhone
    func responsiveFrame(width: CGFloat, height: CGFloat) -> some View {
        self.frame(
            width: ResponsiveLayout.cardWidth(base: width),
            height: ResponsiveLayout.cardHeight(base: height)
        )
    }

    /// Applique un frame responsive pour la largeur uniquement
    func responsiveWidth(_ width: CGFloat) -> some View {
        self.frame(width: ResponsiveLayout.cardWidth(base: width))
    }

    /// Applique un frame responsive pour la hauteur uniquement
    func responsiveHeight(_ height: CGFloat) -> some View {
        self.frame(height: ResponsiveLayout.cardHeight(base: height))
    }

    /// Applique un padding responsive
    func responsivePadding(_ edges: Edge.Set = .all, _ value: CGFloat) -> some View {
        self.padding(edges, ResponsiveLayout.padding(base: value))
    }

    /// Applique le padding horizontal standard adaptatif
    func responsiveHorizontalPadding() -> some View {
        self.padding(.horizontal, ResponsiveLayout.horizontalPadding)
    }

    /// Applique le padding vertical standard adaptatif
    func responsiveVerticalPadding() -> some View {
        self.padding(.vertical, ResponsiveLayout.verticalPadding)
    }

    /// Centre le contenu avec une largeur maximale adaptative (pour les vues principales)
    func adaptiveMaxWidth() -> some View {
        self.frame(maxWidth: ResponsiveLayout.contentMaxWidth)
    }

    /// Centre le contenu avec une largeur maximale pour les modals
    func adaptiveModalWidth() -> some View {
        self.frame(maxWidth: ResponsiveLayout.modalMaxWidth)
    }
}
