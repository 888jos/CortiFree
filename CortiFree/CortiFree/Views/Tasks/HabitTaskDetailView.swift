//
//  HabitTaskDetailView.swift
//  CortiFree
//
//  Created by Claude on 14/11/2025.
//  Vue détaillée d'une tâche d'habitude avec impact sur les scores CortiFree
//

import SwiftUI

struct HabitTaskDetailView: View {
    let task: HabitTask
    let onValidate: () -> Void
    let onSkip: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var animateProgress: Bool = false

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)

            VStack(spacing: 0) {
                // Header with back button (fixed)
                HStack {
                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Title and info (scrollable)
                        VStack(spacing: 12) {
                            Text(task.title)
                                .font(.custom("HankenGrotesk-Bold", size: 28))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(hex: "B794F6")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .multilineTextAlignment(.center)

                            // Frequency and difficulty
                            HStack(spacing: 16) {
                                // Frequency
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))

                                    Text(task.frequency)
                                        .font(.custom("Poppins-Regular", size: 13))
                                        .foregroundColor(.white.opacity(0.7))
                                }

                                // Difficulty
                                HStack(spacing: 6) {
                                    HStack(alignment: .bottom, spacing: 2) {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(task.difficulty >= 1 ? Color.white : Color(hex: "8B8B8B"))
                                            .frame(width: 3, height: 6)

                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(task.difficulty >= 2 ? Color.white : Color(hex: "8B8B8B"))
                                            .frame(width: 3, height: 9)

                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(task.difficulty >= 3 ? Color.white : Color(hex: "8B8B8B"))
                                            .frame(width: 3, height: 12)
                                    }

                                    Text("Difficulté")
                                        .font(.custom("Poppins-Regular", size: 13))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 8)

                        // Progress section
                        VStack(spacing: 16) {
                            // Stats cards - Centered, single line
                            HStack(spacing: 40) {
                                // Current streak
                                HStack(spacing: 6) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "FF8800"))

                                    Text("\(task.streak)")
                                        .font(.custom("HankenGrotesk-Bold", size: 20))
                                        .foregroundColor(.white)

                                    Text("jours")
                                        .font(.custom("Poppins-Regular", size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                }

                                // Total completions
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "B794F6"))

                                    Text("\(task.totalCompletions)")
                                        .font(.custom("HankenGrotesk-Bold", size: 20))
                                        .foregroundColor(.white)

                                    Text("ce mois")
                                        .font(.custom("Poppins-Regular", size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .frame(maxWidth: .infinity)

                            // 7-day progress chart - Maximum spacing
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("7 derniers jours")
                                        .font(.custom("Poppins-SemiBold", size: 16))
                                        .foregroundColor(.white)

                                    // Progression vs last week
                                    let currentWeekCompletions = task.last7Days.filter { $0 }.count
                                    let previousWeekCompletions = 4 // This would come from actual data
                                    let progression = currentWeekCompletions - previousWeekCompletions

                                    HStack(spacing: 4) {
                                        if progression > 0 {
                                            Image(systemName: "arrow.up")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(Color(hex: "B794F6"))

                                            Text("+\(progression) vs semaine précédente")
                                                .font(.custom("Poppins-Regular", size: 11))
                                                .foregroundColor(Color(hex: "B794F6"))
                                        } else if progression < 0 {
                                            Image(systemName: "arrow.down")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.red)

                                            Text("\(progression) vs semaine précédente")
                                                .font(.custom("Poppins-Regular", size: 11))
                                                .foregroundColor(.red)
                                        } else {
                                            Image(systemName: "equal")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white.opacity(0.5))

                                            Text("Identique à la semaine précédente")
                                                .font(.custom("Poppins-Regular", size: 11))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    }
                                }

                                // Chart
                                HStack(alignment: .bottom, spacing: 0) {
                                    ForEach(0..<7) { index in
                                        VStack(spacing: 6) {
                                            // Bar with animation
                                            ZStack(alignment: .bottom) {
                                                // Background bar
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(Color.white.opacity(0.08))
                                                    .frame(width: 20, height: 100)

                                                // Filled bar
                                                if task.last7Days[index] {
                                                    RoundedRectangle(cornerRadius: 3)
                                                        .fill(
                                                            LinearGradient(
                                                                colors: [
                                                                    Color(hex: "B794F6"),
                                                                    Color(hex: "9B59B6")
                                                                ],
                                                                startPoint: .top,
                                                                endPoint: .bottom
                                                            )
                                                        )
                                                        .frame(width: 20, height: animateProgress ? 100 : 0)
                                                }
                                            }

                                            // Day label
                                            Text(getDayLabel(daysAgo: 6 - index))
                                                .font(.custom("Poppins-Medium", size: 9))
                                                .foregroundColor(task.last7Days[index] ? .white : .white.opacity(0.4))
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal, 24)

                        // Impact section title
                        VStack(spacing: 8) {
                            Text("Cette habitude améliore")
                                .font(.custom("HankenGrotesk-Bold", size: 20))
                                .foregroundColor(.white)

                            Text("Ton score CortiFree dans ces domaines")
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 16)

                        // Radar chart for 6 CortiFree domains (reduced by 15%)
                        ZStack {
                            // Background hexagon grid
                            HexagonRadarGrid()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                .frame(width: 238, height: 238)

                            // Filled hexagon based on impact
                            HexagonRadarFill(progress: getImpactProgress())
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "B794F6").opacity(0.7),
                                            Color(hex: "B794F6").opacity(0.4)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 238, height: 238)

                            // Stroke around the filled hexagon - positioned outside
                            HexagonRadarFill(progress: getImpactProgress())
                                .stroke(
                                    Color(hex: "B794F6").opacity(0.5),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                                )
                                .frame(width: 238, height: 238)

                            // Labels at hexagon vertices (adjusted for 15% reduction)
                            ZStack {
                                // Global - Top
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12))
                                    Text("Global")
                                        .font(.custom("Poppins-SemiBold", size: 12))
                                }
                                .foregroundColor(.white)
                                .offset(x: 0, y: -143)

                                // Sérénité - Top right
                                HStack(spacing: 4) {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 12))
                                    Text("Sérénité")
                                        .font(.custom("Poppins-SemiBold", size: 12))
                                }
                                .foregroundColor(.white)
                                .offset(x: 126, y: -70)

                                // Sommeil - Bottom right
                                HStack(spacing: 4) {
                                    Image(systemName: "moon.fill")
                                        .font(.system(size: 12))
                                    Text("Sommeil")
                                        .font(.custom("Poppins-SemiBold", size: 12))
                                }
                                .foregroundColor(.white)
                                .offset(x: 126, y: 70)

                                // Énergie - Bottom
                                HStack(spacing: 4) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 12))
                                    Text("Énergie")
                                        .font(.custom("Poppins-SemiBold", size: 12))
                                }
                                .foregroundColor(.white)
                                .offset(x: 0, y: 143)

                                // Focus - Bottom left
                                HStack(spacing: 4) {
                                    Image(systemName: "target")
                                        .font(.system(size: 12))
                                    Text("Focus")
                                        .font(.custom("Poppins-SemiBold", size: 12))
                                }
                                .foregroundColor(.white)
                                .offset(x: -126, y: 70)

                                // Équilibre - Top left
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 12))
                                    Text("Équilibre")
                                        .font(.custom("Poppins-SemiBold", size: 12))
                                }
                                .foregroundColor(.white)
                                .offset(x: -126, y: -70)
                            }
                        }
                        .padding(.vertical, 48)

                        // Bottom spacing for buttons
                        Spacer(minLength: 120)
                    }
                }
            }

            // Action buttons at bottom
            VStack {
                Spacer()

                HStack(spacing: 12) {
                    // Skip button (red)
                    Button(action: {
                        HapticManager.medium()
                        onSkip()
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))

                            Text("Passer")
                                .font(.custom("Poppins-SemiBold", size: 16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color(hex: "FF3B30"))
                        )
                    }

                    // Validate button (green)
                    Button(action: {
                        HapticManager.success()
                        onValidate()
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))

                            Text("Valider")
                                .font(.custom("Poppins-SemiBold", size: 16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color(hex: "34C759"))
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateProgress = true
                }
            }
        }
    }

    // Helper function to get day labels
    private func getDayLabel(daysAgo: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).capitalized
    }

    // Helper function to convert impact areas to progress array for radar chart
    // Order: [Global, Sérénité, Sommeil, Énergie, Focus, Équilibre]
    private func getImpactProgress() -> [Double] {
        var progress: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

        // Map each impact to its position in the radar
        for impact in task.impactAreas {
            switch impact.title {
            case "Sérénité":
                progress[1] = Double(impact.increaseValue) / 30.0 // Normalize to 0-1 scale
            case "Sommeil":
                progress[2] = Double(impact.increaseValue) / 30.0
            case "Énergie":
                progress[3] = Double(impact.increaseValue) / 30.0
            case "Focus":
                progress[4] = Double(impact.increaseValue) / 30.0
            case "Équilibre":
                progress[5] = Double(impact.increaseValue) / 30.0
            default:
                break
            }
        }

        // Calculate Global as average of the 5 specific domains only
        let domainValues = Array(progress[1...5])
        let nonZeroDomains = domainValues.filter { $0 > 0 }
        if !nonZeroDomains.isEmpty {
            progress[0] = nonZeroDomains.reduce(0, +) / Double(nonZeroDomains.count)
        }

        return progress
    }
}

