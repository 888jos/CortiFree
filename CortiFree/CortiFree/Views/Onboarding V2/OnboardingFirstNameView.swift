//
//  OnboardingFirstNameView.swift
//  CortiFree
//
//  First onboarding question: Milo asks the first name (skippable: Sign in with Apple gives it
//  later). Once it is entered, the home avatar card is « unlocked » with the name bottom right:
//  the first celebration of the app.
//

import SwiftUI

struct OnboardingFirstNameView: View {
    let onContinue: () -> Void

    private enum Stage { case ask, unlocked }

    @State private var stage: Stage = .ask
    @State private var name = UserPersistence.userFirstName ?? ""
    @State private var cardRevealed = false
    @FocusState private var fieldFocused: Bool

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            switch stage {
            case .ask: askStage.transition(.opacity)
            case .unlocked: unlockedStage.transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: stage)
        .onAppear {
            AnalyticsManager.shared.track(event: "onboarding_first_name_viewed", properties: [:])
        }
    }

    // MARK: Ask

    private var askStage: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                LanguageSelectorButton()
                    .padding(.trailing, 30)
            }
            .frame(height: 20)
            .padding(.top, 12)

            OnboardingMascotDialogueView(message: "onboarding_v2.first_name.question".localized)
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 28)

            TextField("", text: $name, prompt: Text("onboarding_v2.first_name.placeholder".localized)
                .foregroundColor(.white.opacity(0.4)))
                .font(.poppinsSemiBold(20))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .textContentType(.givenName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($fieldFocused)
                .onSubmit(validate)
                .onChange(of: name) { _, value in
                    if value.count > 24 { name = String(value.prefix(24)) }
                }
                .frame(height: 58)
                .glassCard(cornerRadius: 29, tint: nil, interactive: true)
                .padding(.horizontal, 34)

            Spacer()

            VStack(spacing: 10) {
                Button(action: validate) {
                    Text("onboarding_v2.first_name.cta".localized)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .contentShape(Capsule())
                }
                .buttonStyle(.glassPrimary)
                .disabled(trimmedName.isEmpty)
                .opacity(trimmedName.isEmpty ? 0.5 : 1)

                Button("onboarding_v2.first_name.skip".localized, action: skip)
                    .font(.poppinsMedium(14))
                    .foregroundStyle(.white.opacity(0.6))
                    .buttonStyle(.plain)
                    .frame(minHeight: 40)
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 20)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { fieldFocused = true }
        }
    }

    // MARK: Unlocked

    private var unlockedStage: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                Text("onboarding_v2.first_name.unlocked_title".localized)
                    .font(.faroBold(26))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                Text(String(format: "onboarding_v2.first_name.unlocked_subtitle".localized, trimmedName))
                    .font(.poppinsRegular(15))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .balancedLines()
                    .padding(.horizontal, 34)
                    .padding(.top, 10)

                AvatarCardFront(firstName: trimmedName, startDate: Date(), currentDay: 0)
                    .shadow(color: Color(hex: "B794F6").opacity(cardRevealed ? 0.55 : 0), radius: 30)
                    .rotation3DEffect(.degrees(cardRevealed ? 0 : 90), axis: (x: 0, y: 1, z: 0))
                    .scaleEffect(cardRevealed ? 1 : 0.6)
                    .opacity(cardRevealed ? 1 : 0)
                    .padding(.top, 30)
                    .accessibilityLabel(String(format: "onboarding_v2.first_name.unlocked_subtitle".localized, trimmedName))

                Spacer()

                Button(action: finish) {
                    Text("onboarding_v2.first_name.unlocked_cta".localized)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .contentShape(Capsule())
                }
                .buttonStyle(.glassPrimary)
                .padding(.horizontal, 34)
                .padding(.bottom, 20)
            }

            if cardRevealed {
                FullScreenConfetti()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.25)) {
                cardRevealed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { HapticManager.success() }
        }
    }

    // MARK: Actions

    private func validate() {
        guard !trimmedName.isEmpty else { return }
        HapticManager.light()
        fieldFocused = false
        UserPersistence.userFirstName = trimmedName
        NotificationCenter.default.post(name: NSNotification.Name("ProfileUpdated"), object: nil)
        AnalyticsManager.shared.track(event: "onboarding_first_name_entered", properties: [:])
        stage = .unlocked
    }

    private func skip() {
        HapticManager.light()
        fieldFocused = false
        AnalyticsManager.shared.track(event: "onboarding_first_name_skipped", properties: [:])
        onContinue()
    }

    private func finish() {
        HapticManager.medium()
        onContinue()
    }
}

#Preview {
    OnboardingFirstNameView {}
}
