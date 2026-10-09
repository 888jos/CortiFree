//
//  OnboardingFirstNameView.swift
//  CortiFree
//
//  First onboarding screen after the welcome, all on one page: the home avatar card rises
//  from the bottom, the first name field appears under it and the name is written live
//  bottom right of the card. Validating with a name throws confetti; the name is optional
//  (Sign in with Apple fills it later), the arrow goes on without one.
//

import SwiftUI

struct OnboardingFirstNameView: View {
    let onContinue: () -> Void

    @State private var name = UserPersistence.userFirstName ?? ""
    @State private var cardAppeared = false
    @State private var fieldVisible = false
    @State private var celebrating = false
    @FocusState private var fieldFocused: Bool

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var hasName: Bool { !trimmedName.isEmpty }
    /// The keyboard takes half the screen: the card shrinks while the name is typed.
    private var cardScale: CGFloat { fieldFocused ? 0.72 : 1.12 }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: fieldFocused ? 2 : 8) {
                    Text("onboarding_v2.first_name.title".localized)
                        .font(.faroBold(fieldFocused ? 22 : 28))
                        .foregroundStyle(.white)
                    if !fieldFocused {
                        Text("onboarding_v2.first_name.subtitle".localized)
                            .font(.poppinsRegular(15))
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.top, fieldFocused ? 8 : 28)
                .padding(.bottom, fieldFocused ? 8 : 18)

                AvatarCardFront(firstName: trimmedName, startDate: Date(), currentDay: 1)
                    .scaleEffect(cardScale)
                    .frame(width: 216 * cardScale, height: 320 * cardScale)
                    .shadow(color: Color(hex: "B794F6").opacity(celebrating ? 0.6 : 0.25), radius: 28)
                    .offset(y: cardAppeared ? 0 : 520)
                    .opacity(cardAppeared ? 1 : 0)
                    .accessibilityHidden(true)

                Spacer(minLength: 10)

                nameField
                    .opacity(fieldVisible ? 1 : 0)
                    .offset(y: fieldVisible ? 0 : 14)
                    .allowsHitTesting(fieldVisible && !celebrating)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            if celebrating {
                FullScreenConfetti()
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: fieldFocused)
        .animation(.easeOut(duration: 0.22), value: hasName)
        .onAppear {
            AnalyticsManager.shared.track(event: "onboarding_first_name_viewed", properties: [:])
            withAnimation(.spring(response: 0.86, dampingFraction: 0.88)) { cardAppeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                withAnimation(.easeOut(duration: 0.28)) { fieldVisible = true }
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("onboarding_v2.first_name.label".localized)
                .font(.poppinsMedium(13))
                .foregroundStyle(.white.opacity(0.85))

            HStack(spacing: 10) {
                TextField("", text: $name, prompt: Text("onboarding_v2.first_name.placeholder".localized)
                    .foregroundColor(.white.opacity(0.4)))
                    .font(.poppinsSemiBold(17))
                    .foregroundStyle(.white)
                    .textContentType(.givenName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($fieldFocused)
                    .onSubmit(validate)
                    .onChange(of: name) { _, value in
                        if value.count > 24 { name = String(value.prefix(24)) }
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                    .glassCard(cornerRadius: 18, tint: hasName ? Color(hex: "B794F6") : nil, interactive: true)

                Button(action: validate) {
                    Image(systemName: hasName ? "checkmark" : "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color(hex: "9B7FD4"), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(PressableCardStyle())
                .accessibilityLabel((hasName ? "onboarding_v2.first_name.continue" : "onboarding_v2.first_name.skip").localized)
            }
        }
    }

    private func validate() {
        guard !celebrating else { return }
        fieldFocused = false
        guard hasName else {
            HapticManager.light()
            AnalyticsManager.shared.track(event: "onboarding_first_name_skipped", properties: [:])
            onContinue()
            return
        }
        UserPersistence.userFirstName = trimmedName
        NotificationCenter.default.post(name: NSNotification.Name("ProfileUpdated"), object: nil)
        AnalyticsManager.shared.track(event: "onboarding_first_name_entered", properties: [:])
        HapticManager.success()
        celebrating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { onContinue() }
    }
}

#Preview {
    OnboardingFirstNameView {}
}
