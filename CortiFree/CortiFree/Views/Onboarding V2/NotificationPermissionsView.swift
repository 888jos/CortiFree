//
//  NotificationPermissionsView.swift
//  CortiFree
//
//  Created by Claude on 11/12/2025.
//  Écran de demande de permissions notifications
//

import SwiftUI
import UserNotifications

struct NotificationPermissionsView: View {
    let onContinue: () -> Void
    @ObservedObject var languageManager = LanguageManager.shared

    @State private var enableStreak: Bool = true
    @State private var enableDailyRitual: Bool = true
    @State private var enableWeeklyReport: Bool = true
    @State private var screenViewTime: Date?
    @State private var isRequestingPermission = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "1a0a2e"),
                    Color(hex: "0f0518")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    OnboardingMascotDialogueView(
                        message: "onboarding_v2.notifications.mascot_message".localized,
                        prominent: false
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 34)
                    .padding(.bottom, 30)

                    // Title
                    Text("onboarding_v2.notifications.stay_motivated".localized)
                    .font(.faroBold(28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "B794F6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 80)
                    .padding(.bottom, 12)

                // Subtitle
                Text("onboarding_v2.notifications.activate_subtitle".localized)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)

                // Notification options
                VStack(spacing: 16) {
                    NotificationToggleCard(
                        title: "onboarding_v2.notifications.daily_routine".localized,
                        description: "onboarding_v2.notifications.daily_routine_desc".localized,
                        isEnabled: $enableStreak
                    )

                    NotificationToggleCard(
                        title: "onboarding_v2.notifications.streak_danger".localized,
                        description: "onboarding_v2.notifications.streak_danger_desc".localized,
                        isEnabled: $enableDailyRitual
                    )

                    NotificationToggleCard(
                        title: "onboarding_v2.notifications.reflection_moment".localized,
                        description: "onboarding_v2.notifications.reflection_moment_desc".localized,
                        isEnabled: $enableWeeklyReport
                    )
                }
                .padding(.horizontal, 24)

                    Spacer(minLength: 100)

                    // Continue button
                    Button(action: {
                        guard !isRequestingPermission else { return }
                    #if DEBUG
                    print("🔔 NotificationPermissionsView: Bouton Suivant cliqué - Navigation vers HabitsProgress")
                    #endif
                    HapticManager.medium()
                    isRequestingPermission = true

                    // Track permission request
                    MixpanelManager.shared.trackOnboardingNotificationPermissionRequested(
                        streakEnabled: enableStreak,
                        dailyRitualEnabled: enableDailyRitual,
                        weeklyReportEnabled: enableWeeklyReport
                    )

                    handleContinue()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("onboarding_v2.notifications.next".localized)
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "B794F6"), Color(hex: "D4B4FF")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .disabled(isRequestingPermission)
            }
        }
        .onAppear {
            screenViewTime = Date()
            MixpanelManager.shared.trackOnboardingNotificationPermissionViewed()
        }
    }

    private func handleContinue() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                NotificationService.shared.requestNotificationPermission { granted in
                    UserDefaults.standard.set(granted, forKey: "notificationsEnabled")
                    MixpanelManager.shared.trackOnboardingNotificationPermissionsGranted(granted: granted)
                    DispatchQueue.main.async {
                        isRequestingPermission = false
                        onContinue()
                    }
                }
            case .denied:
                UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                MixpanelManager.shared.trackOnboardingNotificationPermissionsGranted(granted: false)
                DispatchQueue.main.async {
                    isRequestingPermission = false
                    // Do not bounce the user to Settings from onboarding. The app may
                    // offer a contextual reminder later in the main experience.
                    onContinue()
                }
            case .authorized, .provisional, .ephemeral:
                UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                MixpanelManager.shared.trackOnboardingNotificationPermissionsGranted(granted: true)
                DispatchQueue.main.async {
                    isRequestingPermission = false
                    onContinue()
                }
            @unknown default:
                DispatchQueue.main.async {
                    isRequestingPermission = false
                    onContinue()
                }
            }
        }
    }
}

// MARK: - Notification Toggle Card

struct NotificationToggleCard: View {
    let title: String
    let description: String
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)

                Text(description)
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(Color(hex: "B794F6"))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }
}

#Preview {
    NotificationPermissionsView(onContinue: {})
}
