//
//  RoutinesView.swift
//  CortiFree
//
//  Created on 19/01/2026.
//

import SwiftUI

struct RoutinesView: View {
    @Environment(\.dismiss) var dismiss

    private var isFrench: Bool {
        Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Galaxy background
                GalaxyBackgroundView(intensity: 1.0)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    header

                    // Routines grid - one big card per category
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Subtitle section
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "7E57C2"))

                                Text(isFrench ? "Programmes guidés pour chaque moment" : "Guided programs for every moment")
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.white.opacity(0.7))

                                Spacer()
                            }
                            .padding(.bottom, 4)

                            ForEach(RoutineCategory.allCases, id: \.self) { category in
                                NavigationLink(destination: RoutineLevelSelectionView(category: category)) {
                                    RoutineCategoryCardContent(category: category)
                                }
                                .buttonStyle(RoutineCategoryButtonStyle())
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header
    private var header: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color(hex: "49288C").opacity(0.3), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .ignoresSafeArea(edges: .top)

            HStack {
                Button(action: {
                    HapticManager.light()
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "1A1B3A").opacity(0.8))
                            .frame(width: 40, height: 40)

                        Image(systemName: "chevron.left")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                Text(NSLocalizedString("routines.title", comment: ""))
                    .font(.custom("Poppins-Bold", size: 20))
                    .foregroundColor(.white)

                Spacer()

                // Placeholder for symmetry
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
        }
    }
}

// MARK: - Button Style for Category Cards
struct RoutineCategoryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.light()
                }
            }
    }
}

// MARK: - Routine Category Card Content (for NavigationLink)
struct RoutineCategoryCardContent: View {
    let category: RoutineCategory

    private var isFrench: Bool {
        Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background image
            Image(category.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 180)
                .clipped()

            // Dark gradient overlay for readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.75)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content overlay
            VStack(alignment: .leading, spacing: 0) {
                // Top: Category badge only
                HStack {
                    // Category type badge
                    HStack(spacing: 6) {
                        Text(NSLocalizedString("routines.badge", comment: ""))
                            .font(.custom("Poppins-Bold", size: 10))
                            .tracking(1)
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.35))
                    )

                    Spacer()
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)

                Spacer()

                // Bottom: Title + Info
                VStack(alignment: .leading, spacing: 10) {
                    Text(category.localizedName)
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundColor(.white)

                    Text(category.localizedDescription)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 16) {
                        // Duration range only
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text(category.durationRange)
                                .font(.custom("Poppins-Medium", size: 13))
                        }
                        .foregroundColor(.white.opacity(0.9))

                        Spacer()

                        // Arrow indicator - white filled with dark violet chevron
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 36, height: 36)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "5E35B1"))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(height: 180)
        .contentShape(Rectangle())
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}


// MARK: - Routine Identifiable Extension
extension Routine: Hashable {
    static func == (lhs: Routine, rhs: Routine) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#Preview {
    RoutinesView()
}
