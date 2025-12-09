//
//  CortiFreeRatingView.swift
//  CortiFree
//
//  Created by Claude on 10/11/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CortiFreeRatingView: View {
    let habitsQuizResult: HabitsQuizResult
    let onContinue: () -> Void
    @ObservedObject var languageManager = LanguageManager.shared
    @State private var selectedTab: RatingTab = .current
    @State private var animateProgress: Bool = false
    @State private var currentStartProgress: [Double] = []
    @State private var isSavingScore: Bool = false
    @State private var screenViewTime: Date?

    enum RatingTab {
        case current
        case potential
    }

    // MARK: - Computed Properties for Scores

    private var currentScores: [Int] {
        let scores = [
            min(habitsQuizResult.serenityScore, 65),
            min(habitsQuizResult.sleepScore, 65),
            min(habitsQuizResult.energyScore, 65),
            min(habitsQuizResult.focusScore, 65),
            min(habitsQuizResult.balanceScore, 65)
        ]
        let globalScore = min(scores.reduce(0, +) / scores.count, 65)
        return [globalScore] + scores
    }

    private var potentialScores: [Int] {
        currentScores.map { score in
            // Potentiel = score actuel + 65, plafonné à 98
            min(score + 65, 98)
        }
    }

    private var increases: [Int] {
        zip(currentScores, potentialScores).map { current, potential in
            potential - current
        }
    }

    private var currentProgress: [Double] {
        currentScores.map { Double($0) / 100.0 }
    }

    private var potentialProgress: [Double] {
        potentialScores.map { Double($0) / 100.0 }
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)

            VStack(spacing: 0) {
                    // Title
                    VStack(spacing: 4) {
                        if selectedTab == .current {
                            Text("onboarding_v2.rating.current_title".localized)
                                .font(Font.Poppins.custom(.bold, size: 28))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(hex: "B794F6")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .multilineTextAlignment(.center)
                        } else {
                            VStack(spacing: 0) {
                                Text("onboarding_v2.rating.potential_title".localized)
                                    .font(Font.Poppins.custom(.bold, size: 28))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, Color(hex: "B794F6")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                Text("onboarding_v2.rating.after_66_days".localized)
                                    .font(Font.Poppins.custom(.bold, size: 28))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, Color(hex: "B794F6")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 40)
                    .padding(.bottom, selectedTab == .potential ? 30 : 60)
                    .frame(height: 130)

                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        if selectedTab == .current {
                            // Current ratings - Using real quiz data
                            CortiFreeStatCard(icon: "star.fill", title: "onboarding_v2.rating.global".localized, value: currentScores[0], progress: currentProgress[0], color: Color(hex: "B794F6"), increase: nil, isCurrent: true, animateProgress: animateProgress, startProgress: currentStartProgress.isEmpty ? currentProgress[0] : currentStartProgress[0])
                            CortiFreeStatCard(icon: "leaf.fill", title: "onboarding_v2.rating.serenity".localized, value: currentScores[1], progress: currentProgress[1], color: Color(hex: "9B59B6"), increase: nil, isCurrent: true, animateProgress: animateProgress, startProgress: currentStartProgress.isEmpty ? currentProgress[1] : currentStartProgress[1])
                            CortiFreeStatCard(icon: "moon.fill", title: "onboarding_v2.rating.sleep".localized, value: currentScores[2], progress: currentProgress[2], color: Color(hex: "E74C3C"), increase: nil, isCurrent: true, animateProgress: animateProgress, startProgress: currentStartProgress.isEmpty ? currentProgress[2] : currentStartProgress[2])
                            CortiFreeStatCard(icon: "bolt.fill", title: "onboarding_v2.rating.energy".localized, value: currentScores[3], progress: currentProgress[3], color: Color(hex: "1ABC9C"), increase: nil, isCurrent: true, animateProgress: animateProgress, startProgress: currentStartProgress.isEmpty ? currentProgress[3] : currentStartProgress[3])
                            CortiFreeStatCard(icon: "target", title: "onboarding_v2.rating.focus".localized, value: currentScores[4], progress: currentProgress[4], color: Color(hex: "2ECC71"), increase: nil, isCurrent: true, animateProgress: animateProgress, startProgress: currentStartProgress.isEmpty ? currentProgress[4] : currentStartProgress[4])
                            CortiFreeStatCard(icon: "heart.fill", title: "onboarding_v2.rating.balance".localized, value: currentScores[5], progress: currentProgress[5], color: Color(hex: "3498DB"), increase: nil, isCurrent: true, animateProgress: animateProgress, startProgress: currentStartProgress.isEmpty ? currentProgress[5] : currentStartProgress[5])
                        } else {
                            // Potential ratings - Calculated from current scores
                            CortiFreeStatCard(icon: "star.fill", title: "onboarding_v2.rating.global".localized, value: potentialScores[0], progress: potentialProgress[0], color: Color(hex: "B794F6"), increase: increases[0], isCurrent: false, animateProgress: animateProgress, startProgress: currentStartProgress.isEmpty ? currentProgress[0] : currentStartProgress[0])
                            CortiFreeStatCard(icon: "leaf.fill", title: "onboarding_v2.rating.serenity".localized, value: potentialScores[1], progress: potentialProgress[1], color: Color(hex: "9B59B6"), increase: increases[1], isCurrent: false, animateProgress: animateProgress, startProgress: currentStartProgress.isEmpty ? currentProgress[1] : currentStartProgress[1])
                            CortiFreeStatCard(icon: "moon.fill", title: "onboarding_v2.rating.sleep".localized, value: potentialScores[2], progress: potentialProgress[2], color: Color(hex: "E74C3C"), increase: increases[2], isCurrent: false, animateProgress: animateProgress, startProgress: currentStartProgress.isEmpty ? currentProgress[2] : currentStartProgress[2])
                            CortiFreeStatCard(icon: "bolt.fill", title: "onboarding_v2.rating.energy".localized, value: potentialScores[3], progress: potentialProgress[3], color: Color(hex: "1ABC9C"), increase: increases[3], isCurrent: false, animateProgress: animateProgress, startProgress: currentStartProgress.isEmpty ? currentProgress[3] : currentStartProgress[3])
                            CortiFreeStatCard(icon: "target", title: "onboarding_v2.rating.focus".localized, value: potentialScores[4], progress: potentialProgress[4], color: Color(hex: "2ECC71"), increase: increases[4], isCurrent: false, animateProgress: animateProgress, startProgress: currentStartProgress.isEmpty ? currentProgress[4] : currentStartProgress[4])
                            CortiFreeStatCard(icon: "heart.fill", title: "onboarding_v2.rating.balance".localized, value: potentialScores[5], progress: potentialProgress[5], color: Color(hex: "3498DB"), increase: increases[5], isCurrent: false, animateProgress: animateProgress, startProgress: currentStartProgress.isEmpty ? currentProgress[5] : currentStartProgress[5])
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, selectedTab == .potential ? 0 : 0)
                    .padding(.bottom, 120)

                Spacer()
            }

            // Bottom button
            VStack {
                Spacer()

                if selectedTab == .current {
                    // Full width button for current
                    Button(action: {
                        HapticManager.medium()
                        animateProgress = false
                        // Save current progress as start for potential screen
                        currentStartProgress = currentProgress
                        selectedTab = .potential
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.8)) {
                                animateProgress = true
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .semibold))

                            Text("onboarding_v2.rating.see_potential".localized)
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
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                } else {
                    // Potential: Back button + Continue button
                    HStack(spacing: 12) {
                        // Back button (round)
                        Button(action: {
                            HapticManager.medium()
                            animateProgress = false
                            // Reset to actual percentage values for Current screen
                            currentStartProgress = currentProgress
                            selectedTab = .current
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeOut(duration: 0.8)) {
                                    animateProgress = true
                                }
                            }
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                )
                        }

                        // Continue button (smaller)
                        Button(action: {
                            HapticManager.medium()

                            // Track continue action with time spent
                            let timeSpent = screenViewTime.map { Date().timeIntervalSince($0) } ?? 0
                            MixpanelManager.shared.trackOnboardingRatingContinue(
                                timeSpent: timeSpent
                            )

                            saveScoreAndContinue()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 18, weight: .semibold))

                                Text(StringKeys.Common.continueButton)
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
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            screenViewTime = Date()

            // Track screen viewed with scores
            MixpanelManager.shared.trackOnboardingCortiFreeRatingViewed(
                serenityScore: habitsQuizResult.serenityScore,
                sleepScore: habitsQuizResult.sleepScore,
                energyScore: habitsQuizResult.energyScore,
                focusScore: habitsQuizResult.focusScore,
                habitsScore: habitsQuizResult.habitsScore
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateProgress = true
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func saveScoreAndContinue() {
        guard !isSavingScore else { return }

        Task {
            isSavingScore = true
            defer { isSavingScore = false }

            // Save score to Firebase
            if let userId = Auth.auth().currentUser?.uid {
                do {
                    let globalScore = currentScores[0] // Global score from quiz

                    // Save detailed scores to Firebase
                    let scoresData: [String: Any] = [
                        "onboardingScore": globalScore,
                        "onboardingScoreSavedAt": Timestamp(),
                        "domainScores": [
                            "global": currentScores[0],
                            "serenity": currentScores[1],
                            "sleep": currentScores[2],
                            "energy": currentScores[3],
                            "focus": currentScores[4],
                            "balance": currentScores[5]
                        ],
                        "potentialScores": [
                            "global": potentialScores[0],
                            "serenity": potentialScores[1],
                            "sleep": potentialScores[2],
                            "energy": potentialScores[3],
                            "focus": potentialScores[4],
                            "balance": potentialScores[5]
                        ]
                    ]

                    try await Firestore.firestore()
                        .collection("users")
                        .document(userId)
                        .setData(scoresData, merge: true)

                    // Note: UserSettings and program start date will be initialized
                    // in HomeView.onAppear after user passes paywall

                    #if DEBUG
                    print("✅ Successfully saved detailed onboarding scores")
                    #endif
                } catch {
                    #if DEBUG
                    print("❌ Error saving onboarding scores: \(error)")
                    #endif
                }
            }

            // Continue regardless of save success
            await MainActor.run {
                onContinue()
            }
        }
    }
}

// MARK: - CortiFree Stat Card

struct CortiFreeStatCard: View {
    let icon: String
    let title: String
    let value: Int
    let progress: Double
    let color: Color
    let increase: Int?
    let isCurrent: Bool
    let animateProgress: Bool
    let startProgress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Icon and title - More compact at top
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)

                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 12))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 8)

            Spacer()

            // Value with increase - Centered vertically
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(Font.Poppins.custom(.bold, size: 52))
                    .foregroundColor(.white)

                if let increase = increase {
                    Text("(+\(increase))")
                        .font(Font.Poppins.custom(.bold, size: 20))
                        .foregroundColor(.green)
                }
            }

            Spacer()

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(isCurrent ? Color.white.opacity(0.2) : Color.black.opacity(0.1))
                        .frame(height: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    // Progress - Red for current, Green for potential - Animated from startProgress
                    Rectangle()
                        .fill(increase == nil ? Color.red : Color.green)
                        .frame(width: geometry.size.width * (animateProgress ? progress : startProgress), height: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .aspectRatio(1, contentMode: .fill)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: isCurrent
                            ? [Color(hex: "B794F6"), Color.black]
                            : [
                                Color(hex: "B794F6").opacity(0.2),
                                Color(hex: "B794F6").opacity(0.4)
                            ],
                        startPoint: isCurrent ? .topLeading : .leading,
                        endPoint: isCurrent ? .bottomTrailing : .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isCurrent ? Color.white.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.6), value: isCurrent)
    }
}

#Preview {
    // Mock quiz result for preview (12 questions optimized)
    let mockAnswers = [0, 1, 2, 1, 2, 1, 1, 2, 3, 2, 3, 2] // 12 answers
    let mockResult = HabitsQuizResult(answers: mockAnswers)

    return CortiFreeRatingView(habitsQuizResult: mockResult, onContinue: {})
}
