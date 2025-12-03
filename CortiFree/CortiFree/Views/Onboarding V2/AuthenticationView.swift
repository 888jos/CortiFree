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
import GoogleSignIn
import GoogleSignInSwift

struct AuthenticationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var languageManager = LanguageManager.shared
    @State private var showEmailAuth = false
    @State private var showGoogleAuth = false
    @State private var showAppleAuth = false
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

                    Text("onboarding_v2.auth.create_account_message".localized)
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
                .padding(.top, 60)

                Spacer()

                // Lottie animation
                LottieView(filename: "Flower Animation", loopMode: .loop)
                    .frame(width: 320, height: 320)
                    .padding(.bottom, 32)

                // Authentication buttons
                VStack(spacing: 16) {
                    // Continue with Apple
                    Button(action: {
                        HapticManager.light()
                        showAppleAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20))
                                .foregroundColor(.white)

                            Text("onboarding_v2.auth.apple_button".localized)
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

                    // Continue with Google
                    Button(action: {
                        HapticManager.light()
                        showGoogleAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image("GoogleLogoWhite")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)

                            Text("onboarding_v2.auth.google_button".localized)
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

                    // Continue with Email
                    Button(action: {
                        HapticManager.light()
                        showEmailAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)

                            Text("onboarding_v2.auth.email_button".localized)
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

                // Track auth completion
                if let userId = Auth.auth().currentUser?.uid {
                    MixpanelManager.shared.trackOnboardingAuthenticationCompleted(
                        authMethod: "email",
                        userId: userId
                    )
                }

                onComplete()
            })
        }
        .fullScreenCover(isPresented: $showGoogleAuth) {
            GoogleAuthView(onComplete: {
                showGoogleAuth = false

                // Track auth completion
                if let userId = Auth.auth().currentUser?.uid {
                    MixpanelManager.shared.trackOnboardingAuthenticationCompleted(
                        authMethod: "google",
                        userId: userId
                    )
                }

                onComplete()
            })
        }
        .fullScreenCover(isPresented: $showAppleAuth) {
            AppleAuthView(onComplete: {
                showAppleAuth = false

                // Track auth completion
                if let userId = Auth.auth().currentUser?.uid {
                    MixpanelManager.shared.trackOnboardingAuthenticationCompleted(
                        authMethod: "apple",
                        userId: userId
                    )
                }

                onComplete()
            })
        }
        .onAppear {
            // Track authentication screen view
            MixpanelManager.shared.trackOnboardingAuthenticationViewed(firstName: firstName)
        }
    }

    // MARK: - Authentication Methods

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = NSLocalizedString("error.auth.apple_error", comment: "")
                return
            }

            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = NSLocalizedString("error.auth.token_error", comment: "")
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
        // Google Sign In not implemented - fallback to email auth
        showEmailAuth = true
    }
}

// MARK: - Email Authentication View

