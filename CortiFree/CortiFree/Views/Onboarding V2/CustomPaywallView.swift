//
//  CustomPaywallView.swift
//  CortiFree
//
//  Custom paywall design - triggers Superwall
//  NOTE: This view is now just a placeholder that triggers Superwall's paywall
//

import SwiftUI
import SuperwallKit

struct CustomPaywallView: View {
    let onComplete: () -> Void
    let onPurchase: (String) -> Void // "monthly" or "yearly" (not used, Superwall handles)
    let onRestore: () -> Void
    var habitsQuizResult: HabitsQuizResult?
    var selectedSymptoms: Set<String> = []
    /// The onboarding paywall must not be dismissible into Home without an entitlement.
    /// Paywalls opened from Home keep the default dismissible behavior.
    var requiresPurchaseToComplete: Bool = false

    // REMOVED: RevenueCat is no longer used, Superwall handles everything

    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var userName: String = ""
    @State private var radarAnimationProgress: Double = 0.0 // 0.0 = today, 1.0 = day 28
    @State private var currentHabitIndex: Int = 0
    @State private var currentWeek: Int = 1
    @State private var showStartProgramScreen: Bool = false
    @State private var showBenefitsFlow: Bool = false
    @State private var isPurchasing: Bool = false
    @State private var showPurchaseError: Bool = false
    @State private var purchaseErrorMessage: String = ""

    // Same week-4 targets as the habits progress screen, scaled to the quiz's daily time.
    private var habitProgresses: [PaywallHabitProgress] {
        let titleIDs = ["breathing": "breathe", "meditation": "meditate"]
        return OnboardingHabitTargets.targets(availableMinutes: habitsQuizResult?.availableTime).map { target in
            PaywallHabitProgress(
                icon: target.icon,
                title: "paywall_custom.habit_\(titleIDs[target.id] ?? target.id)_title".localized,
                yAxisValues: target.yAxisValues,
                currentValue: target.currentValue,
                statMessage: target.statMessage,
                curveStyle: target.curveStyle
            )
        }
    }

    private var currentHabitProgress: PaywallHabitProgress {
        habitProgresses[currentHabitIndex]
    }

    // End date of the plan
    /// Last day of the 28-day personal plan started today.
    private var endDate: Date {
        Calendar.current.date(byAdding: .day, value: PersonalPlan.length - 1, to: Date()) ?? Date()
    }

