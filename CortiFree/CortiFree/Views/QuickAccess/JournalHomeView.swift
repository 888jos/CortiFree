//
//  JournalHomeView.swift
//  CortiFree
//
//  Daily journal entry view - one entry per day
//  Layout: Mood selector (top-left), Photo (top-right), Text (bottom)
//

import SwiftUI
import PhotosUI

struct JournalHomeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = JournalViewModel()

    @State private var journalText = ""
    @State private var selectedMood: Mood?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoImage: UIImage?
    @State private var showSuccessMessage = false
    @State private var isLoadingToday = true
    @State private var todayEntry: JournalEntry?
    @State private var showHistory = false
    @State private var showPhotoSourcePicker = false
    @State private var showImagePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @FocusState private var isTextFocused: Bool

    private var wordCount: Int {
        journalText.split(separator: " ").count
    }

    private var characterCount: Int {
        journalText.count
    }

    private var canSave: Bool {
        characterCount >= 1 && hasChanges
    }

    private var hasChanges: Bool {
        // Check if there are any changes compared to existing entry
        if let existing = todayEntry {
            return journalText != existing.content ||
                   selectedMood != existing.mood ||
                   photoImage != nil  // New photo selected
        }
        return characterCount >= 1  // New entry
    }

    private var isToday: Bool {
        guard let entry = todayEntry else { return false }
        return Calendar.current.isDateInToday(entry.createdAt)
    }

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

                if isLoadingToday {
                    Spacer()
                    ProgressView()
                        .tint(Color(hex: "B794F6"))
                        .scaleEffect(1.5)
                    Spacer()
                } else {
                    // Scrollable content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Top row: Mood (left) + Photo (right)
                            HStack(alignment: .top, spacing: 16) {
                                // Mood selector (left)
                                moodSection
                                    .frame(maxWidth: .infinity)

                                // Photo (right)
                                photoSection
                            }

                            // Text section (full width, below)
                            textSection

                            // Save button
                            saveButton

                            // View history button
                            historyButton
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onChange(of: selectedPhoto) {
            Task {
                if let data = try? await selectedPhoto?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    photoImage = image
                }
            }
        }
        .overlay(
            Group {
                if showSuccessMessage {
                    successOverlay
                }
            }
        )
        .confirmationDialog("Choisir la source", isPresented: $showPhotoSourcePicker) {
            Button("Appareil photo") {
                imagePickerSourceType = .camera
                showImagePicker = true
            }
            Button("Photothèque") {
                imagePickerSourceType = .photoLibrary
                showImagePicker = true
            }
            Button("Annuler", role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $photoImage, sourceType: imagePickerSourceType)
        }
        .task {
            await loadTodayEntry()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: {
                HapticManager.light()
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            VStack(spacing: 4) {
                Text(NSLocalizedString("journal_home.title", comment: ""))
                    .font(Font.Poppins.custom(.bold, size: 20))
                    .foregroundColor(.white)

                Text(formatDate(Date()))
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Mood Section (Top Left)

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "face.smiling.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "B794F6"))

                Text(NSLocalizedString("journal_home.mood", comment: ""))
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.white)
            }

            // Mood selector - grid when nothing selected, horizontal when selected
            ZStack {
                if selectedMood == nil {
                    // Grid layout - 2 rows x 3 columns
                    VStack(spacing: 8) {
                        // First row
                        HStack(spacing: 8) {
                            ForEach(Array(Mood.allCases.prefix(3)), id: \.self) { mood in
                                moodButton(mood)
                            }
                        }

                        // Second row
                        HStack(spacing: 8) {
                            ForEach(Array(Mood.allCases.suffix(3)), id: \.self) { mood in
                                moodButton(mood)
                            }
                        }
                    }
                    .transition(.opacity)
                } else {
                    // Horizontal carousel when mood selected
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Spacer to allow centering
                                Spacer()
                                    .frame(width: 40)

                                ForEach(Mood.allCases, id: \.self) { mood in
                                    moodButtonExpanded(mood)
                                        .id(mood)
                                }

                                // Spacer to allow centering
                                Spacer()
                                    .frame(width: 40)
                            }
                        }
                        .transition(.opacity)
                        .onAppear {
                            if let mood = selectedMood {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        proxy.scrollTo(mood, anchor: .center)
                                    }
                                }
                            }
                        }
                        .onChange(of: selectedMood) {
                            if let mood = selectedMood {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    proxy.scrollTo(mood, anchor: .center)
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: 140, height: 140)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Photo Section (Top Right)

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "B794F6"))

                Text(NSLocalizedString("journal_home.photo", comment: ""))
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.white)
            }

            Button(action: {
                HapticManager.light()
                showPhotoSourcePicker = true
            }) {
                ZStack {
                    if let photoImage = photoImage {
                        // Display selected photo
                        Image(uiImage: photoImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(hex: "B794F6"), Color(hex: "9F7AEA")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    } else if let existing = todayEntry,
                              let photoBase64 = existing.photoURL,
                              !photoBase64.isEmpty,
                              let imageData = Data(base64Encoded: photoBase64),
                              let uiImage = UIImage(data: imageData) {
                        // Display existing photo
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "B794F6").opacity(0.5), lineWidth: 2)
                            )
                    } else {
                        // Placeholder
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.03))
                                .frame(width: 140, height: 140)

                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                                .foregroundColor(Color(hex: "B794F6").opacity(0.4))
                                .frame(width: 140, height: 140)

                            VStack(spacing: 6) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(hex: "B794F6").opacity(0.6))

                                Text(NSLocalizedString("journal_home.photo_add", comment: ""))
                                    .font(.custom("Poppins-Medium", size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }
            }
            .frame(width: 140, height: 140)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Text Section

    private var textSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "pencil.line")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "B794F6"))

                Text(NSLocalizedString("journal_home.my_day", comment: ""))
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)

                Spacer()
            }

            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isTextFocused ? Color(hex: "B794F6") : Color.white.opacity(0.1), lineWidth: 1.5)
                    )

                // TextEditor
                TextEditor(text: $journalText)
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(16)
                    .focused($isTextFocused)
                    .frame(minHeight: 200)

                // Placeholder
                if journalText.isEmpty {
                    Text(NSLocalizedString("journal_home.placeholder", comment: ""))
                        .font(.custom("Poppins-Regular", size: 15))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .allowsHitTesting(false)
                }
            }

            // Word and character count
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text("\(characterCount)")
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(Color(hex: "B794F6"))
                    Text(NSLocalizedString("journal_home.characters", comment: ""))
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }

                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 3, height: 3)

                HStack(spacing: 4) {
                    Text("\(wordCount)")
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(Color(hex: "B794F6"))
                    Text(NSLocalizedString("journal_home.words", comment: ""))
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: {
            Task {
                await saveEntry()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: isToday && todayEntry != nil ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill")
                    .font(.system(size: 20))

                Text(isToday && todayEntry != nil ? NSLocalizedString("journal_home.update", comment: "") : NSLocalizedString("journal_home.save", comment: ""))
                    .font(.custom("Poppins-SemiBold", size: 16))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        canSave ?
                        LinearGradient(
                            colors: [Color(hex: "B794F6"), Color(hex: "9F7AEA")],
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
        .disabled(!canSave)
        .opacity(canSave ? 1.0 : 0.5)
    }

    // MARK: - History Button

    private var historyButton: some View {
        Button(action: {
            HapticManager.light()
            showHistory = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14))

                Text(NSLocalizedString("journal_home.view_past_entries", comment: ""))
                    .font(.custom("Poppins-Medium", size: 14))
            }
            .foregroundColor(Color(hex: "B794F6"))
        }
        .fullScreenCover(isPresented: $showHistory) {
            JournalHistoryView()
        }
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "10B981"))

                Text(isToday && todayEntry != nil ? NSLocalizedString("journal_home.entry_updated", comment: "") : NSLocalizedString("journal_home.entry_saved", comment: ""))
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "1a0a2e"))
            )
        }
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLanguage.locale
        formatter.dateFormat = "EEEE d MMMM yyyy"
        return formatter.string(from: date).capitalized
    }

    private func loadTodayEntry() async {
        isLoadingToday = true
        await viewModel.loadAllEntries()

        // Find today's entry
        todayEntry = viewModel.allEntries.first { entry in
            Calendar.current.isDateInToday(entry.createdAt)
        }

        // Populate fields if entry exists
        if let entry = todayEntry {
            journalText = entry.content
            selectedMood = entry.mood
        }

        isLoadingToday = false
    }

    private func saveEntry() async {
        guard canSave else { return }

        HapticManager.medium()

        // Upload photo if new one selected
        var photoURL: String? = todayEntry?.photoURL  // Keep existing if no new photo
        if let photoImage = photoImage {
            photoURL = await viewModel.uploadPhoto(photoImage)
        }

        // Save entry (will update if exists for today)
        await viewModel.saveEntry(
            content: journalText,
            mood: selectedMood,
            photoURL: photoURL,
            wordCount: wordCount,
            entryId: todayEntry?.id  // Pass existing entry ID for update
        )

        // Show success message
        withAnimation {
            showSuccessMessage = true
        }

        // Reload today's entry
        await loadTodayEntry()

        // Hide success message
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        withAnimation {
            showSuccessMessage = false
        }

        // Clear new photo selection (keep existing)
        photoImage = nil
        selectedPhoto = nil
    }

    // MARK: - Mood Button (Grid mode)

    @ViewBuilder
    private func moodButton(_ mood: Mood) -> some View {
        Button(action: {
            HapticManager.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedMood = mood
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    // Circle background with mood color
                    Circle()
                        .fill(Color(hex: mood.color).opacity(0.25))
                        .frame(width: 38, height: 38)

                    // Emoji
                    Text(mood.emoji)
                        .font(.system(size: 20))
                }
            }
            .frame(width: 40, height: 60)
        }
    }

    // MARK: - Mood Button Expanded (Carousel mode)

    @ViewBuilder
    private func moodButtonExpanded(_ mood: Mood) -> some View {
        Button(action: {
            HapticManager.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedMood = mood
            }
        }) {
            VStack(spacing: 6) {
                ZStack {
                    // Circle background - same size for all
                    Circle()
                        .fill(Color(hex: mood.color).opacity(selectedMood == mood ? 0.4 : 0.25))
                        .frame(width: 56, height: 56)

                    // Emoji - same size for all
                    Text(mood.emoji)
                        .font(.system(size: 32))
                }

                // Label only for selected mood
                if selectedMood == mood {
                    Text(mood.displayName)
                        .font(.custom("Poppins-SemiBold", size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 60)
            .opacity(selectedMood == mood ? 1.0 : 0.5)
        }
    }
}

#Preview {
    JournalHomeView()
}
