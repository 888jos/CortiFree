//
//  BreathingExerciseView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Breathing exercise with animated circle
//

import SwiftUI
import Lottie
import FirebaseFirestore

struct BreathingExerciseView: View {
    let exerciseType: AntiStressExerciseType
    let situation: StressSituation
    @ObservedObject var viewModel: AntiStressViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var planetSettings = PlanetSettings.shared

    @State private var isBreathingIn = true
    @State private var timeRemaining: Int
    @State private var cycleCount = 0
    @State private var showCompletion = false
    @State private var showConfetti = false

    // Animation de la planète
    @State private var ballYPosition: CGFloat = 80 // Petite (exhale) = 80, Grande (inhale) = -80
    @State private var currentPhase: BreathingPhase = .inhale
    @State private var haloOpacity: Double = 0.3

    // Easter egg
    @State private var planetTapCount = 0
    @State private var showEasterEgg = false
    @State private var easterEggMessage = ""
    @State private var easterEggStars: [EasterEggStar] = []

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum BreathingPhase {
        case inhale, hold, exhale, holdOut
    }

    init(exerciseType: AntiStressExerciseType, situation: StressSituation, viewModel: AntiStressViewModel) {
        self.exerciseType = exerciseType
        self.situation = situation
        self.viewModel = viewModel
        _timeRemaining = State(initialValue: exerciseType.duration)
    }

    // Breathing pattern based on exercise type
    var breathingPattern: (inhale: Double, hold: Double, exhale: Double, holdOut: Double) {
        switch exerciseType {
        case .guidedBreathing, .consciousBreathing:
            return (4.0, 0.0, 6.0, 0.0) // 4-6 breathing
        case .cardiacCoherence:
            return (5.0, 0.0, 5.0, 0.0) // 5-5 breathing (coherence)
        case .boxBreathing:
            return (4.0, 4.0, 4.0, 4.0) // Box breathing
        case .alternateBreathing:
            return (4.0, 7.0, 8.0, 0.0) // 4-7-8 breathing
        default:
            return (4.0, 0.0, 4.0, 0.0) // Default
        }
    }

    var totalCycleDuration: Double {
        let pattern = breathingPattern
        return pattern.inhale + pattern.hold + pattern.exhale + pattern.holdOut
    }

    var currentPhaseText: String {
        switch currentPhase {
        case .inhale:
            return "Inspire"
        case .hold:
            return "Retiens"
        case .exhale:
            return "Expire"
        case .holdOut:
            return "Retiens"
        }
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()
                    .frame(height: 72) // Space for close button

                // Exercise Title
                VStack(spacing: 8) {
                    Text(exerciseType.displayName)
                        .font(.custom("Poppins-SemiBold", size: 24))
                        .foregroundColor(.white)

                    Text(exerciseType.description)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)

                Spacer()

                // Orb respiratoire avec cercle animé
                VStack(spacing: 30) {
                    BreathingCircle(
                        planet: planetSettings.selectedPlanet,
                        size: ballYPosition == 80 ? 160 : 260,
                        haloOpacity: haloOpacity
                    )
                    .onTapGesture {
                        handlePlanetTap()
                    }

                    // Phase text
                    Text(currentPhaseText)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 450)

                Spacer()

                // Timer and Progress
                VStack(spacing: 16) {
                    Text(formatTime(timeRemaining))
                        .font(.custom("Poppins-Medium", size: 48))
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Text("Cycle \(cycleCount + 1)")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()
            }

            // Close button - fixed position overlay
            VStack {
                HStack {
                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()
            }

            // Easter egg overlay
            if showEasterEgg {
                EasterEggOverlay(
                    message: easterEggMessage,
                    stars: easterEggStars,
                    onDismiss: {
                        withAnimation {
                            showEasterEgg = false
                            easterEggStars = []
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }

            // Completion overlay
            if showCompletion {
                CompletionOverlay(
                    xpEarned: exerciseType.xpReward,
                    onDismiss: {
                        dismiss()
                    }
                )
                .transition(.opacity)
            }

            // Confetti
            if showConfetti {
                LottieView(
                    filename: "confetti",
                    loopMode: .playOnce
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            viewModel.startExercise(exerciseType)
            startBreathingAnimation()
            // Animation du halo avec opacité
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                haloOpacity = 0.5
            }
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                completeExercise()
            }
        }
    }

    // MARK: - Breathing Animation

    private func startBreathingAnimation() {
        animateBreathingCycle()
    }

    private func animateBreathingCycle() {
        let pattern = breathingPattern

        // Inhale - la planète grandit
        currentPhase = .inhale
        withAnimation(.easeInOut(duration: pattern.inhale)) {
            ballYPosition = -80 // Grande
            isBreathingIn = true
        }

        // Hold (if applicable) - la planète reste grande
        if pattern.hold > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + pattern.inhale) {
                currentPhase = .hold
                // La planète reste grande pendant le hold
            }
        }

        // Exhale - la planète rétrécit
        DispatchQueue.main.asyncAfter(deadline: .now() + pattern.inhale + pattern.hold) {
            currentPhase = .exhale
            withAnimation(.easeInOut(duration: pattern.exhale)) {
                ballYPosition = 80 // Petite
                isBreathingIn = false
            }
        }

        // Hold out (if applicable) - la planète reste petite
        if pattern.holdOut > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + pattern.inhale + pattern.hold + pattern.exhale) {
                currentPhase = .holdOut
                // La planète reste petite pendant le hold
            }
        }

