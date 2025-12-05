//
//  CustomPaywallView.swift
//  CortiFree
//
//  Created by Claude on 30/11/2025.
//  Custom paywall design inspired by Life Reset - adapted for CortiFree
//

import SwiftUI
import StoreKit

struct CustomPaywallView: View {
    let onComplete: () -> Void
    let onPurchase: (String) -> Void // "monthly" or "yearly"
    let onRestore: () -> Void

    // StoreKit Manager for real prices
    @StateObject private var storeKit = StoreKitManager.shared

    // User data from onboarding
    var userName: String = "toi"
    var baselineScores: [Double] = [0.4, 0.35, 0.45, 0.5, 0.4] // Sérénité, Sommeil, Énergie, Focus, Équilibre
    var potentialScores: [Double] = [0.85, 0.80, 0.90, 0.88, 0.82]

    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var countdownSeconds: Int = 29 * 60 + 59 // 29:59
    @State private var currentReviewIndex: Int = 0
    @State private var radarAnimationProgress: Double = 0.0 // 0.0 = week 0, 1.0 = week 10
    @State private var currentHabitIndex: Int = 0
    @State private var currentWeek: Int = 1
    @State private var showSpecialOfferPopup: Bool = false
    @State private var showStartProgramScreen: Bool = false
    @State private var showGiftCardScreen: Bool = false

    private var isFrench: Bool {
        Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
    }

    // MARK: - Dynamic Prices from StoreKit

    private var monthlyPrice: String {
        storeKit.monthlyProduct?.displayPrice ?? "9,99 €"
    }

    private var yearlyPrice: String {
        storeKit.yearlyProduct?.displayPrice ?? "34,99 €"
    }

    private var monthlyDecimalPrice: Decimal {
        storeKit.monthlyProduct?.price ?? 9.99
    }

    private var yearlyDecimalPrice: Decimal {
        storeKit.yearlyProduct?.price ?? 34.99
    }

