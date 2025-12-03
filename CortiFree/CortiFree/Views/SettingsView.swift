import SwiftUI
import SafariServices
import FirebaseAuth
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("appLanguage") private var appLanguage: String = {
        // Détection de la région pour la langue par défaut
        let regionCode = Locale.current.region?.identifier ?? ""
        let frenchSpeakingRegions = ["FR", "BE", "CH", "CA", "LU", "MC", "CD", "CI", "SN", "ML", "NE", "BF", "BJ", "TG", "CM", "GA", "CG", "MG", "RE", "GP", "MQ", "GF", "NC", "PF"]

        // Si région francophone -> français, sinon anglais
        return frenchSpeakingRegions.contains(regionCode) ? "fr" : "en"
    }()

    // ViewModel for settings management
    @StateObject private var viewModel = SettingsViewModel()

    // UI State only
    @State private var showLanguagePicker: Bool = false
    @State private var showDebugSection: Bool = false
    @State private var versionTapCount: Int = 0
    @State private var showSafari: Bool = false
    @State private var safariURL: URL?
    @State private var showProfileEdit: Bool = false
    @State private var showDeleteAccountAlert: Bool = false
    @State private var showSignOutAlert: Bool = false
    @State private var showLanguageChangeAlert: Bool = false
    @State private var pendingLanguage: String?
    @State private var showResetUserDefaultsAlert: Bool = false
    @State private var showClearAllDataAlert: Bool = false
    @State private var currentStreak: Int = 0

    var body: some View {
        ZStack {
            // Galaxy background
            LinearGradient(
                colors: [Color(hex: "1F0140"), Color(hex: "01000C")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                settingsScrollView
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerSheet(
                selectedLanguage: $appLanguage,
                onLanguageChange: { newLanguage in
                    pendingLanguage = newLanguage
                    showLanguageChangeAlert = true
                }
            )
        }
        .alert(NSLocalizedString("settings.alert.signout.title", comment: ""), isPresented: $showSignOutAlert) {
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) { }
            Button(NSLocalizedString("settings.alert.signout.title", comment: ""), role: .destructive) {
                signOut()
            }
        } message: {
            Text(NSLocalizedString("settings.alert.signout.message", comment: ""))
        }
        .alert(NSLocalizedString("settings.alert.delete.title", comment: ""), isPresented: $showDeleteAccountAlert) {
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) { }
            Button(NSLocalizedString("settings.alert.delete.button", comment: ""), role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text(NSLocalizedString("settings.alert.delete.message", comment: ""))
        }
        .alert(StringKeys.Settings.languageRestartNote, isPresented: $showLanguageChangeAlert) {
            Button(StringKeys.Common.cancel, role: .cancel) {
                pendingLanguage = nil
            }
            Button(StringKeys.Common.continueButton, role: .destructive) {
                if let newLanguage = pendingLanguage {
                    applyLanguageChange(newLanguage)
                }
            }
        } message: {
            Text(NSLocalizedString("settings.alert.language_restart.message", comment: ""))
        }
        .alert(NSLocalizedString("settings.alert.reset_defaults.title", comment: ""), isPresented: $showResetUserDefaultsAlert) {
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) { }
            Button(NSLocalizedString("settings.alert.reset_defaults.button", comment: ""), role: .destructive) {
                resetUserDefaults()
            }
        } message: {
            Text(NSLocalizedString("settings.alert.reset_defaults.message", comment: ""))
        }
        .alert(NSLocalizedString("settings.alert.clear_data.title", comment: ""), isPresented: $showClearAllDataAlert) {
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) { }
            Button(NSLocalizedString("settings.alert.clear_data.button", comment: ""), role: .destructive) {
                clearAllData()
            }
        } message: {
            Text(NSLocalizedString("settings.alert.clear_data.message", comment: ""))
        }
        .onAppear {
            viewModel.calculateLocalDataSize()
            // Load initial streak value
            currentStreak = UserDefaults.standard.integer(forKey: "streakDays")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StreakUpdated"))) { _ in
            // Reload streak when updated from TasksV2View
            currentStreak = UserDefaults.standard.integer(forKey: "streakDays")
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: {
                HapticManager.light()
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }

            Spacer()

            Text(NSLocalizedString("settings.title", comment: ""))
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.white)

            Spacer()

            // Invisible spacer for centering
            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 20)
    }

    // MARK: - Settings Scroll View
    private var settingsScrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                profileObjectiveSection
                statisticsSection
                subscriptionSection
                privacySecuritySection
                aboutSupportSection

                if showDebugSection {
                    debugSection
                }

                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Profile & Objective Section
    private var profileObjectiveSection: some View {
        settingsSection(title: NSLocalizedString("settings.section.profile", comment: ""), icon: "person.circle.fill") {
            VStack(spacing: 0) {
                settingsRow(
                    icon: "globe",
                    title: NSLocalizedString("settings.language", comment: ""),
                    subtitle: appLanguage == "en" ? "English" : "Français",
                    showChevron: true
                ) {
                    HapticManager.light()
                    showLanguagePicker = true
                }

                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 48)

                settingsToggleRow(
                    icon: "bell.fill",
                    title: StringKeys.Settings.notificationsToggle,
                    subtitle: NSLocalizedString("settings.notifications.subtitle", comment: ""),
                    isOn: $viewModel.notificationsEnabled
                )
            }
        }
    }

    // MARK: - Statistics Section
    private var statisticsSection: some View {
        settingsSection(title: NSLocalizedString("settings.section.statistics", comment: ""), icon: "chart.bar.fill") {
            VStack(spacing: 0) {
                // Streak days
                HStack(spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.orange)
                        .frame(width: 20, height: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("settings.streak.title", comment: ""))
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white)

                        Text(NSLocalizedString("settings.streak.subtitle", comment: ""))
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    Text(String(format: NSLocalizedString("settings.streak.days", comment: ""), currentStreak))
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(Color.appTheme)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                // Current week/day
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("settings.program.title", comment: ""))
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white)

                        Text(NSLocalizedString("settings.program.subtitle", comment: ""))
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    Text(String(format: NSLocalizedString("settings.program.week_day", comment: ""), UserDefaults.standard.integer(forKey: "currentWeek"), UserDefaults.standard.integer(forKey: "currentDay")))
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                // Firebase sync status (if enabled)
                if viewModel.syncEnabled {
                    HStack(spacing: 12) {
                        if viewModel.isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: viewModel.syncError == nil ? "checkmark.icloud.fill" : "exclamationmark.icloud.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(viewModel.syncError == nil ? .green : .orange)
                                .frame(width: 20, height: 20)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.isSyncing ? StringKeys.Settings.syncing : StringKeys.Settings.syncStatus)
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(.white)

                            if let lastSync = viewModel.lastSyncDate {
                                Text(String(format: NSLocalizedString("settings.sync.last_sync", comment: ""), formatSyncDate(lastSync)))
                                    .font(.custom("Poppins-Regular", size: 13))
                                    .foregroundColor(.white.opacity(0.5))
                            } else if let error = viewModel.syncError {
                                Text(String(format: NSLocalizedString("settings.sync.error", comment: ""), error))
                                    .font(.custom("Poppins-Regular", size: 13))
                                    .foregroundColor(.orange.opacity(0.8))
                            } else {
                                Text(NSLocalizedString("settings.sync.auto", comment: ""))
                                    .font(.custom("Poppins-Regular", size: 13))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        settingsSection(title: StringKeys.Settings.subscription, icon: "crown.fill") {
            VStack(spacing: 0) {
                settingsRow(icon: "checkmark.circle.fill", title: NSLocalizedString("settings.subscription.status", comment: ""), subtitle: viewModel.subscriptionStatus, showChevron: false) {}
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "arrow.clockwise", title: StringKeys.Settings.renewalDate, subtitle: viewModel.renewalDate.isEmpty ? "N/A" : viewModel.renewalDate, showChevron: false) {}
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "gearshape.fill", title: NSLocalizedString("settings.subscription.manage", comment: ""), subtitle: NSLocalizedString("settings.subscription.manage_subtitle", comment: ""), showChevron: true) {
                    HapticManager.light()
                    manageSubscription()
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "arrow.down.circle.fill", title: NSLocalizedString("settings.subscription.restore", comment: ""), subtitle: nil, showChevron: true) {
                    HapticManager.light()
                    restorePurchases()
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "rectangle.portrait.and.arrow.right", title: NSLocalizedString("settings.signout", comment: ""), subtitle: nil, showChevron: false, isDestructive: true) {
                    HapticManager.medium()
                    showSignOutAlert = true
                }
            }
        }
    }

    // MARK: - Privacy & Security Section
    private var privacySecuritySection: some View {
        settingsSection(title: NSLocalizedString("settings.section.privacy", comment: ""), icon: "lock.shield.fill") {
            VStack(spacing: 0) {
                settingsRow(icon: "doc.text.fill", title: NSLocalizedString("settings.privacy.policy", comment: ""), subtitle: nil, showChevron: true) {
                    HapticManager.light()
                    openURL("https://cortifree.com/privacy")
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "doc.plaintext.fill", title: NSLocalizedString("settings.privacy.terms", comment: ""), subtitle: nil, showChevron: true) {
                    HapticManager.light()
                    openURL("https://cortifree.com/terms")
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "trash.fill", title: NSLocalizedString("settings.privacy.delete_account", comment: ""), subtitle: NSLocalizedString("settings.privacy.delete_account_subtitle", comment: ""), showChevron: true, isDestructive: true) {
                    HapticManager.heavy()
                    showDeleteAccountAlert = true
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "internaldrive.fill", title: StringKeys.Settings.localDataSize, subtitle: viewModel.localDataSize, showChevron: false) {}
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsToggleRow(icon: "arrow.triangle.2.circlepath.icloud", title: StringKeys.Settings.icloudSync, subtitle: NSLocalizedString("settings.privacy.icloud_subtitle", comment: ""), isOn: $viewModel.syncEnabled)
            }
        }
    }

    // MARK: - About & Support Section
    private var aboutSupportSection: some View {
        settingsSection(title: NSLocalizedString("settings.section.about", comment: ""), icon: "info.circle.fill") {
            VStack(spacing: 0) {
                Button(action: {
                    HapticManager.light()
                    versionTapCount += 1
                    if versionTapCount >= 3 {
                        withAnimation(.spring(response: 0.3)) {
                            showDebugSection = true
                        }
                        versionTapCount = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        versionTapCount = 0
                    }
                }) {
                    settingsRowContent(icon: "app.badge.fill", title: NSLocalizedString("settings.about.version", comment: ""), subtitle: "1.0.0 (Build 1)", showChevron: false, isDestructive: false)
                }
                .buttonStyle(PlainButtonStyle())

                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "envelope.fill", title: NSLocalizedString("settings.about.contact", comment: ""), subtitle: "contact.cortifree@gmail.com", showChevron: true) {
                    HapticManager.light()
                    openURL("mailto:contact.cortifree@gmail.com")
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "questionmark.circle.fill", title: NSLocalizedString("settings.about.faq", comment: ""), subtitle: nil, showChevron: true) {
                    HapticManager.light()
                    openURL("https://cortifree.com/faq")
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "star.fill", title: NSLocalizedString("settings.about.rate", comment: ""), subtitle: NSLocalizedString("settings.about.rate_subtitle", comment: ""), showChevron: true) {
                    HapticManager.light()
                    requestAppReview()
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "link", title: NSLocalizedString("settings.about.follow", comment: ""), subtitle: "@cortifree", showChevron: true) {
                    HapticManager.light()
                    openURL("https://twitter.com/cortifree")
                }
            }
        }
    }

    // MARK: - Debug Section
    private var debugSection: some View {
        settingsSection(title: "🐛 Debug", icon: "ladybug.fill") {
            VStack(spacing: 0) {
                settingsRow(icon: "hammer.fill", title: "Reset UserDefaults", subtitle: nil, showChevron: false) {
                    HapticManager.medium()
                    showResetUserDefaultsAlert = true
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "trash.circle.fill", title: "Clear all data", subtitle: nil, showChevron: false, isDestructive: true) {
                    HapticManager.heavy()
                    showClearAllDataAlert = true
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "arrow.clockwise.circle.fill", title: "Force sync", subtitle: nil, showChevron: false) {
                    HapticManager.light()
                    // Force sync is handled automatically by Firebase
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    // MARK: - Section Builder
    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Text(title)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "131146"))
            )
        }
    }

    // MARK: - Row Builders
    @ViewBuilder
    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String?,
        showChevron: Bool,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            settingsRowContent(
                icon: icon,
                title: title,
                subtitle: subtitle,
                showChevron: showChevron,
                isDestructive: isDestructive
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func settingsRowContent(
        icon: String,
        title: String,
        subtitle: String?,
        showChevron: Bool,
        isDestructive: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isDestructive ? .red : .white)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(isDestructive ? .red : .white)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func settingsToggleRow(
        icon: String,
        title: String,
        subtitle: String?,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.appTheme)
                .onChange(of: isOn.wrappedValue) { _ in
                    HapticManager.light()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func settingsTimeRow(
        icon: String,
        title: String,
        time: Binding<Date>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)

            Text(title)
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.white)

            Spacer()

            DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .colorScheme(.dark)
                .onChange(of: time.wrappedValue) { _ in
                    HapticManager.light()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func settingsSliderRow(
        icon: String,
        title: String,
        value: Binding<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)

                Text(title)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white)

                Spacer()

                Text("\(Int(value.wrappedValue * 100))%")
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }

            Slider(value: value, in: 0...1, step: 0.05)
                .tint(Color.appTheme)
                .onChange(of: value.wrappedValue) { _ in
                    HapticManager.light()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helper Functions
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            if urlString.hasPrefix("http") {
                safariURL = url
                showSafari = true
            } else {
                UIApplication.shared.open(url)
            }
        }
    }

    // MARK: - Statistics Helper Functions

    private func formatSyncDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: appLanguage)
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Language Change

    private func applyLanguageChange(_ newLanguage: String) {
        HapticManager.success()

        // Update @AppStorage variable immediately
        appLanguage = newLanguage

        // Save language preference to AppleLanguages for system-wide consistency
        UserDefaults.standard.set([newLanguage], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        // Force app termination to apply language change
        // The app needs to restart for the language bundle to reload
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }

    // MARK: - Helper Functions

    private func manageSubscription() {
        // Subscription management handled by Superwall in CortiFreeApp
    }

    private func restorePurchases() {
        // Restore purchases handled by Superwall in CortiFreeApp
    }

    private func requestAppReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func signOut() {
        HapticManager.success()

        // Sign out via AuthViewModel
        authViewModel.signOut()

        // Clear local data
        UserDefaults.standard.removeObject(forKey: "onboardingV2Completed")
        UserDefaults.standard.removeObject(forKey: "selectedRoutineId")
        UserDefaults.standard.removeObject(forKey: "selectedRoutineTitle")
        UserDefaults.standard.removeObject(forKey: "routineStartDate")

        // Dismiss settings (will automatically navigate to auth screen via CortiFreeApp)
        dismiss()
    }

    private func deleteAccount() {
        HapticManager.success()

        Task {
            do {
                // Delete Firebase account
                try await Auth.auth().currentUser?.delete()

                // Clear all local data
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()

                // Sign out
                authViewModel.signOut()

                dismiss()
            } catch {
                #if DEBUG
                print("❌ Error deleting account: \(error)")
                #endif
            }
        }
    }

    // MARK: - Debug Actions

    private func resetUserDefaults() {
        HapticManager.success()

        // Reset only UI preferences, keep progression data
        UserDefaults.standard.removeObject(forKey: "notificationsEnabled")
        UserDefaults.standard.removeObject(forKey: "morningRoutineEnabled")
        UserDefaults.standard.removeObject(forKey: "afternoonRoutineEnabled")
        UserDefaults.standard.removeObject(forKey: "eveningRoutineEnabled")
        UserDefaults.standard.removeObject(forKey: "morningTime")
        UserDefaults.standard.removeObject(forKey: "afternoonTime")
        UserDefaults.standard.removeObject(forKey: "eveningTime")
        UserDefaults.standard.removeObject(forKey: "defaultSound")
        UserDefaults.standard.removeObject(forKey: "voiceGuidance")
        UserDefaults.standard.removeObject(forKey: "ambientVolume")
        UserDefaults.standard.removeObject(forKey: "syncEnabled")
        UserDefaults.standard.synchronize()

        // Reload view model to show reset values
        viewModel.loadSettings()
    }

    private func clearAllData() {
        HapticManager.success()

        // Clear all UserDefaults including progression
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()

        // Reload view model
        viewModel.loadSettings()
        viewModel.calculateLocalDataSize()
    }

}

