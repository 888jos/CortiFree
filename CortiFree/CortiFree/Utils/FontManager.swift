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

        for fontName in fontNames {
            guard let fontURL = Bundle.main.url(forResource: fontName.replacingOccurrences(of: ".ttf", with: ""), withExtension: "ttf", subdirectory: "Fonts") else {
                print("❌ Could not find font: \(fontName)")
                continue
            }

            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)

            if success {
                print("✅ Successfully registered font: \(fontName)")
            } else if let error = error?.takeRetainedValue() {
                print("❌ Error registering font \(fontName): \(error)")
            }
        }
    }
}
