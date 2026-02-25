import SwiftUI
import SafariServices
import FirebaseAuth
import FirebaseFirestore
import StoreKit
import RevenueCat
import RevenueCatUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject private var revenueCatManager = RevenueCatManager.shared
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
    @State private var showBugReport: Bool = false
    @State private var bugReportText: String = ""
    @State private var bugReportScreenshot: UIImage? = nil
    @State private var showBugReportSuccess: Bool = false
    @State private var showCustomerCenter: Bool = false
    @State private var showReauthAlert: Bool = false
    @State private var reauthEmail: String = ""
    @State private var reauthPassword: String = ""
    @State private var deleteError: String?
    @State private var showDeleteError: Bool = false

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
        .alert(
            LanguageManager.shared.currentLanguage == .french ?
                "Confirmer votre identité" : "Confirm your identity",
            isPresented: $showReauthAlert
        ) {
            SecureField(
                LanguageManager.shared.currentLanguage == .french ?
                    "Mot de passe" : "Password",
                text: $reauthPassword
            )
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) {
                reauthPassword = ""
            }
            Button(NSLocalizedString("settings.alert.delete.button", comment: ""), role: .destructive) {
                reauthenticateAndDelete()
                reauthPassword = ""
            }
        } message: {
            Text(LanguageManager.shared.currentLanguage == .french ?
                 "Entrez votre mot de passe pour supprimer votre compte." :
                 "Enter your password to delete your account.")
        }
        .alert(
            LanguageManager.shared.currentLanguage == .french ? "Erreur" : "Error",
            isPresented: $showDeleteError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteError ?? "")
        }
        .onAppear {
            viewModel.calculateLocalDataSize()
        }
        .sheet(isPresented: $showBugReport) {
            BugReportSheet(
                bugReportText: $bugReportText,
                bugReportScreenshot: $bugReportScreenshot,
                onSubmit: { submitBugReport() },
                onCancel: {
                    showBugReport = false
                    bugReportText = ""
                    bugReportScreenshot = nil
                }
            )
        }
        .alert(NSLocalizedString("settings.bug_report.success", comment: ""), isPresented: $showBugReportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Merci pour votre retour ! Nous examinerons votre rapport rapidement.")
        }
        .sheet(isPresented: $showCustomerCenter) {
            CustomerCenterView()
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
                .font(.faroBold(24))
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

    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        settingsSection(title: "Abonnement", icon: "crown.fill") {
            VStack(spacing: 0) {
                // RevenueCat subscription status
                settingsRow(
                    icon: revenueCatManager.hasPremiumEntitlement ? "checkmark.circle.fill" : "circle",
                    title: NSLocalizedString("settings.subscription.status", comment: ""),
                    subtitle: revenueCatManager.hasPremiumEntitlement ?
                        (LanguageManager.shared.currentLanguage == .french ? "Premium actif" : "Premium active") :
                        (LanguageManager.shared.currentLanguage == .french ? "Non abonné" : "Not subscribed"),
                    showChevron: false
                ) {}
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                // RevenueCat Customer Center
                settingsRow(icon: "gearshape.fill", title: NSLocalizedString("settings.subscription.manage", comment: ""), subtitle: NSLocalizedString("settings.subscription.manage_subtitle", comment: ""), showChevron: true) {
                    HapticManager.light()
                    showCustomerCenter = true
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
                    LegalDocumentsHelper.openPrivacyPolicy()
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "doc.plaintext.fill", title: NSLocalizedString("settings.privacy.terms", comment: ""), subtitle: nil, showChevron: true) {
                    HapticManager.light()
                    LegalDocumentsHelper.openTerms()
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "building.columns.fill", title: NSLocalizedString("settings.privacy.legal_notice", comment: ""), subtitle: nil, showChevron: true) {
                    HapticManager.light()
                    LegalDocumentsHelper.openLegalNotice()
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "trash.fill", title: NSLocalizedString("settings.privacy.delete_account", comment: ""), subtitle: NSLocalizedString("settings.privacy.delete_account_subtitle", comment: ""), showChevron: true, isDestructive: true) {
                    HapticManager.heavy()
                    showDeleteAccountAlert = true
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "internaldrive.fill", title: "Données locales", subtitle: viewModel.localDataSize, showChevron: false) {}
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

                settingsRow(icon: "ladybug.fill", title: NSLocalizedString("settings.bug_report.title", comment: ""), subtitle: NSLocalizedString("settings.bug_report.subtitle", comment: ""), showChevron: true) {
                    HapticManager.light()
                    showBugReport = true
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
                    .font(.faroSemiBold(13))
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

    // MARK: - Language Change

    private func applyLanguageChange(_ newLanguage: String) {
        HapticManager.success()

        // Update @AppStorage variable immediately
        appLanguage = newLanguage

        // Update LanguageManager (this will update bundle and post notification)
        if let language = LanguageManager.Language(rawValue: newLanguage) {
            LanguageManager.shared.setLanguage(language)
        }

        // Dismiss settings to show refreshed UI
        dismiss()
    }

    // MARK: - Helper Functions

    private func manageSubscription() {
        // Open App Store subscription management
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
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
                guard let user = Auth.auth().currentUser else { return }
                let userId = user.uid

                // Delete user data from Firestore first
                let db = Firestore.firestore()
                try await db.collection("users").document(userId).delete()

                // Delete sub-collections if any
                let settingsRef = db.collection("users").document(userId).collection("settings")
                let settingsDocs = try await settingsRef.getDocuments()
                for doc in settingsDocs.documents {
                    try await doc.reference.delete()
                }

                // Delete Firebase auth account
                try await user.delete()

                // Logout RevenueCat
                await RevenueCatManager.shared.logout()

                // Clear all local data
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()

                // Update auth state
                await MainActor.run {
                    authViewModel.signOut()
                    dismiss()
                }
            } catch let error as NSError {
                if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    // Need re-authentication — show re-auth prompt
                    await MainActor.run {
                        reauthEmail = Auth.auth().currentUser?.email ?? ""
                        showReauthAlert = true
                    }
                } else {
                    await MainActor.run {
                        deleteError = error.localizedDescription
                        showDeleteError = true
                    }
                    #if DEBUG
                    print("❌ Error deleting account: \(error)")
                    #endif
                }
            }
        }
    }

    private func reauthenticateAndDelete() {
        Task {
            do {
                guard let user = Auth.auth().currentUser else { return }
                let credential = EmailAuthProvider.credential(withEmail: reauthEmail, password: reauthPassword)
                try await user.reauthenticate(with: credential)

                // Now retry delete
                deleteAccount()
            } catch {
                await MainActor.run {
                    deleteError = error.localizedDescription
                    showDeleteError = true
                }
            }
        }
    }

    // MARK: - Bug Report

    private func submitBugReport() {
        HapticManager.success()

        Task {
            do {
                let db = Firestore.firestore()
                let userId = Auth.auth().currentUser?.uid ?? "anonymous"
                let userEmail = Auth.auth().currentUser?.email ?? "unknown"

                var reportData: [String: Any] = [
                    "userId": userId,
                    "userEmail": userEmail,
                    "description": bugReportText,
                    "appVersion": "1.0.0",
                    "iosVersion": UIDevice.current.systemVersion,
                    "deviceModel": UIDevice.current.model,
                    "createdAt": FieldValue.serverTimestamp(),
                    "status": "new"
                ]

                // Upload screenshot if available (resized to fit Firestore limit)
                if let screenshot = bugReportScreenshot {
                    // Resize image to max 800px width to stay under Firestore 1MB limit
                    let maxWidth: CGFloat = 800
                    let scale = min(maxWidth / screenshot.size.width, 1.0)
                    let newSize = CGSize(width: screenshot.size.width * scale, height: screenshot.size.height * scale)

                    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                    screenshot.draw(in: CGRect(origin: .zero, size: newSize))
                    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()

                    if let resized = resizedImage,
                       let imageData = resized.jpegData(compressionQuality: 0.5) {
                        let base64String = imageData.base64EncodedString()
                        reportData["screenshotBase64"] = base64String
                    }
                }

                // Save to Firestore
                try await db.collection("bug_reports").addDocument(data: reportData)

                // Reset form and close
                bugReportText = ""
                bugReportScreenshot = nil
                showBugReport = false
                showBugReportSuccess = true

                #if DEBUG
                print("✅ Bug report submitted successfully")
                #endif
            } catch {
                #if DEBUG
                print("❌ Error submitting bug report: \(error)")
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
