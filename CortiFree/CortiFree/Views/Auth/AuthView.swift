//
//  AuthView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Vue d'authentification
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import Lottie
import GoogleSignIn
import GoogleSignInSwift

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSignUpMode = true

    var body: some View {
        if isSignUpMode {
            AuthSignUpView(switchToLogin: { isSignUpMode = false })
                .environmentObject(authViewModel)
        } else {
            AuthLoginView(switchToSignUp: { isSignUpMode = true })
                .environmentObject(authViewModel)
        }
    }
}

// MARK: - Sign Up Screen (Créer un compte)

struct AuthSignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEmailAuth = false
    @State private var showGoogleAuth = false
    @State private var showAppleAuth = false

    var switchToLogin: () -> Void

    var body: some View {
        ZStack {
            // Galaxy background
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

            // Planet silhouette
            GeometryReader { geometry in
                Ellipse()
                    .fill(Color(hex: "050520"))
                    .frame(width: geometry.size.width * 1.5, height: 600)
                    .offset(x: -geometry.size.width * 0.25, y: geometry.size.height - 375)
            }

            VStack(spacing: 0) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Créer un compte")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)

                    Text("Rejoignez CortiFree et commencez votre parcours bien-être")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.top, 80)

                Spacer()

                // Lottie animation
                LottieView(filename: "Flower Animation", loopMode: .loop)
                    .frame(width: 250, height: 250)
                    .padding(.bottom, 24)

                // Authentication buttons
                VStack(spacing: 14) {
                    // Apple
                    Button(action: {
                        HapticManager.light()
                        showAppleAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20))
                                .foregroundColor(.white)

                            Text("S'inscrire avec Apple")
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

                    // Google
                    Button(action: {
                        HapticManager.light()
                        showGoogleAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image("GoogleLogoWhite")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)

                            Text("S'inscrire avec Google")
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

                    // Email
                    Button(action: {
                        HapticManager.light()
                        showEmailAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)

                            Text("S'inscrire avec Email")
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
                }
                .padding(.horizontal, 32)

                // Switch to login
                Button(action: {
                    HapticManager.light()
                    switchToLogin()
                }) {
                    HStack(spacing: 4) {
                        Text("Déjà un compte ?")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.7))

                        Text("Se connecter")
                            .font(.custom("Poppins-SemiBold", size: 14))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $showEmailAuth) {
            AuthEmailFormView(isSignUp: true)
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showGoogleAuth) {
            AuthGoogleView(onComplete: { showGoogleAuth = false }, isSignUp: true)
        }
        .fullScreenCover(isPresented: $showAppleAuth) {
            AuthAppleView(onComplete: { showAppleAuth = false }, isSignUp: true)
        }
        .onAppear {
            MixpanelManager.shared.trackAuthViewDisplayed()
        }
    }
}

// MARK: - Login Screen (Se connecter)

struct AuthLoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEmailAuth = false
    @State private var showGoogleAuth = false
    @State private var showAppleAuth = false

    var switchToSignUp: () -> Void

    var body: some View {
        ZStack {
            // Galaxy background
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

            // Planet silhouette
            GeometryReader { geometry in
                Ellipse()
                    .fill(Color(hex: "050520"))
                    .frame(width: geometry.size.width * 1.5, height: 600)
                    .offset(x: -geometry.size.width * 0.25, y: geometry.size.height - 375)
            }

            VStack(spacing: 0) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bon retour !")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)

                    Text("Connectez-vous pour continuer votre parcours")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.top, 80)

                Spacer()

                // Lottie animation
                LottieView(filename: "Flower Animation", loopMode: .loop)
                    .frame(width: 250, height: 250)
                    .padding(.bottom, 24)

                // Authentication buttons
                VStack(spacing: 14) {
                    // Apple
                    Button(action: {
                        HapticManager.light()
                        showAppleAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20))
                                .foregroundColor(.white)

                            Text("Se connecter avec Apple")
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

                    // Google
                    Button(action: {
                        HapticManager.light()
                        showGoogleAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image("GoogleLogoWhite")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)

                            Text("Se connecter avec Google")
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

                    // Email
                    Button(action: {
                        HapticManager.light()
                        showEmailAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)

                            Text("Se connecter avec Email")
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
                }
                .padding(.horizontal, 32)

                // Switch to signup
                Button(action: {
                    HapticManager.light()
                    switchToSignUp()
                }) {
                    HStack(spacing: 4) {
                        Text("Pas encore de compte ?")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.7))

                        Text("Créer un compte")
                            .font(.custom("Poppins-SemiBold", size: 14))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $showEmailAuth) {
            AuthEmailFormView(isSignUp: false)
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showGoogleAuth) {
            AuthGoogleView(onComplete: { showGoogleAuth = false }, isSignUp: false)
        }
        .fullScreenCover(isPresented: $showAppleAuth) {
            AuthAppleView(onComplete: { showAppleAuth = false }, isSignUp: false)
        }
        .onAppear {
            MixpanelManager.shared.trackLoginViewDisplayed()
        }
    }
}

