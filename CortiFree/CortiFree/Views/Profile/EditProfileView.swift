//
//  EditProfileView.swift
//  CortiFree
//
//  Created by Claude on 18/11/2025.
//

import SwiftUI
import FirebaseAuth

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var profileManager = ProfileManager.shared

    // Personal Info
    @State private var firstName: String = ""
    @State private var bedTime: Date = Calendar.current.date(from: DateComponents(hour: 23, minute: 0)) ?? Date()
    @State private var wakeTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()

    // Goals (modifiable)
    @State private var goals: [String: HabitGoal] = [:]

    // Performance (read-only, from last 7 days)
    @State private var performances: [String: HabitPerformance] = [:]

    @State private var isLoading = false
    @State private var isSaving = false

    // Photo picker
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppConstants.Layout.spacingXLarge) {
                        // Profile Photo Section
                        profilePhotoSection

                        // Profile Section
                        profileSection

                        // Sleep Section
                        sleepSection

                        // Goals Section (8 habits)
                        goalsSection

                        // Info banner
                        infoBanner

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, AppConstants.Layout.paddingLarge)
                    .padding(.top, AppConstants.Layout.paddingLarge)
                }
            }
        }
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                saveProfilePhoto(image)
            }
        }
    }

    // MARK: - Profile Photo Section

    private var profilePhotoSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                HapticManager.light()
                showImagePicker = true
            }) {
                ZStack(alignment: .bottomTrailing) {
                    // Main avatar circle
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "B794F6"), Color(hex: "9B59B6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Group {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Text(String(firstName.prefix(1)).uppercased())
                                        .font(Font.Poppins.custom(.bold, size: 40))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )

                    // Edit icon overlay
                    ZStack {
                        Circle()
                            .fill(Color(hex: "B794F6"))
                            .frame(width: 32, height: 32)

                        Circle()
                            .stroke(Color(hex: "01000C"), lineWidth: 2)
                            .frame(width: 32, height: 32)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .offset(x: -4, y: -4)
                }
            }

            Text("Touchez pour changer la photo")
                .font(.custom(AppConstants.Fonts.regular, size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 20)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: {
                HapticManager.light()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(NSLocalizedString(StringKeys.Profile.editTitle, comment: ""))
                .font(.custom(AppConstants.Fonts.bold, size: 20))
                .foregroundColor(.white)

            Spacer()

            Button(action: {
                HapticManager.medium()
                saveProfile()
            }) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(NSLocalizedString(StringKeys.Profile.save, comment: ""))
                        .font(.custom(AppConstants.Fonts.semiBold, size: 16))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                }
            }
            .disabled(isSaving)
        }
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
        .padding(.top, 20)
        .padding(.bottom, AppConstants.Layout.paddingMedium)
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(spacing: AppConstants.Layout.spacingLarge) {
            Text(NSLocalizedString(StringKeys.Profile.personalInfo, comment: ""))
                .font(.custom(AppConstants.Fonts.semiBold, size: 16))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)

            // First Name
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString(StringKeys.Profile.firstName, comment: ""))
                    .font(.custom(AppConstants.Fonts.medium, size: 13))
                    .foregroundColor(.white.opacity(0.6))

                TextField("", text: $firstName)
                    .font(.custom(AppConstants.Fonts.regular, size: 16))
                    .foregroundColor(.white)
                    .padding(AppConstants.Layout.paddingMedium)
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadiusSmall)
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
        .padding(AppConstants.Layout.paddingLarge)
    }

    // MARK: - Sleep Section

    private var sleepSection: some View {
        VStack(spacing: AppConstants.Layout.spacingLarge) {
            HStack {
                Image(systemName: "moon.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppConstants.Colors.violet)

                Text(NSLocalizedString(StringKeys.Profile.sleepSection, comment: ""))
                    .font(.custom(AppConstants.Fonts.semiBold, size: 16))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }

            // Bedtime
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString(StringKeys.Profile.bedTime, comment: ""))
                        .font(.custom(AppConstants.Fonts.medium, size: 13))
                        .foregroundColor(.white.opacity(0.6))

                    DatePicker("", selection: $bedTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .colorScheme(.dark)
                }

                Spacer()
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Wake time
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString(StringKeys.Profile.wakeTime, comment: ""))
                        .font(.custom(AppConstants.Fonts.medium, size: 13))
                        .foregroundColor(.white.opacity(0.6))

                    DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .colorScheme(.dark)
                }

                Spacer()
            }
        }
        .padding(AppConstants.Layout.paddingLarge)
    }

    // MARK: - Goals Section (8 Habits)

    private var goalsSection: some View {
        VStack(spacing: AppConstants.Layout.spacingLarge) {
            HStack {
                Image(systemName: "target")
                    .font(.system(size: 18))
                    .foregroundColor(AppConstants.Colors.primaryGreen)

                Text(NSLocalizedString(StringKeys.Profile.goalsSection, comment: ""))
                    .font(.custom(AppConstants.Fonts.semiBold, size: 16))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }

            // 8 Habits
            habitRow(habitId: "meditation", icon: "brain.head.profile", color: AppConstants.Colors.violet)
            habitRow(habitId: "breathing", icon: "wind", color: AppConstants.Colors.domainSerenity)
            habitRow(habitId: "journal", icon: "book.fill", color: AppConstants.Colors.journalReflection)
            habitRow(habitId: "sport", icon: "figure.run", color: AppConstants.Colors.domainEnergy)
            habitRow(habitId: "water", icon: "drop.fill", color: .blue)
            habitRow(habitId: "nature", icon: "leaf.fill", color: AppConstants.Colors.domainFocus)
            habitRow(habitId: "social", icon: "person.2.fill", color: AppConstants.Colors.domainBalance)
            habitRow(habitId: "sleep", icon: "moon.stars.fill", color: AppConstants.Colors.domainSleep)
        }
        .padding(AppConstants.Layout.paddingLarge)
    }

    // MARK: - Habit Row

    private func habitRow(habitId: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            // Habit Title
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                Text(NSLocalizedString("profile.habit.\(habitId)", comment: ""))
                    .font(.custom(AppConstants.Fonts.semiBold, size: 15))
                    .foregroundColor(.white)

                Spacer()
            }

            // Current Performance (Read-only)
            if let performance = performances[habitId] {
                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString(StringKeys.Profile.currentSection, comment: ""))
                        .font(.custom(AppConstants.Fonts.medium, size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .italic()

                    HStack(spacing: 12) {
                        // Completion rate
                        Text(performance.formattedCompletionRate)
                            .font(.custom(AppConstants.Fonts.regular, size: 13))
                            .foregroundColor(.white.opacity(0.6))

                        // Frequency
                        Text(performance.formattedAverageFrequency)
                            .font(.custom(AppConstants.Fonts.regular, size: 13))
                            .foregroundColor(.white.opacity(0.6))

                        // Duration or Quantity
                        if let duration = performance.formattedAverageDuration {
                            Text(duration)
                                .font(.custom(AppConstants.Fonts.regular, size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        } else if let quantity = performance.formattedAverageQuantity {
                            Text(quantity)
                                .font(.custom(AppConstants.Fonts.regular, size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.vertical, 6)
            } else {
                Text(NSLocalizedString(StringKeys.Profile.noDataYet, comment: ""))
                    .font(.custom(AppConstants.Fonts.regular, size: 12))
                    .foregroundColor(.white.opacity(0.4))
                    .italic()
                    .padding(.vertical, 6)
            }

            // Goals (Editable with steppers)
            if let goal = goals[habitId] {
                VStack(spacing: 8) {
                    // Frequency stepper
                    HStack {
                        Text(NSLocalizedString(StringKeys.Profile.frequencyLabel, comment: ""))
                            .font(.custom(AppConstants.Fonts.medium, size: 13))
                            .foregroundColor(.white.opacity(0.7))

                        Spacer()

                        stepperControl(
                            value: Binding(
                                get: { goal.frequencyPerWeek },
                                set: { newValue in
                                    var updatedGoal = goal
                                    updatedGoal.frequencyPerWeek = newValue
                                    goals[habitId] = updatedGoal
                                }
                            ),
                            range: 1...7,
                            label: "\(goal.frequencyPerWeek)x/sem"
                        )
                    }

                    // Duration stepper (if applicable)
                    if goal.durationMinutes != nil {
                        HStack {
                            Text(NSLocalizedString(StringKeys.Profile.durationLabel, comment: ""))
                                .font(.custom(AppConstants.Fonts.medium, size: 13))
                                .foregroundColor(.white.opacity(0.7))

                            Spacer()

                            stepperControl(
                                value: Binding(
                                    get: { goal.durationMinutes ?? 5 },
                                    set: { newValue in
                                        var updatedGoal = goal
                                        updatedGoal.durationMinutes = newValue
                                        goals[habitId] = updatedGoal
                                    }
                                ),
                                range: 5...120,
                                step: 5,
                                label: "\(goal.durationMinutes ?? 5) min"
                            )
                        }
                    }

                    // Quantity stepper (water, sleep)
                    if goal.dailyQuantity != nil && habitId == "water" {
                        HStack {
                            Text("Eau/jour")
                                .font(.custom(AppConstants.Fonts.medium, size: 13))
                                .foregroundColor(.white.opacity(0.7))

                            Spacer()

                            stepperControl(
                                value: Binding(
                                    get: { Int((goal.dailyQuantity ?? 2.0) * 10) },
                                    set: { newValue in
                                        var updatedGoal = goal
                                        updatedGoal.dailyQuantity = Float(newValue) / 10.0
                                        goals[habitId] = updatedGoal
                                    }
                                ),
                                range: 10...40,
                                step: 5,
                                label: String(format: "%.1f L", goal.dailyQuantity ?? 2.0)
                            )
                        }
                    }

                    if goal.dailyQuantity != nil && habitId == "sleep" {
                        HStack {
                            Text("Heures/nuit")
                                .font(.custom(AppConstants.Fonts.medium, size: 13))
                                .foregroundColor(.white.opacity(0.7))

                            Spacer()

                            stepperControl(
                                value: Binding(
                                    get: { Int((goal.dailyQuantity ?? 7.0) * 10) },
                                    set: { newValue in
                                        var updatedGoal = goal
                                        updatedGoal.dailyQuantity = Float(newValue) / 10.0
                                        goals[habitId] = updatedGoal
                                    }
                                ),
                                range: 60...90,
                                step: 5,
                                label: String(format: "%.1f h", goal.dailyQuantity ?? 7.0)
                            )
                        }
                    }
                }
            }

            if habitId != "sleep" {
                Divider()
                    .background(Color.white.opacity(0.1))
            }
        }
    }

    // MARK: - Stepper Control

    private func stepperControl(value: Binding<Int>, range: ClosedRange<Int>, step: Int = 1, label: String) -> some View {
        HStack(spacing: 12) {
            // Minus button
            Button(action: {
                if value.wrappedValue > range.lowerBound {
                    HapticManager.light()
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - step)
                }
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(value.wrappedValue > range.lowerBound ? AppConstants.Colors.primaryGreen : .gray)
            }
            .disabled(value.wrappedValue <= range.lowerBound)

            // Value label
            Text(label)
                .font(.custom(AppConstants.Fonts.semiBold, size: 14))
                .foregroundColor(.white)
                .frame(minWidth: 60)

            // Plus button
            Button(action: {
                if value.wrappedValue < range.upperBound {
                    HapticManager.light()
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + step)
                }
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(value.wrappedValue < range.upperBound ? AppConstants.Colors.primaryGreen : .gray)
            }
            .disabled(value.wrappedValue >= range.upperBound)
        }
    }

    // MARK: - Info Banner

    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(AppConstants.Colors.primaryGreen)

            Text(String(format: NSLocalizedString(StringKeys.Profile.applyNextWeek, comment: ""), profileManager.formatNextMondayDisplay()))
                .font(.custom(AppConstants.Fonts.regular, size: 13))
                .foregroundColor(.white.opacity(0.8))

            Spacer()
        }
        .padding(AppConstants.Layout.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadiusSmall)
                .fill(AppConstants.Colors.primaryGreen.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadiusSmall)
                        .stroke(AppConstants.Colors.primaryGreen.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Data Loading

    private func loadData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isLoading = true

        Task {
            do {
                // Load goals
                let fetchedGoals = try await profileManager.fetchCurrentGoals(uid: uid)
                let fetchedPerformances = try await profileManager.fetchAllPerformances(uid: uid)

                await MainActor.run {
                    self.goals = fetchedGoals
                    self.performances = fetchedPerformances
                    self.isLoading = false

                    // Load user info from FirebaseManager
                    if let user = FirebaseManager.shared.currentUser {
                        self.firstName = user.displayName ?? ""
                    }

                    // Load sleep times from UserSettings
                    if let settings = UserSettings.loadFromUserDefaults() {
                        if let bedComponents = timeComponents(from: settings.bedTime) {
                            self.bedTime = Calendar.current.date(from: bedComponents) ?? Date()
                        }
                        if let wakeComponents = timeComponents(from: settings.wakeUpTime) {
                            self.wakeTime = Calendar.current.date(from: wakeComponents) ?? Date()
                        }
                    }
                }
            } catch {
                print("Error loading profile data: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Save Profile

    private func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isSaving = true
        HapticManager.medium()

        Task {
            do {
                // Save personal info
                let bedTimeString = timeString(from: bedTime)
                let wakeTimeString = timeString(from: wakeTime)

                try await profileManager.updatePersonalInfo(
                    uid: uid,
                    firstName: firstName.isEmpty ? nil : firstName,
                    bedTime: bedTimeString,
                    wakeTime: wakeTimeString
                )

                // Save goals
                let goalsArray = Array(goals.values)
                try await profileManager.updateGoals(uid: uid, goals: goalsArray)

                await MainActor.run {
                    self.isSaving = false
                    HapticManager.success()
                    dismiss()
                }
            } catch {
                print("Error saving profile: \(error)")
                await MainActor.run {
                    self.isSaving = false
                    HapticManager.error()
                }
            }
        }
    }

    // MARK: - Save Profile Photo

    private func saveProfilePhoto(_ image: UIImage) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        // Compress and convert to base64
        guard let imageData = image.jpegData(compressionQuality: 0.7),
              let base64String = imageData.base64EncodedString() as String? else {
            print("Error: Could not convert image to base64")
            return
        }

        Task {
            do {
                try await FirebaseManager.shared.updateUserProfile(
                    uid: uid,
                    updates: ["profilePhotoBase64": base64String]
                )
                print("✅ Profile photo saved successfully")
                HapticManager.success()
            } catch {
                print("Error saving profile photo: \(error)")
                HapticManager.error()
            }
        }
    }

    // MARK: - Helper Methods

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func timeComponents(from timeString: String) -> DateComponents? {
        let parts = timeString.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }
        return DateComponents(hour: hour, minute: minute)
    }
}

#Preview {
    EditProfileView()
}
