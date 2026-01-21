//
//  CustomPaywallView.swift
//  CortiFree
//
//  Custom paywall design - uses RevenueCat for pricing
//  Conforme aux guidelines Apple: aucun prix hardcodé, utilise displayPrice
//

import SwiftUI
import RevenueCat
import FirebaseAuth
import FirebaseFirestore
import SuperwallKit

struct CustomPaywallView: View {
    let onComplete: () -> Void
    let onPurchase: (String) -> Void // "monthly" or "yearly"
    let onRestore: () -> Void

    // RevenueCat Manager pour les vrais prix App Store
    @ObservedObject private var revenueCat = RevenueCatManager.shared

    // User data from onboarding
    var baselineScores: [Double] = [0.4, 0.35, 0.45, 0.5, 0.4] // Sérénité, Sommeil, Énergie, Focus, Équilibre
    var potentialScores: [Double] = [0.85, 0.80, 0.90, 0.88, 0.82]

    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var userName: String = ""
    @State private var radarAnimationProgress: Double = 0.0 // 0.0 = week 0, 1.0 = week 10
    @State private var currentHabitIndex: Int = 0
    @State private var currentWeek: Int = 1
    @State private var showStartProgramScreen: Bool = false
    @State private var isPurchasing: Bool = false
    @State private var showPurchaseError: Bool = false
    @State private var purchaseErrorMessage: String = ""
    @StateObject private var superwallDelegate = SuperwallDelegateHandler()

    private var isFrench: Bool {
        LanguageManager.shared.currentLanguage == .french
    }

    // MARK: - Dynamic Prices from RevenueCat (Real App Store Connect prices)
    // Conforme aux guidelines Apple: utilise displayPrice pour les vrais prix localisés

    /// Prix mensuel depuis App Store Connect
    private var monthlyPrice: String {
        revenueCat.monthlyDisplayPrice
    }

    /// Prix annuel depuis App Store Connect
    private var yearlyPrice: String {
        revenueCat.yearlyDisplayPrice
    }

    /// Équivalent mensuel de l'abonnement annuel
    private var yearlyMonthlyEquivalent: String {
        revenueCat.yearlyMonthlyEquivalent
    }

    /// Pourcentage d'économie calculé dynamiquement
    private var discountPercentage: Int {
        revenueCat.yearlySavingsPercentage
    }

    /// Prix journalier de l'abonnement annuel
    private var dailyPrice: String {
        revenueCat.yearlyDailyEquivalent
    }

    /// Période d'essai gratuit (si disponible)
    private var trialPeriod: String? {
        revenueCat.yearlyTrialPeriod
    }

    /// Indique si les produits sont chargés
    private var productsReady: Bool {
        revenueCat.productsLoaded
    }

    // Les habitudes avec leurs statistiques de progression (same as HabitsProgressFlowView)
    private var habitProgresses: [PaywallHabitProgress] {
        [
            PaywallHabitProgress(
                icon: "wind",
                title: isFrench ? "Respirer consciemment / sem." : "Breathe Consciously / week",
                yAxisValues: ["15 min", "30 min", "45 min", "1h"],
                currentValue: "1h",
                statMessage: isFrench ? "pratiqueras la respiration consciente 1h par semaine." : "will practice conscious breathing 1h per week.",
                curveStyle: 0
            ),
            PaywallHabitProgress(
                icon: "figure.mind.and.body",
                title: isFrench ? "Méditer / sem." : "Meditate / week",
                yAxisValues: ["20 min", "40 min", "1h", "1h20", "1h40"],
                currentValue: "1h30",
                statMessage: isFrench ? "méditeras 1h30 par semaine." : "will meditate 1h30 per week.",
                curveStyle: 1
            ),
            PaywallHabitProgress(
                icon: "book.pages",
                title: isFrench ? "Tenir un journal / sem." : "Keep a Journal / week",
                yAxisValues: ["2x", "3x", "5x", "7x"],
                currentValue: "7x",
                statMessage: isFrench ? "tiendras un journal 7 fois par semaine." : "will journal 7 times per week.",
                curveStyle: 2
            ),
            PaywallHabitProgress(
                icon: "figure.walk",
                title: isFrench ? "Faire du sport / sem." : "Exercise / week",
                yAxisValues: ["45 min", "1h30", "2h15", "3h", "3h45"],
                currentValue: "3h30",
                statMessage: isFrench ? "feras du sport 3h30 par semaine." : "will exercise 3h30 per week.",
                curveStyle: 3
            ),
            PaywallHabitProgress(
                icon: "drop.fill",
                title: isFrench ? "Boire de l'eau / jour" : "Drink Water / day",
                yAxisValues: ["1.5L", "2L", "2.5L", "3L"],
                currentValue: "2,5L",
                statMessage: isFrench ? "boiras 2,5L d'eau par jour." : "will drink 2.5L of water per day.",
                curveStyle: 4
            ),
            PaywallHabitProgress(
                icon: "tree.fill",
                title: isFrench ? "Temps en nature / sem." : "Time in Nature / week",
                yAxisValues: ["45 min", "1h30", "2h15", "3h", "3h45"],
                currentValue: "3h30",
                statMessage: isFrench ? "passeras 3h30 en nature par semaine." : "will spend 3h30 in nature per week.",
                curveStyle: 5
            ),
            PaywallHabitProgress(
                icon: "moon.zzz.fill",
                title: isFrench ? "Routine sommeil / jour" : "Sleep Routine / day",
                yAxisValues: ["6h", "6.5h", "7h", "7.5h", "8h"],
                currentValue: "8h",
                statMessage: isFrench ? "dormiras 8 heures par nuit." : "will sleep 8 hours per night.",
                curveStyle: 6
            ),
            PaywallHabitProgress(
                icon: "person.2.fill",
                title: isFrench ? "Connexion sociale / sem." : "Social Connection / week",
                yAxisValues: ["1x", "2x", "3x", "4x"],
                currentValue: "4x",
                statMessage: isFrench ? "te connecteras socialement 4 fois par semaine." : "will connect socially 4 times per week.",
                curveStyle: 7
            )
        ]
    }

