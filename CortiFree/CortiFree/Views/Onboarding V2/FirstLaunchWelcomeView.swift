//
//  FirstLaunchWelcomeView.swift
//  CortiFree
//
//  First-launch welcome screen
//  Mascot introduction + CTA
//

import SwiftUI
import UserNotifications

struct FirstLaunchWelcomeView: View {
    let onContinue: () -> Void

    @State private var screenViewTime: Date?

    @State private var hasContinued = false

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 48)

                LottieView(filename: "sloth_intro.json", loopMode: .loop)
                    .frame(width: 190, height: 190)

                Text("first_launch.mascot_intro".localized)
                    .font(.faroBold(28))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 28)
                    .padding(.top, 20)

                Spacer()

                VStack(spacing: 10) {
                    Button(action: continueToQuiz) {
                        Text("first_launch.cta_button".localized)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(Color(hex: "1A1A4E"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 34)

                    Text("first_launch.cta_sub".localized)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(.bottom, 52)
            }
        }
        .onAppear {
            screenViewTime = Date()
            MixpanelManager.shared.trackOnboardingWelcomeViewed()
        }
    }

    private func continueToQuiz() {
        guard !hasContinued else { return }
        hasContinued = true

        let timeSpent = screenViewTime.map { Date().timeIntervalSince($0) } ?? 0
        HapticManager.medium()

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                NotificationService.shared.requestNotificationPermission { granted in
                    UserDefaults.standard.set(granted, forKey: "notificationsEnabled")
                    DispatchQueue.main.async {
                        finishWelcome(timeSpent: timeSpent)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    finishWelcome(timeSpent: timeSpent)
                }
            }
        }
    }

    private func finishWelcome(timeSpent: TimeInterval) {
        onContinue()
        Task { @MainActor in
            await Task.yield()
            MixpanelManager.shared.trackOnboardingWelcomeContinue(timeSpent: timeSpent)
        }
    }

}

#Preview {
    FirstLaunchWelcomeView(onContinue: {})
}