// MARK: - Email Form View

struct AuthEmailFormView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    let isSignUp: Bool

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showResetPassword = false
    @State private var showGoogleAuth = false
    @State private var showAppleAuth = false
    @FocusState private var focusedField: Field?

    enum Field {
        case username, email, password, confirmPassword
    }

    private var passwordsMatch: Bool {
        password == confirmPassword && !confirmPassword.isEmpty
    }

    private var isFormValid: Bool {
        if isSignUp {
            return !username.isEmpty && !email.isEmpty && !password.isEmpty && password.count >= 6 && passwordsMatch
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }

    var body: some View {
        ZStack {
            // Galaxy background
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

            // Planet silhouette
            GeometryReader { geometry in
                Ellipse()
                    .fill(Color(hex: "050520"))
                    .frame(width: geometry.size.width * 1.5, height: 600)
                    .offset(x: -geometry.size.width * 0.25, y: geometry.size.height - 375)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Close button
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 50)

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isSignUp ? "Créer un compte" : "Connexion")
                            .font(.custom("Poppins-Bold", size: 28))
                            .foregroundColor(.white)

                        Text(isSignUp ? "Entrez vos informations" : "Entrez vos identifiants")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)

                    // Form fields
                    VStack(spacing: 16) {
                        // Username (only for sign up)
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Prénom")
                                    .font(.custom("Poppins-Medium", size: 14))
                                    .foregroundColor(.white)

                                TextField("", text: $username, prompt: Text("Votre prénom").foregroundColor(.white.opacity(0.5)))
                                    .font(.custom("Poppins-Regular", size: 16))
                                    .foregroundColor(.white)
                                    .focused($focusedField, equals: .username)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(focusedField == .username ? Color.white : Color.white.opacity(0.3), lineWidth: 1.5)
                                            )
                                    )
                                    .tint(.white)
                            }
                        }

                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white)

                            TextField("", text: $email, prompt: Text("votre@email.com").foregroundColor(.white.opacity(0.5)))
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .focused($focusedField, equals: .email)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(focusedField == .email ? Color.white : Color.white.opacity(0.3), lineWidth: 1.5)
                                        )
                                )
                                .tint(.white)
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Mot de passe")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white)

                            HStack {
                                if showPassword {
                                    TextField("", text: $password, prompt: Text(isSignUp ? "Min. 6 caractères" : "••••••••").foregroundColor(.white.opacity(0.5)))
                                        .font(.custom("Poppins-Regular", size: 16))
                                        .foregroundColor(.white)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .password)
                                } else {
                                    SecureField("", text: $password, prompt: Text(isSignUp ? "Min. 6 caractères" : "••••••••").foregroundColor(.white.opacity(0.5)))
                                        .font(.custom("Poppins-Regular", size: 16))
                                        .foregroundColor(.white)
                                        .textInputAutocapitalization(.never)
                                        .textContentType(.oneTimeCode)
                                        .focused($focusedField, equals: .password)
                                }

                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .password ? Color.white : Color.white.opacity(0.3), lineWidth: 1.5)
                                    )
                            )
                            .tint(.white)
                        }

                        // Confirm Password (only for sign up)
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Confirmer le mot de passe")
                                    .font(.custom("Poppins-Medium", size: 14))
                                    .foregroundColor(.white)

                                HStack {
                                    SecureField("", text: $confirmPassword, prompt: Text("Confirmez").foregroundColor(.white.opacity(0.5)))
                                        .font(.custom("Poppins-Regular", size: 16))
                                        .foregroundColor(.white)
                                        .textInputAutocapitalization(.never)
                                        .textContentType(.oneTimeCode)
                                        .focused($focusedField, equals: .confirmPassword)

                                    if passwordsMatch {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    focusedField == .confirmPassword ?
                                                    (passwordsMatch ? Color.green : Color.red) :
                                                        Color.white.opacity(0.3),
                                                    lineWidth: 1.5
                                                )
                                        )
                                )
                                .tint(.white)
                            }
                        }

                        // Forgot password (only for login)
                        if !isSignUp {
                            HStack {
                                Spacer()
                                Button(action: { showResetPassword = true }) {
                                    Text("Mot de passe oublié ?")
                                        .font(.custom("Poppins-Medium", size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 32)

                    // Error message
                    if let errorMessage = authViewModel.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(.white)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.2))
                        )
                        .padding(.horizontal, 32)
                    }

                    // Submit button
                    Button(action: {
                        HapticManager.light()
                        Task {
                            if isSignUp {
                                await authViewModel.signUp(email: email, password: password, username: username)
                            } else {
                                await authViewModel.signIn(email: email, password: password)
                            }
                        }
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "0A0A2E")))
                        } else {
                            Text(isSignUp ? "Créer mon compte" : "Se connecter")
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(Color(hex: "0A0A2E"))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                    .padding(.horizontal, 32)
                    .disabled(authViewModel.isLoading || !isFormValid)
                    .opacity(authViewModel.isLoading || !isFormValid ? 0.6 : 1.0)

                    // Divider - Autre méthode
                    HStack(spacing: 16) {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                        Text("Autre méthode")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)

                    // Other auth methods
                    HStack(spacing: 16) {
                        // Apple
                        Button(action: {
                            HapticManager.light()
                            showAppleAuth = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)

                                Text("Apple")
                                    .font(.custom("Poppins-Medium", size: 14))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                            )
                        }

                        // Google
                        Button(action: {
                            HapticManager.light()
                            showGoogleAuth = true
                        }) {
                            HStack(spacing: 8) {
                                Image("GoogleLogoWhite")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)

                                Text("Google")
                                    .font(.custom("Poppins-Medium", size: 14))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                            )
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showResetPassword) {
            ResetPasswordView()
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showAppleAuth) {
            AuthAppleView(onComplete: {
                showAppleAuth = false
                dismiss()
            })
        }
        .fullScreenCover(isPresented: $showGoogleAuth) {
            AuthGoogleView(onComplete: {
                showGoogleAuth = false
                dismiss()
            })
        }
        .onTapGesture {
            focusedField = nil
        }
        .onAppear {
            authViewModel.clearMessages()
        }
    }
}