        // Next cycle
        let nextCycleDelay = pattern.inhale + pattern.hold + pattern.exhale + pattern.holdOut
        DispatchQueue.main.asyncAfter(deadline: .now() + nextCycleDelay) {
            if timeRemaining > 0 {
                cycleCount += 1
                animateBreathingCycle()
            }
        }
    }

    // MARK: - Easter Egg

    private func handlePlanetTap() {
        HapticManager.light()
        planetTapCount += 1

        // Reset counter after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if planetTapCount < 3 {
                planetTapCount = 0
            }
        }

        // Trigger easter egg after 3 taps
        if planetTapCount >= 3 {
            triggerEasterEgg()
            planetTapCount = 0
        }
    }

    private func triggerEasterEgg() {
        HapticManager.success()

        let messages = [
            "Tu es une étoile qui brille 🌟",
            "Continue, tu es sur la bonne voie ✨",
            "Chaque respiration te rapproche de la paix 🌙",
            "Tu es plus fort que tu ne le penses 💪",
            "L'univers t'envoie de bonnes ondes 🌌",
            "Tu es un voyageur cosmique du bien-être 🚀",
            "Ta sérénité rayonne comme une étoile 💫"
        ]

        easterEggMessage = messages.randomElement() ?? "Tu es incroyable ✨"

        // Create shooting stars
        easterEggStars = (0..<15).map { _ in
            EasterEggStar(
                startX: CGFloat.random(in: -100...UIScreen.main.bounds.width + 100),
                startY: CGFloat.random(in: -100...0),
                endX: CGFloat.random(in: -100...UIScreen.main.bounds.width + 100),
                endY: UIScreen.main.bounds.height + 100,
                delay: Double.random(in: 0...1.5)
            )
        }

        withAnimation(.easeInOut(duration: 0.5)) {
            showEasterEgg = true
        }

        // Auto-dismiss after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                showEasterEgg = false
                easterEggStars = []
            }
        }
    }

    // MARK: - Completion

    private func completeExercise() {
        Task {
            await viewModel.completeExercise()
            HapticManager.success()

            withAnimation {
                showConfetti = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showCompletion = true
                }
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Completion Overlay

struct CompletionOverlay: View {
    let xpEarned: Int
    let onDismiss: () -> Void

    @State private var showFeedback = false
    @State private var showCelebration = true

    var body: some View {
        ZStack {
            if showCelebration {
                celebrationView
                    .transition(.opacity)
            }

            if showFeedback {
                ExerciseFeedbackView(xpEarned: xpEarned) { feedback in
                    // Feedback handling will be done by parent view
                    onDismiss()
                }
                .transition(.opacity)
            }
        }
    }

    private var celebrationView: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color.appTheme)

                // Message
                Text("Tu as repris le contrôle")
                    .font(.custom("Poppins-SemiBold", size: 28))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("🧘‍♂️")
                    .font(.system(size: 60))

                // XP earned
                HStack(spacing: 8) {
                    Text("+\(xpEarned)")
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundColor(Color.appTheme)

                    Text("XP")
                        .font(.custom("Poppins-Medium", size: 20))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )

                // Feedback button
                Button(action: {
                    HapticManager.light()
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showCelebration = false
                        showFeedback = true
                    }
                }) {
                    Text("Donner mon avis")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.appTheme,
                                    Color.appThemeSecondary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)

                // Skip button
                Button(action: {
                    HapticManager.light()
                    onDismiss()
                }) {
                    Text("Passer")
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(40)
        }
    }
}

