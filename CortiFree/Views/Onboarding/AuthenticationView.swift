//
//  AuthenticationView.swift
//  CortiFree
//
//  Created by Claude on 01/11/2025.
//  Authentication screen after first name collection
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import Lottie

struct AuthenticationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showEmailAuth = false
    @State private var showGoogleAuth = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    let firstName: String
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Galaxy background with planet
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "0A0A2E"),
                    Color(hex: "1A1A4E")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Stars
            GeometryReader { geometry in
                ForEach(0..<50, id: \.self) { index in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }

            // Planet silhouette at bottom
            GeometryReader { geometry in
                Ellipse()
                    .fill(Color(hex: "050520"))
                    .frame(width: geometry.size.width * 1.5, height: 600)
                    .offset(x: -geometry.size.width * 0.25, y: geometry.size.height - 375)
            }

            VStack(spacing: 0) {
                // Personalized message at top
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(firstName),")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)

                    Text("crée ton compte pour accéder à ton diagnostic personnalisé")
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
                .padding(.top, 60)

                Spacer()

                // Lottie animation
                LottieView(filename: "Tomato plant", loopMode: .loop)
                    .frame(width: 320, height: 320)
                    .padding(.bottom, 32)

                // Authentication buttons
                VStack(spacing: 16) {
                    // Continue with Email (moved to top position)
                    Button(action: {
                        HapticManager.light()
                        showEmailAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)

                            Text("Continuer avec Email")
                                .font(.custom("Poppins-Medium", size: 16))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.white, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 32)

                    // Continue with Apple (temporarily disabled)
                    Button(action: {
                        HapticManager.light()
                        errorMessage = "Apple Sign In sera disponible prochainement"
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20))
                                .foregroundColor(.white)

                            Text("Continuer avec Apple")
                                .font(.custom("Poppins-Medium", size: 16))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.white, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 32)
                    .opacity(0.5)
                    .disabled(true)

                    // Continue with Google
                    Button(action: {
                        HapticManager.light()
                        showGoogleAuth = true
                    }) {
                        HStack(spacing: 12) {
                            // Google "G" logo
                            ZStack {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 20, height: 20)

                                Text("G")
                                    .font(.custom("Poppins-Bold", size: 14))
                                    .foregroundColor(Color(hex: "4285F4"))
                            }

                            Text("Continuer avec Google")
                                .font(.custom("Poppins-Medium", size: 16))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.white, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 32)
                }

                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.red)
                        .padding(.top, 16)
                        .padding(.horizontal, 32)
                }

                Spacer().frame(height: 50)
            }

            // Loading overlay
            if isLoading {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .fullScreenCover(isPresented: $showEmailAuth) {
            EmailAuthView(onComplete: {
                showEmailAuth = false
                onComplete()
            })
        }
        .fullScreenCover(isPresented: $showGoogleAuth) {
            GoogleAuthView(onComplete: {
                showGoogleAuth = false
                onComplete()
            })
        }
    }

    // MARK: - Authentication Methods

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Erreur d'authentification Apple"
                return
            }

            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Impossible de récupérer le token"
                return
            }

            isLoading = true

            Task {
                do {
                    let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                                   rawNonce: nil,
                                                                   fullName: appleIDCredential.fullName)

                    let authResult = try await Auth.auth().signIn(with: credential)

                    // Create user profile in Firestore if new user
                    let userData: [String: Any] = [
                        "uid": authResult.user.uid,
                        "email": authResult.user.email ?? "",
                        "username": appleIDCredential.fullName?.givenName ?? "Utilisateur",
                        "createdAt": Timestamp(date: Date()),
                        "xp": 0,
                        "level": 1,
                        "currentStreak": 0,
                        "longestStreak": 0,
                        "authProvider": "apple"
                    ]

                    try await Firestore.firestore()
                        .collection("users")
                        .document(authResult.user.uid)
                        .setData(userData, merge: true)

                    await MainActor.run {
                        isLoading = false
                        onComplete()
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Erreur: \(error.localizedDescription)"
                    }
                }
            }

        case .failure(let error):
            errorMessage = "Erreur Apple Sign In: \(error.localizedDescription)"
        }
    }

    private func handleGoogleSignIn() {
        // TODO: Implement Google Sign In with GoogleSignIn SDK
        // For now, show email auth as fallback
        showEmailAuth = true
    }
}