    private var currentHabitProgress: PaywallHabitProgress {
        habitProgresses[currentHabitIndex]
    }

    // Calculate end date (66 days from now)
    private var endDate: Date {
        Calendar.current.date(byAdding: .day, value: 66, to: Date()) ?? Date()
    }

    private var formattedEndDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: isFrench ? "fr_FR" : "en_US")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: endDate)
    }

    private var formattedTodayDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: isFrench ? "fr_FR" : "en_US")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "1a0a2e"),
                    Color(hex: "0A0515"),
                    Color(hex: "1a0a2e")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Close button
                    closeButton

                    // Header with checkmark
                    headerSection

                    // Promise section with date
                    promiseSection

                    // Benefits list
                    benefitsSection

                    // Progress chart preview
                    progressChartSection

                    // Plan toggle
                    planToggle

                    // Stats section
                    statsSection

                    // Date transformation
                    dateTransformationSection

                    // Features list
                    featuresSection

                    // Radar chart with potential
                    radarChartSection

                    // Footer links only (button is floating)
                    footerLinksSection
                }
                .padding(.bottom, 140) // Extra space for floating button
            }

            // Floating CTA at bottom
            VStack {
                Spacer()
                floatingCTASection
            }
        }
        .onAppear {
            loadUserName()
            startRadarAnimation()

            // Setup Superwall delegate
            superwallDelegate.onComplete = {
                // When user completes purchase or closes paywall
                onComplete()
            }
            Superwall.shared.delegate = superwallDelegate
        }
        .onChange(of: showStartProgramScreen) { shouldShow in
            if shouldShow {
                // Trigger Superwall paywall instead of custom screen
                // IMPORTANT: Replace "trigger" with the exact placement name from your Superwall dashboard
                let placement = "trigger"

                print("🌍 [CustomPaywall] Triggering Superwall with placement: \(placement)")
                Superwall.shared.register(placement: placement)

                // Reset the flag after triggering
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showStartProgramScreen = false
                }
            }
        }
    }

    // MARK: - Load User Name

    private func loadUserName() {
        if let user = Auth.auth().currentUser {
            // Priority 1: displayName from Firebase Auth (Google/Apple Sign In)
            if let displayName = user.displayName, !displayName.isEmpty {
                // Extract first name from display name
                userName = displayName.components(separatedBy: " ").first ?? displayName
            }
            // Priority 2: Check Firestore for firstName field (Email Sign In)
            else {
                Task {
                    do {
                        let db = Firestore.firestore()
                        let document = try await db.collection("users").document(user.uid).getDocument()

                        if let firstName = document.data()?["firstName"] as? String, !firstName.isEmpty {
                            await MainActor.run {
                                userName = firstName
                            }
                        } else {
                            // Fallback: use email prefix
                            if let email = user.email {
                                let emailPrefix = email.components(separatedBy: "@").first ?? ""
                                await MainActor.run {
                                    userName = emailPrefix.isEmpty ? "vous" : emailPrefix
                                }
                            } else {
                                await MainActor.run {
                                    userName = "vous"
                                }
                            }
                        }
                    } catch {
                        // Fallback if Firestore fails
                        print("Error loading user firstName: \(error)")
                        await MainActor.run {
                            userName = "vous"
                        }
                    }
                }
            }
        } else {
            userName = "vous"
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        HStack {
            Spacer()
            Button(action: {
                HapticManager.light()
                onComplete()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
        .padding(.top, 10)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title
            Text(isFrench
                 ? "Dans 66 jours, tu auras\ntransformé ta vie."
                 : "In 66 days, you will have\ntransformed your life.")
                .font(.custom("Poppins-Bold", size: 26))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
    }

    // MARK: - Promise Section

    private var promiseSection: some View {
        VStack(spacing: 16) {
            Text(isFrench
                 ? "Ton destin t'attend. Tu libéreras ton\nvéritable potentiel le :"
                 : "Your destiny awaits. You will unlock\nyour true potential on:")
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            // Date badge
            Text(formattedEndDate)
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
        }
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PaywallBenefitRow(
                text: isFrench
                    ? "Ton **niveau de stress** va diminuer drastiquement"
                    : "Your **stress level** will decrease drastically"
            )
            PaywallBenefitRow(
                text: isFrench
                    ? "Ton **sommeil et ton énergie** seront 3 fois meilleurs"
                    : "Your **sleep and energy** will be 3 times better"
            )
            PaywallBenefitRow(
                text: isFrench
                    ? "Tu te sentiras **plus serein et concentré** que jamais"
                    : "You will feel **more serene and focused** than ever"
            )
            PaywallBenefitRow(
                text: isFrench
                    ? "Ton **équilibre de vie** sera complètement régénéré"
                    : "Your **life balance** will be completely regenerated"
            )
        }
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
    }

    // MARK: - Progress Chart Section (same as HabitsProgressFlowView)

    private var progressChartSection: some View {
        VStack(spacing: 12) {
            // Habit icons row (clickable)
            HStack(spacing: 6) {
                ForEach(0..<habitProgresses.count, id: \.self) { index in
                    Button(action: {
                        HapticManager.light()
                        currentHabitIndex = index
                        currentWeek = 1
                    }) {
                        Image(systemName: habitProgresses[index].icon)
                            .font(.system(size: 14))
                            .foregroundColor(currentHabitIndex == index ? Color(hex: "B794F6") : .white.opacity(0.5))
                            .frame(width: 30, height: 30)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(currentHabitIndex == index ? Color(hex: "B794F6").opacity(0.2) : Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(currentHabitIndex == index ? Color(hex: "B794F6") : Color.white.opacity(0.2), lineWidth: 1.5)
                            )
                    }
                }
            }

            // Chart card
            VStack(spacing: 10) {
                // Title with gradient
                Text(currentHabitProgress.title)
                    .font(.custom("Poppins-Bold", size: 16))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "B794F6")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Chart (using the real chart from HabitsProgressFlowView)
                HabitProgressChart(
                    yAxisValues: currentHabitProgress.yAxisValues,
                    currentValue: currentHabitProgress.currentValue,
                    weekNumber: 10,
                    maxValue: 4.0,
                    currentProgress: 3.7,
                    curveStyle: currentHabitProgress.curveStyle,
                    currentWeek: $currentWeek
                )
                .frame(height: 160)
                .drawingGroup()
            }
            .padding(AppConstants.Layout.paddingMedium)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .padding(.horizontal, AppConstants.Layout.paddingXLarge)
    }

    // MARK: - Plan Toggle

    private var planToggle: some View {
        HStack(spacing: 0) {
            // CortiFree option
            Button(action: {
                HapticManager.light()
                withAnimation { selectedPlan = .yearly }
            }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(selectedPlan == .yearly ? Color.white : Color.clear)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1)
                        )
                    Text("CortiFree")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(selectedPlan == .yearly ? .white : .white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            // Sans CortiFree option
            Button(action: {
                HapticManager.light()
                withAnimation { selectedPlan = .monthly }
            }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(selectedPlan == .monthly ? Color.white : Color.clear)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                    Text(isFrench ? "Sans CortiFree" : "Without CortiFree")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(selectedPlan == .monthly ? .white : .white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 16) {
            Image("welcome_5_stars")
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 50)
                .clipped()

            Image("welcome_cortifree_app")
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 50)
                .clipped()
        }
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
    }

    // MARK: - Date Transformation Section

    private var dateTransformationSection: some View {
        VStack(spacing: 16) {
            Text(isFrench ? "Si tu commences aujourd'hui" : "If you start today")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)

            Text(isFrench
                 ? "Tu transformeras ta vie et deviendras\nla meilleure version de toi-même d'ici le :"
                 : "You will transform your life and become\nthe best version of yourself by:")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            // Date transformation
            HStack(spacing: 16) {
                // Today
                Text(formattedTodayDate)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                    )

                // Arrows
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        Image(systemName: "play.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                // End date
                Text(formattedEndDate)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(Color(hex: "B794F6"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "B794F6"), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: 0) {
            PaywallFeatureListRow(
                icon: "chart.bar.fill",
                title: isFrench ? "Programme personnalisé" : "Personalized program",
                description: isFrench
                    ? "Un plan adapté à ton niveau, mis à jour chaque semaine."
                    : "A plan adapted to your level, updated weekly.",
                isNew: false
            )

            Divider().background(Color.white.opacity(0.1))

            PaywallFeatureListRow(
                icon: "checkmark.square.fill",
                title: isFrench ? "Planification des tâches" : "Task planning",
                description: isFrench
                    ? "Des habitudes fondées sur la science pour t'aider au quotidien."
                    : "Science-based habits to help you daily.",
                isNew: false
            )

            Divider().background(Color.white.opacity(0.1))

            PaywallFeatureListRow(
                icon: "chart.line.uptrend.xyaxis",
                title: isFrench ? "Suivi des améliorations" : "Progress tracking",
                description: isFrench
                    ? "Suis tes progrès avec des statistiques détaillées."
                    : "Track your progress with detailed statistics.",
                isNew: false
            )

            Divider().background(Color.white.opacity(0.1))

            PaywallFeatureListRow(
                icon: "pencil.and.outline",
                title: isFrench ? "Journal quotidien" : "Daily journal",
                description: isFrench
                    ? "Note tes pensées et émotions pour mieux te connaître."
                    : "Record your thoughts and emotions to know yourself better.",
                isNew: true
            )

        }
        .padding(AppConstants.Layout.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal, AppConstants.Layout.paddingXLarge)
    }

    // MARK: - Radar Chart Section

    // Two fixed states: small red (false) or large green (true)
    private var hexagonIsLarge: Bool {
        radarAnimationProgress >= 0.5
    }

    // Irregular progress values for each vertex
    private var smallProgress: [Double] {
        [0.15, 0.22, 0.18, 0.12, 0.20, 0.16] // Irregular small shape
    }

    private var largeProgress: [Double] {
        [0.92, 0.85, 0.95, 0.88, 0.90, 0.93] // Irregular large shape
    }

    private var radarChartSection: some View {
        VStack(spacing: 16) {
            Text(isFrench
                 ? "Amélioration de \(userName) en 66 jours"
                 : "\(userName)'s improvement in 66 days")
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Hexagon radar chart - switches between two states
            ZStack {
                // Background hexagon grid (responsive size)
                HexagonRadarGrid()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    .responsiveFrame(width: 165, height: 165)

                // Filled irregular hexagon - either small red OR large green
                HexagonRadarFill(progress: hexagonIsLarge ? largeProgress : smallProgress)
                    .fill(
                        LinearGradient(
                            colors: [
                                (hexagonIsLarge ? Color(hex: "27AE60") : Color(hex: "D32F2F")).opacity(0.7),
                                (hexagonIsLarge ? Color(hex: "27AE60") : Color(hex: "D32F2F")).opacity(0.4)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .responsiveFrame(width: 165, height: 165)

                // Stroke around the filled hexagon
                HexagonRadarFill(progress: hexagonIsLarge ? largeProgress : smallProgress)
                    .stroke((hexagonIsLarge ? Color(hex: "27AE60") : Color(hex: "D32F2F")).opacity(0.8), lineWidth: 3)
                    .responsiveFrame(width: 165, height: 165)

                // Labels (using larger frame for positioning)
                PaywallRadarLabels(size: ResponsiveLayout.cardWidth(base: 165), isFrench: isFrench)
            }
            .responsiveFrame(width: 280, height: 280)
            .padding(.vertical, 8)
        }
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
    }

    // MARK: - Floating CTA Section (Fixed at bottom)

    private var floatingCTASection: some View {
        VStack(spacing: 8) {
            // Main CTA button (same style as CortiFreeRatingView)
            Button(action: {
                HapticManager.medium()
                showStartProgramScreen = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .semibold))
                    Text(isFrench ? "Démarrer mon programme" : "Start my program")
                        .font(.custom("Poppins-SemiBold", size: 18))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(hex: "8B5CF6"))
                )
            }

        }
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "1a0a2e").opacity(0),
                    Color(hex: "1a0a2e").opacity(0.95),
                    Color(hex: "1a0a2e")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Footer Links Section

    private var footerLinksSection: some View {
        HStack(spacing: 24) {
            Button(action: {
                HapticManager.light()
                LegalDocumentsHelper.openPrivacyPolicy()
            }) {
                Text(isFrench ? "Confidentialité" : "Privacy")
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }

            Button(action: {
                HapticManager.light()
                onRestore()
            }) {
                Text(isFrench ? "Restaurer" : "Restore")
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }

            Button(action: {
                HapticManager.light()
                LegalDocumentsHelper.openTerms()
            }) {
                Text(isFrench ? "CGU" : "Terms")
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Helper Methods

    private func startRadarAnimation() {
        // Toggle between small (0) and large (1) every 1.5 seconds - no animation
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            radarAnimationProgress = radarAnimationProgress < 0.5 ? 1.0 : 0.0
        }
    }

}

// MARK: - Supporting Types

enum PaywallPlan: String {
    case monthly = "monthly"
    case yearly = "yearly"
}

struct PaywallHabitProgress {
    let icon: String
    let title: String
    let yAxisValues: [String]
    let currentValue: String
    let statMessage: String
    let curveStyle: Int
}

// MARK: - Subcomponents

struct PaywallBenefitRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "8B5CF6"))
                .frame(width: 20)

            Text(LocalizedStringKey(text))
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white)
        }
    }
}

