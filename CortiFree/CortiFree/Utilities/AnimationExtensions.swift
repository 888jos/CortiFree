//
//  AnimationExtensions.swift
//  CortiFree
//
//  Created for premium animations and micro-interactions
//

import SwiftUI

// MARK: - View Extensions for Animations

extension View {

    // MARK: - Cascade Appearance Animation
    /// Animate view appearance with cascade effect
    func cascadeAppear(index: Int, totalCount: Int = 10, baseDelay: Double = 0.05) -> some View {
        self.modifier(CascadeAppearanceModifier(index: index, totalCount: totalCount, baseDelay: baseDelay))
    }

    // MARK: - Bounce Press Effect
    /// Add interactive bounce effect on press
    func bouncePress() -> some View {
        self.modifier(BouncePressModifier())
    }

    // MARK: - Pulse Effect
    /// Add continuous pulse animation
    func pulse(duration: Double = 1.5) -> some View {
        self.modifier(PulseModifier(duration: duration))
    }

    // MARK: - Shake Effect
    /// Shake animation for errors or attention
    func shake(trigger: Bool) -> some View {
        self.modifier(ShakeModifier(shake: trigger))
    }

    // MARK: - Hero Animation
    /// Scale and fade transition
    func heroTransition(isActive: Bool) -> some View {
        self.scaleEffect(isActive ? 1 : 0.9)
            .opacity(isActive ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isActive)
    }

    // MARK: - Glass Morphism
    /// Apply glass morphism effect
    func glassMorphism(cornerRadius: CGFloat = 20) -> some View {
        self.background(
            ZStack {
                Color.white.opacity(0.1)
                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    .opacity(0.8)
            }
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        )
    }
}

// MARK: - Animation Modifiers

struct CascadeAppearanceModifier: ViewModifier {
    let index: Int
    let totalCount: Int
    let baseDelay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .scaleEffect(isVisible ? 1 : 0.9)
            .onAppear {
                withAnimation(
                    .spring(response: 0.6, dampingFraction: 0.8)
                    .delay(Double(index) * baseDelay)
                ) {
                    isVisible = true
                }
            }
            .onDisappear {
                isVisible = false
            }
    }
}

struct BouncePressModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
                // On press start
            } onPressingChanged: { pressing in
                isPressed = pressing
                if pressing {
                    HapticManager.light()
                }
            }
    }
}

struct PulseModifier: ViewModifier {
    let duration: Double
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = 1.05
                    opacity = 0.8
                }
            }
    }
}

struct ShakeModifier: ViewModifier {
    let shake: Bool
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: shake) { oldValue, newValue in
                if newValue {
                    withAnimation(
                        .easeInOut(duration: 0.05)
                        .repeatCount(5, autoreverses: true)
                    ) {
                        offset = 5
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        offset = 0
                    }
                    HapticManager.error()
                }
            }
    }
}

// MARK: - Visual Effect View for Blur

struct VisualEffectView: UIViewRepresentable {
    let effect: UIVisualEffect

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

// MARK: - Premium Transitions

extension AnyTransition {

    static var slideUp: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }

    static var slideDown: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    static var hero: AnyTransition {
        AnyTransition.scale(scale: 0.8)
            .combined(with: .opacity)
            .animation(.spring(response: 0.5, dampingFraction: 0.7))
    }

    static var bounceIn: AnyTransition {
        AnyTransition.scale(scale: 0.3)
            .combined(with: .opacity)
            .animation(.spring(response: 0.5, dampingFraction: 0.6))
    }
}

// MARK: - Animation Presets

struct AnimationPresets {

    static let springSmooth = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let springStiff = Animation.spring(response: 0.3, dampingFraction: 0.9)
    static let springGentle = Animation.spring(response: 0.7, dampingFraction: 0.8)

    static let easeSmooth = Animation.easeInOut(duration: 0.3)
    static let easeSlow = Animation.easeInOut(duration: 0.5)
    static let easeFast = Animation.easeInOut(duration: 0.2)
}

