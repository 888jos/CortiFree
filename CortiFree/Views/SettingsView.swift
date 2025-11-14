import SwiftUI
import SafariServices

struct SettingsView: View {
    @StateObject private var planetSettings = PlanetSettings.shared
    @Environment(\.dismiss) private var dismiss

    // Profile & Objective
    @State private var currentObjective: String = "Réduire mon stress quotidien"
    @State private var notificationsEnabled: Bool = true
    @State private var showObjectiveSheet: Bool = false

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
        .sheet(isPresented: $showObjectiveSheet) {
            ObjectiveSelectionSheet(selectedObjective: $currentObjective)
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
        .sheet(isPresented: $showProfileEdit) {
            PlanetSettingsView()
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
                    icon: "person.fill",
                    title: "Mon profil",
                    subtitle: planetSettings.selectedPlanet.displayName,
                    showChevron: true
                ) {
                    HapticManager.light()
                    showProfileEdit = true
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
                    title: "Changer d'objectif",
                    subtitle: nil,
                    showChevron: true
                ) {
                    HapticManager.light()
                    showObjectiveSheet = true
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
        // TODO: Sign out from Firebase
        dismiss()
    }

    private func deleteAccount() {
        // TODO: Delete account from Firebase and local data
        dismiss()
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

// MARK: - Objective Selection Sheet
struct ObjectiveSelectionSheet: View {
    @Binding var selectedObjective: String
    @Environment(\.dismiss) private var dismiss

    let objectives = [
        "Réduire mon stress quotidien",
        "Améliorer mon sommeil",
        "Augmenter ma concentration",
        "Gérer mon anxiété",
        "Développer ma sérénité"
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

                Text("Choisir mon objectif")
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                VStack(spacing: 12) {
                    ForEach(objectives, id: \.self) { objective in
                        Button(action: {
                            HapticManager.medium()
                            selectedObjective = objective
                            dismiss()
                        }) {
                            HStack {
                                Text(objective)
                                    .font(.custom("Poppins-Regular", size: 16))
                                    .foregroundColor(.white)

                                Spacer()

                                if selectedObjective == objective {
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