// MARK: - Email Authentication View

struct EmailAuthView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var isSignUp = true
    @State private var isLoading = false
    @State private var errorMessage: String?

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "1F0140"),
                    Color(hex: "0B011B"),
                    Color(hex: "01000C")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button at top
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 50)

                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        Text(isSignUp ? "Créer un compte" : "Connexion")
                            .font(.custom("Poppins-Bold", size: 28))
                            .foregroundColor(.white)
                            .padding(.top, 20)

                        // Form fields
                        VStack(spacing: 16) {
                            if isSignUp {
                                TextField("", text: $username, prompt: Text("Prénom").foregroundColor(.white.opacity(0.6)))
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .colorScheme(.dark)
                            }

                            TextField("", text: $email, prompt: Text("Email").foregroundColor(.white.opacity(0.6)))
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .colorScheme(.dark)

                            SecureField("", text: $password, prompt: Text("Mot de passe").foregroundColor(.white.opacity(0.6)))
                                .textFieldStyle(CustomTextFieldStyle())
                                .colorScheme(.dark)

                            if isSignUp {
                                SecureField("", text: $confirmPassword, prompt: Text("Confirmer le mot de passe").foregroundColor(.white.opacity(0.6)))
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .colorScheme(.dark)
                            }
                        }
                        .padding(.horizontal, 32)

                        // Error message
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.red)
                                .padding(.horizontal, 32)
                        }

                        // Submit button
                        Button(action: handleAuth) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "1A1A4E")))
                            } else {
                                Text(isSignUp ? "Créer mon compte" : "Se connecter")
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                    .foregroundColor(Color(hex: "1A1A4E"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                        .padding(.horizontal, 32)
                        .disabled(isLoading)

                        // Toggle sign up/in
                        Button(action: {
                            isSignUp.toggle()
                            errorMessage = nil
                        }) {
                            Text(isSignUp ? "Déjà un compte ? Se connecter" : "Pas de compte ? S'inscrire")
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func handleAuth() {
        errorMessage = nil

        // Validation
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Veuillez remplir tous les champs"
            return
        }

        if isSignUp {
            guard !username.isEmpty else {
                errorMessage = "Veuillez entrer votre prénom"
                return
            }

            guard password == confirmPassword else {
                errorMessage = "Les mots de passe ne correspondent pas"
                return
            }
        }

        isLoading = true

        Task {
            do {
                if isSignUp {
                    _ = try await AuthService.shared.signUp(email: email, password: password, username: username)
                } else {
                    _ = try await AuthService.shared.signIn(email: email, password: password)
                }

                await MainActor.run {
                    isLoading = false
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Erreur: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Google Authentication View

struct GoogleAuthView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background (same as EmailAuthView)
            LinearGradient(
                colors: [
                    Color(hex: "1F0140"),
                    Color(hex: "0B011B"),
                    Color(hex: "01000C")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Close button at top
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 50)

                Spacer()

                // Google logo and title
                VStack(spacing: 24) {
                    // Google "G" logo (large)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .frame(width: 80, height: 80)

                        Text("G")
                            .font(.custom("Poppins-Bold", size: 48))
                            .foregroundColor(Color(hex: "4285F4"))
                    }

                    Text("Continuer avec Google")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Connecte-toi avec ton compte Google pour accéder à ton espace personnalisé")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 32)
                }

                // Sign in button
                Button(action: handleGoogleSignIn) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "1A1A4E")))
                    } else {
                        Text("Se connecter avec Google")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(Color(hex: "1A1A4E"))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .disabled(isLoading)
            }
        }
    }

    private func handleGoogleSignIn() {
        // TODO: Implement actual Google Sign In with GoogleSignIn SDK
        errorMessage = "Google Sign In n'est pas encore implémenté. Utilise l'authentification par email pour le moment."
    }
}

// MARK: - Custom Text Field Style

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .foregroundColor(.white)
            .font(.custom("Poppins-Regular", size: 16))
            .tint(.white)
            .accentColor(.white)
    }
}

#Preview {
    AuthenticationView(firstName: "Sophie", onComplete: {})
}
