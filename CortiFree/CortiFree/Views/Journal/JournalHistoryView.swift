//
//  JournalHistoryView.swift
//  CortiFree
//
//  Simple history view for past journal entries
//

import SwiftUI

struct JournalHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = JournalViewModel()

    // Undo functionality
    @State private var showUndoToast = false
    @State private var deletedEntry: JournalEntry?
    @State private var undoWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "0A0515"),
                    Color(hex: "1a0a2e"),
                    Color(hex: "16082e"),
                    Color(hex: "0A0515")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(Color(hex: "B794F6"))
                        .scaleEffect(1.5)
                    Spacer()
                } else if viewModel.allEntries.isEmpty {
                    emptyState
                        .transition(.slideUp)
                } else {
                    // Timeline - vertical scroll
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.allEntries.enumerated()), id: \.element.id) { index, entry in
                                TimelineEntryCard(entry: entry, onDelete: {
                                    deleteWithUndo(entry)
                                }, onShare: {
                                    shareEntry(entry)
                                })
                                .cascadeAppear(index: index, totalCount: viewModel.allEntries.count)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }

                // Undo Toast
                if showUndoToast {
                    UndoToast(
                        message: LanguageManager.shared.localizedString(for: "journal_history.entry_deleted"),
                        duration: 5.0,
                        undoAction: restoreEntry
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1000)
                }
            }
        }
        .task {
            await viewModel.loadAllEntries()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: {
                HapticManager.light()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 40, height: 40)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassCircle(interactive: true)

            Spacer()

            VStack(spacing: 4) {
                Text(LanguageManager.shared.localizedString(for: "journal_history.title"))
                    .font(Font.Poppins.custom(.bold, size: 20))
                    .foregroundColor(.white)

                Text(viewModel.allEntries.count == 1 ? String(format: LanguageManager.shared.localizedString(for: "journal_history.entries_count"), viewModel.allEntries.count) : String(format: LanguageManager.shared.localizedString(for: "journal_history.entries_count_plural"), viewModel.allEntries.count))
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Helper Functions

    private func deleteWithUndo(_ entry: JournalEntry) {
        HapticManager.medium()

        // Cancel any pending permanent delete
        undoWorkItem?.cancel()

        // Store the entry for potential restoration
        deletedEntry = entry

        // Soft delete (remove from UI but keep reference)
        Task {
            await viewModel.deleteEntry(entry)
        }

        // Show undo toast
        withAnimation(.appSpring) {
            showUndoToast = true
        }

        // Schedule permanent delete after 5 seconds
        let workItem = DispatchWorkItem {
            withAnimation(.appSpring) {
                showUndoToast = false
            }
            deletedEntry = nil
        }

        undoWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: workItem)
    }

    private func restoreEntry() {
        HapticManager.light()

        // Cancel permanent delete
        undoWorkItem?.cancel()

        // Restore entry if it exists
        if deletedEntry != nil {
            Task {
                await viewModel.loadAllEntries() // Reload to restore entry
            }
        }

        // Hide toast
        withAnimation(.appSpring) {
            showUndoToast = false
        }

        deletedEntry = nil
    }

    private func shareEntry(_ entry: JournalEntry) {
        HapticManager.light()

        let shareText = """
        \(LanguageManager.shared.localizedString(for: "journal_history.share_text_prefix"))\(entry.createdAt.formatted(date: .long, time: .omitted))

        \(entry.content)
        \(LanguageManager.shared.localizedString(for: "journal_history.share_text_suffix"))
        """

        let activityController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "book.closed.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "B794F6").opacity(0.5))

            Text(LanguageManager.shared.localizedString(for: "journal_history.empty_title"))
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)

            Text(LanguageManager.shared.localizedString(for: "journal_history.empty_subtitle"))
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Timeline Entry Card

struct TimelineEntryCard: View {
    let entry: JournalEntry
    let onDelete: () -> Void
    let onShare: () -> Void

    @State private var isExpanded = false

    private var previewText: String {
        if entry.content.count > 150 {
            return String(entry.content.prefix(150)) + "..."
        }
        return entry.content
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left: Date column
            VStack(spacing: 4) {
                Text(dayNumber(entry.createdAt))
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.white)

                Text(monthName(entry.createdAt))
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)
            }
            .frame(width: 60)

            // Timeline line
            VStack(spacing: 0) {
                Circle()
                    .fill(entry.mood != nil ? Color(hex: entry.mood!.color) : Color(hex: "B794F6"))
                    .frame(width: 12, height: 12)

                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 2)
            }

            // Right: Entry content
            VStack(alignment: .leading, spacing: 12) {
                // Mood indicator
                if let mood = entry.mood {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: mood.color).opacity(0.3))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(mood.emoji)
                                    .font(.system(size: 18))
                            )

                        Text(mood.displayName)
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(.white)

                        Spacer()
                    }
                }

                // Photo if available
                if let photoBase64 = entry.photoURL, !photoBase64.isEmpty,
                   let imageData = Data(base64Encoded: photoBase64),
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                // Content
                Text(isExpanded ? entry.content : previewText)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(isExpanded ? nil : 3)

                // Expand/Word count
                HStack {
                    if entry.content.count > 150 {
                        Button(action: {
                            HapticManager.light()
                            withAnimation(.spring(response: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Text(isExpanded ? LanguageManager.shared.localizedString(for: "journal_history.see_less") : LanguageManager.shared.localizedString(for: "journal_history.see_more"))
                                .font(.custom("Poppins-Medium", size: 12))
                                .foregroundColor(Color(hex: "B794F6"))
                        }
                    }

                    Spacer()

                    if let wordCount = entry.wordCount {
                        Text(String(format: LanguageManager.shared.localizedString(for: "journal_history.words_count"), wordCount))
                            .font(.custom("Poppins-Regular", size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 20)
            .padding(.bottom, 20)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                HapticManager.medium()
                onDelete()
            } label: {
                Label(LanguageManager.shared.localizedString(for: "journal_history.delete"), systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                HapticManager.light()
                onShare()
            } label: {
                Label(LanguageManager.shared.localizedString(for: "journal_history.share"), systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
        }
    }

    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func monthName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
}

#Preview {
    JournalHistoryView()
}
