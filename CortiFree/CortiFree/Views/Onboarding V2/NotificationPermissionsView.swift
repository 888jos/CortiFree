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
    @State private var reminderTime = NotificationService.shared.morningReminderDate
    @State private var acceptsOffers = true

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingMascotDialogueView(
                    message: "onboarding_v2.notifications.mascot_message_trial".localized,
                    prominent: false
                )
                .padding(.horizontal, 24)
                .padding(.top, 34)

                Spacer()

                permissionCard
                    .padding(.horizontal, 24)

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

                // Consent for promotional notifications (App Store guideline 4.5.4).
                Toggle(isOn: $acceptsOffers) {
                    Text("onboarding_v2.notifications.offers_consent".localized)
                        .font(.poppinsRegular(12))
                        .foregroundStyle(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .toggleStyle(.switch)
                .tint(Color(hex: "B794F6"))
                .padding(.horizontal, 28)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            AnalyticsManager.shared.trackOnboardingNotificationPermissionViewed()
        }
    }

    /// A CortiFree reminder as it will appear on the lock screen (not a copy of the
    /// system permission alert), followed by the time picker.
    private var permissionCard: some View {
        VStack(spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 38, height: 38)
                    .background(Color(hex: "1A1A4E"))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(verbatim: "CortiFree")
                            .font(.poppinsSemiBold(14))
                        Spacer()
                        Text(reminderTime, style: .time)
                            .font(.poppinsRegular(12))
                            .opacity(0.6)
                    }
                    Text("inline.notificationservice.00".localized)
                        .font(.poppinsSemiBold(14))
                    Text("inline.notificationservice.01".localized)
                        .font(.poppinsRegular(13))
                        .opacity(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(.white)
            }
            .padding(14)
            .glassCard(cornerRadius: 22)

            HStack(spacing: 10) {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(Color(hex: "B794F6"))
                Text("onboarding_v2.notifications.trial_reminder".localized)
                    .font(.poppinsMedium(14))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 16)

            HStack {
                Text("onboarding_v2.notifications.time_label".localized)
                    .font(.poppinsMedium(15))
                    .foregroundStyle(.white)
                Spacer()
                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .colorScheme(.dark)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassCard(cornerRadius: 16)
        }
    }

    private func skipPermission() {
        RecoveryScheduler.shared.offersOptIn = acceptsOffers
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
            case .notDetermined, .provisional:
                // Provisional (quiet) authorization is upgraded to real alerts by the system prompt.
                NotificationService.shared.requestNotificationPermission { granted in
                    finishPermissionRequest(granted: granted)
                }
            case .authorized, .ephemeral:
                finishPermissionRequest(granted: true)
            default:
                finishPermissionRequest(granted: false)
            }
        }
    }

    private func finishPermissionRequest(granted: Bool) {
        DispatchQueue.main.async { RecoveryScheduler.shared.offersOptIn = acceptsOffers }
        UserDefaults.standard.set(granted, forKey: "notificationsEnabled")
        NotificationService.shared.setMorningReminder(reminderTime)
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
