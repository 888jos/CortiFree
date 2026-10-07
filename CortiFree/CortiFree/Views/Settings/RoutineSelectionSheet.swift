//
//  RoutineSelectionSheet.swift
//  CortiFree
//
//  Created on 21/01/2026.
//  Extracted from SettingsView for better modularity
//

import SwiftUI

struct RoutineSelectionSheet: View {
    @Binding var currentObjective: String
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRoutineId: String?
    @State private var showChangeWarning = false
    @State private var pendingPlan: RoutinePlan?

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Spacer()
                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 36, height: 36)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassCircle(interactive: true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                VStack(spacing: 12) {
                    Text(LanguageManager.shared.localizedString(for: "settings.change_routine_title"))
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)

                    Text(LanguageManager.shared.localizedString(for: "settings.select_new_routine"))
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 8)

                // Routines list
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(RoutinePlan.allPlans) { plan in
                            RoutineSelectionRow(
                                plan: plan,
                                isSelected: selectedRoutineId == plan.id
                            ) {
                                HapticManager.medium()

                                // Si c'est déjà la routine actuelle, ne rien faire
                                if selectedRoutineId == plan.id {
                                    return
                                }

                                // Sinon, afficher l'avertissement
                                pendingPlan = plan
                                withAnimation(.spring(response: 0.3)) {
                                    showChangeWarning = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }

                Spacer()
            }

            // Custom Warning Popup
            if showChangeWarning {
                ZStack {
                    // Semi-transparent dark background
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                showChangeWarning = false
                                pendingPlan = nil
                            }
                        }

                    // Warning card
                    VStack(spacing: 0) {
                        // Header with warning icon
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.orange)

                            Text(LanguageManager.shared.localizedString(for: "settings.warning_title"))
                                .font(.custom("Poppins-Bold", size: 22))
                                .foregroundColor(.white)

                            Text(LanguageManager.shared.localizedString(for: "settings.change_routine_warning"))
                                .font(.custom("Poppins-Regular", size: 15))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 32)
                        .padding(.horizontal, 24)

                        // List of what will be reset
                        VStack(alignment: .leading, spacing: 12) {
                            WarningItem(text: LanguageManager.shared.localizedString(for: "settings.current_progress"))
                            WarningItem(text: LanguageManager.shared.localizedString(for: "settings.task_history"))
                            WarningItem(text: LanguageManager.shared.localizedString(for: "settings.routine_stats"))
                            WarningItem(text: LanguageManager.shared.localizedString(for: "settings.start_date_reset"))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        // What will be preserved
                        Text(LanguageManager.shared.localizedString(for: "settings.xp_level_preserved"))
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(Color.appTheme)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)

                        // Buttons
                        VStack(spacing: 12) {
                            // Confirm button (destructive)
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    showChangeWarning = false
                                }
                                if let plan = pendingPlan {
                                    changeRoutine(to: plan)
                                }
                            }) {
                                Text(LanguageManager.shared.localizedString(for: "settings.confirm_change"))
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .buttonStyle(.glassPrimary(tint: Color(hex: "EF5A2F")))

                            // Cancel button
                            Button(action: {
                                HapticManager.light()
                                withAnimation(.spring(response: 0.3)) {
                                    showChangeWarning = false
                                    pendingPlan = nil
                                }
                            }) {
                                Text(LanguageManager.shared.localizedString(for: "common.cancel"))
                                    .font(.custom("Poppins-Medium", size: 16))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .buttonStyle(.glassSecondary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                        .padding(.bottom, 32)
                    }
                    .glassCard(cornerRadius: 28)
                    .padding(.horizontal, 32)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .onAppear {
            // Load current routine ID
            selectedRoutineId = UserDefaults.standard.string(forKey: "selectedRoutineId")
        }
    }

    private func changeRoutine(to plan: RoutinePlan) {
        HapticManager.success()
        selectedRoutineId = plan.id

        // Update routine in UserDefaults
        UserDefaults.standard.set(plan.id, forKey: "selectedRoutineId")
        UserDefaults.standard.set(plan.title, forKey: "selectedRoutineTitle")
        UserDefaults.standard.set(Date(), forKey: "routineStartDate")

        // Reset progress
        UserDefaults.standard.set(1, forKey: "currentWeek")
        UserDefaults.standard.set(1, forKey: "currentDay")

        // Update UI
        currentObjective = plan.title

        // Dismiss after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

// MARK: - Warning Item Component
struct WarningItem: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.orange)
                .padding(.top, 2)

            Text(text)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Routine Selection Row
struct RoutineSelectionRow: View {
    let plan: RoutinePlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon instead of planet
                Image(systemName: getIconForRoutine(plan.title))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color.appTheme)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.appTheme.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Text(getDescriptionForRoutine(plan.title))
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.appTheme)
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 20, tint: isSelected ? Color.appTheme : nil, interactive: true)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.appTheme.opacity(0.6) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func getIconForRoutine(_ title: String) -> String {
        if title.contains("stress") || title.contains("anxiété") {
            return "heart.fill"
        } else if title.contains("sommeil") || title.contains("dormir") {
            return "moon.fill"
        } else if title.contains("énergie") || title.contains("fatigue") {
            return "bolt.fill"
        } else if title.contains("concentration") || title.contains("focus") {
            return "brain"
        } else {
            return "star.fill"
        }
    }

    private func getDescriptionForRoutine(_ title: String) -> String {
        if title.contains("stress") {
            return LanguageManager.shared.localizedString(for: "settings.routine_desc.stress")
        } else if title.contains("sommeil") || title.contains("sleep") {
            return LanguageManager.shared.localizedString(for: "settings.routine_desc.sleep")
        } else if title.contains("énergie") || title.contains("energy") {
            return LanguageManager.shared.localizedString(for: "settings.routine_desc.energy")
        } else {
            return LanguageManager.shared.localizedString(for: "settings.routine_desc.default")
        }
    }
}

#Preview {
    RoutineSelectionSheet(currentObjective: .constant("Réduire le stress"))
}
