//
//  RoutinesView.swift
//  CortiFree
//
//  Created on 19/01/2026.
//

import SwiftUI

struct RoutinesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedRoutine: Routine?

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Introduction text
                        introSection

                        // Routines grid
                        routinesGrid

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
        }
        .sheet(item: $selectedRoutine) { routine in
            RoutineDetailView(routine: routine)
                .presentationBackground(.clear)
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

    // MARK: - Intro Section
    private var introSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("routines.subtitle", comment: ""))
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(Color(hex: "B0B8D4"))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Routines Grid
    private var routinesGrid: some View {
        LazyVStack(spacing: 16) {
            ForEach(Routine.allRoutines) { routine in
                RoutineCard(routine: routine) {
                    HapticManager.light()
                    selectedRoutine = routine
                }
            }
        }
    }
}

// MARK: - Routine Card
struct RoutineCard: View {
    let routine: Routine
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(Color(hex: routine.color).opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: routine.icon)
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: routine.color))
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.localizedName)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)

                    Text(routine.localizedDescription)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(Color(hex: "B0B8D4"))
                        .lineLimit(2)

                    // Duration + Difficulty
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text(routine.formattedDuration)
                                .font(.custom("Poppins-Medium", size: 12))
                        }
                        .foregroundColor(Color(hex: routine.color))

                        // Difficulty dots
                        HStack(spacing: 3) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(i < routine.difficulty ? Color(hex: routine.color) : Color.white.opacity(0.2))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "1A1B3A").opacity(0.8),
                                Color(hex: "2A2B5A").opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: routine.color).opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
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
