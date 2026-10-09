//
//  ScreenTimePauseSetupView.swift
//  CortiFree
//
//  « Breathe before TikTok » with Screen Time: allow access, pick the apps, done. No Shortcuts
//  automation. Shown instead of BreathePauseSetupView once ScreenTimeShield.isEnabled; the
//  Shortcuts guide stays one tap away for people who refuse Screen Time access.
//

import FamilyControls
import SwiftUI
import UserNotifications

struct ScreenTimePauseSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authorization = AuthorizationCenter.shared
    @State private var selection = ScreenTimeShield.selection
    @State private var showPicker = false
    @State private var showShortcutsGuide = false
    @State private var isActive = ScreenTimeShield.hasSelection
    @State private var error: String?

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.85).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .cfGlassCircle(interactive: false)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(t("common.close"))
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Image("cortifree_assistant_avatar").resizable().scaledToFit().frame(width: 64, height: 64)
                        Text(t("calm.pause.setup.title"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(t(isActive ? "calm.pause.shield.active" : "calm.pause.shield.subtitle"))
                            .font(.system(size: 15))
                            .foregroundStyle(AudioPalette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        if let error {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Text(t("calm.pause.setup.note"))
                            .font(.system(size: 12))
                            .foregroundStyle(AudioPalette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                }

                VStack(spacing: 10) {
                    Button {
                        HapticManager.light()
                        Task { await chooseApps() }
                    } label: {
                        Label(t(isActive ? "calm.pause.shield.change_apps" : "calm.pause.shield.choose_apps"), systemImage: "hand.raised.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AudioPalette.backgroundDeep)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(AudioPalette.accent, in: Capsule())
                    }
                    .buttonStyle(PressableCardStyle())

                    if isActive {
                        Button(t("calm.pause.shield.turn_off")) { turnOff() }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(minHeight: 40)
                    } else {
                        Button(t("calm.pause.shield.use_shortcuts")) { showShortcutsGuide = true }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(minHeight: 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .preferredColorScheme(.dark)
        .familyActivityPicker(isPresented: $showPicker, selection: $selection)
        .onChange(of: showPicker) { _, presented in
            if !presented { save() }
        }
        .sheet(isPresented: $showShortcutsGuide) { BreathePauseSetupView().presentationDetents([.large]) }
    }

    /// Screen Time access (individual: the user's own device, Face ID), notifications (the shield
    /// opens CortiFree through one), then the app picker.
    private func chooseApps() async {
        error = nil
        if authorization.authorizationStatus != .approved {
            do {
                try await authorization.requestAuthorization(for: .individual)
            } catch {
                self.error = t("calm.pause.shield.denied")
                AnalyticsManager.shared.track(event: "breathe_shield_auth_failed", properties: ["error": "\(error)"])
                return
            }
        }
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        showPicker = true
    }

    private func save() {
        ScreenTimeShield.selection = selection
        isActive = ScreenTimeShield.hasSelection
        if isActive { ScreenTimeShield.applyShield() } else { ScreenTimeShield.removeShield() }
        AnalyticsManager.shared.track(event: "breathe_shield_saved", properties: [
            "apps": selection.applicationTokens.count,
            "categories": selection.categoryTokens.count
        ])
    }

    private func turnOff() {
        selection = FamilyActivitySelection()
        save()
    }
}