    /// Dates follow the app language, not the device region.
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLanguage.locale
        formatter.setLocalizedDateFormatFromTemplate("d MMM yyyy")
        return formatter.string(from: date)
    }

    private var formattedEndDate: String { formattedDate(endDate) }

    private var formattedTodayDate: String { formattedDate(Date()) }

    var body: some View {
        ZStack {
            // PERFORMANCE: Static gradient background (no animations)
            LinearGradient(
                colors: [
                    Color(hex: "1F0140"), // Top - Purple deep
                    Color(hex: "0B011B"), // Middle - Very dark purple
                    Color(hex: "01000C")  // Bottom - Almost black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 32) { // PERFORMANCE: Use LazyVStack instead of VStack
                    // Header with checkmark
                    headerSection
                        .padding(.top, 60)

                    // Promise section with date
                    promiseSection

                    // Personalized insight (replaces both benefits + quiz insight)
                    personalizedInsightSection

                    // Progress chart preview
                    progressChartSection

                    // Plan toggle
                    planToggle

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
        }
        .onChange(of: showStartProgramScreen) { _, show in
            if show {
                showStartProgramScreen = false
                showBenefitsFlow = true
            }
        }
        .fullScreenCover(isPresented: $showBenefitsFlow) {
            OnboardingBenefitsFlowView {
                showBenefitsFlow = false
                DispatchQueue.main.async {
                    presentSuperwallPaywall()
                }
            }
            #if DEBUG
            .onboardingDebugHomeButton()
            #endif
        }
    }

    private func presentSuperwallPaywall() {
                AnalyticsManager.shared.track(event: "onboarding_superwall_placement_triggered", properties: [
                    "placement": SuperwallPlacement.onboarding,
                    "source": "continue_to_your_plan"
                ])
                let handler = PaywallPresentationHandler()
                handler.onPresent { _ in
                    UserDefaults.standard.set(true, forKey: "hasSeenPaywall")
                    UserDefaults.standard.set(true, forKey: "saw_paywall_without_accepting")
                    RecoveryScheduler.shared.markPaywallSeen()
                    OnboardingLiveActivityManager.shared.prepareLiveGiftOffer()
                }
                handler.onDismiss { _, result in
                    switch result {
                    case .declined:
                        guard !RevenueCatManager.shared.hasPremiumEntitlement else {
                            OnboardingLiveActivityManager.shared.clearLiveGiftOffer()
                            return
                        }
                        OnboardingLiveActivityManager.shared.showLiveGiftOffer()
                    case .purchased, .restored:
                        OnboardingLiveActivityManager.shared.clearLiveGiftOffer()
                    }
                }
                Superwall.shared.register(
                    placement: SuperwallPlacement.onboarding,
                    handler: handler
                ) {
                    // Called when Superwall gates are passed — verify subscription before proceeding
                    guard RevenueCatManager.shared.hasPremiumEntitlement else { return }
                    onComplete()
                }
    }

    // MARK: - Load User Name

    /// First name only; stays empty when unknown so the copy falls back to a version without a name.
    private func loadUserName() {
        guard let user = Auth.auth().currentUser else {
            userName = ""
            return
        }
        if let displayName = user.displayName, !displayName.isEmpty {
            userName = displayName.components(separatedBy: " ").first ?? displayName
        } else if let cached = UserDefaults.standard.string(forKey: "userFirstName"), !cached.isEmpty {
            userName = cached
        } else {
            userName = ""
        }
    }

    // MARK: - Header Section

    private var personalizedTitle: String {
        guard let goal = habitsQuizResult?.primaryGoal else {
            return "paywall_custom.title_default".localized
        }
        switch goal {
        case "sleep":   return "paywall_custom.title_sleep".localized
        case "stress":  return "paywall_custom.title_stress".localized
        case "energy":  return "paywall_custom.title_energy".localized
        case "focus":   return "paywall_custom.title_focus".localized
        case "balance": return "paywall_custom.title_balance".localized
        default:        return "paywall_custom.title_default".localized
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title
            Text(personalizedTitle)
                .font(.faroBold(28))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
    }

    // MARK: - Promise Section

    private var promiseSection: some View {
        VStack(spacing: 16) {
            Text("paywall_custom.promise_subtitle".localized)
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

    // MARK: - Personalized Insight Section (fused benefits + quiz patterns)

    private struct DetectedIssue {
        let icon: String
        let fix: String
        let theme: String // used to avoid redundancy when mixing with fallbacks
    }

    // Map: symptom key (from SymptomCheckerView) → DetectedIssue
    // Keys match exactly the `key` strings from both FR and EN symptom lists
    private var symptomToIssue: [String: DetectedIssue] {
        [
            // ── Mental FR ──
            "Anxiété fréquente": DetectedIssue(icon: "waveform.path.ecg", fix: "paywall_custom.fix_anxiety".localized, theme: "anxiety"),
            "Difficulté à se concentrer": DetectedIssue(icon: "scope", fix: "paywall_custom.fix_focus".localized, theme: "focus"),
            "Pensées négatives en boucle": DetectedIssue(icon: "arrow.trianglehead.2.clockwise", fix: "paywall_custom.fix_negative_thoughts".localized, theme: "anxiety"),
            "Irritabilité": DetectedIssue(icon: "flame.fill", fix: "paywall_custom.fix_irritability".localized, theme: "irritability"),
            "Brouillard mental": DetectedIssue(icon: "cloud.fill", fix: "paywall_custom.fix_brain_fog".localized, theme: "anxiety"),
            "Perte de motivation": DetectedIssue(icon: "battery.25percent", fix: "paywall_custom.fix_motivation".localized, theme: "motivation"),
            // ── Mental EN ──
            "Frequent anxiety": DetectedIssue(icon: "waveform.path.ecg", fix: "paywall_custom.fix_anxiety".localized, theme: "anxiety"),
            "Difficulty focusing": DetectedIssue(icon: "scope", fix: "paywall_custom.fix_focus".localized, theme: "focus"),
            "Negative thought loops": DetectedIssue(icon: "arrow.trianglehead.2.clockwise", fix: "paywall_custom.fix_negative_thoughts".localized, theme: "anxiety"),
            "Irritability": DetectedIssue(icon: "flame.fill", fix: "paywall_custom.fix_irritability".localized, theme: "irritability"),
            "Brain fog": DetectedIssue(icon: "cloud.fill", fix: "paywall_custom.fix_brain_fog".localized, theme: "anxiety"),
            "Loss of motivation": DetectedIssue(icon: "battery.25percent", fix: "paywall_custom.fix_motivation".localized, theme: "motivation"),

            // ── Physique FR ──
            "Sommeil perturbé ou non réparateur": DetectedIssue(icon: "moon.zzz.fill", fix: "paywall_custom.fix_sleep".localized, theme: "sleep"),
            "Fatigue chronique": DetectedIssue(icon: "bolt.slash.fill", fix: "paywall_custom.fix_fatigue".localized, theme: "energy"),
            "Maux de tête fréquents": DetectedIssue(icon: "brain.head.profile", fix: "paywall_custom.fix_headaches".localized, theme: "physical"),
            "Tensions dans le cou ou les épaules": DetectedIssue(icon: "figure.arms.open", fix: "paywall_custom.fix_tension".localized, theme: "physical"),
            "Prise de poids inexpliquée": DetectedIssue(icon: "scalemass.fill", fix: "paywall_custom.fix_weight".localized, theme: "physical"),
            "Palpitations ou souffle court": DetectedIssue(icon: "heart.fill", fix: "paywall_custom.fix_heart".localized, theme: "physical"),
            // ── Physique EN ──
            "Disrupted or unrestful sleep": DetectedIssue(icon: "moon.zzz.fill", fix: "paywall_custom.fix_sleep".localized, theme: "sleep"),
            "Chronic fatigue": DetectedIssue(icon: "bolt.slash.fill", fix: "paywall_custom.fix_fatigue".localized, theme: "energy"),
            "Frequent headaches": DetectedIssue(icon: "brain.head.profile", fix: "paywall_custom.fix_headaches".localized, theme: "physical"),
            "Neck or shoulder tension": DetectedIssue(icon: "figure.arms.open", fix: "paywall_custom.fix_tension".localized, theme: "physical"),
            "Unexplained weight gain": DetectedIssue(icon: "scalemass.fill", fix: "paywall_custom.fix_weight".localized, theme: "physical"),
            "Heart palpitations or shortness of breath": DetectedIssue(icon: "heart.fill", fix: "paywall_custom.fix_heart".localized, theme: "physical"),

            // ── Social FR ──
            "Envie de s'isoler": DetectedIssue(icon: "person.crop.circle.badge.minus", fix: "paywall_custom.fix_isolation".localized, theme: "social"),
            "Conflits relationnels plus fréquents": DetectedIssue(icon: "bubble.left.and.bubble.right.fill", fix: "paywall_custom.fix_conflicts".localized, theme: "social"),
            "Perte d'intérêt pour les activités": DetectedIssue(icon: "star.slash.fill", fix: "paywall_custom.fix_interest".localized, theme: "social"),
            "Difficulté à communiquer": DetectedIssue(icon: "mic.slash.fill", fix: "paywall_custom.fix_communication".localized, theme: "social"),
            "Impatience ou irritabilité avec les proches": DetectedIssue(icon: "figure.2.arms.open", fix: "paywall_custom.fix_impatience".localized, theme: "social"),
            // ── Social EN ──
            "Desire to isolate": DetectedIssue(icon: "person.crop.circle.badge.minus", fix: "paywall_custom.fix_isolation".localized, theme: "social"),
            "More frequent relationship conflicts": DetectedIssue(icon: "bubble.left.and.bubble.right.fill", fix: "paywall_custom.fix_conflicts".localized, theme: "social"),
            "Loss of interest in activities": DetectedIssue(icon: "star.slash.fill", fix: "paywall_custom.fix_interest".localized, theme: "social"),
            "Difficulty communicating": DetectedIssue(icon: "mic.slash.fill", fix: "paywall_custom.fix_communication".localized, theme: "social"),
            "Impatience or irritability with loved ones": DetectedIssue(icon: "figure.2.arms.open", fix: "paywall_custom.fix_impatience".localized, theme: "social"),
        ]
    }

    // Ordered fallbacks — listed from most to least generic so we can pick non-redundant ones
    private var allFallbacks: [DetectedIssue] {
        [
            DetectedIssue(icon: "brain.head.profile", fix: "paywall_custom.fallback_stress".localized, theme: "stress"),
            DetectedIssue(icon: "moon.zzz.fill",      fix: "paywall_custom.fallback_sleep".localized,  theme: "sleep"),
            DetectedIssue(icon: "bolt.fill",           fix: "paywall_custom.fallback_energy".localized, theme: "energy"),
            DetectedIssue(icon: "scope",               fix: "paywall_custom.fallback_focus".localized,  theme: "focus"),
        ]
    }

    /// The map is keyed by the FR/EN labels; a symptom picked in de/es/ja/ko is matched through its
    /// stable id (symptom_checker.<group>.<n>) and the French label of that id.
    private static let frenchBundle = Bundle.main.path(forResource: "fr", ofType: "lproj").flatMap(Bundle.init(path:))

    private static func frenchLabel(for symptom: String) -> String {
        guard let id = PlanLocalizationLookup.symptomIDs(from: [symptom]).first,
              let bundle = frenchBundle else { return symptom }
        return bundle.localizedString(forKey: "symptom_checker.\(id)", value: symptom, table: nil)
    }

    private var detectedIssues: [DetectedIssue] {
        let map = symptomToIssue

        // Deduplicate by theme (keep first occurrence per theme), max 3 symptom fixes
        var seenThemes: Set<String> = []
        var symptomFixes: [DetectedIssue] = []
        for symptom in selectedSymptoms {
            guard let issue = map[symptom] ?? map[Self.frenchLabel(for: symptom)], !seenThemes.contains(issue.theme) else { continue }
            seenThemes.insert(issue.theme)
            symptomFixes.append(issue)
            if symptomFixes.count == 3 { break }
        }

        // Fill remaining slots with fallbacks whose theme isn't already shown
        let needed = 4 - symptomFixes.count
        let fillers = allFallbacks
            .filter { !seenThemes.contains($0.theme) }
            .prefix(needed)

        return symptomFixes + Array(fillers)
    }

    private var personalizedInsightSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(detectedIssues.enumerated()), id: \.offset) { _, issue in
                HStack(spacing: 10) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "B794F6"))

                    Text(issue.fix)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    .font(.faroSemiBold(16))
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
                    weekNumber: OnboardingHabitTargets.planWeeks,
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
                    Text("paywall_custom.plan_without".localized)
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

    // MARK: - Date Transformation Section

    private var dateTransformationSection: some View {
        VStack(spacing: 16) {
            Text("paywall_custom.if_start_today".localized)
                .font(.faroBold(22))
                .foregroundColor(.white)

            Text("paywall_custom.transform_subtitle".localized)
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
                title: "paywall_custom.feature_program_title".localized,
                description: "paywall_custom.feature_program_desc".localized,
                isNew: false
            )

            Divider().background(Color.white.opacity(0.1))

            PaywallFeatureListRow(
                icon: "headphones",
                title: "paywall_custom.feature_library_title".localized,
                description: "paywall_custom.feature_library_desc".localized,
                isNew: false
            )

            Divider().background(Color.white.opacity(0.1))

            PaywallFeatureListRow(
                icon: "bubble.left.and.text.bubble.right.fill",
                title: "paywall_custom.feature_milo_title".localized,
                description: "paywall_custom.feature_milo_desc".localized,
                isNew: true
            )

            Divider().background(Color.white.opacity(0.1))

            PaywallFeatureListRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "paywall_custom.feature_tracking_title".localized,
                description: "paywall_custom.feature_tracking_desc".localized,
                isNew: false
            )

            Divider().background(Color.white.opacity(0.1))

            PaywallFeatureListRow(
                icon: "pencil.and.outline",
                title: "paywall_custom.feature_journal_title".localized,
                description: "paywall_custom.feature_journal_desc".localized,
                isNew: false
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

    // Today: the user's own quiz scores. Day 28: an indicative projection.
    // Vertex order: global, serenity, sleep, energy, focus, balance.
    private var smallProgress: [Double] {
        guard let result = habitsQuizResult else { return [0.15, 0.22, 0.18, 0.12, 0.20, 0.16] }
        return [result.globalScore, result.serenityScore, result.sleepScore,
                result.energyScore, result.focusScore, result.balanceScore]
            .map { min(0.85, max(0.15, Double($0) / 100)) }
    }

    private var largeProgress: [Double] {
        smallProgress.map { $0 + (0.95 - $0) * 0.7 }
    }

    private var radarChartSection: some View {
        VStack(spacing: 16) {
            Text(userName.isEmpty
                 ? "paywall_custom.radar_title_generic".localized
                 : String(format: "paywall_custom.radar_title".localized, userName))
                .font(.faroBold(22))
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
                PaywallRadarLabels(size: ResponsiveLayout.cardWidth(base: 165))
            }
            .responsiveFrame(width: 280, height: 280)
            .padding(.vertical, 8)
            .drawingGroup() // PERFORMANCE: Render radar chart as bitmap
        }
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
    }

    // MARK: - Floating CTA Section (Fixed at bottom)

    private var floatingCTASection: some View {
        VStack(spacing: 8) {
            // Main CTA button - Presents the Superwall paywall
            Button(action: {
                HapticManager.medium()
                showStartProgramScreen = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .semibold))
                    Text("paywall_custom.cta_start".localized)
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
                Text("paywall_custom.footer_privacy".localized)
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }

            Button(action: {
                HapticManager.light()
                onRestore()
            }) {
                Text("paywall_custom.footer_restore".localized)
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }

            Button(action: {
                HapticManager.light()
                LegalDocumentsHelper.openTerms()
            }) {
                Text("paywall_custom.footer_terms".localized)
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Helper Methods

    private func startRadarAnimation() {
        // PERFORMANCE: Use DispatchQueue instead of Timer for better performance
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                radarAnimationProgress = radarAnimationProgress < 0.5 ? 1.0 : 0.0
            }
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
                        .font(.faroSemiBold(15))
                        .foregroundColor(.white)

                    if isNew {
                        Text("paywall_custom.new_badge".localized)
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
                Text("paywall_custom.radar_label_global".localized)
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: 0, y: -labelOffset)

            // Sérénité - Top right
            HStack(spacing: 3) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: iconSize))
                Text("paywall_custom.radar_label_serenity".localized)
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: sideOffset, y: -verticalOffset)

            // Sommeil - Bottom right
            HStack(spacing: 3) {
                Image(systemName: "moon.fill")
                    .font(.system(size: iconSize))
                Text("paywall_custom.radar_label_sleep".localized)
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: sideOffset, y: verticalOffset)

            // Énergie - Bottom
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: iconSize))
                Text("paywall_custom.radar_label_energy".localized)
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: 0, y: labelOffset)

            // Focus - Bottom left
            HStack(spacing: 3) {
                Image(systemName: "target")
                    .font(.system(size: iconSize))
                Text("paywall_custom.radar_label_focus".localized)
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: -sideOffset, y: verticalOffset)

            // Glow - Top left
            HStack(spacing: 3) {
                Image(systemName: "sparkles")
                    .font(.system(size: iconSize))
                Text("paywall_custom.radar_label_balance".localized)
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

// Paywalls are presented through Superwall (RevenueCat handles purchases via RCPurchaseController).
