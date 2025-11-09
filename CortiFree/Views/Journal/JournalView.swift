//
//  JournalView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Vue du carnet pour écrire les entrées de journal
//

import SwiftUI

struct JournalView: View {
    let meditationId: String
    let meditationType: String
    let prompt: String?
    var sharedViewModel: JournalViewModel? = nil

    @StateObject private var localViewModel = JournalViewModel()
    @State private var newEntryContent = ""
    @State private var selectedMood: Mood?
    @State private var showSuccessMessage = false
    @FocusState private var isTextFieldFocused: Bool

    private var viewModel: JournalViewModel {
        sharedViewModel ?? localViewModel
    }

    private var wordCount: Int {
        newEntryContent.split(separator: " ").count
    }

    // Types de journal qui doivent afficher le mood selector
    private var shouldShowMoodSelector: Bool {
        switch meditationType {
        case "gratitude", "clarity", "reflection", "general":
            return true
        case "goals", "todo":
            return false
        default:
            return true
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Mood Selector (seulement pour certains types)
                if shouldShowMoodSelector {
                    MoodSelector(selectedMood: $selectedMood)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                }

                // Zone d'écriture
                writingSection

                // Bouton sauvegarder
                saveButton

                // Entrées précédentes
                previousEntriesSection
            }
        }
        .task {
            if sharedViewModel == nil {
                await viewModel.loadEntries(for: meditationId)
            }
        }
    }

    private var writingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Votre réflexion")
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)

            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "1A1B3A").opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isTextFieldFocused ? Color.appTheme : Color.white.opacity(0.1), lineWidth: 1)
                    )

                // TextEditor
                TextEditor(text: $newEntryContent)
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(12)
                    .focused($isTextFieldFocused)
                    .frame(minHeight: 150)

                // Placeholder
                if newEntryContent.isEmpty {
                    Text(prompt ?? "Commencez à écrire...")
                        .font(.custom("Poppins-Regular", size: 15))
                        .foregroundColor(Color.white.opacity(0.4))
                        .italic()
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 180)

            // Word & Character count
            HStack {
                if !newEntryContent.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "text.word.spacing")
                            .font(.system(size: 10))
                            .foregroundColor(Color.appTheme.opacity(0.7))
                        Text("\(wordCount) mots")
                            .font(.custom("Poppins-Medium", size: 12))
                            .foregroundColor(Color.appTheme.opacity(0.7))
                    }
                }
                Spacer()
                Text("\(newEntryContent.count) caractères")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(Color.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var saveButton: some View {
        Button(action: {
            Task {
                await saveEntry()
            }
        }) {
            HStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: showSuccessMessage ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                        .font(.system(size: 16))

                    Text(showSuccessMessage ? "Sauvegardé !" : "Sauvegarder")
                        .font(.custom("Poppins-SemiBold", size: 16))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: showSuccessMessage ? [Color.appTheme, Color(hex: "00CC6A")] : [Color.appTheme, Color.appThemeSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .opacity(newEntryContent.isEmpty ? 0.5 : 1.0)
        }
        .disabled(newEntryContent.isEmpty || viewModel.isLoading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var previousEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.entries.isEmpty {
                HStack {
                    Text("Entrées précédentes")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(viewModel.entries.count)")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(Color.appTheme)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.appTheme.opacity(0.2))
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(viewModel.entries) { entry in
                            EntryCard(entry: entry) {
                                Task {
                                    await viewModel.deleteEntry(entry)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    private func saveEntry() async {
        await viewModel.saveEntry(
            meditationId: meditationId,
            meditationType: meditationType,
            prompt: prompt,
            content: newEntryContent,
            mood: selectedMood,
            reloadAll: sharedViewModel != nil
        )

        if viewModel.errorMessage == nil {
            newEntryContent = ""
            selectedMood = nil
            isTextFieldFocused = false

            // Show success message
            withAnimation {
                showSuccessMessage = true
            }

            // Award XP for journaling
            ProgressionManager.shared.addXP(.dailyMissionComplete)

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSuccessMessage = false
                }
            }
        }
    }
}

// MARK: - Entry Card Component

struct EntryCard: View {
    let entry: JournalEntry
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: date + mood + delete
            HStack {
                // Mood emoji if exists
                if let mood = entry.mood {
                    Text(mood.emoji)
                        .font(.system(size: 20))
                }

                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTheme)

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

            // Prompt (if exists)
            if let prompt = entry.prompt, !prompt.isEmpty {
                Text(prompt)
                    .font(.custom("Poppins-Medium", size: 13))
                    .foregroundColor(Color.appTheme)
                    .italic()
            }

            // Content
            Text(entry.content)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white)
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
    ZStack {
        GalaxyBackgroundView(intensity: 0.8)

        JournalView(
            meditationId: "gratitude",
            meditationType: "gratitude",
            prompt: "Aujourd'hui, je suis reconnaissant pour..."
        )
    }
}
