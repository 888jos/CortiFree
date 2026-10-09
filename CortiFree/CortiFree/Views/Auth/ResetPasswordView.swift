//
//  ResetPasswordView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Vue de réinitialisation du mot de passe
//

import SwiftUI

/// Password reset in two steps: request an 8-digit code by email, then enter it with a
/// new password. A successful reset signs the user in (`onSignedIn`).
struct ResetPasswordView: View {
    @Environment(\.dismiss) var dismiss

    var onSignedIn: ((ConvexUser) -> Void)?

    @State private var email: String
    @State private var code = ""
    @State private var newPassword = ""
    @State private var step: Step = .email
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var signedInUser: ConvexUser?

    private enum Step { case email, code, done }

    init(initialEmail: String = "", onSignedIn: ((ConvexUser) -> Void)? = nil) {
        _email = State(initialValue: initialEmail.trimmingCharacters(in: .whitespacesAndNewlines))
        self.onSignedIn = onSignedIn
    }

    private var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedCode: String { code.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.8)

            VStack(spacing: 32) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassCircle(interactive: true)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                switch step {
                case .email: emailStep
                case .code: codeStep
                case .done: doneStep
                }

                Spacer()
            }
        }
    }

    // MARK: - Steps

    private var emailStep: some View {
        VStack(spacing: 28) {
            header(icon: "lock.rotation", title: "auth.forgot_password".localized, message: "auth.reset.instructions".localized)

            field(
                label: "auth.email".localized, icon: "envelope.fill", text: $email,
                placeholder: "auth.email_placeholder".localized, keyboard: .emailAddress, contentType: .emailAddress
            )

            errorBanner

            primaryButton(title: "auth.reset.send_link".localized, icon: "paperplane.fill",
                          disabled: trimmedEmail.isEmpty, action: sendCode)
        }
    }

    private var codeStep: some View {
        VStack(spacing: 24) {
            header(icon: "envelope.badge.fill", title: "auth.reset.email_sent_title".localized,
                   message: String(format: "auth.reset.code_message".localized, trimmedEmail))

            field(
                label: "auth.reset.code_label".localized, icon: "number", text: $code,
                placeholder: "12345678", keyboard: .numberPad, contentType: .oneTimeCode
            )

            field(
                label: "auth.reset.new_password_label".localized, icon: "lock.fill", text: $newPassword,
                placeholder: "onboarding_v2.auth.password_min_chars".localized, secure: true, contentType: .newPassword
            )

            errorBanner

            primaryButton(title: "auth.reset.confirm_button".localized, icon: "checkmark",
                          disabled: trimmedCode.isEmpty || newPassword.count < convexMinimumPasswordLength,
                          action: confirmReset)

            Button(action: sendCode) {
                Text("auth.reset.resend_code".localized)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .underline()
            }
            .disabled(isLoading)
        }
    }

    private var doneStep: some View {
        VStack(spacing: 24) {
            header(icon: "checkmark.seal.fill", title: "auth.reset.success_title".localized,
                   message: "auth.reset.success_message".localized)

            primaryButton(title: "common.continue".localized, icon: "arrow.right", disabled: false) {
                if let signedInUser, let onSignedIn {
                    onSignedIn(signedInUser)
                } else {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Actions

    private func sendCode() {
        errorMessage = nil
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                try await UnifiedFirebaseService.shared.auth.resetPassword(email: trimmedEmail)
                code = ""
                step = .code
            } catch {
                errorMessage = AuthFailure(error).localizedMessage
            }
        }
    }

    private func confirmReset() {
        errorMessage = nil
        guard newPassword.count >= convexMinimumPasswordLength else {
            errorMessage = AuthFailure.passwordTooShort.localizedMessage
            return
        }
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                signedInUser = try await UnifiedFirebaseService.shared.auth.confirmPasswordReset(
                    email: trimmedEmail, code: trimmedCode, newPassword: newPassword
                )
                await RevenueCatManager.shared.identifyUser(userId: signedInUser?.uid ?? "")
                HapticManager.success()
                step = .done
            } catch {
                let failure = AuthFailure(error)
                // A wrong or expired code surfaces as invalid credentials from Convex Auth.
                errorMessage = (failure == .invalidCredentials ? AuthFailure.invalidCode : failure).localizedMessage
            }
        }
    }

    // MARK: - Building blocks

    private func header(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(Color.appTheme)

            Text(title)
                .font(.custom("Poppins-Bold", size: 26))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    private func field(
        label: String, icon: String, text: Binding<String>, placeholder: String,
        keyboard: UIKeyboardType = .default, secure: Bool = false, contentType: UITextContentType? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.white)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(Color.appTheme)
                    .frame(width: 20)

                Group {
                    if secure {
                        SecureField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                    } else {
                        TextField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                            .keyboardType(keyboard)
                    }
                }
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(contentType)
                .tint(.white)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color(hex: "FF6B9D"))
                Text(errorMessage)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "FF6B9D").opacity(0.2))
            )
            .padding(.horizontal, 24)
        }
    }

    private func primaryButton(title: String, icon: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                    Text(title)
                        .font(.custom("Poppins-SemiBold", size: 16))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .contentShape(Capsule())
        }
        .buttonStyle(.glassPrimary(tint: Color.appTheme))
        .disabled(isLoading || disabled)
        .padding(.horizontal, 24)
    }
}

#Preview {
    ResetPasswordView()
}
