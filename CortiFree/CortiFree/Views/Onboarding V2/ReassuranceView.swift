//
//  ReassuranceView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Reassurance screen with video background and animated text
//

import SwiftUI
import AVKit

struct ReassuranceView: View {
    let overallData: OverallQuizData?
    let onStartQuiz: () -> Void

    private let textSpeedMultiplier = 1.875

    @ObservedObject var languageManager = LanguageManager.shared
    @State private var displayedText: String = ""
    @State private var currentCharacterIndex: Int = 0
    @State private var player: AVPlayer?
    @State private var showButton: Bool = false
    @State private var screenViewTime: Date?

    private var fullText: String {
        let message1: String
        switch overallData?.genderCode {
        case "male":
            message1 = "onboarding_v2.reassurance.message_part1_male".localized
        case "female":
            message1 = "onboarding_v2.reassurance.message_part1_female".localized
        default:
            message1 = "onboarding_v2.reassurance.message_part1_neutral".localized
        }
        let message2 = personalizedMessage
        let message3 = "onboarding_v2.reassurance.message_part3".localized
        let message4 = "onboarding_v2.reassurance.message_part4".localized
        return "\(message1)\n\n\(message2)\n\n\(message3)\n\n\(message4)"
    }

    private var personalizedMessage: String {
        guard let data = overallData else {
            return "onboarding_v2.reassurance.message_part2".localized
        }

        let reason = data.reasonCodes
            .map { "onboarding_v2.reassurance.reason_\($0)".localized }
            .joined(separator: ", ")
        let age = "onboarding_v2.reassurance.age_\(data.ageCode)".localized
        let duration = "onboarding_v2.reassurance.duration_\(data.durationCode)".localized

        return String(
            format: "onboarding_v2.reassurance.personalized".localized,
            reason,
            age,
            duration
        )
    }

    init(overallData: OverallQuizData? = nil, onStartQuiz: @escaping () -> Void) {
        self.overallData = overallData
        self.onStartQuiz = onStartQuiz
    }

    var body: some View {
        ZStack {
            // Video background
            if let player = player {
                VideoPlayerBackground(player: player)
                    .ignoresSafeArea()
            } else {
                // Fallback to galaxy background
                GalaxyBackgroundView()
                    .ignoresSafeArea()
            }

            // Dark overlay for readability
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    LottieView(filename: "sloth_meditate.json", loopMode: .loop)
                .frame(width: 156, height: 156)
                        .padding(.bottom, 8)

                    // Animated text at top (centered)
                    VStack(spacing: 32) {
                    Text(displayedText)
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .frame(minHeight: 200, alignment: .top)
                        .padding(.horizontal, 40)

                }
                // Keep the copy visible after the larger mascot artwork.
                .padding(.top, 20)

                    Spacer(minLength: 48)

                    // Bottom button section (appear after badges)
                    if showButton {
                    VStack(spacing: 12) {
                        Button(action: {
                            HapticManager.medium()

                            // Track button click with time spent
                            if let startTime = screenViewTime {
                                let timeSpent = Date().timeIntervalSince(startTime)
                                MixpanelManager.shared.trackOnboardingReassuranceContinue(timeSpent: timeSpent)
                            }

                            onStartQuiz()
                        }) {
                            HStack(spacing: 12) {
                                Text("onboarding_v2.reassurance.start_quiz".localized)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                    .foregroundColor(Color(hex: "1A1A4E"))

                                // White arrow in dark circle
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "1A1A4E"))
                                        .frame(width: 32, height: 32)

                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.leading, 24)
                            .padding(.trailing, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                        }

                        // Time estimate (centered below button)
                        Text("onboarding_v2.reassurance.time_estimate".localized)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .onAppear {
            // Track screen view
            screenViewTime = Date()
            MixpanelManager.shared.trackOnboardingReassuranceViewed(userName: "")

            setupVideo()
            startTextAnimation()
        }
    }

    // MARK: - Setup Video

    private func setupVideo() {
        // TODO: Replace "reassurance_video" with actual video name
        if let videoURL = Bundle.main.url(forResource: "reassurance_video", withExtension: "mp4") {
            player = AVPlayer(url: videoURL)

            // Loop video
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem,
                queue: .main
            ) { _ in
                player?.seek(to: .zero)
                player?.play()
            }
        }
    }

    // MARK: - Text Animation

    private func startTextAnimation() {
        // Start animation after short delay (reduced by 50%)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            animateNextCharacter()
        }
    }

    private func animateNextCharacter() {
        guard currentCharacterIndex < fullText.count else {
            // Text animation complete, show button after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showButton = true
                }
            }
            return
        }

        let index = fullText.index(fullText.startIndex, offsetBy: currentCharacterIndex)
        displayedText.append(fullText[index])
        currentCharacterIndex += 1

        // Haptic feedback only every 10 characters to avoid rate-limit (32hz)
        if currentCharacterIndex % 10 == 0 {
            HapticManager.light()
        }

        // Reveal the text 1.25x faster than the previous timing.
        let baseDelay: Double = fullText[index].isWhitespace ? 0.0096 : 0.048
        let delay = baseDelay / textSpeedMultiplier
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            animateNextCharacter()
        }
    }
}

// MARK: - Video Player Background

struct VideoPlayerBackground: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(playerLayer)
        context.coordinator.playerLayer = playerLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.playerLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var playerLayer: AVPlayerLayer?
    }
}

#Preview {
    ReassuranceView(onStartQuiz: {})
}
