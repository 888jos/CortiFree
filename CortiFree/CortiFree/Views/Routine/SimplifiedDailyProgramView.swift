//
//  SimplifiedDailyProgramView.swift
//  CortiFree
//
//  Created by Claude on 10/11/2025.
//  Daily program view using TaskDetail from JSON database
//

import SwiftUI

struct SimplifiedDailyProgramView: View {
    let routine: RoutinePlan
    let dayNumber: Int

    @ObservedObject private var taskManager = TaskManager.shared
    @State private var dailyProgram: SimplifiedDailyProgram?
    @State private var tasks: [TaskDetail] = []
    @State private var completedTaskIds: Set<String> = []
    @State private var totalXPEarned: Int = 0
    @State private var showCheckpointCelebration: Bool = false
    @State private var animateIn: Bool = false

    private var allTasksCompleted: Bool {
        guard !tasks.isEmpty else { return false }
        return tasks.allSatisfy { completedTaskIds.contains($0.id) }
    }

    private var progressPercentage: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTaskIds.count) / Double(tasks.count)
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.6)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Progress card
                    progressCard

                    // Focus area
                    if let program = dailyProgram {
                        focusAreaCard(program: program)
                    }

                    // Tasks list
                    tasksSection

                    // Checkpoint celebration
                    if let program = dailyProgram, program.checkpointDay {
                        checkpointSection(program: program)
                    }

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Jour \(dayNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadProgram()
            withAnimation(.easeOut(duration: 0.6)) {
                animateIn = true
            }
        }
        .alert("Checkpoint Atteint!", isPresented: $showCheckpointCelebration) {
            Button("Continuer") {
                showCheckpointCelebration = false
            }
        } message: {
            if let program = dailyProgram {
                Text("Félicitations! Tu as complété toutes les tâches du jour et gagné +\(program.bonusXP) XP bonus!")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Routine info
            HStack(spacing: 12) {
                Image(routine.planetAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.title)
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundColor(.white)

                    Text("Semaine \(((dayNumber - 1) / 7) + 1) • Jour \(dayNumber)/66")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -20)
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        VStack(spacing: 16) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [routine.color, routine.color.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressPercentage, height: 12)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressPercentage)
                }
            }
            .frame(height: 12)

            // Stats
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(completedTaskIds.count)/\(tasks.count)")
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundColor(.white)

                    Text("Tâches complétées")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }

                Divider()
                    .frame(height: 50)
                    .background(Color.white.opacity(0.2))

                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                        Text("\(totalXPEarned)")
                            .font(.custom("Poppins-Bold", size: 24))
                    }
                    .foregroundColor(Color(hex: "FFD700"))

                    Text("XP gagnés")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(routine.color.opacity(0.3), lineWidth: 1)
                )
        )
        .opacity(animateIn ? 1 : 0)
        .scaleEffect(animateIn ? 1 : 0.9)
    }

    // MARK: - Focus Area Card

    private func focusAreaCard(program: SimplifiedDailyProgram) -> some View {
        let weeklyObjective = WeeklyObjective(rawValue: program.week)

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Weekly objective icon
                ZStack {
                    Circle()
                        .fill(weeklyObjective?.color.opacity(0.2) ?? routine.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: weeklyObjective?.icon ?? "target")
                        .font(.system(size: 24))
                        .foregroundColor(weeklyObjective?.color ?? routine.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Semaine \(program.week) • Focus")
                        .font(.custom("Poppins-SemiBold", size: 11))
                        .foregroundColor(.white.opacity(0.6))

                    Text(program.focusArea)
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(.white)
                }

                Spacer()
            }

            // Weekly objective description
            if let objective = weeklyObjective {
                Text(objective.description)
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            (weeklyObjective?.color ?? routine.color).opacity(0.25),
                            (weeklyObjective?.color ?? routine.color).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke((weeklyObjective?.color ?? routine.color).opacity(0.4), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Tasks Section

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tâches d'aujourd'hui")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)

            VStack(spacing: 12) {
                ForEach(tasks) { task in
                    TaskCard(
                        task: task,
                        isCompleted: completedTaskIds.contains(task.id),
                        routineColor: routine.color,
                        onToggle: {
                            toggleTask(task)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Checkpoint Section

    private func checkpointSection(program: SimplifiedDailyProgram) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "FFD700"))

                Text("Jour Checkpoint")
                    .font(.custom("Poppins-Bold", size: 18))
                    .foregroundColor(.white)
            }

            Text("Complète toutes les tâches pour gagner +\(program.bonusXP) XP bonus!")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            if allTasksCompleted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                    Text("Checkpoint complété! +\(program.bonusXP) XP")
                        .font(.custom("Poppins-SemiBold", size: 16))
                }
                .foregroundColor(.green)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFD700").opacity(0.2),
                            Color(hex: "FFD700").opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "FFD700").opacity(0.4), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Load Program

    private func loadProgram() {
        let generator = RoutineProgramGenerator.shared
        let program = generator.generateUniversalProgram()

        if let dayProgram = program.getDayProgram(dayNumber) {
            self.dailyProgram = dayProgram

            // Load tasks from TaskManager
            self.tasks = taskManager.getTasks(byIds: dayProgram.taskIds)

            // Load completed status from UserDefaults (simple storage for now)
            loadCompletedTasks()
        }
    }

    private func loadCompletedTasks() {
        let key = "completed_\(routine.id)_day\(dayNumber)"
        if let data = UserDefaults.standard.data(forKey: key),
           let completed = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.completedTaskIds = completed
            calculateTotalXP()
        }
    }

    private func saveCompletedTasks() {
        let key = "completed_\(routine.id)_day\(dayNumber)"
        if let data = try? JSONEncoder().encode(completedTaskIds) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: - Toggle Task

    private func toggleTask(_ task: TaskDetail) {
        if completedTaskIds.contains(task.id) {
            // Uncomplete
            completedTaskIds.remove(task.id)
            totalXPEarned -= task.xp
        } else {
            // Complete
            completedTaskIds.insert(task.id)
            totalXPEarned += task.xp
            HapticManager.success()

            // XP system removed - using scoring system instead

            // Check if all tasks completed and checkpoint exists
            if allTasksCompleted, let program = dailyProgram, program.checkpointDay {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    totalXPEarned += program.bonusXP
                    // XP system removed - using scoring system instead
                    showCheckpointCelebration = true
                }
            }
        }

        saveCompletedTasks()
    }

    private func calculateTotalXP() {
        totalXPEarned = tasks.filter { completedTaskIds.contains($0.id) }.reduce(0) { $0 + $1.xp }

        // Add checkpoint bonus if completed
        if allTasksCompleted, let program = dailyProgram, program.checkpointDay {
            totalXPEarned += program.bonusXP
        }
    }
}

