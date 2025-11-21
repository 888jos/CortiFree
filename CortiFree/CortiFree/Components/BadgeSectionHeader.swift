//
//  BadgeSectionHeader.swift
//  CortiFree
//
//  Header component for badge sections in ProfileView
//

import SwiftUI

struct BadgeSectionHeader: View {
    let icon: String
    let title: String
    let count: String

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Text(icon)
                .font(.system(size: 20))

            // Title
            Text(title)
                .font(.custom("Poppins-Bold", size: 16))
                .foregroundColor(.white)

            Spacer()

            // Count
            Text(count)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 12)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            BadgeSectionHeader(icon: "🏆", title: "ACHIEVEMENTS", count: "6/10")
            BadgeSectionHeader(icon: "📈", title: "HABITUDES", count: "12/32")
        }
        .padding()
    }
}
