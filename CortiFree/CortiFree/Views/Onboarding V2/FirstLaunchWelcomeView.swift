//
//  FirstLaunchWelcomeView.swift
//  CortiFree
//
//  First-launch welcome screen
//  Mascot introduction + CTA
//

import SwiftUI

struct FirstLaunchWelcomeView: View {
    let onContinue: () -> Void
    var onSignIn: (() -> Void)? = nil

    @State private var screenViewTime: Date?

    @State private var hasContinued = false
    /// Milo "speaks": the three lines are typed one after the other. The full text is always
    /// laid out (untyped characters stay transparent), so nothing reflows while it types.
    @State private var typedCount = 0
    @State private var isTalking = false
    @State private var showsActions = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var lines: [String] {
        ["first_launch.mascot_greeting", "first_launch.mascot_role", "first_launch.mascot_plan"].map(\.localized)
    }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()

            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 48)

                LottieView(filename: "sloth_intro.json", loopMode: .loop)
                    .frame(width: 190, height: 190)
                    // A small bob while Milo is talking.
                    .scaleEffect(isTalking ? 1.04 : 1, anchor: .bottom)
                    .animation(
                        isTalking ? .easeInOut(duration: 0.22).repeatForever(autoreverses: true) : .easeOut(duration: 0.2),
                        value: isTalking
                    )

                ZStack {
                    VStack(spacing: 12) {
                        Text(typed(line: 0, color: .white))
                            .font(.faroBold(25))

                        Text(typed(line: 1, color: .white.opacity(0.86)))
                            .font(.poppinsRegular(16))
                            .multilineTextAlignment(.center)
                            .balancedLines()
                            .lineSpacing(3)

                        Text(typed(line: 2, color: .white.opacity(0.68)))
                            .font(.poppinsRegular(15))
                            .multilineTextAlignment(.center)
                            .balancedLines()
                            .lineSpacing(3)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(lines.joined(separator: " "))
                    // Tap to show everything at once.
                    .contentShape(Rectangle())
                    .onTapGesture(perform: revealAll)

                    IntroSparkle(color: Color(hex: "FFB7E8"), size: 18, delay: 0.0)
                        .offset(x: -150, y: -42)
                    IntroSparkle(color: Color(hex: "D4B4FF"), size: 12, delay: 0.35)
                        .offset(x: 151, y: -28)
                    IntroSparkle(color: Color(hex: "FF8EDB"), size: 10, delay: 0.7)
                        .offset(x: 137, y: 48)
                    IntroSparkle(color: Color(hex: "D4B4FF"), size: 14, delay: 1.05)
                        .offset(x: -142, y: 55)
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 10) {
                    Button(action: continueToQuiz) {
                        Text("first_launch.cta_button".localized)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.glassPrimary)
                    .padding(.horizontal, 34)

                    Text("first_launch.cta_sub".localized)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.35))

                    if let onSignIn {
                        Button {
                            HapticManager.light()
                            onSignIn()
                        } label: {
                            Text("first_launch.have_account".localized)
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .underline()
                                .frame(minHeight: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 32)
                .opacity(showsActions ? 1 : 0)
                .offset(y: showsActions ? 0 : 12)
                .allowsHitTesting(showsActions)
            }
        }
        .onAppear {
            screenViewTime = Date()
            AnalyticsManager.shared.trackOnboardingWelcomeViewed()
        }
        .task { await typeLines() }
    }

    // MARK: - Milo typing

    /// Line `index` with only the characters typed so far visible.
    private func typed(line index: Int, color: Color) -> AttributedString {
        let text = lines[index]
        let before = lines.prefix(index).reduce(0) { $0 + $1.count }
        let visible = min(max(typedCount - before, 0), text.count)
        var shown = AttributedString(String(text.prefix(visible)))
        shown.foregroundColor = color
        var hidden = AttributedString(String(text.dropFirst(visible)))
        hidden.foregroundColor = color.opacity(0)
        return shown + hidden
    }

    private var totalCount: Int { lines.reduce(0) { $0 + $1.count } }

    private func typeLines() async {
        guard !reduceMotion else { return revealAll() }
        try? await Task.sleep(nanoseconds: 400_000_000)
        isTalking = true
        for (index, line) in lines.enumerated() {
            for _ in line {
                guard !Task.isCancelled, typedCount < totalCount else { return }
                typedCount += 1
                if typedCount % 12 == 0 { HapticManager.light() }
                try? await Task.sleep(nanoseconds: 28_000_000)
            }
            // A breath between sentences, like someone talking.
            if index < lines.count - 1 {
                isTalking = false
                try? await Task.sleep(nanoseconds: 380_000_000)
                isTalking = true
            }
        }
        revealAll()
    }

    private func revealAll() {
        typedCount = totalCount
        isTalking = false
        guard !showsActions else { return }
        withAnimation(.easeOut(duration: 0.35).delay(reduceMotion ? 0 : 0.2)) {
            showsActions = true
        }
    }

    private func continueToQuiz() {
        guard !hasContinued else { return }
        hasContinued = true

        let timeSpent = screenViewTime.map { Date().timeIntervalSince($0) } ?? 0
        HapticManager.medium()

        finishWelcome(timeSpent: timeSpent)
    }

    private func finishWelcome(timeSpent: TimeInterval) {
        onContinue()
        Task { @MainActor in
            await Task.yield()
            AnalyticsManager.shared.trackOnboardingWelcomeContinue(timeSpent: timeSpent)
        }
    }

}

private struct IntroSparkle: View {
    let color: Color
    let size: CGFloat
    let delay: Double

    @State private var isShining = false

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.75), radius: 8)
            .scaleEffect(isShining ? 1.18 : 0.62)
            .opacity(isShining ? 1.0 : 0.35)
            .animation(
                .easeInOut(duration: 1.35)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isShining
            )
            .onAppear { isShining = true }
    }
}

#Preview {
    FirstLaunchWelcomeView(onContinue: {})
}