// MARK: - Routine Selection Sheet
struct RoutineSelectionSheet: View {
    @Binding var currentObjective: String
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRoutineId: String?
    @State private var showChangeWarning = false
    @State private var pendingPlan: RoutinePlan?

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Spacer()
                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                VStack(spacing: 12) {
                    Text(NSLocalizedString("settings.change_routine_title", comment: ""))
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)

                    Text(NSLocalizedString("settings.select_new_routine", comment: ""))
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 8)

                // Routines list
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(RoutinePlan.allPlans) { plan in
                            RoutineSelectionRow(
                                plan: plan,
                                isSelected: selectedRoutineId == plan.id
                            ) {
                                HapticManager.medium()

                                // Si c'est déjà la routine actuelle, ne rien faire
                                if selectedRoutineId == plan.id {
                                    return
                                }

                                // Sinon, afficher l'avertissement
                                pendingPlan = plan
                                withAnimation(.spring(response: 0.3)) {
                                    showChangeWarning = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }

                Spacer()
            }

            // Custom Warning Popup
            if showChangeWarning {
                ZStack {
                    // Semi-transparent dark background
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                showChangeWarning = false
                                pendingPlan = nil
                            }
                        }

                    // Warning card
                    VStack(spacing: 0) {
                        // Header with warning icon
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.orange)

                            Text(NSLocalizedString("settings.warning_title", comment: ""))
                                .font(.custom("Poppins-Bold", size: 22))
                                .foregroundColor(.white)

                            Text(NSLocalizedString("settings.change_routine_warning", comment: ""))
                                .font(.custom("Poppins-Regular", size: 15))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 32)
                        .padding(.horizontal, 24)

                        // List of what will be reset
                        VStack(alignment: .leading, spacing: 12) {
                            WarningItem(text: NSLocalizedString("settings.current_progress", comment: ""))
                            WarningItem(text: NSLocalizedString("settings.task_history", comment: ""))
                            WarningItem(text: NSLocalizedString("settings.routine_stats", comment: ""))
                            WarningItem(text: NSLocalizedString("settings.start_date_reset", comment: ""))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        // What will be preserved
                        Text(NSLocalizedString("settings.xp_level_preserved", comment: ""))
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(Color.appTheme)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)

                        // Buttons
                        VStack(spacing: 12) {
                            // Confirm button (destructive)
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    showChangeWarning = false
                                }
                                if let plan = pendingPlan {
                                    changeRoutine(to: plan)
                                }
                            }) {
                                Text(NSLocalizedString("settings.confirm_change", comment: ""))
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.orange, Color.red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                            }

                            // Cancel button
                            Button(action: {
                                HapticManager.light()
                                withAnimation(.spring(response: 0.3)) {
                                    showChangeWarning = false
                                    pendingPlan = nil
                                }
                            }) {
                                Text(NSLocalizedString("common.cancel", comment: ""))
                                    .font(.custom("Poppins-Medium", size: 16))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                        .padding(.bottom, 32)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: "1A1B3A"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 32)
                    .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .onAppear {
            // Load current routine ID
            selectedRoutineId = UserDefaults.standard.string(forKey: "selectedRoutineId")
        }
    }

    private func changeRoutine(to plan: RoutinePlan) {
        HapticManager.success()
        selectedRoutineId = plan.id

        // Update routine in UserDefaults
        UserDefaults.standard.set(plan.id, forKey: "selectedRoutineId")
        UserDefaults.standard.set(plan.title, forKey: "selectedRoutineTitle")
        UserDefaults.standard.set(Date(), forKey: "routineStartDate")

        // Reset progress
        UserDefaults.standard.set(1, forKey: "currentWeek")
        UserDefaults.standard.set(1, forKey: "currentDay")

        // Update UI
        currentObjective = plan.title

        // Dismiss after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

// MARK: - Warning Item Component
struct WarningItem: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.orange)
                .padding(.top, 2)

            Text(text)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Routine Selection Row