// MARK: - Exercise Feedback View

struct ExerciseFeedbackViewWrapper: View {
    let exerciseType: AntiStressExerciseType
    let xpEarned: Int
    let onDismiss: () -> Void

    var body: some View {
        ExerciseFeedbackView(xpEarned: xpEarned) { feedback in
            if let feedback = feedback {
                saveFeedback(feedback)
            }
            onDismiss()
        }
    }

    private func saveFeedback(_ feedback: ExerciseFeedback) {
        // Save to Firebase
        Task {
            guard let userId = FirebaseManager.shared.currentUser?.uid else {
                print("No user logged in")
                return
            }

            // Create completed task
            let completedTask = CompletedTask(
                taskId: UUID().uuidString,
                exerciseId: exerciseType.rawValue,
                routineId: FirebaseManager.shared.currentUser?.selectedRoutineId ?? "manual",
                weekNumber: FirebaseManager.shared.currentUser?.currentWeek ?? 0,
                dayNumber: FirebaseManager.shared.currentUser?.currentDay ?? 0,
                moment: getMomentOfDay(),
                completedAt: Timestamp(),
                durationActualSeconds: exerciseType.duration,
                xpEarned: 15,
                feedbackMood: feedback.mood?.rawValue,
                feedbackNote: feedback.note,
                wasManual: true,
                deviceInfo: DeviceInfo(platform: "iOS", version: UIDevice.current.systemVersion)
            )

            do {
                try await FirebaseManager.shared.saveCompletedTask(uid: userId, task: completedTask)

                // Save feedback
                let feedbackModel = FeedbackModel(
                    type: "exercise_completion",
                    exerciseId: exerciseType.rawValue,
                    mood: feedback.mood?.rawValue ?? "neutral",
                    rating: nil,
                    note: feedback.note,
                    timestamp: Timestamp(),
                    context: FeedbackContext(
                        routineId: FirebaseManager.shared.currentUser?.selectedRoutineId,
                        week: FirebaseManager.shared.currentUser?.currentWeek,
                        day: FirebaseManager.shared.currentUser?.currentDay
                    )
                )

                try await FirebaseManager.shared.saveFeedback(uid: userId, feedback: feedbackModel)

                print("✅ Feedback saved to Firebase successfully")
            } catch {
                print("❌ Error saving feedback to Firebase: \(error.localizedDescription)")
            }
        }
    }

    private func getMomentOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "morning"
        } else if hour < 18 {
            return "afternoon"
        } else {
            return "evening"
        }
    }
}

// MARK: - Exercise Feedback View

struct ExerciseFeedbackView: View {
    @StateObject private var planetSettings = PlanetSettings.shared

    let xpEarned: Int
    let onComplete: (ExerciseFeedback?) -> Void

