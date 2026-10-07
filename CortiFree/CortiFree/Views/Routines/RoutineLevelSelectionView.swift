//
//  RoutineLevelSelectionView.swift
//  CortiFree
//
//  Created on 20/01/2026.
//

import SwiftUI

struct RoutineLevelSelectionView: View {
    let category: RoutineCategory
    @Environment(\.dismiss) var dismiss
    @State private var selectedRoutine: Routine?
    @State private var showPlayer = false

    private var routines: [Routine] {
        Routine.routines(for: category)
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.75)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with category info
                headerSection

                // Level cards - stacked visual design
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(Array(routines.enumerated()), id: \.element.id) { index, routine in
                            RoutineLevelCard(
                                routine: routine,
                                category: category,
                                index: index
                            ) {
                                selectedRoutine = routine
                            }
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: selectedRoutine) { _, newValue in
            if newValue != nil {
                showPlayer = true
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let routine = selectedRoutine {
                RoutinePlayerView(routine: routine)
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Top bar with back button
            HStack {
                Button(action: {
                    HapticManager.light()
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassCircle(interactive: true)

                Spacer()

                // Category title centered
                VStack(spacing: 2) {
                    Text(category.localizedName)
                        .font(.faroBold(22))
                        .foregroundColor(.white)

                    Text(LanguageManager.shared.localizedString(for: "inline.routinelevelselectionview.00"))
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Placeholder for symmetry
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Routine Level Card (Premium Design)
struct RoutineLevelCard: View {
    let routine: Routine
    let category: RoutineCategory
    let index: Int
    let action: () -> Void

    @State private var isPressed = false

    // Level-specific styling
    private var levelEmoji: String {
        switch routine.difficulty {
        case 1: return "🌱"
        case 2: return "🌿"
        case 3: return "🌳"
        default: return "🌱"
        }
    }

    private var levelLabel: String {
        switch routine.difficulty {
        case 1: return LanguageManager.shared.localizedString(for: "inline.routinelevelselectionview.01")
        case 2: return LanguageManager.shared.localizedString(for: "inline.routinelevelselectionview.02")
        case 3: return LanguageManager.shared.localizedString(for: "inline.routinelevelselectionview.03")
        default: return ""
        }
    }

    /// Glass tint grows with difficulty (level 1 stays neutral glass).
    private var levelTint: Color? {
        routine.difficulty >= 2 ? Color(hex: "5C6BC0") : nil
    }

    private var borderOpacity: Double {
        switch routine.difficulty {
        case 1: return 0.2
        case 2: return 0.35
        case 3: return 0.5
        default: return 0.2
        }
    }

    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            HStack(spacing: 16) {
                // Left: Emoji + Level indicator
                VStack(spacing: 8) {
                    Text(levelEmoji)
                        .font(.system(size: 36))

                    // Level dots
                    HStack(spacing: 4) {
                        ForEach(1...3, id: \.self) { dot in
                            Circle()
                                .fill(dot <= routine.difficulty
                                      ? Color(hex: "5C6BC0")
                                      : Color.white.opacity(0.2))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .frame(width: 70)

                // Center: Content
                VStack(alignment: .leading, spacing: 8) {
                    // Level label
                    Text(levelLabel)
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundColor(.white)

                    // Routine name
                    Text(routine.localizedName)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)

                    // Stats row
                    HStack(spacing: 16) {
                        // Duration
                        HStack(spacing: 5) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text(routine.formattedDuration)
                                .font(.custom("Poppins-Medium", size: 13))
                        }
                        .foregroundColor(Color(hex: "5C6BC0"))

                        // Steps count
                        HStack(spacing: 5) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 12))
                            Text("\(routine.steps.count)")
                                .font(.custom("Poppins-Medium", size: 13))
                        }
                        .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                // Right: Play button
                ZStack {
                    Circle()
                        .fill(Color(hex: "5C6BC0"))
                        .frame(width: 50, height: 50)
                        .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                        .shadow(color: Color(hex: "5C6BC0").opacity(0.3), radius: 6, x: 0, y: 3)

                    Image(systemName: "play.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .offset(x: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .glassCard(cornerRadius: 20, tint: levelTint, interactive: true)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        Color(hex: "5C6BC0").opacity(borderOpacity),
                        lineWidth: 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    RoutineLevelSelectionView(category: .morning)
}