struct EmailAuthView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var languageManager = LanguageManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var isSignUp = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false
    @State private var showGoogleAuth = false
    @State private var showAppleAuth = false
    @FocusState private var focusedField: Field?

    enum Field {
        case username, email, password, confirmPassword
    }

    var onComplete: () -> Void

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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text(isSignUp ? "onboarding_v2.auth.create_account".localized : "onboarding_v2.auth.login".localized)
                                .font(.custom("Poppins-Bold", size: 28))
                                .foregroundColor(.white)

                            Text(isSignUp ? "onboarding_v2.auth.enter_info".localized : "onboarding_v2.auth.enter_credentials".localized)
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 32)
                        .padding(.top, 20)

                        // Form fields
                        VStack(spacing: 16) {
                            // Username (only for sign up)
                            if isSignUp {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("onboarding_v2.auth.first_name_label".localized)
                                        .font(.custom("Poppins-Medium", size: 14))
                                        .foregroundColor(.white)

                                    TextField("", text: $username, prompt: Text("onboarding_v2.auth.first_name".localized).foregroundColor(.white.opacity(0.5)))
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

                                TextField("", text: $email, prompt: Text("onboarding_v2.auth.email_placeholder".localized).foregroundColor(.white.opacity(0.5)))
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
                                Text("onboarding_v2.auth.password_label".localized)
                                    .font(.custom("Poppins-Medium", size: 14))
                                    .foregroundColor(.white)

                                HStack {
                                    if showPassword {
                                        TextField("", text: $password, prompt: Text(isSignUp ? "onboarding_v2.auth.password_min_chars".localized : "••••••••").foregroundColor(.white.opacity(0.5)))
                                            .font(.custom("Poppins-Regular", size: 16))
                                            .foregroundColor(.white)
                                            .textInputAutocapitalization(.never)
                                            .focused($focusedField, equals: .password)
                                    } else {
                                        SecureField("", text: $password, prompt: Text(isSignUp ? "onboarding_v2.auth.password_min_chars".localized : "••••••••").foregroundColor(.white.opacity(0.5)))
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
                                    Text("onboarding_v2.auth.confirm_password_label".localized)
                                        .font(.custom("Poppins-Medium", size: 14))
                                        .foregroundColor(.white)

                                    HStack {
                                        SecureField("", text: $confirmPassword, prompt: Text("onboarding_v2.auth.confirm_placeholder".localized).foregroundColor(.white.opacity(0.5)))
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
                        }
                        .padding(.horizontal, 32)

                        // Error message
                        if let errorMessage = errorMessage {
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
                        Button(action: handleAuth) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "1A1A4E")))
                            } else {
                                Text(isSignUp ? "onboarding_v2.auth.create_my_account".localized : "onboarding_v2.auth.sign_in".localized)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                    .foregroundColor(Color(hex: "1A1A4E"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                        .padding(.horizontal, 32)
                        .disabled(isLoading || !isFormValid)
                        .opacity(isLoading || !isFormValid ? 0.6 : 1.0)

                        // Toggle sign up/in
                        Button(action: {
                            isSignUp.toggle()
                            errorMessage = nil
                        }) {
                            Text(isSignUp ? "onboarding_v2.auth.already_account_login".localized : "onboarding_v2.auth.no_account_signup".localized)
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        // Divider - Autre méthode
                        HStack(spacing: 16) {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                            Text("onboarding_v2.auth.other_method".localized)
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
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onTapGesture {
            focusedField = nil
        }
        .fullScreenCover(isPresented: $showAppleAuth) {
            AppleAuthView(onComplete: {
                showAppleAuth = false
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

    private func handleAuth() {
        errorMessage = nil

        // Validation
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "onboarding_v2.auth.fill_all_fields".localized
            return
        }

        if isSignUp {
            guard !username.isEmpty else {
                errorMessage = "onboarding_v2.auth.enter_first_name".localized
                return
            }

            guard password == confirmPassword else {
                errorMessage = "onboarding_v2.auth.passwords_dont_match".localized
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
    @ObservedObject var languageManager = LanguageManager.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showEmailAuth = false
    @State private var showAppleAuth = false

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background
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
                    Image("GoogleLogoWhite")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)

                    Text("onboarding_v2.auth.google_title".localized)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("onboarding_v2.auth.google_description".localized)
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
                        Text("onboarding_v2.auth.google_sign_in".localized)
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
                    Text("onboarding_v2.auth.other_method".localized)
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
            AppleAuthView(onComplete: {
                showAppleAuth = false
                onComplete()
            })
        }
        .fullScreenCover(isPresented: $showEmailAuth) {
            EmailAuthView(onComplete: {
                showEmailAuth = false
                onComplete()
            })
        }
    }

    private func handleGoogleSignIn() {
        isLoading = true
        errorMessage = nil

        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "onboarding_v2.auth.google_launch_error".localized
            isLoading = false
            return
        }

        // Get the client ID from GoogleService-Info.plist
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            errorMessage = "onboarding_v2.auth.google_config_missing".localized
            isLoading = false
            return
        }

        // Configure Google Sign In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // Start Google Sign In flow
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Erreur Google Sign In: \(error.localizedDescription)"
                }
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "onboarding_v2.auth.google_info_error".localized
                }
                return
            }

            // Create Firebase credential with Google tokens
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            // Sign in to Firebase with Google credential
            Task {
                do {
                    let authResult = try await Auth.auth().signIn(with: credential)

                    // Create/update user profile in Firestore
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

                    // Save firstName to UserDefaults for offline access
                    UserDefaults.standard.set(user.profile?.givenName ?? "Utilisateur", forKey: "userFirstName")

                    await MainActor.run {
                        isLoading = false
                        HapticManager.success()
                        onComplete()
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Erreur Firebase: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

// MARK: - Apple Authentication View

struct AppleAuthView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var languageManager = LanguageManager.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showEmailAuth = false
    @State private var showGoogleAuth = false

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background
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

                // Apple logo and title
                VStack(spacing: 24) {
                    // Apple logo (large)
                    Image(systemName: "apple.logo")
                        .font(.system(size: 60))
                        .foregroundColor(.white)

                    Text("onboarding_v2.auth.apple_title".localized)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("onboarding_v2.auth.apple_description".localized)
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
                    Text("onboarding_v2.auth.other_method".localized)
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
            GoogleAuthView(onComplete: {
                showGoogleAuth = false
                onComplete()
            })
        }
        .fullScreenCover(isPresented: $showEmailAuth) {
            EmailAuthView(onComplete: {
                showEmailAuth = false
                onComplete()
            })
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "onboarding_v2.auth.apple_error".localized
                return
            }

            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "onboarding_v2.auth.token_error".localized
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

                    // Get name from Apple credential (only provided on first sign-in)
                    let firstName = appleIDCredential.fullName?.givenName
                    let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")

                    // Create/update user profile in Firestore
                    var userData: [String: Any] = [
                        "uid": authResult.user.uid,
                        "email": authResult.user.email ?? appleIDCredential.email ?? "",
                        "createdAt": Timestamp(date: Date()),
                        "authProvider": "apple",
                        "lastLoginAt": Timestamp(date: Date())
                    ]

                    // Only add name fields if we got them (first sign-in only)
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

                    await MainActor.run {
                        isLoading = false
                        HapticManager.success()
                        onComplete()
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Erreur Firebase: \(error.localizedDescription)"
                    }
                }
            }

        case .failure(let error):
            // Don't show error for user cancellation
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "Erreur Apple Sign In: \(error.localizedDescription)"
            }
        }
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
