//
//  FontManager.swift
//  CortiFree
//
//  Created by Claude on 10/11/2025.
//

import UIKit
import CoreText

class FontManager {
    static func registerFonts() {
        // Register available fonts
        let fontNames = [
            "HankenGrotesk-Black.ttf",
            "HankenGrotesk-BlackItalic.ttf",
            "HankenGrotesk-Bold.ttf",
            "HankenGrotesk-BoldItalic.ttf",
            "HankenGrotesk-ExtraBold.ttf",
            "HankenGrotesk-ExtraBoldItalic.ttf",
            "HankenGrotesk-ExtraLight.ttf",
            "HankenGrotesk-ExtraLightItalic.ttf",
            "HankenGrotesk-Italic.ttf",
            "HankenGrotesk-Light.ttf",
            "HankenGrotesk-LightItalic.ttf",
            "HankenGrotesk-Medium.ttf",
            "HankenGrotesk-MediumItalic.ttf",
            "HankenGrotesk-Regular.ttf",
            "HankenGrotesk-SemiBold.ttf",
            "HankenGrotesk-SemiBoldItalic.ttf",
            "HankenGrotesk-Thin.ttf",
            "HankenGrotesk-ThinItalic.ttf",
            "Faro-RegularLucky.ttf",
            "Faro-DisplayLucky.ttf",
            "Faro-BoldLucky.ttf",
            "Faro-SemiBoldLucky.ttf",
            "Faro-LightLucky.ttf"
        ]

        var registeredCount = 0
        for fontName in fontNames {
            guard let fontURL = Bundle.main.url(forResource: fontName.replacingOccurrences(of: ".ttf", with: ""), withExtension: "ttf", subdirectory: "Fonts") else {
                // Don't spam console with missing font messages
                continue
            }

            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)

            if success {
                registeredCount += 1
            }
        }

        print("✅ Registered \(registeredCount) fonts successfully")

        // Map Poppins font names to HankenGrotesk equivalents
        setupFontAliases()
    }

    private static func setupFontAliases() {
        // Since Poppins fonts are not available, map them to HankenGrotesk
        // This is a workaround to avoid crashes when Poppins is requested
        let fontMapping = [
            "Poppins-Regular": "HankenGrotesk-Regular",
            "Poppins-Medium": "HankenGrotesk-Medium",
            "Poppins-SemiBold": "HankenGrotesk-SemiBold",
            "Poppins-Bold": "HankenGrotesk-Bold"
        ]

        // Store the mapping for use in the app
        UserDefaults.standard.set(fontMapping, forKey: "fontMapping")
        print("✅ Font aliases configured for Poppins → HankenGrotesk")
    }
}
