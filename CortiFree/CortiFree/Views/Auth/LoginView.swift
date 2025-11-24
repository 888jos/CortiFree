//
//  LoginView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Vue de connexion
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showResetPassword = false
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.2)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)

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

                        Text("Bon retour !")
                            .font(.custom("Poppins-Bold", size: 32))
                            .foregroundColor(.white)

                        Text("Connectez-vous pour continuer")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .padding(.bottom, 20)

                    // Formulaire de connexion
                    VStack(spacing: 20) {
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
                                            Text(password.isEmpty ? "••••••••" : "")
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
                                            Text(password.isEmpty ? "••••••••" : "")
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

                        // Mot de passe oublié
                        HStack {
                            Spacer()
                            Button(action: { showResetPassword = true }) {
                                Text("Mot de passe oublié ?")
                                    .font(.custom("Poppins-Medium", size: 14))
                                    .foregroundColor(Color.appTheme)
                            }
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

                    // Bouton de connexion
                    Button(action: {
                        Task {
                            await authViewModel.signIn(email: email, password: password)
                        }
                    }) {
                        HStack(spacing: 12) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20))
                                Text("Se connecter")
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
                    .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
                    .opacity(authViewModel.isLoading || email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // Retour
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Retour")
                        }
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showResetPassword) {
            ResetPasswordView()
                .environmentObject(authViewModel)
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside text fields
            focusedField = nil
        }
        .onAppear {
            authViewModel.clearMessages()
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
