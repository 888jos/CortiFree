//
//  TasksView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Rewritten with exact design specifications
//

import SwiftUI
import Lottie

struct TasksView: View {
    @StateObject private var viewModel = TasksViewModel()
    @State private var showAddTaskView = false
    @State private var selectedTask: TaskItem? = nil

    // Expansion state for each period
    @State private var showMorningTasks = true
    @State private var showDayTasks = true
    @State private var showNightTasks = true

    // Computed property that gets all tasks from ViewModel, sorted chronologically
    private var allTasksSorted: [TaskItem] {
        return viewModel.tasks.sorted { task1, task2 in
            guard let time1 = task1.recommendedTime,
                  let time2 = task2.recommendedTime else {
                return false
            }
            return time1 < time2
        }
    }

    // Tasks grouped by category
    private var morningTasks: [TaskItem] {
        viewModel.morningTasks.sorted { task1, task2 in
            guard let time1 = task1.recommendedTime,
                  let time2 = task2.recommendedTime else {
                return false
            }
            return time1 < time2
        }
    }

    private var dayTasks: [TaskItem] {
        viewModel.dayTasks.sorted { task1, task2 in
            guard let time1 = task1.recommendedTime,
                  let time2 = task2.recommendedTime else {
                return false
            }
            return time1 < time2
        }
    }

    private var nightTasks: [TaskItem] {
        viewModel.nightTasks.sorted { task1, task2 in
            guard let time1 = task1.recommendedTime,
                  let time2 = task2.recommendedTime else {
                return false
            }
            return time1 < time2
        }
    }

    // Total count of all tasks
    private var totalTaskCount: Int {
        viewModel.totalCount
    }

    // Completed count of all tasks
    private var completedTaskCount: Int {
        viewModel.completedCount
    }

    // Completion percentage
    private var completionPercentage: Double {
        viewModel.completionPercentage
    }

    // Static sample tasks with recommended times (sorted chronologically)
    // These are now loaded from Firebase instead of being local only
    private static let defaultTaskTemplates: [TaskItem] = [
        TaskItem(
            id: "task-breathing-478",
            title: "Respiration 4-7-8",
            category: .morning,
            taskFrequency: .daily,
            customCategory: .breathing,
            durationInMinutes: 5,
            isCustomTask: false,
            sfSymbol: "wind",
            recommendedTime: "07:00",
            taskDescription: "La technique de respiration 4-7-8 active le système nerveux parasympathique, réduisant instantanément les niveaux de cortisol. En inspirant 4 secondes, retenant 7 secondes et expirant 8 secondes, vous signalez à votre corps qu'il est en sécurité. Cette pratique matinale programme votre journée en mode calme plutôt qu'en mode stress."
        ),
        TaskItem(
            id: "task-meditation-5min",
            title: "Méditer 5 minutes",
            category: .morning,
            taskFrequency: .daily,
            customCategory: .mental,
            durationInMinutes: 5,
            isCustomTask: false,
            sfSymbol: "figure.mind.and.body",
            recommendedTime: "08:00",
            taskDescription: "La méditation matinale réduit le cortisol jusqu'à 20% selon des études scientifiques. Elle renforce votre capacité à gérer le stress tout au long de la journée en créant un espace mental de recul. Même 5 minutes suffisent pour recalibrer votre système nerveux et améliorer votre régulation émotionnelle face aux défis quotidiens."
        ),
        TaskItem(
            id: "task-water-glass",
            title: "Boire un verre d'eau",
            category: .day,
            taskFrequency: .daily,
            customCategory: .nutrition,
            durationInMinutes: 2,
            isCustomTask: false,
            sfSymbol: "drop.fill",
            recommendedTime: "12:00",
            taskDescription: "La déshydratation, même légère, augmente la production de cortisol et amplifie la perception du stress. Votre cerveau est composé de 75% d'eau - le maintenir hydraté optimise vos fonctions cognitives et votre capacité à gérer l'anxiété. Un simple verre d'eau peut réduire les symptômes de stress en quelques minutes."
        ),
        TaskItem(
            id: "task-stretching",
            title: "S'étirer doucement",
            category: .day,
            taskFrequency: .daily,
            customCategory: .movement,
            durationInMinutes: 10,
            isCustomTask: false,
            sfSymbol: "figure.flexibility",
            recommendedTime: "15:00",
            taskDescription: "Les étirements doux libèrent les tensions musculaires accumulées par le stress et favorisent la circulation sanguine. Cette pratique envoie des signaux de détente au cerveau, réduisant la production de cortisol. En milieu d'après-midi, elle prévient l'accumulation de stress et maintient votre corps dans un état de relaxation active."
        ),
        TaskItem(
            id: "task-screens-off",
            title: "Éteindre les écrans",
            category: .night,
            taskFrequency: .daily,
            customCategory: .sleep,
            durationInMinutes: 5,
            isCustomTask: false,
            sfSymbol: "moonphase.waning.crescent",
            recommendedTime: "21:00",
            taskDescription: "La lumière bleue des écrans inhibe la mélatonine et stimule la production de cortisol, perturbant votre rythme circadien. Éteindre les écrans 1h avant le coucher permet à votre cerveau de se préparer naturellement au sommeil. Un sommeil de qualité est votre meilleure défense contre le stress chronique et l'anxiété."
        )
    ]

