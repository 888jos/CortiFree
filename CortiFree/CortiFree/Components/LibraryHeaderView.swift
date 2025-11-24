//
//  LibraryHeaderView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Header section for LibraryView with background image and icon navigation
//

import SwiftUI

struct LibraryHeaderView: View {
    let onIconTap: (LibrarySection) -> Void

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Background Image - extends to top of screen, ignoring safe area
                ZStack(alignment: .top) {
                    Image("libraryHeaderImage")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .ignoresSafeArea(edges: .top)
                        .overlay(
                            // Gradient fade from transparent to dark at bottom
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.clear,
                                    Color(hex: "01000C").opacity(0.3),
                                    Color(hex: "01000C")
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .frame(height: 200)

                // Gradient extension to smoothly blend with background
                LinearGradient(
                    colors: [
                        Color(hex: "01000C"),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
                .allowsHitTesting(false)
            }
            .zIndex(0)

            VStack(spacing: 0) {
                // Title "Librairie" - positioned in upper portion of image
                HStack {
                    Text(NSLocalizedString("library.title", comment: ""))
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundColor(Color(hex: "FFFFFF"))
                        .shadow(
                            color: Color.black.opacity(0.4),
                            radius: 3,
                            x: 0,
                            y: 1
                        )
                    Spacer()
                }
                .padding(.leading, 24)
                .padding(.top, 60)

                Spacer()

                // Icon Row - overlapping bottom of image by ~30px
                HStack(spacing: 30) {
                    LibraryIconButton(
                        section: .respiration,
                        title: NSLocalizedString("library.icon.breathing", comment: ""),
                        iconName: "wind"
                    ) {
                        onIconTap(.respiration)
                    }

                    LibraryIconButton(
                        section: .meditation,
                        title: NSLocalizedString("library.icon.meditation", comment: ""),
                        iconName: "figure.mind.and.body"
                    ) {
                        onIconTap(.meditation)
                    }

                    LibraryIconButton(
                        section: .journal,
                        title: NSLocalizedString("library.icon.journal", comment: ""),
                        iconName: "book.closed.fill"
                    ) {
                        onIconTap(.journal)
                    }

                    LibraryIconButton(
                        section: .recherches,
                        title: NSLocalizedString("library.icon.studies", comment: ""),
                        iconName: "book.fill"
                    ) {
                        onIconTap(.recherches)
                    }
                }
                .padding(.bottom, -30)
            }
            .frame(height: 200)
            .zIndex(100)
        }
        .frame(height: 200 + 30)
    }
}

// MARK: - Library Section Enum

enum LibrarySection {
    case respiration
    case meditation
    case journal
    case recherches

    var displayName: String {
        switch self {
        case .respiration: return "Respiration"
        case .meditation: return "Méditation"
        case .journal: return "Journal"
        case .recherches: return "Études"
        }
    }
}

// MARK: - Library Icon Button

struct LibraryIconButton: View {
    let section: LibrarySection
    let title: String
    let iconName: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.light()

            // Scale animation
            withAnimation(.spring(response: 0.1, dampingFraction: 0.6)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.1, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }

            // Trigger action
            action()
        }) {
            VStack(spacing: 6) {
                // Circular icon container
                ZStack {
                    // Background circle
                    Circle()
                        .fill(Color(hex: "130C57"))
                        .frame(width: 60, height: 60)

                    // Stroke border
                    Circle()
                        .stroke(Color(hex: "49288C"), lineWidth: 1)
                        .frame(width: 60, height: 60)

                    // Icon
                    Image(systemName: iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)

                    // Ripple overlay when pressed
                    if isPressed {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .transition(.opacity)
                    }
                }
                .shadow(
                    color: Color.black.opacity(0.25),
                    radius: 6,
                    x: 0,
                    y: 3
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)

                // Label text
                Text(title)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Dark background for preview
        LinearGradient(
            colors: [
                Color(hex: "1F0140"),
                Color(hex: "0B011B"),
                Color(hex: "01000C")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 0) {
            LibraryHeaderView { section in
                print("Tapped on \(section.displayName)")
            }

            Spacer()

            // Show some content below to demonstrate the overlap
            VStack(spacing: 20) {
                Text("Content below header")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "2A2B5A"))
                    .frame(height: 100)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 20)
        }
    }
}