    // Calculate monthly equivalent for yearly subscription
    private var yearlyMonthlyEquivalent: String {
        let yearlyPrice = yearlyDecimalPrice
        let monthlyEquivalent = yearlyPrice / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = storeKit.yearlyProduct?.priceFormatStyle.currencyCode ?? "EUR"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: monthlyEquivalent as NSDecimalNumber) ?? "2,92 €"
    }

    // Calculate discount percentage: (monthly×12 - yearly) / (monthly×12) × 100
    private var discountPercentage: Int {
        let monthlyTotal = monthlyDecimalPrice * 12
        let yearly = yearlyDecimalPrice
        guard monthlyTotal > 0 else { return 71 }
        let discount = ((monthlyTotal - yearly) / monthlyTotal) * 100
        return Int(NSDecimalNumber(decimal: discount).doubleValue.rounded())
    }

    // Daily price for yearly subscription
    private var dailyPrice: String {
        let yearlyPrice = yearlyDecimalPrice
        let dailyEquivalent = yearlyPrice / 365
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = storeKit.yearlyProduct?.priceFormatStyle.currencyCode ?? "EUR"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: dailyEquivalent as NSDecimalNumber) ?? "0,10 €"
    }

    // Les habitudes avec leurs statistiques de progression (same as HabitsProgressFlowView)
    private var habitProgresses: [PaywallHabitProgress] {
        [
            PaywallHabitProgress(
                icon: "wind",
                title: isFrench ? "Respirer consciemment" : "Breathe Consciously",
                yAxisValues: ["15 min", "30 min", "45 min", "1h"],
                currentValue: "1h",
                statMessage: isFrench ? "pratiqueras la respiration consciente 1h par semaine." : "will practice conscious breathing 1h per week.",
                curveStyle: 0
            ),
            PaywallHabitProgress(
                icon: "figure.mind.and.body",
                title: isFrench ? "Méditer" : "Meditate",
                yAxisValues: ["20 min", "40 min", "1h", "1h20", "1h40"],
                currentValue: "1h30",
                statMessage: isFrench ? "méditeras 1h30 par semaine." : "will meditate 1h30 per week.",
                curveStyle: 1
            ),
            PaywallHabitProgress(
                icon: "book.pages",
                title: isFrench ? "Tenir un journal" : "Keep a Journal",
                yAxisValues: ["2x", "3x", "5x", "7x"],
                currentValue: "7x",
                statMessage: isFrench ? "tiendras un journal 7 fois par semaine." : "will journal 7 times per week.",
                curveStyle: 2
            ),
            PaywallHabitProgress(
                icon: "figure.walk",
                title: isFrench ? "Faire du sport" : "Exercise",
                yAxisValues: ["45 min", "1h30", "2h15", "3h", "3h45"],
                currentValue: "3h30",
                statMessage: isFrench ? "feras du sport 3h30 par semaine." : "will exercise 3h30 per week.",
                curveStyle: 3
            ),
            PaywallHabitProgress(
                icon: "drop.fill",
                title: isFrench ? "Boire de l'eau" : "Drink Water",
                yAxisValues: ["1.5L", "2L", "2.5L", "3L"],
                currentValue: "2,5L",
                statMessage: isFrench ? "boiras 2,5L d'eau par jour." : "will drink 2.5L of water per day.",
                curveStyle: 4
            ),
            PaywallHabitProgress(
                icon: "tree.fill",
                title: isFrench ? "Passer du temps en nature" : "Spend Time in Nature",
                yAxisValues: ["45 min", "1h30", "2h15", "3h", "3h45"],
                currentValue: "3h30",
                statMessage: isFrench ? "passeras 3h30 en nature par semaine." : "will spend 3h30 in nature per week.",
                curveStyle: 5
            ),
            PaywallHabitProgress(
                icon: "moon.zzz.fill",
                title: isFrench ? "Suivre une routine sommeil" : "Follow a Sleep Routine",
                yAxisValues: ["6h", "6.5h", "7h", "7.5h", "8h"],
                currentValue: "8h",
                statMessage: isFrench ? "dormiras 8 heures par nuit." : "will sleep 8 hours per night.",
                curveStyle: 6
            ),
            PaywallHabitProgress(
                icon: "person.2.fill",
                title: isFrench ? "Se connecter socialement" : "Connect Socially",
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

                    // Countdown timer
                    countdownSection

                    // Stats section
                    statsSection

                    // Date transformation
                    dateTransformationSection

                    // Features list
                    featuresSection

                    // Radar chart with potential
                    radarChartSection

                    // Testimonial quote
                    testimonialSection

                    // Reviews carousel
                    reviewsSection

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

            // Gift card screen overlay (before special offer)
            if showGiftCardScreen {
                PaywallGiftCardScreen(
                    isPresented: $showGiftCardScreen,
                    onContinue: {
                        showGiftCardScreen = false
                        showSpecialOfferPopup = true
                    },
                    onDismiss: {
                        showGiftCardScreen = false
                    }
                )
                .transition(.opacity)
            }

            // Special offer popup overlay
            if showSpecialOfferPopup {
                PaywallSpecialOfferPopup(
                    isPresented: $showSpecialOfferPopup,
                    onPurchase: onPurchase,
                    onDismissToPaywall: {
                        showSpecialOfferPopup = false
                    },
                    countdownSeconds: countdownSeconds,
                    yearlyPrice: yearlyPrice,
                    yearlyMonthlyEquivalent: yearlyMonthlyEquivalent,
                    discountPercentage: discountPercentage,
                    dailyPrice: dailyPrice
                )
                .transition(.opacity)
            }

            // Start program screen overlay
            if showStartProgramScreen {
                PaywallStartProgramScreen(
                    isPresented: $showStartProgramScreen,
                    userName: userName,
                    onPurchase: onPurchase,
                    onRestore: onRestore,
                    countdownSeconds: countdownSeconds,
                    monthlyPrice: monthlyPrice,
                    yearlyPrice: yearlyPrice,
                    yearlyMonthlyEquivalent: yearlyMonthlyEquivalent,
                    discountPercentage: discountPercentage,
                    dailyPrice: dailyPrice
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            startCountdown()
            startRadarAnimation()
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
            // Checkmark icon
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 50, height: 50)

                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }

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

    // MARK: - Countdown Section

    private var countdownSection: some View {
        VStack(spacing: 16) {
            Text(isFrench ? "L'offre se termine dans :" : "Offer ends in:")
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.white.opacity(0.8))

            HStack(spacing: 12) {
                PaywallCountdownUnit(value: String(format: "%02d", countdownSeconds / 3600))
                PaywallCountdownUnit(value: String(format: "%02d", (countdownSeconds % 3600) / 60))
                PaywallCountdownUnit(value: String(format: "%02d", countdownSeconds % 60))
            }

            // Limited offer button
            Button(action: {
                HapticManager.medium()
                withAnimation(.easeInOut(duration: 0.2)) {
                    showGiftCardScreen = true
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 18))

                    Text(isFrench ? "Obtenir la Réduction Limitée" : "Get Limited Discount")
                        .font(.custom("Poppins-SemiBold", size: 16))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "9F7AEA"), Color(hex: "B794F6")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(AppConstants.Layout.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, AppConstants.Layout.paddingXLarge)
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
                // Background hexagon grid (fixed size)
                HexagonRadarGrid()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    .frame(width: 165, height: 165)

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
                    .frame(width: 165, height: 165)

                // Stroke around the filled hexagon
                HexagonRadarFill(progress: hexagonIsLarge ? largeProgress : smallProgress)
                    .stroke((hexagonIsLarge ? Color(hex: "27AE60") : Color(hex: "D32F2F")).opacity(0.8), lineWidth: 3)
                    .frame(width: 165, height: 165)

                // Labels (using larger frame for positioning)
                PaywallRadarLabels(size: 165, isFrench: isFrench)
            }
            .frame(width: 280, height: 280)
            .padding(.vertical, 8)
        }
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
    }

    // MARK: - Testimonial Section

    private var testimonialSection: some View {
        VStack(spacing: 12) {
            Text(isFrench
                 ? "Ton destin t'attend. Tu libéreras ton\nvéritable potentiel le :"
                 : "Your destiny awaits. You will unlock\nyour true potential on:")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Text(formattedEndDate)
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                )

            Text(isFrench
                 ? "«Le meilleur investissement que\nj'ai jamais fait. Aucun regret.»"
                 : "\"The best investment I've\never made. No regrets.\"")
                .font(.custom("Poppins-SemiBold", size: 18))
                .italic()
                .foregroundColor(Color(hex: "FFD700"))
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Text(isFrench ? "- Marie de Paris, France" : "- Sarah from New York, USA")
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
    }

    // MARK: - Reviews Section

    private var reviewsSection: some View {
        VStack(spacing: 16) {
            // Review card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(reviews[currentReviewIndex].username)
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.white)

                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                        }
                    }
                }

                Text(reviews[currentReviewIndex].text)
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
            }
            .padding(AppConstants.Layout.paddingMedium)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )

            // Dots indicator
            HStack(spacing: 6) {
                ForEach(0..<reviews.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentReviewIndex ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.horizontal, AppConstants.Layout.paddingXLarge)
        .onAppear {
            startReviewCarousel()
        }
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
                        .fill(Color(hex: "B794F6"))
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
                if let url = URL(string: "https://cortifree.app/privacy") {
                    UIApplication.shared.open(url)
                }
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
                if let url = URL(string: "https://cortifree.app/terms") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text(isFrench ? "CGU" : "Terms")
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Helper Methods

    private func startCountdown() {
        // Check if we have a saved end time
        let endTimeKey = "paywallCountdownEndTime"
        let userDefaults = UserDefaults.standard

        if let savedEndTime = userDefaults.object(forKey: endTimeKey) as? Date {
            // Calculate remaining time
            let remaining = Int(savedEndTime.timeIntervalSinceNow)
            if remaining > 0 {
                countdownSeconds = remaining
            } else {
                // Timer expired, restart at 30 minutes
                let newEndTime = Date().addingTimeInterval(30 * 60)
                userDefaults.set(newEndTime, forKey: endTimeKey)
                countdownSeconds = 30 * 60
            }
        } else {
            // First time - set end time to 30 minutes from now
            let endTime = Date().addingTimeInterval(Double(countdownSeconds))
            userDefaults.set(endTime, forKey: endTimeKey)
        }

        // Start the timer
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Recalculate from saved end time to handle background
            if let savedEndTime = userDefaults.object(forKey: endTimeKey) as? Date {
                let remaining = Int(savedEndTime.timeIntervalSinceNow)
                if remaining > 0 {
                    countdownSeconds = remaining
                } else {
                    // Timer reached 0, restart at 30 minutes
                    let newEndTime = Date().addingTimeInterval(30 * 60)
                    userDefaults.set(newEndTime, forKey: endTimeKey)
                    countdownSeconds = 30 * 60
                }
            }
        }
    }

    private func startReviewCarousel() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation {
                currentReviewIndex = (currentReviewIndex + 1) % reviews.count
            }
        }
    }

    private func startRadarAnimation() {
        // Toggle between small (0) and large (1) every 1.5 seconds - no animation
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            radarAnimationProgress = radarAnimationProgress < 0.5 ? 1.0 : 0.0
        }
    }

    // Reviews data
    private var reviews: [PaywallReview] {
        [
            PaywallReview(
                username: "claire_zen",
                text: isFrench
                    ? "CortiFree m'aide déjà à me sentir plus sereine et maître de mes émotions ! L'app est apaisante et les exercices sont parfaits pour mon quotidien stressant."
                    : "CortiFree is already helping me feel more serene and in control of my emotions! The app is soothing and the exercises are perfect for my stressful daily life."
            ),
            PaywallReview(
                username: "thomas_fit",
                text: isFrench
                    ? "Après 3 semaines, mon sommeil s'est nettement amélioré. Les méditations guidées sont top et je me sens plus énergique chaque jour."
                    : "After 3 weeks, my sleep has improved significantly. The guided meditations are great and I feel more energetic every day."
            ),
            PaywallReview(
                username: "sophie_paris",
                text: isFrench
                    ? "Le programme de 66 jours est vraiment bien structuré. Je vois mes progrès sur le graphique et ça me motive à continuer !"
                    : "The 66-day program is really well structured. I can see my progress on the chart and it motivates me to keep going!"
            )
        ]
    }
}