struct PaywallHabitIcon: View {
    let icon: String
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color(hex: "B794F6").opacity(0.3) : Color.white.opacity(0.08))
                .frame(width: 40, height: 40)

            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? Color(hex: "B794F6") : .white.opacity(0.5))
        }
    }
}

struct PaywallFeatureListRow: View {
    let icon: String
    let title: String
    let description: String
    let isNew: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "B794F6").opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "B794F6"))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.white)

                    if isNew {
                        Text("NEW")
                            .font(.custom("Poppins-Bold", size: 9))
                            .foregroundColor(Color(hex: "8B5CF6"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(hex: "8B5CF6"), lineWidth: 1)
                            )
                    }
                }

                Text(description)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Paywall Radar Labels

struct PaywallRadarLabels: View {
    let size: CGFloat
    let isFrench: Bool

    private var labelOffset: CGFloat { size * 0.72 }
    private var sideOffset: CGFloat { size * 0.62 }
    private var verticalOffset: CGFloat { size * 0.36 }
    private var fontSize: CGFloat { 10 }
    private var iconSize: CGFloat { 9 }

    var body: some View {
        ZStack {
            // Global - Top
            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: iconSize))
                Text(isFrench ? "Global" : "Overall")
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: 0, y: -labelOffset)

            // Sérénité - Top right
            HStack(spacing: 3) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: iconSize))
                Text(isFrench ? "Sérénité" : "Serenity")
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: sideOffset, y: -verticalOffset)

            // Sommeil - Bottom right
            HStack(spacing: 3) {
                Image(systemName: "moon.fill")
                    .font(.system(size: iconSize))
                Text(isFrench ? "Sommeil" : "Sleep")
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: sideOffset, y: verticalOffset)

            // Énergie - Bottom
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: iconSize))
                Text(isFrench ? "Énergie" : "Energy")
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: 0, y: labelOffset)

            // Focus - Bottom left
            HStack(spacing: 3) {
                Image(systemName: "target")
                    .font(.system(size: iconSize))
                Text("Focus")
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: -sideOffset, y: verticalOffset)

            // Équilibre - Top left
            HStack(spacing: 3) {
                Image(systemName: "heart.fill")
                    .font(.system(size: iconSize))
                Text(isFrench ? "Équilibre" : "Balance")
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: -sideOffset, y: -verticalOffset)
        }
    }
}

