//
//  TasksLibraryView.swift
//  CortiFree
//
//  Created by Claude on 10/11/2025.
//  Browse all 59 tasks from the database
//

import SwiftUI

struct TasksLibraryView: View {
    @ObservedObject private var taskManager = TaskManager.shared
    @State private var selectedCategory: TaskCategoryType?
    @State private var searchQuery: String = ""

    private var filteredTasks: [TaskDetail] {
        var tasks = taskManager.allTasks

        // Filter by category
        if let category = selectedCategory {
            tasks = tasks.filter { $0.categoryType == category }
        }

        // Filter by search
        if !searchQuery.isEmpty {
            tasks = taskManager.searchTasks(query: searchQuery)
        }

        return tasks
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Search bar
                searchBar

                // Category filters
                categoryFilters

                // Tasks list
                if taskManager.isLoaded {
                    if taskManager.allTasks.isEmpty {
                        emptyStateView
                    } else {
                        tasksList
                    }
                } else {
                    loadingView
                }
            }
        }
        .navigationTitle("Bibliothèque")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("📱 TasksLibraryView appeared")
            print("   isLoaded: \(taskManager.isLoaded)")
            print("   allTasks count: \(taskManager.allTasks.count)")

            // Force reload if needed
            if !taskManager.isLoaded {
                print("🔄 Force reloading task database...")
                taskManager.loadTaskDatabase()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(taskManager.allTasks.count)")
                        .font(.custom("Poppins-Bold", size: 32))
                        .foregroundColor(.white)

                    Text("tâches disponibles")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(TaskCategoryType.allCases.count)")
                        .font(.custom("Poppins-Bold", size: 32))
                        .foregroundColor(Color.appTheme)

                    Text("catégories")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(
            Color.white.opacity(0.05)
        )
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.5))

            TextField("Rechercher une tâche...", text: $searchQuery)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white)
                .autocorrectionDisabled()

            if !searchQuery.isEmpty {
                Button(action: { searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    // MARK: - Category Filters

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All categories button
                CategoryFilterChip(
                    title: "Tous",
                    icon: "square.grid.2x2.fill",
                    isSelected: selectedCategory == nil,
                    count: taskManager.allTasks.count
                ) {
                    selectedCategory = nil
                }

                ForEach(TaskCategoryType.allCases, id: \.self) { category in
                    CategoryFilterChip(
                        title: category.displayName,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category,
                        count: taskManager.getTasks(byCategory: category).count
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Tasks List

    private var tasksList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(filteredTasks) { task in
                    NavigationLink(destination: TaskInstructionsView(task: task)) {
                        TaskLibraryCard(task: task)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)

            Text("Chargement des tâches...")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Aucune tâche chargée")
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundColor(.white)

            Text("Le fichier TASKS_DATABASE.json n'a pas pu être chargé.\n\nVérifiez la console pour plus de détails.")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                taskManager.loadTaskDatabase()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Réessayer")
                }
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let title: String
    let icon: String
    var color: Color = .appTheme
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))

                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 13))

                Text("(\(count))")
                    .font(.custom("Poppins-Regular", size: 12))
                    .opacity(0.7)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Task Library Card

struct TaskLibraryCard: View {
    let task: TaskDetail

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(task.categoryType.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: task.icon)
                    .font(.system(size: 20))
                    .foregroundColor(task.categoryType.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.custom("Poppins-SemiBold", size: 15))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(task.description)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)

                HStack(spacing: 12) {
                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text("\(task.durationMinutes) min")
                            .font(.custom("Poppins-Medium", size: 11))
                    }
                    .foregroundColor(.white.opacity(0.5))

                    // XP
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text("\(task.xp) XP")
                            .font(.custom("Poppins-Medium", size: 11))
                    }
                    .foregroundColor(Color(hex: "FFD700"))

                    // Difficulty
                    HStack(spacing: 4) {
                        Image(systemName: task.difficultyLevel.icon)
                            .font(.system(size: 10))
                        Text(task.difficultyLevel.rawValue)
                            .font(.custom("Poppins-Medium", size: 11))
                    }
                    .foregroundColor(task.difficultyLevel.color)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            task.categoryType.color.opacity(0.15),
                            task.categoryType.color.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(task.categoryType.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Task Instructions View

struct TaskInstructionsView: View {
    let task: TaskDetail

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header with icon
                HStack {
                    ZStack {
                        Circle()
                            .fill(task.categoryType.color.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: task.icon)
                            .font(.system(size: 36))
                            .foregroundColor(task.categoryType.color)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        // XP Badge
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                            Text("\(task.xp) XP")
                                .font(.custom("Poppins-Bold", size: 18))
                        }
                        .foregroundColor(Color(hex: "FFD700"))

                        // Duration
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                            Text("\(task.durationMinutes) min")
                                .font(.custom("Poppins-SemiBold", size: 14))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                }

                // Title
                Text(task.title)
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundColor(.white)

                // Tags
                FlowLayout(spacing: 8) {
                    ForEach(task.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.custom("Poppins-Medium", size: 11))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(task.categoryType.color.opacity(0.3))
                            )
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // Description
                SectionView(title: "Description", icon: "text.alignleft") {
                    Text(task.description)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }

                // Why it works
                SectionView(title: "Pourquoi ça marche", icon: "lightbulb.fill") {
                    Text(task.whyItWorks)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }

                // Instructions
                SectionView(title: "Instructions", icon: "list.bullet") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(task.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.custom("Poppins-Bold", size: 14))
                                    .foregroundColor(task.categoryType.color)
                                    .frame(width: 24, height: 24)
                                    .background(
                                        Circle()
                                            .fill(task.categoryType.color.opacity(0.2))
                                    )

                                Text(instruction)
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }

                // Scientific reference
                if let reference = task.scientificReference {
                    SectionView(title: "Référence scientifique", icon: "books.vertical.fill") {
                        Text(reference)
                            .font(.custom("Poppins-Italic", size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.05))
                            )
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(24)
        }
        .background(
            ZStack {
                GalaxyBackgroundView(intensity: 0.6)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        task.categoryType.color.opacity(0.1),
                        Color.clear,
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        )
        .navigationTitle(task.categoryType.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Section View

struct SectionView<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.appTheme)

                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)
            }

            content()
        }
    }
}

// MARK: - Flow Layout (for tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for size in sizes {
            if lineWidth + size.width > proposal.width ?? 0 {
                totalHeight += lineHeight + spacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            totalWidth = max(totalWidth, lineWidth)
        }

        totalHeight += lineHeight
        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var lineX = bounds.minX
        var lineY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if lineX + size.width > bounds.maxX {
                lineY += lineHeight + spacing
                lineX = bounds.minX
                lineHeight = 0
            }

            subview.place(at: CGPoint(x: lineX, y: lineY), proposal: .unspecified)
            lineX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

#Preview {
    NavigationView {
        TasksLibraryView()
    }
}