// MARK: - Task Card

struct TaskCard: View {
    let task: TaskDetail
    let isCompleted: Bool
    let routineColor: Color
    let onToggle: () -> Void

    @State private var showDetail: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            Button(action: onToggle) {
                HStack(spacing: 16) {
                    // Checkbox
                    ZStack {
                        Circle()
                            .stroke(isCompleted ? routineColor : Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 28, height: 28)

                        if isCompleted {
                            Circle()
                                .fill(routineColor)
                                .frame(width: 28, height: 28)

                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }

                    // Icon
                    ZStack {
                        Circle()
                            .fill(task.categoryType.color.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: task.icon)
                            .font(.system(size: 18))
                            .foregroundColor(task.categoryType.color)
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.custom("Poppins-SemiBold", size: 15))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        HStack(spacing: 12) {
                            // Duration
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 10))
                                Text("\(task.durationMinutes) min")
                                    .font(.custom("Poppins-Medium", size: 11))
                            }

                            // XP
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                Text("\(task.xp) XP")
                                    .font(.custom("Poppins-Medium", size: 11))
                            }
                            .foregroundColor(Color(hex: "FFD700"))

                            // Category
                            Text(task.categoryType.displayName)
                                .font(.custom("Poppins-Medium", size: 10))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(task.categoryType.color.opacity(0.3))
                                )
                        }
                        .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    // Info button
                    Button(action: { showDetail.toggle() }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(routineColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())

            // Expandable detail
            if showDetail {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.2))

                    // Description
                    Text(task.description)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.8))

                    // Instructions button (TODO: Create TaskInstructionsView)
                    // NavigationLink(destination: TaskInstructionsView(task: task)) {
                    Button(action: {
                        // TODO: Navigate to instructions
                    }) {
                        HStack {
                            Text("Voir les instructions")
                                .font(.custom("Poppins-SemiBold", size: 13))

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(routineColor)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: isCompleted ? [
                            routineColor.opacity(0.2),
                            routineColor.opacity(0.1)
                        ] : [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isCompleted ? routineColor.opacity(0.4) : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.3), value: showDetail)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SimplifiedDailyProgramView(
            routine: RoutinePlan.allPlans[0],
            dayNumber: 1
        )
    }
}
