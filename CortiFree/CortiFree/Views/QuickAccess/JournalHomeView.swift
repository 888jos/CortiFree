//
//  JournalHomeView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Vue d'accueil du journal avec toutes les entrées
//

import SwiftUI

struct JournalHomeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = JournalViewModel()
    @State private var selectedTab: JournalTab = .todo
    @State private var showNewEntry = false

    enum JournalTab: String, CaseIterable {
        case todo = "To-Do"
        case gratitude = "Gratitude"
        case reflection = "Réflexion"
        case goals = "Objectifs"

        var icon: String {
            switch self {
            case .todo: return "checklist"
            case .gratitude: return "heart.text.square.fill"
            case .reflection: return "sparkles"
            case .goals: return "flag.checkered"
            }
        }

        var color: Color {
            switch self {
            case .todo: return Color(hex: "00BCD4")
            case .gratitude: return Color(hex: "FF6B9D")
            case .reflection: return Color(hex: "FFB74D")
            case .goals: return Color(hex: "4CAF50")
            }
        }

        var description: String {
            switch self {
            case .todo: return "Tes routines quotidiennes"
            case .gratitude: return "Ce pour quoi tu es reconnaissant"
            case .reflection: return "Réfléchis sur ta journée"
            case .goals: return "Tes objectifs et ambitions"
            }
        }

        var meditationId: String? {
            switch self {
            case .gratitude: return "gratitude"
            case .reflection: return "reflection"
            case .goals: return "goals"
            default: return nil
            }
        }
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)

            VStack(spacing: 0) {
                // Header
                headerSection

                // Content with vertical tabs
                HStack(spacing: 0) {
                    // Vertical Tab Bar
                    tabBarSection

                    // Content
                    if selectedTab == .todo {
                        // Vue To-Do spéciale
                        DailyTodosView()
                    } else if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(Color.appTheme)
                        Spacer()
                    } else if filteredEntries.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                // Stats for current tab
                                statsSection

                                // Entries list
                                entriesList

                                Spacer(minLength: 100)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        }
                    }
                }
            }

            // Floating Action Button (seulement pour les onglets non-todo)
            if selectedTab != .todo && !filteredEntries.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showNewEntry = true }) {
                            Image(systemName: "plus")
                                .font(.custom("Poppins-SemiBold", size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [selectedTab.color, selectedTab.color.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: selectedTab.color.opacity(0.4), radius: 12, x: 0, y: 4)
                                )
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .task {
            await viewModel.loadAllEntries()
        }
        .sheet(isPresented: $showNewEntry) {
            newEntrySheet
        }
    }

    private var filteredEntries: [JournalEntry] {
        switch selectedTab {
        case .todo:
            return [] // To-do tab doesn't use journal entries
        case .gratitude:
            return viewModel.entries.filter { $0.meditationType == "gratitude" }
        case .reflection:
            return viewModel.entries.filter { $0.meditationType == "reflection" }
        case .goals:
            return viewModel.entries.filter { $0.meditationType == "goals" }
        }
    }

    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }

            Spacer()

            VStack(spacing: 4) {
                Text("Mon Journal")
                    .font(.custom("Poppins-SemiBold", size: 20))
                    .foregroundColor(.white)

                // Streak indicator
                if streakDays > 0 {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 14))
                        Text("\(streakDays) jour\(streakDays > 1 ? "s" : "")")
                            .font(.custom("Poppins-Medium", size: 12))
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            // Invisible spacer for centering
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var streakDays: Int {
        guard !viewModel.entries.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedEntries = viewModel.entries.sorted { $0.createdAt > $1.createdAt }

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        for entry in sortedEntries {
            let entryDate = calendar.startOfDay(for: entry.createdAt)

            if calendar.isDate(entryDate, inSameDayAs: checkDate) {
                if streak == 0 || calendar.isDate(entryDate, inSameDayAs: calendar.date(byAdding: .day, value: -streak, to: Date())!) {
                    streak += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                }
            } else {
                break
            }
        }

        return streak
    }

    private var tabBarSection: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                ForEach(JournalTab.allCases, id: \.self) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
        }
        .frame(width: 90)
    }

    private var statsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: selectedTab.rawValue,
                    value: "\(filteredEntries.count)",
                    icon: selectedTab.icon,
                    color: selectedTab.color
                )

                StatCard(
                    title: "Cette semaine",
                    value: "\(entriesThisWeek)",
                    icon: "calendar.badge.checkmark",
                    color: selectedTab.color
                )
            }

            // Mood distribution (if entries have mood data)
            if !filteredEntries.isEmpty && filteredEntries.contains(where: { $0.mood != nil }) {
                moodStatsCard
            }
        }
    }

    private var moodStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "face.smiling")
                    .font(.system(size: 16))
                    .foregroundColor(selectedTab.color)

                Text("Humeur moyenne")
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.white)

                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(Mood.allCases, id: \.self) { mood in
                    let count = filteredEntries.filter { $0.mood == mood }.count
                    if count > 0 {
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.system(size: 24))
                            Text("\(count)")
                                .font(.custom("Poppins-Bold", size: 12))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: mood.color).opacity(0.2))
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1A1B3A").opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedTab.color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var entriesList: some View {
        VStack(spacing: 12) {
            ForEach(filteredEntries) { entry in
                JournalEntryRow(entry: entry) {
                    Task {
                        await viewModel.deleteEntry(entry)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: selectedTab.icon)
                .font(.system(size: 60))
                .foregroundColor(selectedTab.color.opacity(0.5))

            VStack(spacing: 8) {
                Text("Aucune entrée pour \(selectedTab.rawValue)")
                    .font(.custom("Poppins-SemiBold", size: 20))
                    .foregroundColor(.white)

                Text(selectedTab.description)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Bouton pour créer une entrée si c'est un onglet non-todo
            if selectedTab != .todo {
                Button(action: { showNewEntry = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Créer une entrée")
                            .font(.custom("Poppins-SemiBold", size: 16))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [selectedTab.color, selectedTab.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
                .padding(.top, 8)
            }

            Spacer()
        }
    }

    private var newEntrySheet: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.8)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { showNewEntry = false }) {
                        Image(systemName: "xmark")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }

                    Spacer()

                    Text(entrySheetTitle)
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)

                    Spacer()

                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Journal view adapté selon l'onglet
                JournalView(
                    meditationId: selectedTab.meditationId ?? "general",
                    meditationType: selectedTab.meditationId ?? "general",
                    prompt: entryPrompt,
                    sharedViewModel: viewModel
                )
            }
        }
    }

    private var entrySheetTitle: String {
        switch selectedTab {
        case .todo: return "Routine Quotidienne"
        case .gratitude: return "Journal de Gratitude"
        case .reflection: return "Réflexion du Jour"
        case .goals: return "Mes Objectifs"
        }
    }

    private var entryPrompt: String {
        switch selectedTab {
        case .todo: return "Décris ta routine..."
        case .gratitude: return DailyPrompt.getDailyPrompt(for: "gratitude")
        case .reflection: return DailyPrompt.getDailyPrompt(for: "reflection")
        case .goals: return DailyPrompt.getDailyPrompt(for: "goals")
        }
    }

    private var entriesThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return filteredEntries.filter { $0.createdAt >= weekAgo }.count
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let tab: JournalHomeView.JournalTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? tab.color : Color.white.opacity(0.6))

                Text(tab.rawValue)
                    .font(.custom("Poppins-Medium", size: 9))
                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tab.color.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? tab.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.custom("Poppins-Bold", size: 28))
                .foregroundColor(.white)

            Text(title)
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(Color.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1A1B3A").opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }

                Text(title)
                    .font(.custom("Poppins-Medium", size: 14))
            }
            .foregroundColor(isSelected ? .white : Color.white.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ?
                          LinearGradient(
                            colors: [Color.appTheme, Color.appThemeSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                          ) :
                          LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                    )
            )
        }
    }
}