// MARK: - Animated Hexagon Shape

struct PaywallAnimatedHexagon: View {
    let size: CGFloat
    let color: Color

    var body: some View {
        PaywallHexagonShape()
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(0.7),
                        color.opacity(0.4)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                PaywallHexagonShape()
                    .stroke(color.opacity(0.8), lineWidth: 4)
            )
            .frame(width: size, height: size)
    }
}

struct PaywallHexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for i in 0..<6 {
            let angle = Double(i) * .pi / 3 - .pi / 2
            let point = CGPoint(
                x: center.x + radius * CGFloat(cos(angle)),
                y: center.y + radius * CGFloat(sin(angle))
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Feature Bullet (purple star + white text)

struct PaywallFeatureBullet: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "B794F6"))

            Text(text)
                .font(.custom("Poppins-Medium", size: 15))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Start Program Screen

struct PaywallStartProgramScreen: View {
    @Binding var isPresented: Bool
    let userName: String
    let onPurchase: (String) -> Void
    let onRestore: () -> Void

    // Observe RevenueCat directly for real-time price updates
    @ObservedObject private var revenueCat = RevenueCatManager.shared

    @State private var selectedPlan: String = "yearly"

    private var isFrench: Bool {
        LanguageManager.shared.currentLanguage == .french
    }

