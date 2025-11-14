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