// MARK: - Lottie Success Animation Helper

struct SuccessAnimationView: View {
    @State private var showAnimation = false
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            if showAnimation {
                LottieView(
                    filename: "confetti",
                    loopMode: .playOnce
                )
                .frame(width: 300, height: 300)
                .onAppear {
                    HapticManager.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onComplete()
                    }
                }
            }
        }
        .onAppear {
            showAnimation = true
        }
    }
}

// MARK: - Flip Digit View (for countdown)

struct FlipDigitView: View {
    let digit: Int
    let font: Font
    let foregroundColor: Color

    @State private var previousDigit: Int = 0
    @State private var isFlipping = false

    var body: some View {
        ZStack {
            // Current digit
            Text("\(String(format: "%02d", digit))")
                .font(font)
                .foregroundColor(foregroundColor)
                .rotation3DEffect(
                    .degrees(isFlipping ? 90 : 0),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.5
                )
                .opacity(isFlipping ? 0 : 1)

            // Previous digit (flipping out)
            Text("\(String(format: "%02d", previousDigit))")
                .font(font)
                .foregroundColor(foregroundColor)
                .rotation3DEffect(
                    .degrees(isFlipping ? -90 : 0),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.5
                )
                .opacity(isFlipping ? 1 : 0)
        }
        .onChange(of: digit) { oldValue, newValue in
            guard oldValue != newValue else { return }
            previousDigit = oldValue

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isFlipping = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isFlipping = false
                }
            }
        }
        .onAppear {
            previousDigit = digit
        }
    }
}

// MARK: - Animated Number Text (Counting Animation)

struct AnimatedNumberText: View {
    let value: Int
    let font: Font
    let foregroundColor: Color

    @State private var displayValue: Double = 0

    var body: some View {
        Text("\(Int(displayValue))")
            .font(font)
            .foregroundColor(foregroundColor)
            .onChange(of: value) { oldValue, newValue in
                withAnimation(.easeOut(duration: 0.6)) {
                    displayValue = Double(newValue)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    displayValue = Double(value)
                }
            }
    }
}

// MARK: - Animated Progress Bar

struct AnimatedProgressBar: View {
    let progress: Double
    let height: CGFloat
    let color: Color
    let backgroundColor: Color

    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)
                    .frame(height: height)

                // Progress fill
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * animatedProgress, height: height)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Success Checkmark View

struct SuccessCheckmarkView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Green circle background
            Circle()
                .fill(Color.green)
                .frame(width: 80, height: 80)

            // White checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            // Scale up animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.2
            }

            // Settle to normal size
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = 1.0
                }
            }

            // Fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                }
            }

            // Complete callback
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                onComplete()
            }
        }
    }
}

// MARK: - Skeleton Loader

struct SkeletonLoader: View {
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.white.opacity(0.1))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset * (width + 100))
            )
            .clipped()
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = 2
                }
            }
    }
}

// MARK: - Skeleton Card Loader (for TaskCard-like loading)

struct SkeletonTaskCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title skeleton
            SkeletonLoader(width: 200, height: 20, cornerRadius: 4)

            HStack(spacing: 16) {
                // Duration skeleton
                SkeletonLoader(width: 60, height: 14, cornerRadius: 4)

                // Frequency skeleton
                SkeletonLoader(width: 70, height: 14, cornerRadius: 4)

                // Difficulty skeleton
                SkeletonLoader(width: 80, height: 14, cornerRadius: 4)
            }
        }
        .padding()
        .frame(width: 345, height: 180)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Skeleton Badge Loader

struct SkeletonBadge: View {
    let size: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            // Circle skeleton
            SkeletonLoader(width: size, height: size, cornerRadius: size / 2)

            // Title skeleton
            SkeletonLoader(width: size + 10, height: 12, cornerRadius: 4)

            // Progress skeleton
            SkeletonLoader(width: size - 10, height: 10, cornerRadius: 4)
        }
    }
}