    // Dynamic prices from RevenueCat
    private var monthlyPrice: String { revenueCat.monthlyDisplayPrice }
    private var yearlyPrice: String { revenueCat.yearlyDisplayPrice }
    private var yearlyMonthlyEquivalent: String { revenueCat.yearlyMonthlyEquivalent }
    private var discountPercentage: Int { revenueCat.yearlySavingsPercentage }
    private var dailyPrice: String { revenueCat.yearlyDailyEquivalent }

    var body: some View {
        ZStack {
            // Galaxy background (same as app)
            GalaxyBackgroundView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with Restore and Close
                HStack {
                    Button(action: {
                        HapticManager.light()
                        onRestore()
                    }) {
                        Text(isFrench ? "Restaurer" : "Restore")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Button(action: {
                        HapticManager.light()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Main title - more impactful
                        VStack(spacing: 8) {
                            Text(isFrench ? "Reprends le contrôle" : "Take back control")
                                .font(.custom("Poppins-Bold", size: 28))
                                .foregroundColor(.white)

                            Text(isFrench ? "de ton bien-être" : "of your well-being")
                                .font(.custom("Poppins-Bold", size: 28))
                                .foregroundColor(Color(hex: "B794F6"))
                        }
                        .padding(.top, 20)

                        // Subtitle
                        Text(isFrench
                             ? "66 jours pour transformer tes habitudes"
                             : "66 days to transform your habits")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.bottom, 8)

                        // Features list - aligned left with better styling
                        VStack(alignment: .leading, spacing: 16) {
                            PaywallFeatureRow(
                                icon: "calendar.badge.clock",
                                text: isFrench ? "Programme personnalisé de 66 jours" : "Personalized 66-day program"
                            )
                            PaywallFeatureRow(
                                icon: "wind",
                                text: isFrench ? "Exercices de respiration guidés" : "Guided breathing exercises"
                            )
                            PaywallFeatureRow(
                                icon: "chart.line.uptrend.xyaxis",
                                text: isFrench ? "Suivi quotidien de tes progrès" : "Daily progress tracking"
                            )
                            PaywallFeatureRow(
                                icon: "brain.head.profile",
                                text: isFrench ? "Méditations anti-stress" : "Anti-stress meditations"
                            )
                            PaywallFeatureRow(
                                icon: "bell.badge",
                                text: isFrench ? "Rappels intelligents" : "Smart reminders"
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 16)

                        // Pricing options side by side - equal height
                        HStack(spacing: 12) {
                            // Monthly option
                            ProgramPlanCard(
                                title: isFrench ? "MENSUEL" : "MONTHLY",
                                price: monthlyPrice,
                                period: isFrench ? "/mois" : "/mo",
                                badgeText: nil,
                                trialText: nil,
                                isSelected: selectedPlan == "monthly",
                                isRecommended: false,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        HapticManager.light()
                                        selectedPlan = "monthly"
                                    }
                                }
                            )

                            // Yearly option (with badge + free trial)
                            ProgramPlanCard(
                                title: isFrench ? "ANNUEL" : "YEARLY",
                                price: yearlyPrice,
                                period: isFrench ? "/an" : "/yr",
                                badgeText: isFrench ? "-\(discountPercentage)%" : "-\(discountPercentage)%",
                                trialText: isFrench ? "3 jours gratuits" : "3 days free",
                                isSelected: selectedPlan == "yearly",
                                isRecommended: true,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        HapticManager.light()
                                        selectedPlan = "yearly"
                                    }
                                }
                            )
                        }
                        .padding(.horizontal, 24)

                        // Price breakdown - More visible for Apple Review compliance
                        if selectedPlan == "yearly" {
                            VStack(spacing: 6) {
                                // Monthly equivalent - More prominent
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "8B5CF6"))
                                    Text(isFrench
                                         ? "Soit seulement \(yearlyMonthlyEquivalent)/mois"
                                         : "That's only \(yearlyMonthlyEquivalent)/month")
                                        .font(.custom("Poppins-SemiBold", size: 15))
                                        .foregroundColor(Color(hex: "8B5CF6"))
                                }
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        }

