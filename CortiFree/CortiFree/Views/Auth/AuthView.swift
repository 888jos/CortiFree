//
//  AuthView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Vue d'authentification
//

import SwiftUI
import AuthenticationServices
import Lottie
import GoogleSignIn
import GoogleSignInSwift
import CryptoKit

private func authRandomNonce(length: Int = 32) -> String {
    let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    while result.count < length {
        var byte: UInt8 = 0
        guard SecRandomCopyBytes(kSecRandomDefault, 1, &byte) == errSecSuccess else { continue }
        if Int(byte) < characters.count * (256 / characters.count) {
            result.append(characters[Int(byte) % characters.count])
        }
    }
    return result
}

private func authSHA256(_ input: String) -> String {
    SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
}

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
                    Text("auth.create_account".localized)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)

                    Text("auth.signup_subtitle".localized)
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

                            Text("auth.signup_with_apple".localized)
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

                    if false {
                    Button(action: {
                        HapticManager.light()
                        showGoogleAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image("GoogleLogoWhite")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)

                            Text("auth.signup_with_google".localized)
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

                    // Email
                    Button(action: {
                        HapticManager.light()
                        showEmailAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)

                            Text("auth.signup_with_email".localized)
                                .font(.custom("Poppins-Medium", size: 16))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.glassSecondary)
                }
                .padding(.horizontal, 32)

                // Switch to login
                Button(action: {
                    HapticManager.light()
                    switchToLogin()
                }) {
                    HStack(spacing: 4) {
                        Text("auth.already_account_question".localized)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.7))

                        Text("auth.sign_in".localized)
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
            AnalyticsManager.shared.trackAuthViewDisplayed()
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
                    Text("auth.welcome_back".localized)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)

                    Text("auth.signin_subtitle".localized)
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

                            Text("auth.signin_with_apple".localized)
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

                    if false {
                    Button(action: {
                        HapticManager.light()
                        showGoogleAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image("GoogleLogoWhite")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)

                            Text("auth.sign_in_google".localized)
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

                    // Email
                    Button(action: {
                        HapticManager.light()
                        showEmailAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)

                            Text("auth.signin_with_email".localized)
                                .font(.custom("Poppins-Medium", size: 16))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.glassSecondary)
                }
                .padding(.horizontal, 32)

                // Switch to signup
                Button(action: {
                    HapticManager.light()
                    switchToSignUp()
                }) {
                    HStack(spacing: 4) {
                        Text("auth.no_account_question".localized)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.7))

                        Text("auth.create_account".localized)
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
            AnalyticsManager.shared.trackLoginViewDisplayed()
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
                        Text(isSignUp ? "auth.create_account".localized : "auth.login".localized)
                            .font(.custom("Poppins-Bold", size: 28))
                            .foregroundColor(.white)

                        Text(isSignUp ? "auth.enter_details".localized : "auth.enter_credentials".localized)
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
                                Text("auth.first_name".localized)
                                    .font(.custom("Poppins-Medium", size: 14))
                                    .foregroundColor(.white)

                                TextField("", text: $username, prompt: Text("auth.first_name_placeholder".localized).foregroundColor(.white.opacity(0.5)))
                                    .font(.custom("Poppins-Regular", size: 16))
                                    .foregroundColor(.white)
                                    .focused($focusedField, equals: .username)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color.white.opacity(0.06))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .strokeBorder(focusedField == .username ? Color.white.opacity(0.7) : Color.white.opacity(0.12), lineWidth: 1)
                                            )
                                    )
                                    .tint(.white)
                            }
                        }

                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("auth.email".localized)
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white)

                            TextField("", text: $email, prompt: Text("auth.email_placeholder".localized).foregroundColor(.white.opacity(0.5)))
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .focused($focusedField, equals: .email)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(focusedField == .email ? Color.white.opacity(0.7) : Color.white.opacity(0.12), lineWidth: 1)
                                        )
                                )
                                .tint(.white)
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("auth.password".localized)
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white)

                            HStack {
                                if showPassword {
                                    TextField("", text: $password, prompt: Text(isSignUp ? "auth.password_placeholder".localized : "••••••••").foregroundColor(.white.opacity(0.5)))
                                        .font(.custom("Poppins-Regular", size: 16))
                                        .foregroundColor(.white)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .password)
                                } else {
                                    SecureField("", text: $password, prompt: Text(isSignUp ? "auth.password_placeholder".localized : "••••••••").foregroundColor(.white.opacity(0.5)))
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
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(focusedField == .password ? Color.white.opacity(0.7) : Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            )
                            .tint(.white)
                        }

                        // Confirm Password (only for sign up)
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("auth.confirm_password".localized)
                                    .font(.custom("Poppins-Medium", size: 14))
                                    .foregroundColor(.white)

                                HStack {
                                    SecureField("", text: $confirmPassword, prompt: Text("auth.confirm_placeholder".localized).foregroundColor(.white.opacity(0.5)))
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
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(
                                                    focusedField == .confirmPassword ?
                                                    (passwordsMatch ? Color.green : Color.red) :
                                                        Color.white.opacity(0.12),
                                                    lineWidth: 1
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
                                    Text("auth.forgot_password".localized)
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
                        Group {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isSignUp ? "auth.create_my_account".localized : "auth.sign_in".localized)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.glassPrimary)
                    .padding(.horizontal, 32)
                    .disabled(authViewModel.isLoading || !isFormValid)

                    // Divider - Autre méthode
                    HStack(spacing: 16) {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                        Text("auth.other_method".localized)
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

                        if false {
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

                    Text("auth.google_title".localized)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("auth.google_subtitle".localized)
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
                        Text("auth.continue_with_google".localized)
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
                    Text("auth.other_method".localized)
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

                            Text("auth.email".localized)
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.glassSecondary)
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
            errorMessage = "auth.error.google_launch".localized
            isLoading = false
            return
        }

        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            errorMessage = "auth.error.google_config".localized
            isLoading = false
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = String(format: "auth.error.generic".localized, error.localizedDescription)
                }
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "auth.error.missing_info".localized
                }
                return
            }

            Task {
                do {
                    let signedIn = try await Auth.auth().signInWithGoogle(
                        idToken: idToken,
                        firstName: user.profile?.givenName
                    )
                    UserDefaults.standard.set(user.profile?.givenName ?? "auth.default_user_name".localized, forKey: "userFirstName")
                    UserDefaults.standard.set(signedIn.onboardingCompleted, forKey: "onboardingV2Completed")
                    await RevenueCatManager.shared.identifyUser(userId: signedIn.uid)

                    await MainActor.run {
                        isLoading = false
                        HapticManager.success()
                        onComplete()
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = String(format: "auth.error.generic".localized, error.localizedDescription)
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
    @State private var currentNonce: String?

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

                    Text("auth.apple_title".localized)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("auth.apple_subtitle".localized)
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
                    let nonce = authRandomNonce()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = authSHA256(nonce)
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
                    Text("auth.other_method".localized)
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
                    if false {
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

                    // Email
                    Button(action: {
                        HapticManager.light()
                        showEmailAuth = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)

                            Text("auth.email".localized)
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.glassSecondary)
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
                errorMessage = "auth.error.apple".localized
                return
            }

            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "auth.error.token".localized
                return
            }
            guard let nonce = currentNonce else {
                errorMessage = "auth.error.token".localized
                return
            }

            isLoading = true

            Task {
                do {
                    let firstName = appleIDCredential.fullName?.givenName
                    let user = try await Auth.auth().signInWithApple(
                        identityToken: idTokenString,
                        rawNonce: nonce,
                        firstName: firstName
                    )
                    if let firstName, !firstName.isEmpty {
                        UserDefaults.standard.set(firstName, forKey: "userFirstName")
                    }
                    UserDefaults.standard.set(user.onboardingCompleted, forKey: "onboardingV2Completed")
                    await RevenueCatManager.shared.identifyUser(userId: user.uid)

                    await MainActor.run {
                        isLoading = false
                        HapticManager.success()
                        onComplete()
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = String(format: "auth.error.generic".localized, error.localizedDescription)
                    }
                }
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = String(format: "auth.error.generic".localized, error.localizedDescription)
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
