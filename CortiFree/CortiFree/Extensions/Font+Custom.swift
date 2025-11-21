//
//  Font+Custom.swift
//  CortiFree
//
//  Custom font extension with fallback support
//

import SwiftUI

extension Font {
    // Custom font with automatic fallback to HankenGrotesk
    static func customFont(_ name: String, size: CGFloat) -> Font {
        // Check if Poppins was requested and map to HankenGrotesk
        let mappedName: String
        switch name {
        case "Poppins-Regular":
            mappedName = "HankenGrotesk-Regular"
        case "Poppins-Medium":
            mappedName = "HankenGrotesk-Medium"
        case "Poppins-SemiBold":
            mappedName = "HankenGrotesk-SemiBold"
        case "Poppins-Bold":
            mappedName = "HankenGrotesk-Bold"
        default:
            mappedName = name
        }

        // Try to create the custom font, fallback to system if fails
        if UIFont(name: mappedName, size: size) != nil {
            return Font.custom(mappedName, size: size)
        } else {
            // Fallback to system font with similar weight
            switch name {
            case "Poppins-Bold", "HankenGrotesk-Bold":
                return Font.system(size: size, weight: .bold)
            case "Poppins-SemiBold", "HankenGrotesk-SemiBold":
                return Font.system(size: size, weight: .semibold)
            case "Poppins-Medium", "HankenGrotesk-Medium":
                return Font.system(size: size, weight: .medium)
            default:
                return Font.system(size: size, weight: .regular)
            }
        }
    }

    // Convenience methods for common fonts
    static func poppinsRegular(_ size: CGFloat) -> Font {
        return customFont("Poppins-Regular", size: size)
    }

    static func poppinsMedium(_ size: CGFloat) -> Font {
        return customFont("Poppins-Medium", size: size)
    }

    static func poppinsSemiBold(_ size: CGFloat) -> Font {
        return customFont("Poppins-SemiBold", size: size)
    }

    static func poppinsBold(_ size: CGFloat) -> Font {
        return customFont("Poppins-Bold", size: size)
    }
}

// View modifier for custom fonts
extension View {
    func customFont(_ name: String, size: CGFloat) -> some View {
        self.font(.customFont(name, size: size))
    }
}