// MARK: - Journal Entry Row

struct JournalEntryRow: View {
    let entry: JournalEntry
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: date + type + mood + delete
            HStack {
                // Mood emoji if exists
                if let mood = entry.mood {
                    Text(mood.emoji)
                        .font(.system(size: 20))
                }

                // Type icon
                if let type = JournalType(rawValue: entry.meditationType) {
                    Image(systemName: type.icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color.appTheme)
                }

                Text(entry.createdAt, style: .date)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(Color.white.opacity(0.6))

                Text(entry.createdAt, style: .time)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(Color.white.opacity(0.6))

                Spacer()

                // Word count if exists
                if let wordCount = entry.wordCount, wordCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "text.word.spacing")
                            .font(.system(size: 10))
                        Text("\(wordCount)")
                            .font(.custom("Poppins-Regular", size: 11))
                    }
                    .foregroundColor(Color.white.opacity(0.5))
                }

                Button(action: { showDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "FF6B9D"))
                }
            }

            // Prompt
            if let prompt = entry.prompt, !prompt.isEmpty {
                Text(prompt)
                    .font(.custom("Poppins-Medium", size: 13))
                    .foregroundColor(Color.appTheme)
                    .italic()
            }

            // Content preview
            Text(entry.content)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white)
                .lineLimit(3)
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1A1B3A").opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .confirmationDialog("Supprimer cette entrée ?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) {
                onDelete()
            }
            Button("Annuler", role: .cancel) {}
        }
    }
}

#Preview {
    JournalHomeView()
}