                        // APPLE REQUIREMENT 3.1.2: Explicit subscription pricing information
                        // Must be displayed BEFORE the purchase button
                        VStack(spacing: 6) {
                            // Subscription name and full price
                            VStack(spacing: 2) {
                                Text(selectedPlan == "yearly"
                                     ? (isFrench ? "Abonnement annuel CortiFree" : "CortiFree Annual Subscription")
                                     : (isFrench ? "Abonnement mensuel CortiFree" : "CortiFree Monthly Subscription"))
                                    .font(.custom("Poppins-SemiBold", size: 15))
                                    .foregroundColor(.white.opacity(0.9))

                                // Full price with period
                                if selectedPlan == "yearly" {
                                    Text(isFrench
                                         ? "\(yearlyPrice) / an (\(yearlyMonthlyEquivalent) / mois)"
                                         : "\(yearlyPrice) per year (\(yearlyMonthlyEquivalent) per month)")
                                        .font(.custom("Poppins-Medium", size: 14))
                                        .foregroundColor(Color(hex: "8B5CF6"))
                                } else {
                                    Text(isFrench
                                         ? "\(monthlyPrice) / mois"
                                         : "\(monthlyPrice) per month")
                                        .font(.custom("Poppins-Medium", size: 14))
                                        .foregroundColor(Color(hex: "8B5CF6"))
                                }
                            }

                            // Auto-renewal and cancellation notice (MUST be before button per Apple 3.1.2)
                            Text(isFrench
                                 ? "Renouvellement automatique • Résiliable à tout moment"
                                 : "Auto-renewing • Cancel anytime")
                                .font(.custom("Poppins-Regular", size: 11))
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .padding(.top, 2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                        // Spacer to push content up and leave room for fixed button
                        Spacer()
                            .frame(height: 220)
                    }
                }
            }

            // Fixed bottom section - OVERLAY (outside ScrollView for proper hit testing)
            VStack {
                Spacer()

                VStack(spacing: 12) {
                    // CTA Button - Increased height for iPad accessibility
                    Button(action: {
                        print("🔥 Purchase button tapped - Plan: \(selectedPlan)")
                        HapticManager.medium()
                        onPurchase(selectedPlan)
                    }) {
                        HStack(spacing: 8) {
                            Text(selectedPlan == "yearly"
                                 ? (isFrench ? "Commencer mon essai gratuit" : "Start my free trial")
                                 : (isFrench ? "S'abonner maintenant" : "Subscribe now"))
                                .font(.custom("Poppins-Bold", size: ResponsiveLayout.fontSize(base: 17)))
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .multilineTextAlignment(.center)

                            Image(systemName: "arrow.right")
                                .font(.system(size: ResponsiveLayout.fontSize(base: 16), weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: ResponsiveLayout.isIPad ? 64 : 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "7C3AED"), Color(hex: "5B21B6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "7C3AED").opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)

                    // Free trial info text when yearly is selected
                    if selectedPlan == "yearly" {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "8B5CF6"))
                            Text(isFrench
                                 ? "3 jours gratuits, puis \(yearlyPrice)/an"
                                 : "3 days free, then \(yearlyPrice)/year")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    // Legal disclaimer - Detailed cancellation instructions (additional info, not replacement)
                    Text(isFrench
                         ? "Annulation dans Réglages > App Store > Abonnements."
                         : "Cancel in Settings > App Store > Subscriptions.")
                        .font(.custom("Poppins-Regular", size: 10))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)

                    // Footer links
                    HStack(spacing: 20) {
                        Button(action: {
                            HapticManager.light()
                            LegalDocumentsHelper.openTerms()
                        }) {
                            Text(isFrench ? "Conditions" : "Terms")
                                .font(.custom("Poppins-Regular", size: 11))
                                .foregroundColor(.white.opacity(0.4))
                        }

                        Text("•")
                            .font(.custom("Poppins-Regular", size: 11))
                            .foregroundColor(.white.opacity(0.3))

                        Button(action: {
                            HapticManager.light()
                            LegalDocumentsHelper.openPrivacyPolicy()
                        }) {
                            Text(isFrench ? "Confidentialité" : "Privacy")
                                .font(.custom("Poppins-Regular", size: 11))
                                .foregroundColor(.white.opacity(0.4))
                        }

                        Text("•")
                            .font(.custom("Poppins-Regular", size: 11))
                            .foregroundColor(.white.opacity(0.3))

                        Button(action: {
                            HapticManager.light()
                            onRestore()
                        }) {
                            Text(isFrench ? "Restaurer" : "Restore")
                                .font(.custom("Poppins-Regular", size: 11))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.bottom, 24)
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color(hex: "0D0D1A").opacity(0.95), Color(hex: "0D0D1A")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 180)
                    .offset(y: -40)
                    .allowsHitTesting(false)
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Feature Row with icon

struct PaywallFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "B794F6"))
                .frame(width: 24)

            Text(text)
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - App Screenshots Carousel

struct AppScreenshotsCarousel: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: -30) {
                // Show placeholder screens (in real app, use actual screenshots)
                ForEach(0..<5, id: \.self) { index in
                    AppScreenshotMock(index: index)
                        .frame(width: 140, height: 260)
                        .scaleEffect(index == 2 ? 1.1 : 0.9)
                        .zIndex(index == 2 ? 1 : 0)
                }
            }
            .padding(.horizontal, 40)
        }
    }
}

