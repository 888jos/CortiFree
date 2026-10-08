//
//  HabitTaskDetailView.swift
//  CortiFree
//
//  Created by Claude on 14/11/2025.
//  Vue détaillée d'une tâche d'habitude : progression et validation
//

import SwiftUI

struct HabitTaskDetailView: View {
    let task: HabitTask
    let onValidate: () -> Void
    let onSkip: () -> Void
    var isCurrentDay: Bool = true // Defaults to true for backwards compatibility
    @Environment(\.dismiss) private var dismiss

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

                        Text(LanguageManager.shared.localizedString(for: "task.detail.days"))
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
                            .font(.faroBold(28))
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

                        // Plan progress: one square per plan day, one row per week
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LanguageManager.shared.localizedString(for: "task.detail.progression_plan"))
                                        .font(.custom("Poppins-SemiBold", size: 16))
                                        .foregroundColor(.white)

                                    Text("\(scheduledCount) \(LanguageManager.shared.localizedString(for: "task.detail.occurrences"))")
                                        .font(.custom("Poppins-Regular", size: 11))
                                        .foregroundColor(Color(hex: "B794F6"))
                                }

                                Spacer()

                                HStack(spacing: 4) {
                                    Text("\(doneCount)")
                                        .font(Font.Poppins.custom(.bold, size: 14))
                                        .foregroundColor(.white)

                                    Text(LanguageManager.shared.localizedString(for: "task.detail.total"))
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

                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7),
                                spacing: 6
                            ) {
                                ForEach(Array(task.planDays.enumerated()), id: \.offset) { _, day in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(squareColor(for: day))
                                        .aspectRatio(1, contentMode: .fit)
                                }
                            }
                        }
                        .frame(width: 240)
                        .padding(.horizontal, 24)

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

                            Text(LanguageManager.shared.localizedString(for: "task.detail.button.skip"))
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

                            Text(LanguageManager.shared.localizedString(for: "task.detail.button.validate"))
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
    }

    private var scheduledCount: Int { task.planDays.filter { $0 != .off }.count }
    private var doneCount: Int { task.planDays.filter { $0 == .done }.count }

    private func squareColor(for day: HabitPlanDay) -> Color {
        switch day {
        case .done: return Color(hex: "B794F6")
        case .today: return Color(hex: "B794F6").opacity(0.5)
        case .missed, .upcoming: return Color.white.opacity(0.2)
        case .off: return Color.white.opacity(0.05)
        }
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
    /// One entry per plan day (1...28) for the progress grid.
    var planDays: [HabitPlanDay] = []
}

enum HabitPlanDay: Equatable {
    case off       // habit not scheduled that day
    case done
    case today     // scheduled today, not done yet
    case missed
    case upcoming
}

// MARK: - Preview

#Preview {
    let mockTask = HabitTask(
        title: "Stay Hydrated",
        frequency: "2.5L",
        duration: "2.5L",
        frequencyText: "Daily",
        difficulty: 1,
        streak: 17,
        imageName: "habit_water",
        totalCompletions: 24,
        last7Days: [true, true, false, true, true, true, true],
        completedDays: [1, 2, 4, 5, 6, 7],
        planDays: (1...28).map { $0 % 3 == 0 ? .off : ($0 < 10 ? .done : ($0 == 10 ? .today : .upcoming)) }
    )

    HabitTaskDetailView(
        task: mockTask,
        onValidate: { print("Validated") },
        onSkip: { print("Skipped") }
    )
    .environment(\.locale, Locale(identifier: "en"))
}
