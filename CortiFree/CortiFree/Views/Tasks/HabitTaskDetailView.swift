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
    var isCurrentDay: Bool = true // Defaults to true for backwards compatibility
    @Environment(\.dismiss) private var dismiss
    @State private var animateProgress: Bool = false

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)

            VStack(spacing: 0) {
                // Header with back button and streak (fixed)
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

                    // Streak indicator
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "FF8800"))

                        Text("\(task.streak)")
                            .font(Font.Poppins.custom(.bold, size: 20))
                            .foregroundColor(.white)

                        Text(NSLocalizedString("task.detail.days", comment: ""))
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Title only
                        Text(task.title)
                            .font(Font.Poppins.custom(.bold, size: 28))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(hex: "B794F6")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 8)

                        // Progress section - width matches hexagon labels span
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(NSLocalizedString("task.detail.progression_66_days", comment: ""))
                                        .font(.custom("Poppins-SemiBold", size: 16))
                                        .foregroundColor(.white)

                                    let occurrenceDays = getExpectedOccurrenceDays()

                                    Text("\(occurrenceDays.count) \(NSLocalizedString("task.detail.occurrences", comment: ""))")
                                        .font(.custom("Poppins-Regular", size: 11))
                                        .foregroundColor(Color(hex: "B794F6"))
                                }

                                Spacer()

                                // Total completions - Top right in rectangle
                                HStack(spacing: 4) {
                                    Text("\(task.totalCompletions)")
                                        .font(Font.Poppins.custom(.bold, size: 14))
                                        .foregroundColor(.white)

                                    Text(NSLocalizedString("task.detail.this_month", comment: ""))
                                        .font(.custom("Poppins-Regular", size: 10))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(hex: "B794F6").opacity(0.2))
                                )
                            }

                            // Grid of squares - aligned to leading
                            let occurrenceDays = getExpectedOccurrenceDays()

                            LazyVGrid(
                                columns: Array(repeating: GridItem(.fixed(12), spacing: 3), count: 12),
                                alignment: .leading,
                                spacing: 3
                            ) {
                                ForEach(occurrenceDays, id: \.self) { day in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(squareColor(for: day))
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                        .frame(width: 240) // Width from heart icon to end of Sérénité
                        .padding(.horizontal, 24)

                        // Impact section title - centered
                        VStack(spacing: 4) {
                            Text(NSLocalizedString("task.detail.habit_improves", comment: ""))
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.white)

                            Text(NSLocalizedString("task.detail.cortifree_score_domains", comment: ""))
                                .font(.custom("Poppins-Regular", size: 11))
                                .foregroundColor(Color(hex: "B794F6"))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)

                        // Radar chart for 6 CortiFree domains (reduced x0.75)
                        ZStack {
                            // Background hexagon grid
                            HexagonRadarGrid()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                .frame(width: 178, height: 178)

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
                                .frame(width: 178, height: 178)

                            // Stroke around the filled hexagon - positioned outside
                            HexagonRadarFill(progress: getImpactProgress())
                                .stroke(
                                    Color(hex: "B794F6").opacity(0.5),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                )
                                .frame(width: 178, height: 178)

                            // Labels at hexagon vertices (adjusted for x0.75 reduction)
                            ZStack {
                                // Global - Top
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 11))
                                    Text(NSLocalizedString("task.detail.domain.global", comment: ""))
                                        .font(.custom("Poppins-SemiBold", size: 11))
                                }
                                .foregroundColor(.white)
                                .offset(x: 0, y: -107)

                                // Sérénité - Top right
                                HStack(spacing: 4) {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 11))
                                    Text(NSLocalizedString("task.detail.domain.serenity", comment: ""))
                                        .font(.custom("Poppins-SemiBold", size: 11))
                                }
                                .foregroundColor(.white)
                                .offset(x: 95, y: -52)

                                // Sommeil - Bottom right
                                HStack(spacing: 4) {
                                    Image(systemName: "moon.fill")
                                        .font(.system(size: 11))
                                    Text(NSLocalizedString("task.detail.domain.sleep", comment: ""))
                                        .font(.custom("Poppins-SemiBold", size: 11))
                                }
                                .foregroundColor(.white)
                                .offset(x: 95, y: 52)

                                // Énergie - Bottom
                                HStack(spacing: 4) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 11))
                                    Text(NSLocalizedString("task.detail.domain.energy", comment: ""))
                                        .font(.custom("Poppins-SemiBold", size: 11))
                                }
                                .foregroundColor(.white)
                                .offset(x: 0, y: 107)

                                // Focus - Bottom left
                                HStack(spacing: 4) {
                                    Image(systemName: "target")
                                        .font(.system(size: 11))
                                    Text(NSLocalizedString("task.detail.domain.focus", comment: ""))
                                        .font(.custom("Poppins-SemiBold", size: 11))
                                }
                                .foregroundColor(.white)
                                .offset(x: -95, y: 52)

                                // Équilibre - Top left
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 11))
                                    Text(NSLocalizedString("task.detail.domain.balance", comment: ""))
                                        .font(.custom("Poppins-SemiBold", size: 11))
                                }
                                .foregroundColor(.white)
                                .offset(x: -95, y: -52)
                            }
                        }
                        .padding(.vertical, 32)

                        // Bottom spacing for buttons
                        Spacer(minLength: 120)
                    }
                }
            }

            // Action buttons at bottom
            VStack {
                Spacer()

                HStack(spacing: 12) {
                    // Skip button (red when active, gray when disabled)
                    Button(action: {
                        guard isCurrentDay else { return }
                        HapticManager.medium()
                        onSkip()
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))

                            Text(NSLocalizedString("task.detail.button.skip", comment: ""))
                                .font(.custom("Poppins-SemiBold", size: 16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(isCurrentDay ? Color(hex: "FF3B30") : Color.gray.opacity(0.5))
                        )
                    }
                    .disabled(!isCurrentDay)

                    // Validate button (green when active, gray when disabled)
                    Button(action: {
                        guard isCurrentDay else { return }
                        HapticManager.success()
                        onValidate()
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))

                            Text(NSLocalizedString("task.detail.button.validate", comment: ""))
                                .font(.custom("Poppins-SemiBold", size: 16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(isCurrentDay ? Color(hex: "34C759") : Color.gray.opacity(0.5))
                        )
                    }
                    .disabled(!isCurrentDay)
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

    // Helper function to calculate expected occurrence days based on frequency
    private func getExpectedOccurrenceDays() -> [Int] {
        var days: [Int] = []
        let habitId = getHabitId(for: task.imageName)

        for day in 1...66 {
            let week = WeeklyHabitProgression.currentWeek(for: day)
            let dayOfWeek = (day - 1) % 7 // 0 = Monday, 6 = Sunday

            // Get frequency for this week from progression
            let progression = getProgressionForHabit(habitId, week: week)

            // Check if habit should be done this day
            if shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: progression) {
                days.append(day)
            }
        }
        return days
    }

    // Helper to get progression for a specific habit and week
    private func getProgressionForHabit(_ habitId: String, week: Int) -> Int {
        switch habitId {
        case "sleep":
            return WeeklyHabitProgression.sleepProgression(week: week).frequencyPerWeek
        case "water":
            return WeeklyHabitProgression.waterProgression(week: week).frequencyPerWeek
        case "journal":
            return WeeklyHabitProgression.journalProgression(week: week).frequencyPerWeek
        case "breathing":
            return WeeklyHabitProgression.breathingProgression(week: week).frequencyPerWeek
        case "meditation":
            return WeeklyHabitProgression.meditationProgression(week: week).frequencyPerWeek
        case "sport":
            return WeeklyHabitProgression.sportProgression(week: week).frequencyPerWeek
        case "nature":
            return WeeklyHabitProgression.natureProgression(week: week).frequencyPerWeek
        case "social":
            return WeeklyHabitProgression.socialProgression(week: week).frequencyPerWeek
        default:
            return 7
        }
    }

    // Helper to check if task should show on a specific day based on frequency
    private func shouldShowTask(dayOfWeek: Int, frequencyPerWeek: Int) -> Bool {
        switch frequencyPerWeek {
        case 7: return true // Every day
        case 6: return dayOfWeek != 0 // All except Monday
        case 5: return ![6, 3].contains(dayOfWeek) // All except Sunday and Thursday
        case 4: return ![2, 5].contains(dayOfWeek) // All except Wednesday and Saturday
        case 3: return [0, 2, 5].contains(dayOfWeek) // Monday, Wednesday, Saturday
        case 2: return [1, 4].contains(dayOfWeek) // Tuesday, Friday
        case 1: return dayOfWeek == 2 // Wednesday only
        default: return false
        }
    }

    // Helper to determine grid columns based on number of squares
    private func getGridColumns(for count: Int) -> Int {
        if count <= 40 {
            return 8 // Like AvatarProgressCard
        } else if count <= 80 {
            return 10
        } else {
            return 12 // For habits like Sleep with 66 squares
        }
    }

    // Helper to get square color based on completion status
    private func squareColor(for day: Int) -> Color {
        let currentDay = UserDefaults.standard.integer(forKey: "currentDay")

        // Get the occurrence days for this habit to verify day is valid
        let occurrenceDays = getExpectedOccurrenceDays()
        guard occurrenceDays.contains(day) else {
            return Color.white.opacity(0.2)
        }

        // Check if this program day has been completed
        if task.completedDays.contains(day) {
            return Color(hex: "B794F6") // Validated - violet 100%
        } else if day == currentDay {
            return Color(hex: "B794F6").opacity(0.5) // Current day not validated - violet 50%
        } else {
            return Color.white.opacity(0.2) // Not validated or future day - white 20%
        }
    }

    // Helper function to convert impact areas to progress array for radar chart
    // Order: [Global, Sérénité, Sommeil, Énergie, Focus, Équilibre]
    private func getImpactProgress() -> [Double] {
        // Get the real impact weights from HabitImpactWeights
        let habitId = getHabitId(for: task.imageName)
        let impact = HabitImpactWeights.impactForHabit(habitId)

        // Normalize weights to 0-1 scale for radar chart display
        // Max weight per task ≈ 0.3 (some habits have higher weights)
        // We'll use 65 as max since that's the total progression over 66 days
        // But for display, we normalize relative to the strongest impact
        let maxWeight = max(impact.serenity, impact.sleep, impact.energy, impact.focus, impact.balance, 0.001)

        let normalizedSerenity = impact.serenity / maxWeight
        let normalizedSleep = impact.sleep / maxWeight
        let normalizedEnergy = impact.energy / maxWeight
        let normalizedFocus = impact.focus / maxWeight
        let normalizedBalance = impact.balance / maxWeight

        // Global is the average of all domains
        let global = (normalizedSerenity + normalizedSleep + normalizedEnergy + normalizedFocus + normalizedBalance) / 5.0

        return [global, normalizedSerenity, normalizedSleep, normalizedEnergy, normalizedFocus, normalizedBalance]
    }

    // Helper to map image name to habit ID
    private func getHabitId(for imageName: String) -> String {
        if imageName.contains("sleep") || imageName.contains("sommeil") {
            return "sleep"
        } else if imageName.contains("breathe") || imageName.contains("respir") {
            return "breathing"
        } else if imageName.contains("meditate") || imageName.contains("médita") {
            return "meditation"
        } else if imageName.contains("water") || imageName.contains("eau") {
            return "water"
        } else if imageName.contains("sport") || imageName.contains("exercice") {
            return "sport"
        } else if imageName.contains("nature") {
            return "nature"
        } else if imageName.contains("social") || imageName.contains("ami") {
            return "social"
        } else if imageName.contains("journal") {
            return "journal"
        }
        return "unknown"
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
    let completedDays: [Int] // Program days completed (1-66+)
    let impactAreas: [ImpactArea]

    // Static function to generate impact areas based on habit image name
    // Uses real impact weights from HabitImpactWeights
    static func getImpactAreas(for imageName: String) -> [ImpactArea] {
        // Map image name to habit ID
        let habitId: String
        if imageName.contains("sleep") || imageName.contains("sommeil") {
            habitId = "sleep"
        } else if imageName.contains("breathe") || imageName.contains("respir") {
            habitId = "breathing"
        } else if imageName.contains("meditate") || imageName.contains("médita") {
            habitId = "meditation"
        } else if imageName.contains("water") || imageName.contains("eau") {
            habitId = "water"
        } else if imageName.contains("sport") || imageName.contains("exercice") {
            habitId = "sport"
        } else if imageName.contains("nature") {
            habitId = "nature"
        } else if imageName.contains("social") || imageName.contains("ami") {
            habitId = "social"
        } else if imageName.contains("journal") {
            habitId = "journal"
        } else {
            habitId = "unknown"
        }

        // Get real impact weights
        let impact = HabitImpactWeights.impactForHabit(habitId)

        // Convert weights to ImpactArea array
        // Scale weights to display values (multiply by ~100 for better visual)
        // Sort by descending impact value to show most important first
        var areas = [
            ImpactArea(icon: "leaf.fill", title: "Sérénité", increaseValue: Int(impact.serenity * 100), color: Color(hex: "9B59B6")),
            ImpactArea(icon: "moon.fill", title: "Sommeil", increaseValue: Int(impact.sleep * 100), color: Color(hex: "E74C3C")),
            ImpactArea(icon: "bolt.fill", title: "Énergie", increaseValue: Int(impact.energy * 100), color: Color(hex: "1ABC9C")),
            ImpactArea(icon: "target", title: "Focus", increaseValue: Int(impact.focus * 100), color: Color(hex: "2ECC71")),
            ImpactArea(icon: "heart.fill", title: "Équilibre", increaseValue: Int(impact.balance * 100), color: Color(hex: "3498DB"))
        ]

        // Sort by impact value (descending) and keep only top 4
        areas.sort { $0.increaseValue > $1.increaseValue }
        return Array(areas.prefix(4))
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
        completedDays: [1, 2, 4, 5, 6, 7],
        impactAreas: HabitTask.getImpactAreas(for: "habit_water")
    )

    HabitTaskDetailView(
        task: mockTask,
        onValidate: { print("Validated") },
        onSkip: { print("Skipped") }
    )
}
