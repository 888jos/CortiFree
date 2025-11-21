import SwiftUI
import SafariServices
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("appLanguage") private var appLanguage: String = Locale.current.language.languageCode?.identifier ?? "fr"

    // Profile & Objective
    @State private var currentObjective: String = "Réduire mon stress quotidien"
    @State private var notificationsEnabled: Bool = true
    @State private var showRoutineSheet: Bool = false
    @State private var showLanguagePicker: Bool = false

    // Experience & Habits
    @State private var morningRoutineEnabled: Bool = true
    @State private var afternoonRoutineEnabled: Bool = true
    @State private var eveningRoutineEnabled: Bool = true
    @State private var morningTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var afternoonTime: Date = Calendar.current.date(from: DateComponents(hour: 14, minute: 0)) ?? Date()
    @State private var eveningTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @State private var defaultSound: String = "Pluie forestière"
    @State private var voiceGuidance: Bool = true
    @State private var ambientVolume: Double = 0.7

    // Subscription
    @State private var subscriptionStatus: String = "Premium actif"
    @State private var renewalDate: String = "15 novembre 2025"

    // Privacy
    @State private var localDataSize: String = "2.3 MB"
    @State private var syncEnabled: Bool = true

    // Debug
    @State private var showDebugSection: Bool = false
    @State private var versionTapCount: Int = 0

    // Safari
    @State private var showSafari: Bool = false
    @State private var safariURL: URL?

    // Alerts & Sheets
    @State private var showProfileEdit: Bool = false
    @State private var showSoundPicker: Bool = false
    @State private var showDeleteAccountAlert: Bool = false
    @State private var showSignOutAlert: Bool = false

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
        .sheet(isPresented: $showRoutineSheet) {
            RoutineSelectionSheet(currentObjective: $currentObjective)
        }
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerSheet(selectedLanguage: $appLanguage)
        }
        .onChange(of: notificationsEnabled) { _ in
            saveSettings()
        }
        .onChange(of: morningRoutineEnabled) { _ in
            saveSettings()
        }
        .onChange(of: afternoonRoutineEnabled) { _ in
            saveSettings()
        }
        .onChange(of: eveningRoutineEnabled) { _ in
            saveSettings()
        }
        .onChange(of: voiceGuidance) { _ in
            saveSettings()
        }
        .onChange(of: ambientVolume) { _ in
            saveSettings()
        }
        .onChange(of: syncEnabled) { _ in
            saveSettings()
        }
        .sheet(isPresented: $showSoundPicker) {
            SoundPickerSheet(selectedSound: $defaultSound)
        }
        .alert("Se déconnecter", isPresented: $showSignOutAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Se déconnecter", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir vous déconnecter ?")
        }
        .alert("Supprimer le compte", isPresented: $showDeleteAccountAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Cette action est irréversible. Toutes vos données seront définitivement supprimées.")
        }
        .onAppear {
            calculateLocalDataSize()
            // Load current routine from UserDefaults
            if let routineTitle = UserDefaults.standard.string(forKey: "selectedRoutineTitle") {
                currentObjective = routineTitle
            }
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

            Text("Paramètres")
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
                experienceHabitsSection
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
        settingsSection(title: "Profil & Objectif", icon: "person.circle.fill") {
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

                settingsRow(
                    icon: "target",
                    title: "Mon objectif actuel",
                    subtitle: currentObjective,
                    showChevron: false
                ) {}

                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 48)

                settingsRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Changer de routine",
                    subtitle: nil,
                    showChevron: true
                ) {
                    HapticManager.light()
                    showRoutineSheet = true
                }

                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 48)

                settingsToggleRow(
                    icon: "bell.fill",
                    title: "Rappels & Notifications",
                    subtitle: "Recevoir des rappels quotidiens",
                    isOn: $notificationsEnabled
                )
            }
        }
    }

    // MARK: - Experience & Habits Section
    private var experienceHabitsSection: some View {
        settingsSection(title: "Expérience & Habitudes", icon: "sparkles") {
            VStack(spacing: 0) {
                routinesSubsection
                timesSubsection
                soundsSubsection
            }
        }
    }

    private var routinesSubsection: some View {
        Group {
            Text("Routines quotidiennes")
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

            settingsToggleRow(
                icon: "sunrise.fill",
                title: "Routine matinale",
                subtitle: nil,
                isOn: $morningRoutineEnabled
            )

            Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

            settingsToggleRow(
                icon: "sun.max.fill",
                title: "Routine après-midi",
                subtitle: nil,
                isOn: $afternoonRoutineEnabled
            )

            Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

            settingsToggleRow(
                icon: "moon.stars.fill",
                title: "Routine soirée",
                subtitle: nil,
                isOn: $eveningRoutineEnabled
            )

            Divider().background(Color.white.opacity(0.1)).padding(.top, 12)
        }
    }

    private var timesSubsection: some View {
        Group {
            Text("Heures de rappel")
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)

            settingsTimeRow(icon: "sunrise.fill", title: "Matinée", time: $morningTime)
            Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

            settingsTimeRow(icon: "sun.max.fill", title: "Après-midi", time: $afternoonTime)
            Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

            settingsTimeRow(icon: "moon.stars.fill", title: "Soirée", time: $eveningTime)
            Divider().background(Color.white.opacity(0.1)).padding(.top, 12)
        }
    }

    private var soundsSubsection: some View {
        Group {
            settingsRow(
                icon: "speaker.wave.2.fill",
                title: "Sons relaxants par défaut",
                subtitle: defaultSound,
                showChevron: true
            ) {
                HapticManager.light()
                showSoundPicker = true
            }

            Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

            settingsToggleRow(
                icon: "waveform",
                title: "Voix & Guidance",
                subtitle: "Accompagnement vocal durant les exercices",
                isOn: $voiceGuidance
            )

            Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

            settingsSliderRow(
                icon: "speaker.wave.3.fill",
                title: "Volume d'ambiance",
                value: $ambientVolume
            )
        }
    }

    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        settingsSection(title: "Abonnement & Accès Premium", icon: "crown.fill") {
            VStack(spacing: 0) {
                settingsRow(icon: "checkmark.circle.fill", title: "Statut actuel", subtitle: subscriptionStatus, showChevron: false) {}
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "arrow.clockwise", title: "Renouvellement", subtitle: renewalDate, showChevron: false) {}
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "gearshape.fill", title: "Gérer mon abonnement", subtitle: "Modifier ou annuler", showChevron: true) {
                    HapticManager.light()
                    manageSubscription()
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "arrow.down.circle.fill", title: "Restaurer mes achats", subtitle: nil, showChevron: true) {
                    HapticManager.light()
                    restorePurchases()
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Se déconnecter", subtitle: nil, showChevron: false, isDestructive: true) {
                    HapticManager.medium()
                    showSignOutAlert = true
                }
            }
        }
    }

    // MARK: - Privacy & Security Section
    private var privacySecuritySection: some View {
        settingsSection(title: "Confidentialité & Sécurité", icon: "lock.shield.fill") {
            VStack(spacing: 0) {
                settingsRow(icon: "doc.text.fill", title: "Politique de confidentialité", subtitle: nil, showChevron: true) {
                    HapticManager.light()
                    openURL("https://cortifree.com/privacy")
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "doc.plaintext.fill", title: "Conditions d'utilisation", subtitle: nil, showChevron: true) {
                    HapticManager.light()
                    openURL("https://cortifree.com/terms")
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "trash.fill", title: "Supprimer mon compte", subtitle: "Action irréversible", showChevron: true, isDestructive: true) {
                    HapticManager.heavy()
                    showDeleteAccountAlert = true
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "internaldrive.fill", title: "Données locales", subtitle: localDataSize, showChevron: false) {}
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsToggleRow(icon: "arrow.triangle.2.circlepath.icloud", title: "Synchronisation iCloud", subtitle: "Sauvegarder vos données dans le cloud", isOn: $syncEnabled)
            }
        }
    }

    // MARK: - About & Support Section
    private var aboutSupportSection: some View {
        settingsSection(title: "À propos & Support", icon: "info.circle.fill") {
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
                    settingsRowContent(icon: "app.badge.fill", title: "Version", subtitle: "1.0.0 (Build 1)", showChevron: false, isDestructive: false)
                }
                .buttonStyle(PlainButtonStyle())

                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "envelope.fill", title: "Contact support", subtitle: "support@cortifree.com", showChevron: true) {
                    HapticManager.light()
                    openURL("mailto:support@cortifree.com")
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "questionmark.circle.fill", title: "FAQ", subtitle: nil, showChevron: true) {
                    HapticManager.light()
                    openURL("https://cortifree.com/faq")
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "star.fill", title: "Noter l'application", subtitle: "Aidez-nous à nous améliorer", showChevron: true) {
                    HapticManager.light()
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "link", title: "Suivre CortiFree", subtitle: "@cortifree", showChevron: true) {
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
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "trash.circle.fill", title: "Clear all data", subtitle: nil, showChevron: false, isDestructive: true) {
                    HapticManager.heavy()
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)

                settingsRow(icon: "arrow.clockwise.circle.fill", title: "Force sync", subtitle: nil, showChevron: false) {
                    HapticManager.light()
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
                    saveSettings()
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

    private func saveSettings() {
        // Save to UserDefaults
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(morningRoutineEnabled, forKey: "morningRoutineEnabled")
        UserDefaults.standard.set(afternoonRoutineEnabled, forKey: "afternoonRoutineEnabled")
        UserDefaults.standard.set(eveningRoutineEnabled, forKey: "eveningRoutineEnabled")
        UserDefaults.standard.set(voiceGuidance, forKey: "voiceGuidance")
        UserDefaults.standard.set(ambientVolume, forKey: "ambientVolume")
        UserDefaults.standard.set(syncEnabled, forKey: "syncEnabled")

        // TODO: Sync to Firestore when implemented
    }

    // MARK: - Helper Functions

    private func manageSubscription() {
        // TODO: Open Superwall subscription management
        #if canImport(SuperwallKit)
        // Superwall.shared.presentPaywall(...)
        #endif
    }

    private func restorePurchases() {
        // TODO: Restore purchases via Superwall/StoreKit
        #if canImport(SuperwallKit)
        // Superwall.shared.restorePurchases(...)
        #endif
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
                print("❌ Error deleting account: \(error)")
            }
        }
    }

    private func calculateLocalDataSize() {
        // Calculate size of local data
        let fileManager = FileManager.default
        if let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let size = try fileManager.allocatedSizeOfDirectory(at: documentsPath)
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useMB, .useKB]
                formatter.countStyle = .file
                localDataSize = formatter.string(fromByteCount: Int64(size))
            } catch {
                localDataSize = "N/A"
            }
        }
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
                    Text("Changer de routine")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)

                    Text("Sélectionne ta nouvelle routine")
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

                            Text("⚠️ Attention")
                                .font(.custom("Poppins-Bold", size: 22))
                                .foregroundColor(.white)

                            Text("Changer de routine réinitialisera :")
                                .font(.custom("Poppins-Regular", size: 15))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 32)
                        .padding(.horizontal, 24)

                        // List of what will be reset
                        VStack(alignment: .leading, spacing: 12) {
                            WarningItem(text: "Ta progression actuelle (semaine/jour)")
                            WarningItem(text: "Ton historique de tâches complétées")
                            WarningItem(text: "Tes statistiques de la routine")
                            WarningItem(text: "La date de début sera remise à aujourd'hui")
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        // What will be preserved
                        Text("Ton XP total, niveau et streak seront conservés.")
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
                                Text("Confirmer le changement")
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
                                Text("Annuler")
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
            return "Techniques de relaxation et méditation"
        } else if title.contains("sommeil") {
            return "Routine du soir et sommeil réparateur"
        } else if title.contains("énergie") {
            return "Boost d'énergie naturelle"
        } else {
            return "Programme personnalisé de bien-être"
        }
    }
}

// MARK: - Sound Picker Sheet
struct SoundPickerSheet: View {
    @Binding var selectedSound: String
    @Environment(\.dismiss) private var dismiss

    let sounds = [
        "Pluie forestière",
        "Ocean",
        "Feu de cheminée",
        "Vent doux",
        "Rivière",
        "Oiseaux matinaux"
    ]

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

                Text("Sons relaxants")
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
                            selectedLanguage = language.0

                            // Update app language
                            UserDefaults.standard.set([language.0], forKey: "AppleLanguages")
                            UserDefaults.standard.synchronize()

                            // Show restart alert
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                dismiss()
                                // The app needs to be restarted for language change
                                exit(0)
                            }
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