    @State private var selectedMood: FeedbackMood?
    @State private var note: String = ""
    @State private var showThankYou = false
    @State private var scaleEffect: CGFloat = 0.8

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    onComplete(nil)
                }

            VStack(spacing: 0) {
                if showThankYou {
                    thankYouView
                } else {
                    feedbackView
                }
            }
            .scaleEffect(scaleEffect)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scaleEffect = 1.0
            }
        }
    }

    private var feedbackView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)

                    Text("+\(xpEarned) XP")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.1)))

                Text("Comment te sens-tu ?")
                    .font(.custom("Poppins-SemiBold", size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Ton ressenti nous aide à améliorer l'app")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)

            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    ForEach(FeedbackMood.allCases, id: \.self) { mood in
                        moodButton(mood)
                    }
                }
                .padding(.horizontal, 8)

                if let mood = selectedMood {
                    Text(mood.description)
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(planetSettings.selectedPlanet.haloColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 20)

            VStack(alignment: .leading, spacing: 12) {
                Text("Une remarque ? (optionnel)")
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.8))

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)

                    if note.isEmpty {
                        Text("Partage ton expérience...")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }

                    TextEditor(text: $note)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(height: 80)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .frame(height: 80)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                Button(action: submitFeedback) {
                    HStack {
                        Text(selectedMood != nil ? "Envoyer" : "Passer")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)

                        if selectedMood != nil {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: selectedMood != nil ? [
                                planetSettings.selectedPlanet.haloColor,
                                planetSettings.selectedPlanet.haloColor.opacity(0.8)
                            ] : [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: 380)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1A1B3A").opacity(0.95),
                            Color(hex: "2A2B5A").opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    planetSettings.selectedPlanet.haloColor.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal, 24)
    }

    private var thankYouView: some View {
        VStack(spacing: 24) {
            LottieView(filename: "confetti", loopMode: .playOnce)
                .frame(width: 200, height: 200)
                .allowsHitTesting(false)

            VStack(spacing: 12) {
                Text("Merci !")
                    .font(.custom("Poppins-Bold", size: 32))
                    .foregroundColor(.white)

                Text("Ton retour nous est précieux")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: 320)
        .padding(.vertical, 60)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1A1B3A").opacity(0.95),
                            Color(hex: "2A2B5A").opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .padding(.horizontal, 24)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    scaleEffect = 0.8
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete(nil)
                }
            }
        }
    }

    private func moodButton(_ mood: FeedbackMood) -> some View {
        Button(action: {
            HapticManager.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedMood = mood
            }
        }) {
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.system(size: selectedMood == mood ? 34 : 30))
                    .scaleEffect(selectedMood == mood ? 1.05 : 1.0)

                if selectedMood == mood {
                    Circle()
                        .fill(planetSettings.selectedPlanet.haloColor)
                        .frame(width: 5, height: 5)
                        .transition(.scale)
                }
            }
            .frame(width: 56, height: 64)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selectedMood == mood ?
                          planetSettings.selectedPlanet.haloColor.opacity(0.2) :
                          Color.white.opacity(0.05)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                selectedMood == mood ?
                                    planetSettings.selectedPlanet.haloColor.opacity(0.5) :
                                    Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func submitFeedback() {
        HapticManager.success()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showThankYou = true
        }
    }
}

enum FeedbackMood: String, CaseIterable, Codable {
    case veryBad, bad, neutral, good, veryGood

    var emoji: String {
        switch self {
        case .veryBad: return "😢"
        case .bad: return "😕"
        case .neutral: return "😐"
        case .good: return "😊"
        case .veryGood: return "😄"
        }
    }

    var description: String {
        switch self {
        case .veryBad: return "Pas efficace du tout"
        case .bad: return "Peu efficace"
        case .neutral: return "Moyennement efficace"
        case .good: return "Efficace"
        case .veryGood: return "Très efficace !"
        }
    }
}

struct ExerciseFeedback: Codable {
    let mood: FeedbackMood?
    let note: String?
    let timestamp: Date
}

// MARK: - Easter Egg Components

struct EasterEggStar: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let delay: Double
}

struct EasterEggOverlay: View {
    let message: String
    let stars: [EasterEggStar]
    let onDismiss: () -> Void

    @State private var animateStars = false
    @State private var showMessage = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Shooting stars
            ForEach(stars) { star in
                EasterEggStarView(star: star, animate: animateStars)
            }

            // Message
            VStack(spacing: 24) {
                Text(message)
                    .font(.custom("Poppins-Bold", size: 32))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .scaleEffect(showMessage ? 1 : 0.5)
                    .opacity(showMessage ? 1 : 0)

                Text("Tape pour continuer")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .opacity(showMessage ? 1 : 0)
            }
        }
        .onAppear {
            HapticManager.success()
            withAnimation(.easeOut(duration: 0.3)) {
                animateStars = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showMessage = true
                }
            }
        }
    }
}

struct EasterEggStarView: View {
    let star: EasterEggStar
    let animate: Bool

    var body: some View {
        LinearGradient(
            colors: [.white, .white.opacity(0)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 80, height: 2)
        .rotationEffect(.degrees(45))
        .position(
            x: animate ? star.endX : star.startX,
            y: animate ? star.endY : star.startY
        )
        .animation(
            .easeIn(duration: 1.5).delay(star.delay),
            value: animate
        )
        .opacity(animate ? 0 : 1)
    }
}

#Preview {
    BreathingExerciseView(
        exerciseType: .guidedBreathing,
        situation: .overwhelmed,
        viewModel: AntiStressViewModel()
    )
}
