//
//  SignUpView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Vue d'inscription
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @FocusState private var focusedField: Field?

    enum Field {
        case username, email, password, confirmPassword
    }

    private var passwordsMatch: Bool {
        password == confirmPassword && !confirmPassword.isEmpty
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.2)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer(minLength: 40)

                    // Logo et titre
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.appTheme, Color.appThemeSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.appTheme.opacity(0.5), radius: 20)

                        Text("Bienvenue !")
                            .font(.custom("Poppins-Bold", size: 32))
                            .foregroundColor(.white)

                        Text("Créez votre compte CortiFree")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .padding(.bottom, 12)

                    // Formulaire d'inscription
                    VStack(spacing: 18) {
                        // Username field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nom d'utilisateur")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(Color.appTheme)
                                    .frame(width: 20)

                                TextField("", text: $username)
                                    .font(.custom("Poppins-Regular", size: 16))
                                    .foregroundColor(.white)
                                    .textInputAutocapitalization(.never)
                                    .focused($focusedField, equals: .username)
                                    .overlay(
                                        Text(username.isEmpty ? "Votre pseudo" : "")
                                            .font(.custom("Poppins-Regular", size: 16))
                                            .foregroundColor(Color.white.opacity(0.4))
                                            .allowsHitTesting(false)
                                        , alignment: .leading
                                    )
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .username ? Color.appTheme : Color.white.opacity(0.2), lineWidth: 1.5)
                                    )
                            )
                        }

                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
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
                                    .focused($focusedField, equals: .email)
                                    .overlay(
                                        Text(email.isEmpty ? "votre@email.com" : "")
                                            .font(.custom("Poppins-Regular", size: 16))
                                            .foregroundColor(Color.white.opacity(0.4))
                                            .allowsHitTesting(false)
                                        , alignment: .leading
                                    )
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .email ? Color.appTheme : Color.white.opacity(0.2), lineWidth: 1.5)
                                    )
                            )
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mot de passe")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(Color.appTheme)
                                    .frame(width: 20)

                                if showPassword {
                                    TextField("", text: $password)
                                        .font(.custom("Poppins-Regular", size: 16))
                                        .foregroundColor(.white)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .password)
                                        .overlay(
                                            Text(password.isEmpty ? "Min. 6 caractères" : "")
                                                .font(.custom("Poppins-Regular", size: 16))
                                                .foregroundColor(Color.white.opacity(0.4))
                                                .allowsHitTesting(false)
                                            , alignment: .leading
                                        )
                                } else {
                                    SecureField("", text: $password)
                                        .font(.custom("Poppins-Regular", size: 16))
                                        .foregroundColor(.white)
                                        .textInputAutocapitalization(.never)
                                        .textContentType(.oneTimeCode)
                                        .focused($focusedField, equals: .password)
                                        .overlay(
                                            Text(password.isEmpty ? "Min. 6 caractères" : "")
                                                .font(.custom("Poppins-Regular", size: 16))
                                                .foregroundColor(Color.white.opacity(0.4))
                                                .allowsHitTesting(false)
                                            , alignment: .leading
                                        )
                                }

                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(Color.white.opacity(0.5))
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .password ? Color.appTheme : Color.white.opacity(0.2), lineWidth: 1.5)
                                    )
                            )
                        }

                        // Confirm Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirmer le mot de passe")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(passwordsMatch ? Color.appTheme : Color(hex: "FF6B9D"))
                                    .frame(width: 20)

                                if showConfirmPassword {
                                    TextField("", text: $confirmPassword)
                                        .font(.custom("Poppins-Regular", size: 16))
                                        .foregroundColor(.white)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .confirmPassword)
                                        .overlay(
                                            Text(confirmPassword.isEmpty ? "Confirmez votre mot de passe" : "")
                                                .font(.custom("Poppins-Regular", size: 16))
                                                .foregroundColor(Color.white.opacity(0.4))
                                                .allowsHitTesting(false)
                                            , alignment: .leading
                                        )
                                } else {
                                    SecureField("", text: $confirmPassword)
                                        .font(.custom("Poppins-Regular", size: 16))
                                        .foregroundColor(.white)
                                        .textInputAutocapitalization(.never)
                                        .textContentType(.oneTimeCode)
                                        .focused($focusedField, equals: .confirmPassword)
                                        .overlay(
                                            Text(confirmPassword.isEmpty ? "Confirmez votre mot de passe" : "")
                                                .font(.custom("Poppins-Regular", size: 16))
                                                .foregroundColor(Color.white.opacity(0.4))
                                                .allowsHitTesting(false)
                                            , alignment: .leading
                                        )
                                }

                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(Color.white.opacity(0.5))
                                }

                                if passwordsMatch {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color.appTheme)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                focusedField == .confirmPassword ?
                                                (passwordsMatch ? Color.appTheme : Color(hex: "FF6B9D")) :
                                                    Color.white.opacity(0.2),
                                                lineWidth: 1.5
                                            )
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // Message d'erreur
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

                    // Bouton d'inscription
                    Button(action: {
                        Task {
                            await authViewModel.signUp(email: email, password: password, username: username)
                        }
                    }) {
                        HStack(spacing: 12) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                Text("Créer mon compte")
                                    .font(.custom("Poppins-SemiBold", size: 18))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.appTheme, Color.appThemeSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: Color.appTheme.opacity(0.4), radius: 15, y: 8)
                    }
                    .disabled(authViewModel.isLoading || !isFormValid)
                    .opacity(authViewModel.isLoading || !isFormValid ? 0.6 : 1.0)
                    .padding(.horizontal, 24)

                    // Retour
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Retour")
                        }
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear {
            authViewModel.clearMessages()
        }
    }

    private var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password.count >= 6 &&
        passwordsMatch
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
