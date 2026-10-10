import SwiftUI
import SafariServices
import StoreKit
import RevenueCat
import UserNotifications
import AuthenticationServices

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var revenueCatManager = RevenueCatManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var health = HealthKitService.shared

    // ViewModel for settings management
    @StateObject private var viewModel = SettingsViewModel()
    @AppStorage(MiloConsent.storageKey) private var miloConsentStore = ""

    // UI State only
    @State private var showLanguagePicker: Bool = false
    @State private var showDebugSection: Bool = false
    @State private var versionTapCount: Int = 0
    @State private var showDeleteAccountAlert: Bool = false
    @State private var showSignOutAlert: Bool = false
    @State private var showLanguageChangeAlert: Bool = false
    @State private var pendingLanguage: String?
    @State private var showResetUserDefaultsAlert: Bool = false
    @State private var showClearAllDataAlert: Bool = false
    @State private var supportDraft: SupportMail.Draft?
    @State private var showCustomerCenter: Bool = false
    @State private var showLogin: Bool = false
    @State private var showReauthAlert: Bool = false
    @State private var reauthPassword: String = ""
    @State private var deleteError: String?
    @State private var showDeleteError: Bool = false
    @State private var isDeletingAccount: Bool = false
    @State private var isRestoringPurchases: Bool = false
    @State private var infoAlertMessage: String?
    @State private var showWidgetGallery: Bool = false

    /// Opens straight on the delete-account confirmation (from the subscription locked screen).
    private let promptsAccountDeletion: Bool

    init(promptsAccountDeletion: Bool = false) {
        self.promptsAccountDeletion = promptsAccountDeletion
    }

    private static let appStoreID = "6758314805"
    private static let supportEmail = SupportMail.address

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

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
        .sheet(isPresented: $showLanguagePicker, onDismiss: {
            // Present the confirmation only once the sheet is gone (an alert raised
            // while a sheet is dismissing is silently dropped by SwiftUI).
            if pendingLanguage != nil {
                showLanguageChangeAlert = true
            }
        }) {
            LanguagePickerSheet(
                selectedLanguage: .constant(languageManager.currentLanguage.rawValue),
                onLanguageChange: { newLanguage in
                    pendingLanguage = newLanguage
                }
            )
        }
        .alert(LanguageManager.shared.localizedString(for: "settings.alert.signout.title"), isPresented: $showSignOutAlert) {
            Button(LanguageManager.shared.localizedString(for: "common.cancel"), role: .cancel) { }
            Button(LanguageManager.shared.localizedString(for: "settings.alert.signout.title"), role: .destructive) {
                signOut()
            }
        } message: {
            Text(LanguageManager.shared.localizedString(for: "settings.alert.signout.message"))
        }
        .alert(LanguageManager.shared.localizedString(for: "settings.alert.delete.title"), isPresented: $showDeleteAccountAlert) {
            Button(LanguageManager.shared.localizedString(for: "common.cancel"), role: .cancel) { }
            Button(LanguageManager.shared.localizedString(for: "settings.alert.delete.button"), role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text(LanguageManager.shared.localizedString(for: "settings.alert.delete.message"))
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
            Text(LanguageManager.shared.localizedString(for: "settings.alert.language_restart.message"))
        }
        // Debug-only actions (resetUserDefaults / clearAllData exist only in DEBUG builds).
        #if DEBUG
        .alert(LanguageManager.shared.localizedString(for: "settings.alert.reset_defaults.title"), isPresented: $showResetUserDefaultsAlert) {
            Button(LanguageManager.shared.localizedString(for: "common.cancel"), role: .cancel) { }
            Button(LanguageManager.shared.localizedString(for: "settings.alert.reset_defaults.button"), role: .destructive) {
                resetUserDefaults()
            }
        } message: {
            Text(LanguageManager.shared.localizedString(for: "settings.alert.reset_defaults.message"))
        }
        .alert(LanguageManager.shared.localizedString(for: "settings.alert.clear_data.title"), isPresented: $showClearAllDataAlert) {
            Button(LanguageManager.shared.localizedString(for: "common.cancel"), role: .cancel) { }
            Button(LanguageManager.shared.localizedString(for: "settings.alert.clear_data.button"), role: .destructive) {
                clearAllData()
            }
        } message: {
            Text(LanguageManager.shared.localizedString(for: "settings.alert.clear_data.message"))
        }
        #endif
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
            Button(LanguageManager.shared.localizedString(for: "settings.alert.delete.button"), role: .destructive) {
                let password = reauthPassword
                reauthPassword = ""
                reauthenticateAndDelete(password: password)
            }
        } message: {
            Text(LanguageManager.shared.localizedString(for: "inline.settingsview.language.02"))
        }
        .alert(
            LanguageManager.shared.localizedString(for: "inline.settingsview.language.03"),
            isPresented: $showDeleteError
        ) {
            Button(LanguageManager.shared.localizedString(for: "common.ok"), role: .cancel) {}
        } message: {
            Text(deleteError ?? "")
        }
        .alert(
            LanguageManager.shared.localizedString(for: "settings.title"),
            isPresented: Binding(
                get: { infoAlertMessage != nil },
                set: { if !$0 { infoAlertMessage = nil } }
            )
        ) {
            Button(LanguageManager.shared.localizedString(for: "common.ok"), role: .cancel) {}
        } message: {
            Text(infoAlertMessage ?? "")
        }
        .overlay {
            if isDeletingAccount {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.4)
                }
            }
        }
        .allowsHitTesting(!isDeletingAccount)
        .onAppear {
            viewModel.calculateLocalDataSize()
            viewModel.refreshNotificationAuthorization()
            NotificationService.shared.syncDailyNotificationsWithPreference()
            if promptsAccountDeletion && authViewModel.isAuthenticated { showDeleteAccountAlert = true }
        }
        .onChange(of: scenePhase) { _, phase in
            // Returning from the iOS Settings app after changing the permission
            guard phase == .active else { return }
            viewModel.refreshNotificationAuthorization()
            NotificationService.shared.syncDailyNotificationsWithPreference()
        }
        .sheet(item: $supportDraft) { draft in
            SupportMailComposer(draft: draft)
                .ignoresSafeArea()
        }
        .manageSubscriptionsSheet(isPresented: $showCustomerCenter)
        .fullScreenCover(isPresented: $showLogin) {
            AuthenticationView(
                onBack: {
                    showLogin = false
                },
                onComplete: {
                    showLogin = false
                }
            )
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
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassCircle(interactive: true)

            Spacer()

            Text(LanguageManager.shared.localizedString(for: "settings.title"))
                .font(.faroBold(24))
                .foregroundColor(.white)

            Spacer()

            // Invisible spacer for centering
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
        .padding(.bottom, 16)
    }

    // MARK: - Settings Scroll View
    private var settingsScrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                profileObjectiveSection
                widgetsSection
                subscriptionSection
                privacySecuritySection
                aboutSupportSection

                #if DEBUG
                if showDebugSection {
                    debugSection
                }
                #endif

                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Profile & Objective Section
    private var profileObjectiveSection: some View {
        settingsSection(title: LanguageManager.shared.localizedString(for: "settings.section.profile"), icon: "person.circle.fill") {
            VStack(spacing: 0) {
                if !authViewModel.isAuthenticated {
                    settingsRow(
                        icon: "person.crop.circle.badge.plus",
                        title: LanguageManager.shared.localizedString(for: "onboarding_v2.auth.login_button"),
                        subtitle: LanguageManager.shared.localizedString(for: "progress.error.signed_out"),
                        showChevron: true
                    ) {
                        HapticManager.light()
                        showLogin = true
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.leading, 48)
                }

                settingsRow(
                    icon: "globe",
                    title: LanguageManager.shared.localizedString(for: "settings.language"),
                    subtitle: languageManager.currentLanguage.displayName,
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
                    subtitle: LanguageManager.shared.localizedString(for: "settings.notifications.subtitle"),
                    isOn: Binding(
                        get: { viewModel.notificationsEnabled && viewModel.notificationsAuthorized },
                        set: handleNotificationsToggle
                    )
                )
            }
        }
    }

    // MARK: - Widgets Section
    private var widgetsSection: some View {
        settingsSection(title: LanguageManager.shared.localizedString(for: "settings.section.widgets"), icon: "square.grid.2x2.fill") {
            settingsRow(
                icon: "apps.iphone.badge.plus",
                title: LanguageManager.shared.localizedString(for: "settings.widgets.row"),
                subtitle: LanguageManager.shared.localizedString(for: "settings.widgets.row_subtitle"),
                showChevron: true
            ) {
                HapticManager.light()
                showWidgetGallery = true
            }
        }
        .sheet(isPresented: $showWidgetGallery) {
            WidgetGalleryView()
        }
    }

    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        settingsSection(title: LanguageManager.shared.localizedString(for: "settings.subscription_premium"), icon: "crown.fill") {
            VStack(spacing: 0) {
                // RevenueCat subscription status
                settingsRow(
                    icon: revenueCatManager.hasPremiumEntitlement ? "checkmark.circle.fill" : "circle",
                    title: LanguageManager.shared.localizedString(for: "settings.subscription.status"),
                    subtitle: revenueCatManager.hasPremiumEntitlement ?
                        (LanguageManager.shared.localizedString(for: "inline.settingsview.language.04")) :
                        (LanguageManager.shared.localizedString(for: "inline.settingsview.language.05")),
                    showChevron: false
                ) {}
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                // Apple subscription management
                settingsRow(icon: "gearshape.fill", title: LanguageManager.shared.localizedString(for: "settings.subscription.manage"), subtitle: LanguageManager.shared.localizedString(for: "settings.subscription.manage_subtitle"), showChevron: true) {
                    HapticManager.light()
                    showCustomerCenter = true
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "arrow.clockwise.circle.fill", title: LanguageManager.shared.localizedString(for: "settings.restore_purchases"), subtitle: nil, showChevron: false) {
                    HapticManager.light()
                    restorePurchases()
                }
                .disabled(isRestoringPurchases)

                if authViewModel.isAuthenticated {
                    Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                    settingsRow(icon: "rectangle.portrait.and.arrow.right", title: LanguageManager.shared.localizedString(for: "settings.signout"), subtitle: nil, showChevron: false, isDestructive: true) {
                        HapticManager.medium()
                        showSignOutAlert = true
                    }
                }
            }
        }
    }

    // MARK: - Privacy & Security Section
    private var privacySecuritySection: some View {
        settingsSection(title: LanguageManager.shared.localizedString(for: "settings.section.privacy"), icon: "lock.shield.fill") {
            VStack(spacing: 0) {
                settingsRow(icon: "doc.text.fill", title: LanguageManager.shared.localizedString(for: "settings.privacy.policy"), subtitle: nil, showChevron: true) {
                    HapticManager.light()
                    LegalDocumentsHelper.openPrivacyPolicy()
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "doc.plaintext.fill", title: LanguageManager.shared.localizedString(for: "settings.privacy.terms"), subtitle: nil, showChevron: true) {
                    HapticManager.light()
                    LegalDocumentsHelper.openTerms()
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "building.columns.fill", title: LanguageManager.shared.localizedString(for: "settings.privacy.legal_notice"), subtitle: nil, showChevron: true) {
                    HapticManager.light()
                    LegalDocumentsHelper.openLegalNotice()
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                if authViewModel.isAuthenticated {
                    settingsRow(icon: "trash.fill", title: LanguageManager.shared.localizedString(for: "settings.privacy.delete_account"), subtitle: LanguageManager.shared.localizedString(for: "settings.privacy.delete_account_subtitle"), showChevron: true, isDestructive: true) {
                        HapticManager.heavy()
                        showDeleteAccountAlert = true
                    }
                    Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)
                }

                settingsRowContent(icon: "internaldrive.fill", title: LanguageManager.shared.localizedString(for: "settings.privacy.local_data"), subtitle: viewModel.localDataSize, showChevron: false, isDestructive: false)
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                // Syncs the preferences to the user's Firestore account (not iCloud)
                settingsToggleRow(icon: "arrow.triangle.2.circlepath.icloud", title: LanguageManager.shared.localizedString(for: "settings.privacy.cloud_sync"), subtitle: LanguageManager.shared.localizedString(for: "settings.privacy.cloud_sync_subtitle"), isOn: $viewModel.syncEnabled)

                if authViewModel.isAuthenticated, let uid = Auth.auth().currentUser?.uid {
                    Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)
                    // Consent to send Milo messages to the AI provider (asked before the first message).
                    settingsToggleRow(icon: "bubble.left.and.text.bubble.right.fill", title: LanguageManager.shared.localizedString(for: "settings.privacy.milo"), subtitle: LanguageManager.shared.localizedString(for: "settings.privacy.milo_subtitle"), isOn: Binding(
                        get: { MiloConsent.isGranted(in: miloConsentStore, uid: uid) },
                        set: { miloConsentStore = $0 ? MiloConsent.granting(uid, in: miloConsentStore) : MiloConsent.revoking(uid, in: miloConsentStore) }
                    ))
                }

                if health.isAvailable {
                    Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)
                    // Health data stays on the device (HealthKit only).
                    settingsToggleRow(icon: "heart.fill", title: LanguageManager.shared.localizedString(for: "settings.health.title"), subtitle: LanguageManager.shared.localizedString(for: "settings.health.subtitle"), isOn: healthBinding)
                }
            }
        }
    }

    private var healthBinding: Binding<Bool> {
        Binding(
            get: { health.isEnabled },
            set: { enabled in
                if enabled {
                    Task { await health.enable() }
                } else {
                    health.disable()
                }
            }
        )
    }

    // MARK: - About & Support Section
    private var aboutSupportSection: some View {
        settingsSection(title: LanguageManager.shared.localizedString(for: "settings.section.about"), icon: "info.circle.fill") {
            VStack(spacing: 0) {
                Button(action: {
                    #if DEBUG
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
                    #endif
                }) {
                    settingsRowContent(icon: "app.badge.fill", title: LanguageManager.shared.localizedString(for: "settings.about.version"), subtitle: appVersionString, showChevron: false, isDestructive: false)
                }
                .buttonStyle(PlainButtonStyle())

                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "envelope.fill", title: LanguageManager.shared.localizedString(for: "settings.about.contact"), subtitle: Self.supportEmail, showChevron: true) {
                    HapticManager.light()
                    openSupportMail(.contact)
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "ladybug.fill", title: LanguageManager.shared.localizedString(for: "settings.bug_report.title"), subtitle: LanguageManager.shared.localizedString(for: "settings.bug_report.subtitle"), showChevron: true) {
                    HapticManager.light()
                    openSupportMail(.bug)
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "lightbulb.fill", title: LanguageManager.shared.localizedString(for: "settings.feature_request.title"), subtitle: LanguageManager.shared.localizedString(for: "settings.feature_request.subtitle"), showChevron: true) {
                    HapticManager.light()
                    openSupportMail(.feature)
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "star.fill", title: LanguageManager.shared.localizedString(for: "settings.about.rate"), subtitle: LanguageManager.shared.localizedString(for: "settings.about.rate_subtitle"), showChevron: true) {
                    HapticManager.light()
                    requestAppReview()
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "link", title: LanguageManager.shared.localizedString(for: "settings.about.follow"), subtitle: "@cortifree", showChevron: true) {
                    HapticManager.light()
                    openURL("https://twitter.com/cortifree")
                }
            }
        }
    }

    // MARK: - Debug Section
    #if DEBUG
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
                    viewModel.syncToFirebase()
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
    #endif

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
            .glassCard(cornerRadius: 22)
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
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url) { success in
            if !success && url.scheme == "mailto" {
                // No Mail account configured: show the address so the user can copy it
                UIPasteboard.general.string = Self.supportEmail
                infoAlertMessage = String(
                    format: LanguageManager.shared.localizedString(for: "settings.contact.no_mail_app"),
                    Self.supportEmail
                )
            }
        }
    }

    // MARK: - Language Change

    private func applyLanguageChange(_ newLanguage: String) {
        HapticManager.success()

        pendingLanguage = nil

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
        // SKStoreReviewController is rate-limited (and never shows in TestFlight), so an
        // explicit "Rate the app" button opens the App Store review page instead.
        openURL("https://apps.apple.com/app/id\(Self.appStoreID)?action=write-review")
    }

    private func restorePurchases() {
        isRestoringPurchases = true
        Task {
            do {
                _ = try await RevenueCatManager.shared.restorePurchases()
                infoAlertMessage = LanguageManager.shared.localizedString(
                    for: revenueCatManager.hasPremiumEntitlement ? "settings.restore.success" : "settings.restore.nothing"
                )
            } catch {
                infoAlertMessage = error.localizedDescription
            }
            isRestoringPurchases = false
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

    // MARK: - Account Deletion

    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else {
            deleteError = AccountDeletionService.DeletionError.notSignedIn.errorDescription
            showDeleteError = true
            return
        }

        switch AccountDeletionService.shared.reauthMethod(for: user) {
        case .password:
            // Firebase requires a recent sign-in: ask for the password BEFORE deleting anything
            showReauthAlert = true
        case .apple:
            Task {
                do {
                    try await AccountDeletionService.shared.reauthenticateWithApple()
                    await performAccountDeletion()
                } catch {
                    // User cancelled the Apple sheet: stay silent
                    if (error as? ASAuthorizationError)?.code == .canceled { return }
                    deleteError = error.localizedDescription
                    showDeleteError = true
                }
            }
        case .none, .unsupported:
            Task { await performAccountDeletion() }
        }
    }

    private func reauthenticateAndDelete(password: String) {
        Task {
            do {
                try await AccountDeletionService.shared.reauthenticateWithPassword(password: password)
                await performAccountDeletion()
            } catch {
                deleteError = error.localizedDescription
                showDeleteError = true
            }
        }
    }

    @MainActor
    private func performAccountDeletion() async {
        isDeletingAccount = true
        do {
            try await AccountDeletionService.shared.deleteAccount()
            HapticManager.success()
            isDeletingAccount = false
            // Resets auth state → CortiFreeApp shows the onboarding/auth root again
            authViewModel.signOut()
            dismiss()
        } catch AccountDeletionService.DeletionError.requiresRecentLogin {
            isDeletingAccount = false
            if Auth.auth().currentUser?.providerData.contains(where: { $0.providerID == "password" }) == true {
                showReauthAlert = true
            } else {
                deleteError = AccountDeletionService.DeletionError.requiresRecentLogin.errorDescription
                showDeleteError = true
            }
        } catch {
            isDeletingAccount = false
            HapticManager.error()
            deleteError = error.localizedDescription
            showDeleteError = true
            #if DEBUG
            print("❌ Error deleting account: \(error)")
            #endif
        }
    }

    // MARK: - Support Mail

    /// Contact, bug and feature requests: Mail composer pre-filled with user id + device info,
    /// then the default mail client, then copy the address as a last resort.
    private func openSupportMail(_ kind: SupportMail.Kind) {
        let draft = SupportMail.draft(kind)
        if SupportMail.canUseComposer {
            supportDraft = draft
            return
        }
        guard let url = SupportMail.mailtoURL(for: draft) else { return }
        openURL(url.absoluteString)
    }

    // MARK: - Notifications

    private func handleNotificationsToggle(_ enabled: Bool) {
        guard enabled else {
            viewModel.notificationsEnabled = false
            NotificationService.shared.cancelDailyNotifications()
            NotificationService.shared.cancelStreakDangerNotification()
            return
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                NotificationService.shared.requestNotificationPermission { granted in
                    DispatchQueue.main.async {
                        viewModel.notificationsEnabled = granted
                        viewModel.notificationsAuthorized = granted
                        UserDefaults.standard.set(granted, forKey: "notificationsEnabled")
                        NotificationService.shared.syncDailyNotificationsWithPreference()
                    }
                }
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    viewModel.notificationsEnabled = true
                    viewModel.notificationsAuthorized = true
                    UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                    NotificationService.shared.syncDailyNotificationsWithPreference()
                }
            case .denied:
                DispatchQueue.main.async {
                    // Keep the user's intent; the toggle turns on once iOS permission is granted
                    // (re-checked when the app becomes active again).
                    viewModel.notificationsEnabled = true
                    viewModel.notificationsAuthorized = false
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(settingsURL)
                }
            @unknown default:
                DispatchQueue.main.async {
                    viewModel.notificationsEnabled = false
                }
            }
        }
    }

    #if DEBUG
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
    #endif

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