// MARK: - Supporting Types

enum PaywallPlan: String {
    case monthly = "monthly"
    case yearly = "yearly"
}

struct PaywallReview {
    let username: String
    let text: String
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
                .foregroundColor(Color(hex: "10B981"))
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

struct PaywallCountdownUnit: View {
    let value: String

    var body: some View {
        Text(value)
            .font(.custom("Poppins-Bold", size: 28))
            .foregroundColor(.white)
            .frame(width: 60, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "B794F6").opacity(0.3))
            )
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
                            .foregroundColor(Color(hex: "10B981"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(hex: "10B981"), lineWidth: 1)
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

// MARK: - Special Offer Popup

struct PaywallSpecialOfferPopup: View {
    @Binding var isPresented: Bool
    let onPurchase: (String) -> Void
    let onDismissToPaywall: () -> Void
    let countdownSeconds: Int

    // Dynamic prices from StoreKit
    var yearlyPrice: String = "34,99 €"
    var yearlyMonthlyEquivalent: String = "2,92 €"
    var discountPercentage: Int = 71
    var dailyPrice: String = "0,10 €"

    @State private var showConfetti: Bool = false

    private var isFrench: Bool {
        Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
    }

    var body: some View {
        ZStack {
            // Galaxy background (same as app)
            GalaxyBackgroundView()
                .ignoresSafeArea()

            // Lottie confetti animation (plays once on appear)
            if showConfetti {
                LottieView(filename: "confetti", loopMode: .playOnce)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Button(action: {
                        HapticManager.light()
                        onDismissToPaywall()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Title
                Text(isFrench ? "Offre unique" : "Unique Offer")
                    .font(.custom("Poppins-Bold", size: 32))
                    .foregroundColor(.white)
                    .padding(.top, 8)

                // Countdown section
                VStack(spacing: 12) {
                    Text(isFrench ? "L'offre se termine dans :" : "Offer ends in:")
                        .font(.custom("Poppins-Regular", size: 15))
                        .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 10) {
                        OfferCountdownUnit(value: String(format: "%02d", countdownSeconds / 3600))
                        OfferCountdownUnit(value: String(format: "%02d", (countdownSeconds % 3600) / 60))
                        OfferCountdownUnit(value: String(format: "%02d", countdownSeconds % 60))
                    }
                }
                .padding(.top, 24)

                Spacer()

                // Main offer card with gradient
                VStack(spacing: 20) {
                    // Discount percentage (uniform white text)
                    HStack(spacing: 8) {
                        Text("\(discountPercentage)%")
                            .font(.custom("Poppins-Bold", size: 56))
                            .foregroundColor(.white)
                        Text(isFrench ? "de réduction" : "discount")
                            .font(.custom("Poppins-Bold", size: 28))
                            .foregroundColor(.white)
                    }

                    // Monthly equivalent badge
                    Text(isFrench ? "Seulement \(yearlyMonthlyEquivalent) par mois" : "Only \(yearlyMonthlyEquivalent) per month")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.black.opacity(0.4))
                        )

                    // Price
                    Text("\(yearlyPrice)/\(isFrench ? "an" : "yr") - \(isFrench ? "au plus bas" : "lowest price")")
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(.white.opacity(0.7))

                    // Benefits list
                    VStack(alignment: .leading, spacing: 10) {
                        OfferBenefitRow(text: isFrench ? "Seulement \(dailyPrice) par jour" : "Only \(dailyPrice) per day")
                        OfferBenefitRow(text: isFrench ? "Programme CortiFree de 66 jours" : "66-day CortiFree program")
                        OfferBenefitRow(text: isFrench ? "Transforme ta vie pour toujours" : "Transform your life forever")
                        OfferBenefitRow(text: isFrench ? "Accès illimité" : "Unlimited access")
                    }
                    .padding(.top, 8)
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "7C3AED"),
                                    Color.black
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .padding(.horizontal, 24)

                Spacer()

                // CTA Button (white)
                Button(action: {
                    HapticManager.medium()
                    onPurchase("yearly")
                }) {
                    Text(isFrench ? "Obtenez votre offre limitée\nmaintenant !" : "Get your limited offer\nnow!")
                        .font(.custom("Poppins-SemiBold", size: 17))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                        )
                }
                .padding(.horizontal, 24)

                // Footer info
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        Text(isFrench ? "Facturation annuelle - annulez quand vous voulez." : "Annual billing - cancel anytime.")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    // Footer links
                    HStack(spacing: 24) {
                        Button(action: {
                            if let url = URL(string: "https://cortifree.app/terms") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text(isFrench ? "Conditions d'Utilisation" : "Terms of Use")
                                .font(.custom("Poppins-Regular", size: 11))
                                .foregroundColor(.white.opacity(0.4))
                        }

                        Button(action: {
                            if let url = URL(string: "https://cortifree.app/privacy") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text(isFrench ? "Politique de confidentialité" : "Privacy Policy")
                                .font(.custom("Poppins-Regular", size: 11))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            // Trigger confetti animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showConfetti = true
                HapticManager.medium()
            }
        }
    }
}

// MARK: - Countdown Unit (White boxes for offer)

struct OfferCountdownUnit: View {
    let value: String

    var body: some View {
        Text(value)
            .font(.custom("Poppins-Bold", size: 28))
            .foregroundColor(.black)
            .frame(width: 60, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
    }
}

// MARK: - Benefit Row for Offer

struct OfferBenefitRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "B794F6"))

            Text(text)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.9))
        }
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
    let countdownSeconds: Int

    // Dynamic prices from StoreKit
    var monthlyPrice: String = "9,99 €"
    var yearlyPrice: String = "34,99 €"
    var yearlyMonthlyEquivalent: String = "2,92 €"
    var discountPercentage: Int = 71
    var dailyPrice: String = "0,10 €"

    @State private var selectedPlan: String = "yearly"
    @State private var showSpecialOffer: Bool = false
    @State private var hasShownSpecialOffer: Bool = false

    private var isFrench: Bool {
        Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
    }

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

                    // Logo CortiFree
                    Image("cortifree_logo_white")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)

                    Spacer()

                    Button(action: {
                        HapticManager.light()
                        // Show special offer if not shown yet, otherwise close
                        if !hasShownSpecialOffer {
                            hasShownSpecialOffer = true
                            showSpecialOffer = true
                        } else {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Main title
                        Text(isFrench
                             ? "Tu es le personnage principal.\nDans 66 jours, ton retour épique\ncommence."
                             : "You are the main character.\nIn 66 days, your epic comeback\nbegins.")
                            .font(.custom("Poppins-Bold", size: 22))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        // Features list with purple star icons
                        VStack(alignment: .leading, spacing: 14) {
                            PaywallFeatureBullet(text: isFrench ? "Programme personnalisé de 66 jours" : "Personalized 66-day program")
                            PaywallFeatureBullet(text: isFrench ? "Exercices de respiration guidés" : "Guided breathing exercises")
                            PaywallFeatureBullet(text: isFrench ? "Suivi quotidien de tes progrès" : "Daily progress tracking")
                            PaywallFeatureBullet(text: isFrench ? "Méditations anti-stress" : "Anti-stress meditations")
                            PaywallFeatureBullet(text: isFrench ? "Rappels intelligents" : "Smart reminders")
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 20)

                        // Pricing options side by side
                        HStack(spacing: 12) {
                            // Monthly option
                            ProgramPlanCard(
                                title: isFrench ? "MENSUEL" : "MONTHLY",
                                price: monthlyPrice,
                                period: isFrench ? "/mo" : "/mo",
                                subtitle: isFrench ? "Plan de base" : "Basic plan",
                                badgeText: nil,
                                isSelected: selectedPlan == "monthly",
                                onTap: {
                                    HapticManager.light()
                                    selectedPlan = "monthly"
                                }
                            )

                            // Yearly option (with badge)
                            ProgramPlanCard(
                                title: isFrench ? "ANNUEL" : "YEARLY",
                                price: yearlyPrice,
                                period: isFrench ? "/an" : "/yr",
                                subtitle: isFrench ? "Seulement \(yearlyMonthlyEquivalent) par mois !" : "Only \(yearlyMonthlyEquivalent) per month!",
                                badgeText: isFrench ? "ÉCONOMISEZ \(discountPercentage) %" : "SAVE \(discountPercentage)%",
                                isSelected: selectedPlan == "yearly",
                                onTap: {
                                    HapticManager.light()
                                    selectedPlan = "yearly"
                                }
                            )
                        }
                        .padding(.horizontal, 24)

                        // CTA Button
                        Button(action: {
                            HapticManager.medium()
                            onPurchase(selectedPlan)
                        }) {
                            Text(isFrench ? "Lancer mon parcours" : "Start my journey")
                                .font(.custom("Poppins-Bold", size: 18))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "7C3AED"), Color(hex: "2563EB")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 24)

                        // Footer links
                        HStack(spacing: 32) {
                            Button(action: {
                                if let url = URL(string: "https://cortifree.app/terms") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text(isFrench ? "Conditions d'Utilisation" : "Terms of Use")
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundColor(.white.opacity(0.4))
                            }

                            Button(action: {
                                if let url = URL(string: "https://cortifree.app/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text(isFrench ? "Politique de confidentialité" : "Privacy Policy")
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        .padding(.bottom, 32)
                    }
                }
            }

            // Special offer popup overlay (inside StartProgramScreen)
            if showSpecialOffer {
                PaywallSpecialOfferPopup(
                    isPresented: $showSpecialOffer,
                    onPurchase: { plan in
                        showSpecialOffer = false
                        onPurchase(plan)
                    },
                    onDismissToPaywall: {
                        showSpecialOffer = false
                        isPresented = false
                    },
                    countdownSeconds: countdownSeconds,
                    yearlyPrice: yearlyPrice,
                    yearlyMonthlyEquivalent: yearlyMonthlyEquivalent,
                    discountPercentage: discountPercentage,
                    dailyPrice: dailyPrice
                )
                .transition(.opacity)
            }
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
    let subtitle: String
    let badgeText: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Badge at top (if exists)
                if let badge = badgeText {
                    Text(badge)
                        .font(.custom("Poppins-Bold", size: 11))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(hex: "10B981"))
                }

                VStack(spacing: 8) {
                    Text(title)
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(.white.opacity(0.7))

                    HStack(alignment: .bottom, spacing: 2) {
                        Text(price)
                            .font(.custom("Poppins-Bold", size: 24))
                            .foregroundColor(.white)
                        Text(period)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.bottom, 3)
                    }
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .frame(maxWidth: .infinity)
        // Subtitle below card
        .overlay(
            Text(subtitle)
                .font(.custom("Poppins-Medium", size: 11))
                .foregroundColor(badgeText != nil ? Color(hex: "10B981") : .white.opacity(0.5))
                .offset(y: badgeText != nil ? 80 : 70),
            alignment: .bottom
        )
    }
}

// MARK: - Gift Card Screen (before special offer)

struct PaywallGiftCardScreen: View {
    @Binding var isPresented: Bool
    let onContinue: () -> Void
    let onDismiss: () -> Void

    private var isFrench: Bool {
        Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Button(action: {
                        HapticManager.light()
                        onDismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Title
                Text(isFrench ? "Offre unique" : "Unique Offer")
                    .font(.custom("Poppins-Bold", size: 32))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                // Subtitle
                Text(isFrench
                     ? "Voici une réduction limitée.\nProfitez-en avant qu'elle ne disparaisse."
                     : "Here's a limited discount.\nGrab it before it's gone.")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 32)

                // Gift card image
                Image("special_offer_card")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280)
                    .cornerRadius(20)
                    .shadow(color: Color(hex: "7C3AED").opacity(0.5), radius: 20, x: 0, y: 10)

                Spacer()

                // CTA Button (gradient purple to blue)
                Button(action: {
                    HapticManager.medium()
                    onContinue()
                }) {
                    Text(isFrench ? "Obtenez votre offre limitée\nmaintenant !" : "Get your limited offer\nnow!")
                        .font(.custom("Poppins-SemiBold", size: 17))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "7C3AED"), Color(hex: "2563EB")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)

                // No thanks button
                Button(action: {
                    HapticManager.light()
                    onDismiss()
                }) {
                    Text(isFrench ? "Non merci" : "No thanks")
                        .font(.custom("Poppins-Regular", size: 15))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
    }
}

// Previews moved to PaywallSubviews.swift to fix compilation timeout
