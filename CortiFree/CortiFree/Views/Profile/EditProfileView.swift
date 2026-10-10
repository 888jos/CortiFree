//
//  EditProfileView.swift
//  CortiFree
//
//  Created by Claude on 18/11/2025.
//  Refactored: Simplified profile editing without habit customization
//

import SwiftUI
import AuthenticationServices

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel

    // Personal Info
    @State private var firstName: String = ""
    @State private var userEmail: String = ""

    // Alerts
    @State private var showRestartAlert: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showLogoutAlert: Bool = false

    // Photo picker
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var storedPhoto: UIImage?

    // Loading states
    @State private var isSaving = false
    @State private var isDeletingAccount = false
    @State private var showReauthAlert = false
    @State private var reauthPassword = ""
    @State private var saveErrorMessage: String?
    @FocusState private var focusedField: PersonalInfoField?

    private enum PersonalInfoField {
        case firstName
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.75)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 1. Profile Photo Section
                        profilePhotoSection

                        // 2. Personal Info Section
                        personalInfoSection

                        // 3. Goals Section (66 days objectives)
                        goalsSection

                        // 4. Account Management Section
                        accountSection

                        // App version at bottom
                        appVersionFooter

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
            if let image = newImage, image !== storedPhoto {
                saveProfilePhoto(image)
            }
        }
        .alert(LanguageManager.shared.localizedString(for: "editprofile.alert.restart.title"), isPresented: $showRestartAlert) {
            Button(LanguageManager.shared.localizedString(for: "common.cancel"), role: .cancel) { }
            Button(LanguageManager.shared.localizedString(for: "editprofile.alert.restart.button"), role: .destructive) {
                restartProgram()
            }
        } message: {
            Text(LanguageManager.shared.localizedString(for: "editprofile.alert.restart.message"))
        }
        .alert(LanguageManager.shared.localizedString(for: "editprofile.alert.delete.title"), isPresented: $showDeleteAlert) {
            Button(LanguageManager.shared.localizedString(for: "common.cancel"), role: .cancel) { }
            Button(LanguageManager.shared.localizedString(for: "editprofile.alert.delete.button"), role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text(LanguageManager.shared.localizedString(for: "editprofile.alert.delete.message"))
        }
        .alert(LanguageManager.shared.localizedString(for: "editprofile.alert.logout.title"), isPresented: $showLogoutAlert) {
            Button(LanguageManager.shared.localizedString(for: "common.cancel"), role: .cancel) { }
            Button(LanguageManager.shared.localizedString(for: "editprofile.alert.logout.button"), role: .destructive) {
                logout()
            }
        } message: {
            Text(LanguageManager.shared.localizedString(for: "editprofile.alert.logout.message"))
        }
        .alert(LanguageManager.shared.localizedString(for: "editprofile.title"), isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button(LanguageManager.shared.localizedString(for: "common.ok"), role: .cancel) {
                saveErrorMessage = nil
            }
        } message: {
            Text(saveErrorMessage ?? LanguageManager.shared.localizedString(for: "error.generic"))
        }
        .alert(
            LanguageManager.shared.localizedString(for: "inline.settingsview.language.00"),
            isPresented: $showReauthAlert
        ) {
            SecureField(
                LanguageManager.shared.localizedString(for: "inline.settingsview.language.01"),
                text: $reauthPassword
            )
            Button(LanguageManager.shared.localizedString(for: "common.cancel"), role: .cancel) {
                reauthPassword = ""
            }
            Button(LanguageManager.shared.localizedString(for: "editprofile.alert.delete.button"), role: .destructive) {
                let password = reauthPassword
                reauthPassword = ""
                Task {
                    do {
                        try await AccountDeletionService.shared.reauthenticateWithPassword(password: password)
                        await performAccountDeletion()
                    } catch {
                        saveErrorMessage = error.localizedDescription
                    }
                }
            }
        } message: {
            Text(LanguageManager.shared.localizedString(for: "inline.settingsview.language.02"))
        }
        .overlay {
            if isDeletingAccount {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    ProgressView().tint(.white).scaleEffect(1.4)
                }
            }
        }
        .allowsHitTesting(!isDeletingAccount)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: {
                HapticManager.light()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassCircle(interactive: true)

            Spacer()

            Text(LanguageManager.shared.localizedString(for: "editprofile.title"))
                .font(.custom(AppConstants.Fonts.bold, size: 20))
                .foregroundColor(.white)

            Spacer()

            Button(action: {
                HapticManager.medium()
                saveProfile()
            }) {
                Group {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(LanguageManager.shared.localizedString(for: "common.save"))
                            .font(.custom(AppConstants.Fonts.semiBold, size: 16))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 40)
            }
            .buttonStyle(.glassSecondary)
            .disabled(isSaving)
        }
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
        .padding(.top, 20)
        .padding(.bottom, AppConstants.Layout.paddingMedium)
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

            Text(LanguageManager.shared.localizedString(for: "editprofile.change_photo"))
                .font(.custom(AppConstants.Fonts.regular, size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 20)
    }

    // MARK: - Personal Info Section

    private var personalInfoSection: some View {
        VStack(spacing: 16) {
            // Section title
            HStack {
                Image(systemName: "person.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppConstants.Colors.violet)

                Text(LanguageManager.shared.localizedString(for: "editprofile.section.personal_info"))
                    .font(.custom(AppConstants.Fonts.semiBold, size: 16))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }

            // First Name (editable)
            VStack(alignment: .leading, spacing: 8) {
                Text(LanguageManager.shared.localizedString(for: "editprofile.first_name"))
                    .font(.custom(AppConstants.Fonts.medium, size: 13))
                    .foregroundColor(.white.opacity(0.6))

                TextField(
                    LanguageManager.shared.localizedString(for: "editprofile.first_name"),
                    text: $firstName
                )
                    .font(.custom(AppConstants.Fonts.regular, size: 16))
                    .foregroundColor(.white)
                    .tint(AppConstants.Colors.violet)
                    .textContentType(.givenName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($focusedField, equals: .firstName)
                    .textFieldStyle(.plain)
                    .padding(AppConstants.Layout.paddingMedium)
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadiusSmall, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadiusSmall, style: .continuous)
                            .stroke(
                                focusedField == .firstName ? AppConstants.Colors.violet : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
                    .contentShape(Rectangle())
                    .onSubmit { focusedField = nil }
            }

            // Email (read-only)
            VStack(alignment: .leading, spacing: 8) {
                Text(LanguageManager.shared.localizedString(for: "editprofile.email"))
                    .font(.custom(AppConstants.Fonts.medium, size: 13))
                    .foregroundColor(.white.opacity(0.6))

                HStack {
                    Text(userEmail)
                        .font(.custom(AppConstants.Fonts.regular, size: 16))
                        .foregroundColor(.white.opacity(0.5))

                    Spacer()

                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(AppConstants.Layout.paddingMedium)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadiusSmall, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
            }
        }
        .padding(AppConstants.Layout.paddingLarge)
        .glassCard(cornerRadius: 22)
    }

    // MARK: - Goals Section (66 Days Objectives)

    private var goalsSection: some View {
        VStack(spacing: 16) {
            // Section title
            HStack {
                Image(systemName: "target")
                    .font(.system(size: 18))
                    .foregroundColor(AppConstants.Colors.primaryGreen)

                Text(LanguageManager.shared.localizedString(for: "editprofile.section.goals"))
                    .font(.custom(AppConstants.Fonts.semiBold, size: 16))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }

            // 8 Habits with final objectives (aligned with HabitsProgressFlowView)
            VStack(spacing: 12) {
                goalRow(icon: "wind", name: LanguageManager.shared.localizedString(for: "editprofile.habit.breathing"), objective: LanguageManager.shared.localizedString(for: "editprofile.goal.breathing"), color: AppConstants.Colors.domainSerenity)
                goalRow(icon: "brain.head.profile", name: LanguageManager.shared.localizedString(for: "editprofile.habit.meditation"), objective: LanguageManager.shared.localizedString(for: "editprofile.goal.meditation"), color: AppConstants.Colors.violet)
                goalRow(icon: "book.fill", name: LanguageManager.shared.localizedString(for: "editprofile.habit.journal"), objective: LanguageManager.shared.localizedString(for: "editprofile.goal.journal"), color: AppConstants.Colors.journalReflection)
                goalRow(icon: "figure.run", name: LanguageManager.shared.localizedString(for: "editprofile.habit.sport"), objective: LanguageManager.shared.localizedString(for: "editprofile.goal.sport"), color: AppConstants.Colors.domainEnergy)
                goalRow(icon: "drop.fill", name: LanguageManager.shared.localizedString(for: "editprofile.habit.hydration"), objective: LanguageManager.shared.localizedString(for: "editprofile.goal.hydration"), color: .blue)
                goalRow(icon: "leaf.fill", name: LanguageManager.shared.localizedString(for: "editprofile.habit.nature"), objective: LanguageManager.shared.localizedString(for: "editprofile.goal.nature"), color: AppConstants.Colors.domainFocus)
                goalRow(icon: "person.2.fill", name: LanguageManager.shared.localizedString(for: "editprofile.habit.social"), objective: LanguageManager.shared.localizedString(for: "editprofile.goal.social"), color: AppConstants.Colors.domainBalance)
                goalRow(icon: "moon.stars.fill", name: LanguageManager.shared.localizedString(for: "editprofile.habit.sleep"), objective: LanguageManager.shared.localizedString(for: "editprofile.goal.sleep"), color: AppConstants.Colors.domainSleep)
            }
        }
        .padding(AppConstants.Layout.paddingLarge)
        .glassCard(cornerRadius: 22)
    }

    // MARK: - Goal Row

    private func goalRow(icon: String, name: String, objective: String, color: Color) -> some View {
        HStack {
            // Icon + Name
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 24)

                Text(name)
                    .font(.custom(AppConstants.Fonts.medium, size: 15))
                    .foregroundColor(.white)
            }

            Spacer()

            // Objective
            Text(objective)
                .font(.custom(AppConstants.Fonts.regular, size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 8)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(spacing: 16) {
            // Section title
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.6))

                Text(LanguageManager.shared.localizedString(for: "editprofile.section.account"))
                    .font(.custom(AppConstants.Fonts.semiBold, size: 16))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }

            // Restart Program Button
            Button(action: {
                HapticManager.medium()
                showRestartAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .semibold))

                    Text(LanguageManager.shared.localizedString(for: "editprofile.restart_program"))
                        .font(.custom(AppConstants.Fonts.semiBold, size: 15))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
                .foregroundColor(.white)
                .padding(AppConstants.Layout.paddingMedium)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadiusSmall)
                        .fill(AppConstants.Colors.violet.opacity(0.22))
                )
            }

            if authViewModel.isAuthenticated {
                // Logout Button
                Button(action: {
                    HapticManager.light()
                    showLogoutAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .semibold))

                        Text(LanguageManager.shared.localizedString(for: "editprofile.logout"))
                            .font(.custom(AppConstants.Fonts.semiBold, size: 15))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .foregroundColor(.white)
                    .padding(AppConstants.Layout.paddingMedium)
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadiusSmall)
                            .fill(Color.white.opacity(0.06))
                    )
                }

                // Delete Account Button
                Button(action: {
                    HapticManager.medium()
                    showDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .semibold))

                        Text(LanguageManager.shared.localizedString(for: "editprofile.delete_account"))
                            .font(.custom(AppConstants.Fonts.semiBold, size: 15))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.5))
                    }
                    .foregroundColor(.red)
                    .padding(AppConstants.Layout.paddingMedium)
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadiusSmall)
                            .fill(Color.red.opacity(0.14))
                    )
                }
            }
        }
        .padding(AppConstants.Layout.paddingLarge)
        .glassCard(cornerRadius: 22)
    }

    // MARK: - App Version Footer

    private var appVersionFooter: some View {
        VStack(spacing: 4) {
            Text("CortiFree")
                .font(.custom(AppConstants.Fonts.semiBold, size: 14))
                .foregroundColor(.white.opacity(0.4))

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Version \(version) (\(build))")
                    .font(.custom(AppConstants.Fonts.regular, size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.top, 24)
    }

    // MARK: - Data Loading

    private func loadData() {
        // The local name is the source of truth before authentication or sync.
        if let storedName = UserPersistence.userFirstName,
           !storedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            firstName = storedName
        }

        // Load user info from Firebase Auth
        if let user = Auth.auth().currentUser {
            userEmail = user.email ?? ""
        }

        // Load first name from FirebaseManager
        if firstName.isEmpty, let user = FirebaseManager.shared.currentUser {
            firstName = user.displayName ?? ""
        }

        // Fallback: try to load from UserDefaults
        if firstName.isEmpty {
            firstName = UserDefaults.standard.string(forKey: "userFirstName") ?? ""
        }

        // Existing profile photo (local copy, saved on every change)
        if selectedImage == nil, let photo = ProfilePhotoStorage.load() {
            storedPhoto = photo
            selectedImage = photo
        }
    }

    // MARK: - Save Profile

    private func saveProfile() {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFirstName.isEmpty else {
            saveErrorMessage = LanguageManager.shared.localizedString(for: "editprofile.first_name_required")
            focusedField = .firstName
            return
        }

        isSaving = true
        focusedField = nil
        HapticManager.medium()

        // Persist immediately so profile editing works offline and before sign-in.
        UserPersistence.userFirstName = trimmedFirstName

        Task {
            if let user = Auth.auth().currentUser {
                do {
                    try await FirebaseManager.shared.updateUserProfile(
                        uid: user.uid,
                        updates: ["firstName": trimmedFirstName, "displayName": trimmedFirstName]
                    )
                } catch {
                    #if DEBUG
                    print("Profile Firestore name sync failed: \(error)")
                    #endif
                }
            }

            await MainActor.run {
                firstName = trimmedFirstName
                isSaving = false
                NotificationCenter.default.post(name: NSNotification.Name("ProfileUpdated"), object: nil)
                HapticManager.success()
                dismiss()
            }
        }
    }

    // MARK: - Save Profile Photo

    private func saveProfilePhoto(_ image: UIImage) {
        // Resized before upload to Convex file storage.
        guard let imageData = ProfilePhotoStorage.compressedJPEG(from: image) else {
            HapticManager.error()
            return
        }

        // Local first: works offline and for signed-out users
        ProfilePhotoStorage.save(imageData)
        NotificationCenter.default.post(name: NSNotification.Name("ProfileUpdated"), object: nil)
        HapticManager.success()

        guard let uid = Auth.auth().currentUser?.uid else { return }
        let base64String = imageData.base64EncodedString()
        Task {
            do {
                try await FirebaseManager.shared.updateUserProfile(
                    uid: uid,
                    updates: ["profilePhotoBase64": base64String]
                )
            } catch {
                #if DEBUG
                print("Error saving profile photo: \(error)")
                #endif
            }
        }
    }

    // MARK: - Restart Program

    private func restartProgram() {
        HapticManager.success()

        // Reset to day 1, week 1
        UserDefaults.standard.set(1, forKey: "currentWeek")
        UserDefaults.standard.set(1, forKey: "currentDay")
        UserDefaults.standard.set(Date(), forKey: "routineStartDate")

        // Reset streaks and this device's completions: old days 1…N must not count in the new run.
        StreakService.reset(userID: Auth.auth().currentUser?.uid ?? UserPersistence.localUserID)

        // Day 1 starts today at midnight; keep every other user setting intact
        let newStartDate = UserSettings.calculateProgramStartDate()
        UserDefaults.standard.set(newStartDate, forKey: "programStartDate")
        var localSettings = UserSettings.loadFromUserDefaults() ?? UserSettings()
        localSettings.programStartDate = newStartDate
        localSettings.saveToUserDefaults()
        ProgressAnalyticsService.shared.invalidateDashboardCache()
        // The plan restarts at day 1 too, otherwise plan days and history keys drift apart.
        PersonalPlanStore.shared.restartFromDayOne()

        // Update Firebase programStartDate
        if let uid = Auth.auth().currentUser?.uid {
            Task {
                do {
                    var settings = (try? await FirebaseManager.shared.fetchUserSettings(uid: uid)) ?? localSettings
                    settings.programStartDate = newStartDate
                    try await FirebaseManager.shared.saveUserSettings(uid: uid, settings: settings)
                    try await FirebaseManager.shared.resetProgramDayData(uid: uid)
                    ProgressAnalyticsService.shared.invalidateDashboardCache()
                    #if DEBUG
                    print("✅ Program restarted to day 1")
                    #endif
                } catch {
                    #if DEBUG
                    print("❌ Error resetting program: \(error)")
                    #endif
                }
            }
        }

        // Notify other views to refresh
        NotificationCenter.default.post(name: NSNotification.Name("ProgramRestarted"), object: nil)

        dismiss()
    }

    // MARK: - Delete Account

    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }

        switch AccountDeletionService.shared.reauthMethod(for: user) {
        case .password:
            showReauthAlert = true
        case .apple:
            Task {
                do {
                    try await AccountDeletionService.shared.reauthenticateWithApple()
                    await performAccountDeletion()
                } catch {
                    if (error as? ASAuthorizationError)?.code == .canceled { return }
                    saveErrorMessage = error.localizedDescription
                }
            }
        case .none, .unsupported:
            Task { await performAccountDeletion() }
        }
    }

    @MainActor
    private func performAccountDeletion() async {
        isDeletingAccount = true
        do {
            // Firestore data (incl. subcollections), Auth user, identities, local state
            try await AccountDeletionService.shared.deleteAccount()
            HapticManager.success()
            isDeletingAccount = false
            authViewModel.signOut()
            dismiss()
        } catch AccountDeletionService.DeletionError.requiresRecentLogin {
            isDeletingAccount = false
            if Auth.auth().currentUser?.providerData.contains(where: { $0.providerID == "password" }) == true {
                showReauthAlert = true
            } else {
                saveErrorMessage = AccountDeletionService.DeletionError.requiresRecentLogin.errorDescription
            }
        } catch {
            isDeletingAccount = false
            HapticManager.error()
            saveErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Logout

    private func logout() {
        HapticManager.light()
        authViewModel.signOut()
        dismiss()
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AuthViewModel())
}
