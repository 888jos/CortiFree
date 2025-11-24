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
    let userName: String
    let onStartQuiz: () -> Void

    @State private var displayedText: String = ""
    @State private var currentCharacterIndex: Int = 0
    @State private var player: AVPlayer?
    @State private var showBadges: Bool = false
    @State private var showButton: Bool = false
    @State private var screenViewTime: Date?

    private let fullText: String

    init(userName: String, onStartQuiz: @escaping () -> Void) {
        self.userName = userName
        self.onStartQuiz = onStartQuiz
        self.fullText = "\(userName) ce n'est pas grave. Tu n'es pas seul(e).\n\nDes milliers de personnes comme toi ont déjà retrouvé leur sérénité avec CortiFree.\n\nMaintenant, on va procéder à un quiz rapide pour mieux comprendre ta situation et personnaliser ton parcours."
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

            VStack(spacing: 0) {
                // Animated text at top (centered)
                VStack(spacing: 32) {
                    Text(displayedText)
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .frame(minHeight: 200, alignment: .top)
                        .padding(.horizontal, 40)

                    // Social proof badges (appear after text completes)
                    if showBadges {
                        HStack(spacing: 16) {
                            Image("welcome_5_stars")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 50)
                                .clipped()
                                .transition(.move(edge: .leading).combined(with: .opacity))

                            Image("welcome_cortifree_app")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 50)
                                .clipped()
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                }
                .padding(.top, 80)

                Spacer()

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
                                Text("Commencer le quiz")
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
                        Text("Prends 2 minutes")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            // Track screen view
            screenViewTime = Date()
            MixpanelManager.shared.trackOnboardingReassuranceViewed(userName: userName)

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
            // Text animation complete, show badges after delay (reduced by 50%)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showBadges = true
                }

                // Show button after badges appear (reduced by 50%)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showButton = true
                    }
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

        // Continue animation with slight delay (reduced by 80% from original)
        let delay: Double = fullText[index].isWhitespace ? 0.002 : 0.01
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
    ReassuranceView(userName: "Sophie", onStartQuiz: {})
}