struct RoutineSelectionRow: View {
    let plan: RoutinePlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon instead of planet
                Image(systemName: getIconForRoutine(plan.title))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color.appTheme)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.appTheme.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Text(getDescriptionForRoutine(plan.title))
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.appTheme)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        Color.appTheme.opacity(0.15) :
                        Color(hex: "131146")
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.appTheme.opacity(0.5) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func getIconForRoutine(_ title: String) -> String {
        if title.contains("stress") || title.contains("anxiété") {
            return "heart.fill"
        } else if title.contains("sommeil") || title.contains("dormir") {
            return "moon.fill"
        } else if title.contains("énergie") || title.contains("fatigue") {
            return "bolt.fill"
        } else if title.contains("concentration") || title.contains("focus") {
            return "brain"
        } else {
            return "star.fill"
        }
    }

    private func getDescriptionForRoutine(_ title: String) -> String {
        if title.contains("stress") {
            return NSLocalizedString("settings.routine_desc.stress", comment: "")
        } else if title.contains("sommeil") || title.contains("sleep") {
            return NSLocalizedString("settings.routine_desc.sleep", comment: "")
        } else if title.contains("énergie") || title.contains("energy") {
            return NSLocalizedString("settings.routine_desc.energy", comment: "")
        } else {
            return NSLocalizedString("settings.routine_desc.default", comment: "")
        }
    }
}