    var body: some View {
        ZStack {
            // Galaxy animated background
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea(.all)

            if viewModel.isLoading {
                ProgressView()
                    .tint(Color.appTheme)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Progress Header
                        progressHeader
                            .padding(.top, 60)

                        // Tasks Section Header
                        tasksHeaderSection
                            .padding(.top, 48)

                        // Task Categories - Grouped by period
                        VStack(spacing: 20) {
                            // Morning Tasks Section
                            if !morningTasks.isEmpty {
                                periodTasksSection(
                                    title: "Durant la matinée",
                                    icon: "sunrise.fill",
                                    tasks: morningTasks,
                                    isExpanded: $showMorningTasks
                                )
                            }

                            // Day Tasks Section
                            if !dayTasks.isEmpty {
                                periodTasksSection(
                                    title: "Durant la journée",
                                    icon: "sun.max.fill",
                                    tasks: dayTasks,
                                    isExpanded: $showDayTasks
                                )
                            }

                            // Night Tasks Section
                            if !nightTasks.isEmpty {
                                periodTasksSection(
                                    title: "Durant la soirée",
                                    icon: "moon.stars.fill",
                                    tasks: nightTasks,
                                    isExpanded: $showNightTasks
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        Spacer(minLength: 120)
                    }
                }
            }

            // Confetti overlay
            if viewModel.showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingAddButton {
                        showAddTaskView = true
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 100) // Increased to clear tabbar
                }
            }
        }
        .ignoresSafeArea(edges: [.top, .leading, .trailing])
        .refreshable {
            await viewModel.loadTasks()
        }
        .sheet(isPresented: $showAddTaskView) {
            AddTaskView(viewModel: viewModel)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task)
                .presentationBackground(.clear)
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        // Progress Circle (226px)
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(hex: "404040"), lineWidth: 26)
                .frame(width: 226, height: 226)

            // Progress arc with gradient stroke
            Circle()
                .trim(from: 0, to: completionPercentage)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.appTheme,
                            Color.appThemeSecondary
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 26, lineCap: .round)
                )
                .frame(width: 226, height: 226)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.75), value: completionPercentage)

            // Text content inside circle
            VStack(spacing: 8) {
                // PROGRÈS label
                Text("PROGRÈS")
                    .font(.custom("Poppins-Bold", size: 18))
                    .foregroundColor(.white)

                // Percentage text
                Text("\(Int(completionPercentage * 100))%")
                    .font(.custom("Poppins-Bold", size: 56))
                    .foregroundColor(.white)
                    .animation(.spring(response: 0.6, dampingFraction: 0.75), value: completionPercentage)
                    .contentTransition(.numericText())
            }
        }
    }

    // MARK: - Tasks Header Section

    private var tasksHeaderSection: some View {
        HStack {
            Text("Tâches à accomplir aujourd'hui")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)

            Spacer()

            Text("\(String(format: "%02d", completedTaskCount))/\(String(format: "%02d", totalTaskCount))")
                .font(.custom("Poppins-Medium", size: 16))
                .foregroundColor(Color.appTheme)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - All Tasks Section (Merged & Sorted)

    // MARK: - Period Tasks Section (Expandable)

    private func periodTasksSection(title: String, icon: String, tasks: [TaskItem], isExpanded: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - Always visible with chevron toggle - MORE PROMINENT
            Button(action: {
                HapticManager.light()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.wrappedValue.toggle()
                }
            }) {
                HStack(spacing: 14) {
                    // Period icon - BIGGER
                    ZStack {
                        Circle()
                            .fill(Color.appTheme.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.appTheme)
                    }

                    // Title - BIGGER
                    Text(title)
                        .font(.custom("Poppins-Bold", size: 20))
                        .foregroundColor(.white)

                    Spacer()

                    // Task count badge
                    Text("\(tasks.filter { $0.completed }.count)/\(tasks.count)")
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.appTheme.opacity(0.3))
                        )

                    // Chevron
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())

            // Tasks list - Expandable
            if isExpanded.wrappedValue {
                VStack(spacing: 6) {
                    ForEach(tasks) { task in
                        TaskRow(
                            task: task,
                            onComplete: {
                                // Toggle the completion state for all tasks via ViewModel/Firebase
                                Task {
                                    await viewModel.toggleTask(task)
                                }
                            },
                            onDelete: {
                                // Allow deletion only for custom tasks
                                if task.isCustomTask {
                                    Task {
                                        await viewModel.deleteTask(task)
                                    }
                                }
                            },
                            onTap: {
                                selectedTask = task
                            }
                        )
                    }
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Default Tasks Section

    private var defaultTasksSection: some View {
        VStack(spacing: 0) {
            // Default Tasks Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.appThemeSecondary)

                Text("Tâches recommandées")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)

                Spacer()

                Text("\(viewModel.defaultTasks.filter { $0.completed }.count)/\(viewModel.defaultTasks.count)")
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(Color.appThemeSecondary)
            }
            .frame(height: 48)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "2A2B5A").opacity(0.8),
                                Color(hex: "1F1F3F").opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )

            // Default Task List
            VStack(spacing: 8) {
                ForEach(viewModel.defaultTasks) { task in
                    TaskRow(
                        task: task,
                        onComplete: {
                            Task {
                                await viewModel.toggleTask(task)
                            }
                        },
                        onDelete: {
                            Task {
                                await viewModel.deleteTask(task)
                            }
                        }
                    )
                    .onTapGesture {
                        HapticManager.light()
                        selectedTask = task
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Custom Tasks Section

    private var customTasksSection: some View {
        VStack(spacing: 0) {
            // Custom Tasks Header
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.appTheme)

                Text("Mes tâches personnalisées")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)

                Spacer()

                Text("\(viewModel.customTasks.filter { $0.completed }.count)/\(viewModel.customTasks.count)")
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(Color.appTheme)
            }
            .frame(height: 48)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "49288C").opacity(0.4),
                                Color(hex: "2A2B5A").opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )

            // Custom Task List
            VStack(spacing: 0) {
                ForEach(viewModel.customTasks) { task in
                    CustomTaskRow(
                        task: task,
                        onToggle: {
                            Task {
                                await viewModel.toggleTask(task)
                            }
                        },
                        onDelete: {
                            Task {
                                await viewModel.deleteTask(task)
                            }
                        },
                        onTap: {
                            selectedTask = task
                        }
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "2A2B5A").opacity(0.5))
            )
            .padding(.top, 8)
        }
    }

    // MARK: - Task Category Section

    private func taskCategorySection(category: TaskCategory, categoryName: String, tasks: [TaskItem]) -> some View {
        VStack(spacing: 0) {
            // Category Header (48px)
            Button(action: {
                HapticManager.light()
                withAnimation(.spring(response: 0.3)) {
                    viewModel.toggleSection(category)
                }
            }) {
                HStack {
                    Text(categoryName)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: viewModel.isSectionExpanded(category) ? "chevron.down" : "chevron.up")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .frame(height: 48)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: viewModel.isSectionExpanded(category) ? 12 : 12)
                        .fill(Color(hex: "2A2B5A"))
                )
            }

            // Expanded Task List
            if viewModel.isSectionExpanded(category) {
                VStack(spacing: 0) {
                    ForEach(tasks) { task in
                        TaskRowDetailed(
                            task: task,
                            onToggle: {
                                Task {
                                    await viewModel.toggleTask(task)
                                }
                            },
                            onDelete: {
                                Task {
                                    await viewModel.deleteTask(task)
                                }
                            },
                            onTap: {
                                selectedTask = task
                            }
                        )
                    }
                }
                .background(Color(hex: "2A2B5A"))
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Task Row Detailed

struct TaskRowDetailed: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    var onTap: (() -> Void)? = nil

    @State private var isCompleted: Bool = false
    @State private var offset: CGFloat = 0
    @State private var showCheckmark: Bool = false

    var body: some View {
        ZStack {
            // Swipe action backgrounds
            HStack(spacing: 0) {
                // Green complete action (right swipe)
                Color.appTheme
                    .frame(width: abs(offset))
                    .overlay(
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                            .opacity(offset > 50 ? 1 : 0)
                    )

                Spacer()

                // Red delete action (left swipe)
                Color(hex: "FF4444")
                    .frame(width: abs(offset))
                    .overlay(
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                            .opacity(offset < -50 ? 1 : 0)
                    )
            }

            // Main task row
            HStack(spacing: 12) {
                // Checkbox
                Button(action: {
                    HapticManager.light()
                    withAnimation(.spring(response: 0.3)) {
                        isCompleted.toggle()
                        showCheckmark = isCompleted
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onToggle()
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(isCompleted ? Color.appTheme : Color(hex: "666666"), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if showCheckmark {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.appTheme)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Task title
                Text(task.title)
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(isCompleted ? Color(hex: "B0B8D4") : .white)
                    .strikethrough(isCompleted, color: Color(hex: "B0B8D4"))
                    .animation(.easeInOut(duration: 0.2), value: isCompleted)

                Spacer()

                // Action buttons
                HStack(spacing: 8) {
                    // Delete button (X)
                    Button(action: {
                        HapticManager.medium()
                        withAnimation(.spring(response: 0.3)) {
                            onDelete()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(hex: "FF4444"))
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Toggle button (✓)
                    Button(action: {
                        HapticManager.light()
                        withAnimation(.spring(response: 0.3)) {
                            isCompleted.toggle()
                            showCheckmark = isCompleted
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onToggle()
                        }
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.appTheme)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(height: 56)
            .padding(.horizontal, 16)
            .background(
                isCompleted ?
                    Color.appTheme.opacity(0.1) :
                    Color(hex: "2A2B5A")
            )
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation.width
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3)) {
                            if value.translation.width > 100 {
                                // Complete action
                                if !isCompleted {
                                    isCompleted = true
                                    showCheckmark = true
                                    HapticManager.light()
                                    onToggle()
                                }
                                offset = 0
                            } else if value.translation.width < -100 {
                                // Delete action
                                HapticManager.medium()
                                onDelete()
                                offset = 0
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                HapticManager.light()
                onTap?()
            }
        }
        .onAppear {
            isCompleted = task.completed
            showCheckmark = task.completed
        }
        .onChange(of: task.completed) { _, newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                isCompleted = newValue
                showCheckmark = newValue
            }
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    var body: some View {
        LottieView(
            filename: "confetti",
            loopMode: .playOnce
        )
    }
}

// MARK: - Custom Task Row

struct CustomTaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    var onTap: (() -> Void)? = nil

    @State private var isCompleted: Bool = false
    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack {
            // Swipe action backgrounds
            HStack(spacing: 0) {
                // Green complete action (right swipe)
                Color.appTheme
                    .frame(width: abs(offset))
                    .overlay(
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                            .opacity(offset > 50 ? 1 : 0)
                    )

                Spacer()

                // Red delete action (left swipe)
                Color.red.opacity(0.8)
                    .frame(width: abs(offset))
                    .overlay(
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                            .opacity(offset < -50 ? 1 : 0)
                    )
            }

            // Task content
            HStack(spacing: 12) {
                // Checkbox
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isCompleted.toggle()
                    }
                    HapticManager.light()
                    onToggle()
                }) {
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.appTheme,
                                        Color.appThemeSecondary
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 24, height: 24)

                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.appTheme)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Task info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        // Category icon
                        if let customCategory = task.customCategory {
                            Image(systemName: customCategory.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }

                        // Task title
                        Text(task.title)
                            .font(.custom("Poppins-Regular", size: 15))
                            .foregroundColor(.white)
                            .strikethrough(isCompleted, color: .white)
                    }

                    // Task metadata
                    HStack(spacing: 12) {
                        // Frequency
                        if let frequency = task.taskFrequency {
                            HStack(spacing: 4) {
                                Image(systemName: "repeat")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "B0B8D4"))
                                Text(frequency.displayName)
                                    .font(.custom("Poppins-Regular", size: 11))
                                    .foregroundColor(Color(hex: "B0B8D4"))
                            }
                        }

                        // Duration
                        if let duration = task.durationInMinutes {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "B0B8D4"))
                                Text("\(duration) min")
                                    .font(.custom("Poppins-Regular", size: 11))
                                    .foregroundColor(Color(hex: "B0B8D4"))
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "2A2B5A").opacity(0.5))
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation.width
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if value.translation.width > 80 {
                                // Complete action
                                if !isCompleted {
                                    isCompleted = true
                                    onToggle()
                                }
                                offset = 0
                            } else if value.translation.width < -80 {
                                // Delete action
                                onDelete()
                                offset = 0
                            } else {
                                // Reset
                                offset = 0
                            }
                        }
                    }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                HapticManager.light()
                onTap?()
            }
        }
        .onAppear {
            isCompleted = task.completed
        }
    }
}

#Preview {
    TasksView()
}
