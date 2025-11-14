//
//  ConfettiModifier.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Updated to use Lottie animation
//

import SwiftUI
import Lottie

struct ConfettiModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if isActive {
                        LottieView(
                            filename: "confetti",
                            loopMode: .playOnce
                        )
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                    }
                }
            )
            .onChange(of: isActive) { _, active in
                if active {
                    // Trigger haptic
                    HapticManager.success()
                }
            }
    }
}

extension View {
    func confetti(isActive: Bool) -> some View {
        modifier(ConfettiModifier(isActive: isActive))
    }
}