// MARK: - Google Authentication View

struct AuthGoogleView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showEmailAuth = false
    @State private var showAppleAuth = false

    var onComplete: () -> Void
    var isSignUp: Bool = true

    var body: some View {
        ZStack {
            // Galaxy background
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

            // Planet silhouette
            GeometryReader { geometry in
                Ellipse()
                    .fill(Color(hex: "050520"))
                    .frame(width: geometry.size.width * 1.5, height: 600)
                    .offset(x: -geometry.size.width * 0.25, y: geometry.size.height - 375)
            }

            VStack(spacing: 32) {
                // Close button
                HStack {
                    Button(action: { dismiss() }) {
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
                    Image("GoogleLogoWhite")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)

                    Text("Connexion Google")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Utilisez votre compte Google pour continuer")
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
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "0A0A2E")))
                    } else {
                        Text("Continuer avec Google")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(Color(hex: "0A0A2E"))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .padding(.horizontal, 32)
                .disabled(isLoading)

                // Divider - Autre méthode
                HStack(spacing: 16) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                    Text("Autre méthode")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)

                // Other auth methods
                HStack(spacing: 16) {
                    // Apple
                    Button(action: {
                        HapticManager.light()
                        showAppleAuth = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 16))
                                .foregroundColor(.white)

                            Text("Apple")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                        )
                    }

                    // Email
                    Button(action: {
                        HapticManager.light()
                        showEmailAuth = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)

                            Text("Email")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $showAppleAuth) {
            AuthAppleView(onComplete: {
                showAppleAuth = false
                dismiss()
            }, isSignUp: isSignUp)
        }
        .fullScreenCover(isPresented: $showEmailAuth) {
            AuthEmailFormView(isSignUp: isSignUp)
        }
    }

    private func handleGoogleSignIn() {
        isLoading = true
        errorMessage = nil

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Impossible de lancer Google Sign In"
            isLoading = false
            return
        }

        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            errorMessage = "Configuration Google manquante"
            isLoading = false
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Erreur: \(error.localizedDescription)"
                }
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Impossible de récupérer les informations"
                }
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Task {
                do {
                    let authResult = try await Auth.auth().signIn(with: credential)

                    let userData: [String: Any] = [
                        "uid": authResult.user.uid,
                        "email": authResult.user.email ?? "",
                        "firstName": user.profile?.givenName ?? "Utilisateur",
                        "displayName": user.profile?.name ?? "Utilisateur",
                        "photoURL": user.profile?.imageURL(withDimension: 200)?.absoluteString ?? "",
                        "createdAt": Timestamp(date: Date()),
                        "authProvider": "google",
                        "lastLoginAt": Timestamp(date: Date())
                    ]

                    try await Firestore.firestore()
                        .collection("users")
                        .document(authResult.user.uid)
                        .setData(userData, merge: true)

                    UserDefaults.standard.set(user.profile?.givenName ?? "Utilisateur", forKey: "userFirstName")

                    // Vérifier si l'utilisateur a déjà complété l'onboarding
                    let userDoc = try await Firestore.firestore()
                        .collection("users")
                        .document(authResult.user.uid)
                        .getDocument()

                    if let data = userDoc.data(),
                       let onboardingCompleted = data["onboardingCompleted"] as? Bool,
                       onboardingCompleted {
                        UserDefaults.standard.set(true, forKey: "onboardingV2Completed")
                    }

                    await MainActor.run {
                        isLoading = false
                        HapticManager.success()
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
}

// MARK: - Apple Authentication View

struct AuthAppleView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showEmailAuth = false
    @State private var showGoogleAuth = false

    var onComplete: () -> Void
    var isSignUp: Bool = true

    var body: some View {
        ZStack {
            // Galaxy background
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

            // Planet silhouette
            GeometryReader { geometry in
                Ellipse()
                    .fill(Color(hex: "050520"))
                    .frame(width: geometry.size.width * 1.5, height: 600)
                    .offset(x: -geometry.size.width * 0.25, y: geometry.size.height - 375)
            }

            VStack(spacing: 32) {
                // Close button
                HStack {
                    Button(action: { dismiss() }) {
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

                // Apple logo and title
                VStack(spacing: 24) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 60))
                        .foregroundColor(.white)

                    Text("Connexion Apple")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Utilisez votre identifiant Apple pour continuer")
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

                // Sign in with Apple button
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .cornerRadius(40)
                .padding(.horizontal, 32)
                .disabled(isLoading)

                // Divider - Autre méthode
                HStack(spacing: 16) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                    Text("Autre méthode")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)

                // Other auth methods
                HStack(spacing: 16) {
                    // Google
                    Button(action: {
                        HapticManager.light()
                        showGoogleAuth = true
                    }) {
                        HStack(spacing: 8) {
                            Image("GoogleLogoWhite")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)

                            Text("Google")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                        )
                    }

                    // Email
                    Button(action: {
                        HapticManager.light()
                        showEmailAuth = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)

                            Text("Email")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
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
        .fullScreenCover(isPresented: $showGoogleAuth) {
            AuthGoogleView(onComplete: {
                showGoogleAuth = false
                dismiss()
            }, isSignUp: isSignUp)
        }
        .fullScreenCover(isPresented: $showEmailAuth) {
            AuthEmailFormView(isSignUp: isSignUp)
        }
    }

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
                    let credential = OAuthProvider.appleCredential(
                        withIDToken: idTokenString,
                        rawNonce: nil,
                        fullName: appleIDCredential.fullName
                    )

                    let authResult = try await Auth.auth().signIn(with: credential)

                    let firstName = appleIDCredential.fullName?.givenName
                    let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")

                    var userData: [String: Any] = [
                        "uid": authResult.user.uid,
                        "email": authResult.user.email ?? appleIDCredential.email ?? "",
                        "createdAt": Timestamp(date: Date()),
                        "authProvider": "apple",
                        "lastLoginAt": Timestamp(date: Date())
                    ]

                    if let firstName = firstName, !firstName.isEmpty {
                        userData["firstName"] = firstName
                        UserDefaults.standard.set(firstName, forKey: "userFirstName")
                    }
                    if !displayName.isEmpty {
                        userData["displayName"] = displayName
                    }

                    try await Firestore.firestore()
                        .collection("users")
                        .document(authResult.user.uid)
                        .setData(userData, merge: true)

                    // Vérifier si l'utilisateur a déjà complété l'onboarding
                    let userDoc = try await Firestore.firestore()
                        .collection("users")
                        .document(authResult.user.uid)
                        .getDocument()

                    if let data = userDoc.data(),
                       let onboardingCompleted = data["onboardingCompleted"] as? Bool,
                       onboardingCompleted {
                        UserDefaults.standard.set(true, forKey: "onboardingV2Completed")
                    }

                    await MainActor.run {
                        isLoading = false
                        HapticManager.success()
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
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "Erreur: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
