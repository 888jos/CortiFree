//
//  ResetPasswordView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Vue de réinitialisation du mot de passe
//

import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var emailSent = false

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.8)

            VStack(spacing: 32) {
                // Header
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

                if emailSent {
                    // Success state
                    VStack(spacing: 24) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 70))
                            .foregroundColor(Color.appTheme)

                        VStack(spacing: 12) {
                            Text("auth.reset.email_sent_title".localized)
                                .font(.custom("Poppins-Bold", size: 28))
                                .foregroundColor(.white)

                            Text("auth.reset.email_sent_message".localized)
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(Color.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        Button(action: { dismiss() }) {
                            Text("common.close".localized)
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.glassPrimary(tint: Color.appTheme))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                } else {
                    // Form state
                    VStack(spacing: 28) {
                        // Icon and title
                        VStack(spacing: 16) {
                            Image(systemName: "lock.rotation")
                                .font(.system(size: 60))
                                .foregroundColor(Color.appTheme)

                            Text("auth.forgot_password".localized)
                                .font(.custom("Poppins-Bold", size: 26))
                                .foregroundColor(.white)

                            Text("auth.reset.instructions".localized)
                                .font(.custom("Poppins-Regular", size: 15))
                                .foregroundColor(Color.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("auth.email".localized)
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(Color.appTheme)
                                    .frame(width: 20)

                                TextField("", text: $email)
                                    .font(.custom("Poppins-Regular", size: 16))
                                    .foregroundColor(.white)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .overlay(
                                        Text(email.isEmpty ? "auth.email_placeholder".localized : "")
                                            .font(.custom("Poppins-Regular", size: 16))
                                            .foregroundColor(Color.white.opacity(0.4))
                                            .allowsHitTesting(false)
                                        , alignment: .leading
                                    )
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

                        // Error message
                        if let errorMessage = authViewModel.errorMessage {
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

                        // Send button
                        Button(action: {
                            Task {
                                await authViewModel.resetPassword(email: email)
                                if authViewModel.errorMessage == nil {
                                    emailSent = true
                                }
                            }
                        }) {
                            HStack(spacing: 12) {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 18))
                                    Text("auth.reset.send_link".localized)
                                        .font(.custom("Poppins-SemiBold", size: 16))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .contentShape(Capsule())
                        }
                        .buttonStyle(.glassPrimary(tint: Color.appTheme))
                        .disabled(authViewModel.isLoading || email.isEmpty)
                        .padding(.horizontal, 24)
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            authViewModel.clearMessages()
        }
    }
}

#Preview {
    ResetPasswordView()
        .environmentObject(AuthViewModel())
}
