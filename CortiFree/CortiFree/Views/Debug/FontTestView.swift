//
//  FontTestView.swift
//  CortiFree
//
//  Test view to display all available fonts
//

import SwiftUI
import UIKit

struct FontTestView: View {
    @State private var allFonts: [String] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Available Fonts")
                    .font(.title)
                    .padding()

                ForEach(allFonts, id: \.self) { fontName in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fontName)
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("The quick brown fox")
                            .font(.custom(fontName, size: 18))
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            loadAllFonts()
        }
    }

    private func loadAllFonts() {
        var fonts: [String] = []

        for family in UIFont.familyNames.sorted() {
            for font in UIFont.fontNames(forFamilyName: family).sorted() {
                if font.contains("Faro") || font.contains("Hanken") {
                    fonts.append(font)
                    print("✅ Found font: \(font)")
                }
            }
        }

        allFonts = fonts
    }
}

#Preview {
    FontTestView()
        .onAppear {
            FontManager.registerFonts()
        }
}
