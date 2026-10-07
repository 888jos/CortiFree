//
//  RoutinesView.swift
//  CortiFree
//
//  Created on 19/01/2026.
//

import SwiftUI

struct RoutinesView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Galaxy background
                GalaxyBackgroundView(intensity: 0.75)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    header

                    // One compact card per category, stacked vertically.
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Subtitle section
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "7E57C2"))

                                Text(LanguageManager.shared.localizedString(for: "inline.routinesview.00"))
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.white.opacity(0.7))

                                Spacer()
                            }
                            .padding(.bottom, 4)

                            LazyVStack(spacing: 12) {
                                ForEach(RoutineCategory.allCases, id: \.self) { category in
                                    NavigationLink(destination: RoutineLevelSelectionView(category: category)) {
                                        RoutineCategoryCardContent(category: category)
                                    }
                                    .buttonStyle(RoutineCategoryButtonStyle())
                                }
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
            .frame(height: 76)
            .ignoresSafeArea(edges: .top)

            HStack {
                Button(action: {
                    HapticManager.light()
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassCircle(interactive: true)

                Spacer()

                Text(LanguageManager.shared.localizedString(for: "routines.title"))
                    .font(.faroBold(20))
                    .foregroundColor(.white)

                Spacer()

                // Placeholder for symmetry
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 10)
        }
        .frame(height: 76)
    }
}

// MARK: - Button Style for Category Cards
struct RoutineCategoryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
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

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background image
            Image(category.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 156)
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
                        Text(LanguageManager.shared.localizedString(for: "routines.badge"))
                            .font(.custom("Poppins-Bold", size: 10))
                            .tracking(1)
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .glassCapsule()

                    Spacer()
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)

                Spacer()

                // Bottom: Title + Info
                VStack(alignment: .leading, spacing: 10) {
                    Text(category.localizedName)
                    .font(.faroBold(17))
                        .foregroundColor(.white)

                    Text(category.localizedDescription)
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 16) {
                        // Duration range only
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            .font(.system(size: 10))
                            Text(category.durationRange)
                                .font(.custom("Poppins-Medium", size: 10))
                        }
                        .foregroundColor(.white.opacity(0.9))

                        Spacer()

                        // Arrow indicator - white filled with dark violet chevron
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 30, height: 30)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "5E35B1"))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
                .frame(height: 156)
        .contentShape(Rectangle())
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.28), .white.opacity(0.06)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 6)
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
