//
//  EditProfileView.swift
//  CortiFree
//
//  Created by Claude on 18/11/2025.
//  Refactored: Simplified profile editing without habit customization
//

import SwiftUI
import FirebaseAuth

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

    // Loading states
    @State private var isSaving = false

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
            if let image = newImage {
                saveProfilePhoto(image)
            }
        }
        .alert(NSLocalizedString("editprofile.alert.restart.title", comment: ""), isPresented: $showRestartAlert) {
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) { }
            Button(NSLocalizedString("editprofile.alert.restart.button", comment: ""), role: .destructive) {
                restartProgram()
            }
        } message: {
            Text(NSLocalizedString("editprofile.alert.restart.message", comment: ""))
        }
        .alert(NSLocalizedString("editprofile.alert.delete.title", comment: ""), isPresented: $showDeleteAlert) {
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) { }
            Button(NSLocalizedString("editprofile.alert.delete.button", comment: ""), role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text(NSLocalizedString("editprofile.alert.delete.message", comment: ""))
        }
        .alert(NSLocalizedString("editprofile.alert.logout.title", comment: ""), isPresented: $showLogoutAlert) {
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) { }
            Button(NSLocalizedString("editprofile.alert.logout.button", comment: ""), role: .destructive) {
                logout()
            }
        } message: {
            Text(NSLocalizedString("editprofile.alert.logout.message", comment: ""))
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
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(NSLocalizedString("editprofile.title", comment: ""))
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
                    Text(NSLocalizedString("common.save", comment: ""))
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

            Text(NSLocalizedString("editprofile.change_photo", comment: ""))
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

                Text(NSLocalizedString("editprofile.section.personal_info", comment: ""))
                    .font(.custom(AppConstants.Fonts.semiBold, size: 16))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }

            // First Name (editable)
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("editprofile.first_name", comment: ""))
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

            // Email (read-only)
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("editprofile.email", comment: ""))
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
                    RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadiusSmall)
                        .fill(Color.white.opacity(0.05))
                )
            }
        }
        .padding(AppConstants.Layout.paddingLarge)
    }

    // MARK: - Goals Section (66 Days Objectives)

    private var goalsSection: some View {
        VStack(spacing: 16) {
            // Section title
            HStack {
                Image(systemName: "target")
                    .font(.system(size: 18))
                    .foregroundColor(AppConstants.Colors.primaryGreen)

                Text(NSLocalizedString("editprofile.section.goals", comment: ""))
                    .font(.custom(AppConstants.Fonts.semiBold, size: 16))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }

            // 8 Habits with final objectives (aligned with HabitsProgressFlowView)
            VStack(spacing: 12) {
                goalRow(icon: "wind", name: NSLocalizedString("editprofile.habit.breathing", comment: ""), objective: NSLocalizedString("editprofile.goal.breathing", comment: ""), color: AppConstants.Colors.domainSerenity)
                goalRow(icon: "brain.head.profile", name: NSLocalizedString("editprofile.habit.meditation", comment: ""), objective: NSLocalizedString("editprofile.goal.meditation", comment: ""), color: AppConstants.Colors.violet)
                goalRow(icon: "book.fill", name: NSLocalizedString("editprofile.habit.journal", comment: ""), objective: NSLocalizedString("editprofile.goal.journal", comment: ""), color: AppConstants.Colors.journalReflection)
                goalRow(icon: "figure.run", name: NSLocalizedString("editprofile.habit.sport", comment: ""), objective: NSLocalizedString("editprofile.goal.sport", comment: ""), color: AppConstants.Colors.domainEnergy)
                goalRow(icon: "drop.fill", name: NSLocalizedString("editprofile.habit.hydration", comment: ""), objective: NSLocalizedString("editprofile.goal.hydration", comment: ""), color: .blue)
                goalRow(icon: "leaf.fill", name: NSLocalizedString("editprofile.habit.nature", comment: ""), objective: NSLocalizedString("editprofile.goal.nature", comment: ""), color: AppConstants.Colors.domainFocus)
                goalRow(icon: "person.2.fill", name: NSLocalizedString("editprofile.habit.social", comment: ""), objective: NSLocalizedString("editprofile.goal.social", comment: ""), color: AppConstants.Colors.domainBalance)
                goalRow(icon: "moon.stars.fill", name: NSLocalizedString("editprofile.habit.sleep", comment: ""), objective: NSLocalizedString("editprofile.goal.sleep", comment: ""), color: AppConstants.Colors.domainSleep)
            }
        }
        .padding(AppConstants.Layout.paddingLarge)
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

                Text(NSLocalizedString("editprofile.section.account", comment: ""))
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

                    Text(NSLocalizedString("editprofile.restart_program", comment: ""))
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
                        .fill(AppConstants.Colors.violet.opacity(0.3))
                )
            }

            // Logout Button
            Button(action: {
                HapticManager.light()
                showLogoutAlert = true
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .semibold))

                    Text(NSLocalizedString("editprofile.logout", comment: ""))
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
                        .fill(Color.white.opacity(0.1))
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

                    Text(NSLocalizedString("editprofile.delete_account", comment: ""))
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
                        .fill(Color.red.opacity(0.15))
                )
            }
        }
        .padding(AppConstants.Layout.paddingLarge)
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
        // Load user info from Firebase Auth
        if let user = Auth.auth().currentUser {
            userEmail = user.email ?? ""
        }

        // Load first name from FirebaseManager
        if let user = FirebaseManager.shared.currentUser {
            firstName = user.displayName ?? ""
        }

        // Fallback: try to load from UserDefaults
        if firstName.isEmpty {
            firstName = UserDefaults.standard.string(forKey: "userFirstName") ?? ""
        }
    }

    // MARK: - Save Profile

    private func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid,
              let user = Auth.auth().currentUser else { return }

        isSaving = true
        HapticManager.medium()

        Task {
            do {
                // 1. Update Firebase Auth displayName (this is what ProfileCardView uses)
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = firstName
                try await changeRequest.commitChanges()

                // 2. Save first name to Firestore
                try await FirebaseManager.shared.updateUserProfile(
                    uid: uid,
                    updates: ["firstName": firstName, "displayName": firstName]
                )

                // 3. Save to UserDefaults for offline access
                UserDefaults.standard.set(firstName, forKey: "userFirstName")

                // 4. Notify other views to refresh immediately
                NotificationCenter.default.post(name: NSNotification.Name("ProfileUpdated"), object: nil)

                await MainActor.run {
                    isSaving = false
                    HapticManager.success()
                    dismiss()
                }
            } catch {
                #if DEBUG
                print("Error saving profile: \(error)")
                #endif
                await MainActor.run {
                    isSaving = false
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
            #if DEBUG
            print("Error: Could not convert image to base64")
            #endif
            return
        }

        Task {
            do {
                try await FirebaseManager.shared.updateUserProfile(
                    uid: uid,
                    updates: ["profilePhotoBase64": base64String]
                )
                #if DEBUG
                print("✅ Profile photo saved successfully")
                #endif
                HapticManager.success()
            } catch {
                #if DEBUG
                print("Error saving profile photo: \(error)")
                #endif
                HapticManager.error()
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

        // Reset streaks
        UserDefaults.standard.set(0, forKey: "streakDays")
        UserDefaults.standard.set(0, forKey: "bestStreak")

        // Update Firebase programStartDate
        if let uid = Auth.auth().currentUser?.uid {
            Task {
                do {
                    var settings = UserSettings()
                    settings.programStartDate = Date()
                    try await FirebaseManager.shared.saveUserSettings(uid: uid, settings: settings)
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
        HapticManager.success()

        Task {
            do {
                // Delete Firebase account and all Firestore data
                try await Auth.auth().currentUser?.delete()

                // Clear all local UserDefaults data
                if let domain = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.removePersistentDomain(forName: domain)
                    UserDefaults.standard.synchronize()
                }

                // Sign out the user
                await MainActor.run {
                    authViewModel.signOut()
                    dismiss()
                }
            } catch {
                #if DEBUG
                print("❌ Error deleting account: \(error)")
                #endif
                HapticManager.error()
            }
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
