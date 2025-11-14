//
//  NotificationPermissionsView.swift
//  CortiFree
//
//  Created by Claude on 11/12/2025.
//  Écran de demande de permissions notifications
//

import SwiftUI

struct NotificationPermissionsView: View {
    let onContinue: () -> Void

    @State private var enableStreak: Bool = true
    @State private var enableDailyRitual: Bool = true
    @State private var enableWeeklyReport: Bool = true

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

            VStack(spacing: 0) {
                // Title
                Text("Reste motivé chaque jour")
                    .font(.custom("Poppins-Bold", size: 28))
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
                Text("Active les notifications pour ne jamais perdre ta routine et suivre tes progrès")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)

                // Notification options
                VStack(spacing: 16) {
                    NotificationToggleCard(
                        title: "Rappel de routine quotidienne",
                        description: "Rappel personnalisable pour tes sessions quotidiennes et maintenir ta constance",
                        isEnabled: $enableStreak
                    )

                    NotificationToggleCard(
                        title: "Série en danger",
                        description: "Préserve ta motivation : on te rappelle si tu risques de perdre ta série du jour",
                        isEnabled: $enableDailyRitual
                    )

                    NotificationToggleCard(
                        title: "Moment de réflexion",
                        description: "Rappel en soirée pour prendre quelques minutes et noter tes pensées du jour",
                        isEnabled: $enableWeeklyReport
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // Continue button
                Button(action: {
                    HapticManager.medium()
                    requestNotificationPermissions()
                    onContinue()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Suivant")
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
        }
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notification permissions granted")
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
