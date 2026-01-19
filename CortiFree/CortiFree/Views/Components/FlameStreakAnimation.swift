import SwiftUI
import Lottie

struct FlameStreakAnimation: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @Binding var isShowing: Bool

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Lottie Flame Animation
                LottieView(filename: "Flame - Streak", loopMode: .playOnce)
                    .frame(width: 200, height: 290)
                    .scaleEffect(scale)

                // Streak text
                VStack(spacing: 8) {
                    Text("Streak +1!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Première tâche du jour 🔥")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }

            // Auto-dismiss after animation duration (~2.5 seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isShowing = false
                }
            }

            // Track analytics
            MixpanelManager.shared.track(
                event: "flame_streak_animation_shown",
                properties: [:]
            )
        }
    }
}

// Preview
#Preview {
    FlameStreakAnimation(isShowing: .constant(true))
}
