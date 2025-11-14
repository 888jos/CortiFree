//
//  AuthView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Vue d'accueil de l'authentification
//

import SwiftUI

struct AuthView: View {
    @State private var showLogin = false
    @State private var showSignUp = false

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.2)

            VStack(spacing: 0) {
                Spacer()

                // Logo et branding
                VStack(spacing: 24) {
                    // Animated logo
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.appTheme.opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)

                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 90))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.appTheme, Color.appThemeSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.appTheme.opacity(0.5), radius: 30)
                    }

                    VStack(spacing: 12) {
                        Text("CortiFree")
                            .font(.custom("Poppins-Bold", size: 42))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)

                        Text("Votre compagnon bien-être")
                            .font(.custom("Poppins-Regular", size: 18))
                            .foregroundColor(Color.white.opacity(0.8))
                    }
                }
                .padding(.bottom, 60)

                // Boutons d'authentification
                VStack(spacing: 16) {
                    // Bouton Créer un compte
                    Button(action: { showSignUp = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.badge.plus.fill")
                                .font(.system(size: 20))
                            Text("Créer un compte")
                                .font(.custom("Poppins-SemiBold", size: 18))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [Color.appTheme, Color.appThemeSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .shadow(color: Color.appTheme.opacity(0.4), radius: 20, y: 10)
                    }

                    // Bouton Se connecter
                    Button(action: { showLogin = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                            Text("Se connecter")
                                .font(.custom("Poppins-SemiBold", size: 18))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.white.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                        )
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // Footer
                VStack(spacing: 8) {
                    Text("En continuant, vous acceptez nos")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(Color.white.opacity(0.5))

                    HStack(spacing: 4) {
                        Button(action: {}) {
                            Text("Conditions d'utilisation")
                                .font(.custom("Poppins-Medium", size: 12))
                                .foregroundColor(Color.appTheme)
                        }

                        Text("et")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(Color.white.opacity(0.5))

                        Button(action: {}) {
                            Text("Politique de confidentialité")
                                .font(.custom("Poppins-Medium", size: 12))
                                .foregroundColor(Color.appTheme)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
        }
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView()
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