struct AppScreenshotMock: View {
    let index: Int

    private var screenContent: (icon: String, title: String, color: Color) {
        let contents = [
            ("house.fill", "Home", Color(hex: "FF6B6B")),
            ("chart.bar.fill", "Progress", Color(hex: "4ECDC4")),
            ("calendar", "Day 12/66", Color(hex: "45B7D1")),
            ("checkmark.circle.fill", "Tasks", Color(hex: "96CEB4")),
            ("trophy.fill", "Achievement", Color(hex: "FFD700"))
        ]
        return contents[index % contents.count]
    }

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1a0a2e"),
                            screenContent.color.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    VStack(spacing: 12) {
                        Image(systemName: screenContent.icon)
                            .font(.system(size: 32))
                            .foregroundColor(screenContent.color)

                        Text(screenContent.title)
                            .font(.custom("Poppins-SemiBold", size: 14))
                            .foregroundColor(.white)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Program Plan Card

struct ProgramPlanCard: View {
    let title: String
    let price: String
    let period: String
    let badgeText: String?
    let trialText: String?
    let isSelected: Bool
    let isRecommended: Bool
    let onTap: () -> Void

    private let cardHeight: CGFloat = 140

    private var isFrench: Bool {
        LanguageManager.shared.currentLanguage == .french
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Content area - same height for both cards
                VStack(spacing: 6) {
                    // Badge or spacer for alignment
                    if let badge = badgeText {
                        Text(badge)
                            .font(.custom("Poppins-Bold", size: 11))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "8B5CF6"))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        // Invisible spacer to maintain alignment
                        Text(" ")
                            .font(.custom("Poppins-Bold", size: 11))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .opacity(0)
                    }

                    Text(title)
                        .font(.custom("Poppins-SemiBold", size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(price)
                            .font(.custom("Poppins-Bold", size: 26))
                            .foregroundColor(.white)
                        Text(period)
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    // Trial text or spacer
                    if let trial = trialText {
                        HStack(spacing: 4) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 10))
                            Text(trial)
                                .font(.custom("Poppins-Medium", size: 11))
                        }
                        .foregroundColor(Color(hex: "8B5CF6"))
                        .padding(.top, 2)
                    } else {
                        // Spacer for alignment
                        Text(" ")
                            .font(.custom("Poppins-Medium", size: 11))
                            .padding(.top, 2)
                            .opacity(0)
                    }
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .frame(height: cardHeight)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected
                          ? (isRecommended ? Color(hex: "7C3AED").opacity(0.2) : Color.white.opacity(0.12))
                          : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected
                            ? (isRecommended ? Color(hex: "B794F6") : Color.white.opacity(0.6))
                            : Color.white.opacity(0.15),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            // Recommended label
            .overlay(
                Group {
                    if isRecommended && isSelected {
                        Text(isFrench ? "RECOMMANDÉ" : "RECOMMENDED")
                            .font(.custom("Poppins-Bold", size: 9))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "7C3AED"))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .offset(y: -cardHeight / 2 - 8)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            )
            // Selection animation
            .scaleEffect(isSelected ? 1.02 : 0.98)
            .opacity(isSelected ? 1 : 0.7)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .frame(maxWidth: .infinity)
    }
}

// Previews moved to PaywallSubviews.swift to fix compilation timeout