// MARK: - Impact Stat Card

struct ImpactStatCard: View {
    let icon: String
    let title: String
    let increase: Int
    let color: Color
    let animateProgress: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon on the left
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32, height: 32)

            // Title on the right
            Text(title)
                .font(.custom("Poppins-SemiBold", size: 14))
                .foregroundColor(.white)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.15),
                            color.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Models

struct HabitTask: Identifiable {
    var id: String { title } // Use title as unique identifier
    let title: String
    let frequency: String  // Kept for compatibility
    let duration: String    // Ex: "30 min" or "2.5L"
    let frequencyText: String  // Ex: "3x/sem" or "Quotidien"
    let difficulty: Int
    let streak: Int
    let imageName: String
    let totalCompletions: Int
    let last7Days: [Bool] // true if completed that day
    let impactAreas: [ImpactArea]

    // Static function to generate impact areas based on habit image name
    static func getImpactAreas(for imageName: String) -> [ImpactArea] {
        // Normalize image name to base habit type
        let normalizedName: String
        if imageName.starts(with: "habit_sport") {
            normalizedName = "habit_sport"
        } else if imageName.starts(with: "habit_nature") {
            normalizedName = "habit_nature"
        } else if imageName.starts(with: "habit_social") {
            normalizedName = "habit_social"
        } else if imageName.starts(with: "habit_sleep") {
            normalizedName = "habit_sleep"
        } else {
            normalizedName = imageName
        }

        switch normalizedName {
        case "task_breathe", "habit_breathe":
            return [
                ImpactArea(icon: "leaf.fill", title: "Sérénité", increaseValue: 18, color: Color(hex: "9B59B6")),
                ImpactArea(icon: "bolt.fill", title: "Énergie", increaseValue: 12, color: Color(hex: "1ABC9C")),
                ImpactArea(icon: "target", title: "Focus", increaseValue: 10, color: Color(hex: "2ECC71")),
                ImpactArea(icon: "moon.fill", title: "Sommeil", increaseValue: 8, color: Color(hex: "E74C3C"))
            ]

        case "task_meditate", "habit_meditate":
            return [
                ImpactArea(icon: "leaf.fill", title: "Sérénité", increaseValue: 20, color: Color(hex: "9B59B6")),
                ImpactArea(icon: "target", title: "Focus", increaseValue: 18, color: Color(hex: "2ECC71")),
                ImpactArea(icon: "heart.fill", title: "Équilibre", increaseValue: 15, color: Color(hex: "3498DB")),
                ImpactArea(icon: "moon.fill", title: "Sommeil", increaseValue: 10, color: Color(hex: "E74C3C"))
            ]

        case "task_journal", "habit_journal":
            return [
                ImpactArea(icon: "heart.fill", title: "Équilibre", increaseValue: 20, color: Color(hex: "3498DB")),
                ImpactArea(icon: "leaf.fill", title: "Sérénité", increaseValue: 15, color: Color(hex: "9B59B6")),
                ImpactArea(icon: "target", title: "Focus", increaseValue: 12, color: Color(hex: "2ECC71")),
                ImpactArea(icon: "moon.fill", title: "Sommeil", increaseValue: 8, color: Color(hex: "E74C3C"))
            ]

        case "task_sport", "habit_sport":
            return [
                ImpactArea(icon: "bolt.fill", title: "Énergie", increaseValue: 22, color: Color(hex: "1ABC9C")),
                ImpactArea(icon: "moon.fill", title: "Sommeil", increaseValue: 15, color: Color(hex: "E74C3C")),
                ImpactArea(icon: "leaf.fill", title: "Sérénité", increaseValue: 12, color: Color(hex: "9B59B6")),
                ImpactArea(icon: "heart.fill", title: "Équilibre", increaseValue: 10, color: Color(hex: "3498DB"))
            ]

        case "task_water", "habit_water":
            return [
                ImpactArea(icon: "bolt.fill", title: "Énergie", increaseValue: 15, color: Color(hex: "1ABC9C")),
                ImpactArea(icon: "target", title: "Focus", increaseValue: 15, color: Color(hex: "2ECC71")),
                ImpactArea(icon: "leaf.fill", title: "Sérénité", increaseValue: 8, color: Color(hex: "9B59B6")),
                ImpactArea(icon: "moon.fill", title: "Sommeil", increaseValue: 6, color: Color(hex: "E74C3C"))
            ]

        case "task_nature", "habit_nature":
            return [
                ImpactArea(icon: "leaf.fill", title: "Sérénité", increaseValue: 20, color: Color(hex: "9B59B6")),
                ImpactArea(icon: "bolt.fill", title: "Énergie", increaseValue: 15, color: Color(hex: "1ABC9C")),
                ImpactArea(icon: "heart.fill", title: "Équilibre", increaseValue: 12, color: Color(hex: "3498DB")),
                ImpactArea(icon: "moon.fill", title: "Sommeil", increaseValue: 10, color: Color(hex: "E74C3C"))
            ]

        case "task_sleep", "habit_sleep":
            return [
                ImpactArea(icon: "moon.fill", title: "Sommeil", increaseValue: 25, color: Color(hex: "E74C3C")),
                ImpactArea(icon: "bolt.fill", title: "Énergie", increaseValue: 20, color: Color(hex: "1ABC9C")),
                ImpactArea(icon: "target", title: "Focus", increaseValue: 18, color: Color(hex: "2ECC71")),
                ImpactArea(icon: "heart.fill", title: "Équilibre", increaseValue: 12, color: Color(hex: "3498DB"))
            ]

        case "task_social", "habit_social":
            return [
                ImpactArea(icon: "heart.fill", title: "Équilibre", increaseValue: 22, color: Color(hex: "3498DB")),
                ImpactArea(icon: "leaf.fill", title: "Sérénité", increaseValue: 18, color: Color(hex: "9B59B6")),
                ImpactArea(icon: "bolt.fill", title: "Énergie", increaseValue: 10, color: Color(hex: "1ABC9C")),
                ImpactArea(icon: "target", title: "Focus", increaseValue: 8, color: Color(hex: "2ECC71"))
            ]

        default:
            // Default fallback
            return [
                ImpactArea(icon: "star.fill", title: "Bien-être", increaseValue: 10, color: Color(hex: "B794F6"))
            ]
        }
    }
}

struct ImpactArea {
    let icon: String
    let title: String
    let increaseValue: Int
    let color: Color
}

// MARK: - Preview

#Preview {
    let mockTask = HabitTask(
        title: "S'hydrater régulièrement",
        frequency: "2.5L",
        duration: "2.5L",
        frequencyText: "Quotidien",
        difficulty: 1,
        streak: 17,
        imageName: "habit_water",
        totalCompletions: 24,
        last7Days: [true, true, false, true, true, true, true],
        impactAreas: HabitTask.getImpactAreas(for: "habit_water")
    )

    HabitTaskDetailView(
        task: mockTask,
        onValidate: { print("Validated") },
        onSkip: { print("Skipped") }
    )
}
