//
//  NotificationPermissionsView.swift
//  CortiFree
//

import SwiftUI
import UserNotifications

struct NotificationPermissionsView: View {
    let onContinue: () -> Void
    @ObservedObject var languageManager = LanguageManager.shared
    @State private var isRequestingPermission = false

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingMascotDialogueView(
                    message: "onboarding_v2.notifications.mascot_message".localized,
                    prominent: false
                )
                .padding(.horizontal, 24)
                .padding(.top, 34)

                Spacer()

                permissionCard
                    .padding(.horizontal, 42)

                Image(systemName: "arrow.down")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color(hex: "B794F6"))
                    .padding(.top, 24)

                Spacer()

                Button(action: requestPermission) {
                    Text("onboarding_v2.notifications.allow".localized)
                        .font(.poppinsSemiBold(17))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(.glassPrimary)
                .disabled(isRequestingPermission)
                .padding(.horizontal, 24)

                Button("onboarding_v2.notifications.not_now".localized, action: skipPermission)
                    .font(.poppinsMedium(14))
                    .foregroundStyle(.white.opacity(0.62))
                    .buttonStyle(.plain)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
            }
        }
        .onAppear {
            AnalyticsManager.shared.trackOnboardingNotificationPermissionViewed()
        }
    }

    private var permissionCard: some View {
        VStack(spacing: 0) {
            Image(systemName: "app.badge.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color(hex: "8B5CF6"))
                .frame(width: 58, height: 58)
                .background(Color(hex: "EDE9FE"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text("onboarding_v2.notifications.preview_title".localized)
                .font(.poppinsSemiBold(16))
                .foregroundStyle(Color(hex: "181829"))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
                .padding(.horizontal, 18)

            Text("onboarding_v2.notifications.preview_body".localized)
                .font(.poppinsRegular(12))
                .foregroundStyle(Color(hex: "555568"))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .padding(.horizontal, 18)

            Divider()
                .padding(.top, 18)

            HStack(spacing: 0) {
                Text("onboarding_v2.notifications.dont_allow".localized)
                    .frame(maxWidth: .infinity)

                Divider()

                Text("onboarding_v2.notifications.allow_short".localized)
                    .foregroundStyle(Color(hex: "8B5CF6"))
                    .frame(maxWidth: .infinity)
            }
            .font(.poppinsMedium(14))
            .foregroundStyle(Color(hex: "77778A"))
            .frame(height: 48)
        }
        .padding(.top, 20)
        .background(Color.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: "B794F6").opacity(0.45), lineWidth: 2)
        )
    }

    private func skipPermission() {
        AnalyticsManager.shared.trackOnboardingNotificationPermissionsGranted(granted: false)
        onContinue()
    }

    private func requestPermission() {
        guard !isRequestingPermission else { return }
        isRequestingPermission = true
        HapticManager.medium()
        AnalyticsManager.shared.trackOnboardingNotificationPermissionRequested(
            streakEnabled: true,
            dailyRitualEnabled: true,
            weeklyReportEnabled: true
        )

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                NotificationService.shared.requestNotificationPermission { granted in
                    finishPermissionRequest(granted: granted)
                }
            case .authorized, .provisional, .ephemeral:
                finishPermissionRequest(granted: true)
            default:
                finishPermissionRequest(granted: false)
            }
        }
    }

    private func finishPermissionRequest(granted: Bool) {
        UserDefaults.standard.set(granted, forKey: "notificationsEnabled")
        AnalyticsManager.shared.trackOnboardingNotificationPermissionsGranted(granted: granted)
        DispatchQueue.main.async {
            isRequestingPermission = false
            onContinue()
        }
    }
}

#Preview {
    NotificationPermissionsView(onContinue: {})
}
