//
//  RecoveryDebugView.swift
//  CortiFree
//
//  DEBUG only: test the trial recovery notifications and the recovery paywalls
//  without waiting for the real delays.
//

#if DEBUG
import SwiftUI
import SuperwallKit
import UserNotifications

/// Bell button shown under the onboarding debug "home" button.
struct RecoveryDebugButton: View {
    @State private var isPresented = false

    var body: some View {
        Button {
            HapticManager.medium()
            isPresented = true
        } label: {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(Color.purple.opacity(0.94))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.28), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("DEBUG: Recovery notifications")
        .sheet(isPresented: $isPresented) {
            RecoveryDebugView()
        }
    }
}

struct RecoveryDebugView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var state = RecoveryScheduler.shared.debugState
    @State private var permission = "…"
    @State private var pendingRecovery: [String] = []
    @State private var toast: String?

    private let segments: [RecoverySegment] = [.earlyOnboarding, .planReady, .paywall]

    var body: some View {
        NavigationStack {
            List {
                stateSection
                actionsSection
                paywallSection
                ForEach(segments, id: \.rawValue) { segment in
                    messagesSection(for: segment)
                }
            }
            .navigationTitle("Relance essai")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .overlay(alignment: .bottom) {
                if let toast {
                    Text(toast)
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .task { await refresh() }
        }
    }

    // MARK: Sections

    private var stateSection: some View {
        Section("État") {
            row("Segment", state.segment)
            row("Objectif", RecoveryScheduler.shared.debugGoal ?? "—")
            row("Permission", permission)
            row("Holdout (aucune relance)", state.holdout ? "oui" : "non")
            row("Offres acceptées", state.offersOptIn ? "oui" : "non")
            row("Paywall vu", state.paywallSeenAt.map(format) ?? "—")
            row("Ancre onboarding", state.onboardingAnchor.map(format) ?? "—")
            row("Départs", "\(state.dropOffCount)")
            row("Relances en attente", pendingRecovery.isEmpty ? "aucune" : pendingRecovery.joined(separator: ", "))
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            Button("Simuler un départ (programme toute la séquence)") {
                RecoveryScheduler.shared.appDidEnterBackground()
                done("Séquence programmée")
            }
            Button("Demander l'autorisation discrète") {
                RecoveryScheduler.shared.requestProvisionalAuthorizationIfNeeded()
                done("Demandée (si jamais demandé)")
            }
            Button(state.holdout ? "Sortir du holdout" : "Mettre dans le holdout") {
                RecoveryScheduler.shared.debugSetHoldout(!state.holdout)
                done(state.holdout ? "Hors holdout" : "Dans le holdout")
            }
            Button(state.offersOptIn ? "Refuser les offres" : "Accepter les offres") {
                RecoveryScheduler.shared.offersOptIn.toggle()
                done("Consentement modifié")
            }
            Button("Marquer le paywall comme vu maintenant") {
                RecoveryScheduler.shared.markPaywallSeen()
                done("Paywall vu")
            }
            Button("Envoyer l'état au serveur (OneSignal)") {
                RecoveryScheduler.shared.syncToServer()
                done("Envoyé à Convex")
            }
            Button("Réinitialiser la relance", role: .destructive) {
                RecoveryScheduler.shared.debugReset()
                done("Réinitialisé")
            }
        }
    }

    private var paywallSection: some View {
        Section {
            ForEach([SuperwallPlacement.onboarding, RecoveryPlacement.offer, RecoveryPlacement.lastChance], id: \.self) { placement in
                Button("Ouvrir \(placement)") { present(placement) }
            }
        } header: {
            Text("Paywalls")
        } footer: {
            Text("Ouvre le placement directement, sans la fenêtre de 48 h. Un placement absent du dashboard Superwall ne s'affiche pas.")
        }
    }

    private func messagesSection(for segment: RecoverySegment) -> some View {
        let goal = RecoveryScheduler.shared.debugGoal
        let drops = (1...3).map { RecoveryPlanner.dropOffMessage(for: segment, dropOffCount: $0) }
        let messages = drops + RecoveryPlanner.sequence(for: segment, goal: goal)
        return Section {
            ForEach(Array(messages.enumerated()), id: \.offset) { _, message in
                Button {
                    RecoveryScheduler.shared.debugSend(message, segment: segment)
                    done("\(message.id) dans 5 s : quitte l'app")
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(message.id) · \(timing(message))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("\(message.key).title".localized)
                            .font(.subheadline.weight(.semibold))
                        Text("\(message.key).body".localized)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Segment \(segment.rawValue) — envoyer dans 5 s")
        }
    }

    // MARK: Helpers

    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .font(.footnote)
    }

    private func timing(_ message: RecoveryMessage) -> String {
        var text: String
        switch message.timing {
        case .after(let delay):
            text = delay < 3600 ? "+\(Int(delay / 60)) min" : "+\(Int(delay / 3600)) h"
        case .day(let day, let hour, let minute):
            text = String(format: "J+%d %02dh%02d", day, hour, minute)
        }
        if message.isPromotional { text += " · offre" }
        if let product = message.requiredProduct { text += " (\(product))" }
        return text
    }

    private func format(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    private func present(_ placement: String) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            Superwall.shared.register(placement: placement, params: ["source": "debug"])
        }
    }

    private func done(_ message: String) {
        HapticManager.light()
        withAnimation { toast = message }
        Task {
            await refresh()
            try? await Task.sleep(for: .seconds(2))
            withAnimation { toast = nil }
        }
    }

    private func refresh() async {
        state = RecoveryScheduler.shared.debugState
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permission = switch settings.authorizationStatus {
        case .authorized: "autorisée"
        case .provisional: "discrète (provisoire)"
        case .denied: "refusée"
        case .notDetermined: "jamais demandée"
        case .ephemeral: "éphémère"
        @unknown default: "?"
        }
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        pendingRecovery = pending.map(\.identifier)
            .filter { $0.hasPrefix("recovery_") }
            .map { $0.replacingOccurrences(of: "recovery_", with: "") }
            .sorted()
    }
}
#endif