// MARK: - Sound Picker Sheet
struct SoundPickerSheet: View {
    @Binding var selectedSound: String
    @Environment(\.dismiss) private var dismiss

    var sounds: [String] {
        [
            NSLocalizedString("settings.forest_rain", comment: ""),
            NSLocalizedString("settings.ocean", comment: ""),
            NSLocalizedString("settings.fireplace", comment: ""),
            NSLocalizedString("settings.gentle_wind", comment: ""),
            NSLocalizedString("settings.river", comment: ""),
            NSLocalizedString("settings.morning_birds", comment: "")
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1F0140"), Color(hex: "01000C")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Text(NSLocalizedString("settings.relaxing_sounds", comment: ""))
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                VStack(spacing: 12) {
                    ForEach(sounds, id: \.self) { sound in
                        Button(action: {
                            HapticManager.medium()
                            selectedSound = sound
                            dismiss()
                        }) {
                            HStack {
                                Text(sound)
                                    .font(.custom("Poppins-Regular", size: 16))
                                    .foregroundColor(.white)

                                Spacer()

                                if selectedSound == sound {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color.appTheme)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "131146"))
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }
}

// MARK: - Language Picker Sheet
struct LanguagePickerSheet: View {
    @Binding var selectedLanguage: String
    var onLanguageChange: ((String) -> Void)?
    @Environment(\.dismiss) private var dismiss

    let languages = [
        ("fr", "Français", "🇫🇷"),
        ("en", "English", "🇬🇧")
    ]

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Spacer()
                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                VStack(spacing: 8) {
                    Text(NSLocalizedString("settings.choose_language", comment: ""))
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)

                    Text(NSLocalizedString("settings.language_subtitle", comment: ""))
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Languages list
                VStack(spacing: 12) {
                    ForEach(languages, id: \.0) { language in
                        Button(action: {
                            HapticManager.medium()

                            // Don't change if it's already selected
                            if selectedLanguage == language.0 {
                                dismiss()
                                return
                            }

                            // Call the callback to handle language change
                            onLanguageChange?(language.0)
                            dismiss()
                        }) {
                            HStack(spacing: 16) {
                                Text(language.2)
                                    .font(.system(size: 32))

                                Text(language.1)
                                    .font(.custom("Poppins-SemiBold", size: 18))
                                    .foregroundColor(.white)

                                Spacer()

                                if selectedLanguage == language.0 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.appTheme)
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        selectedLanguage == language.0 ?
                                        Color.appTheme.opacity(0.15) :
                                        Color(hex: "131146")
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                selectedLanguage == language.0 ?
                                                Color.appTheme.opacity(0.5) :
                                                Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)

                Text(NSLocalizedString("settings.language_restart_note", comment: ""))
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
        }
    }
}

// MARK: - FileManager Extension
extension FileManager {
    func allocatedSizeOfDirectory(at url: URL) throws -> UInt64 {
        guard let enumerator = self.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
            options: [],
            errorHandler: nil
        ) else {
            return 0
        }

        var size: UInt64 = 0

        while let fileURL = enumerator.nextObject() as? URL {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
                size += UInt64(resourceValues.totalFileAllocatedSize ?? 0)
            } catch {
                continue
            }
        }

        return size
    }
}

#Preview {
    SettingsView()
}
