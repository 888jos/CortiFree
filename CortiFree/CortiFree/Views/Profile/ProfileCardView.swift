//
//  ProfileCardView.swift
//  CortiFree
//
//  Carte de profil avec avatar et progression 66 jours
//

import SwiftUI
import FirebaseAuth

struct ProfileCardView: View {
    // Removed ProgressionManager - using scoring system instead
    @State private var completedDays: Int = 23 // Nombre de jours complétés
    @State private var currentDay: Int = 24 // Jour actuel du programme
    @State private var userName: String = ""
    @State private var userLevel: String = "" // Deprecated - no longer using levels
    @State private var globalScore: Int = 0
    @State private var globalStreak: Int = 0

    private let totalDays = 66
    private let columns = 9  // 9 colonnes pour mieux remplir l'espace
    private let rows = 8     // 8 lignes (72 carrés max, on affiche 66)

    var body: some View {
        VStack(spacing: 0) {
            // Avatar Section (2/3 de la carte)
            VStack(spacing: 16) {
                // Avatar circle
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [
                                Color(hex: "B794F6").opacity(0.2),
                                Color(hex: "9F7AEA").opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

                    // Profile avatar SVG
                    Image("profile_avatar")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                }

                // User info
                VStack(spacing: 4) {
                    Text(userName.isEmpty ? getUserName() : userName)
                        .font(.custom("Poppins-SemiBold", size: 24))
                        .foregroundColor(.white)

                    // Removed level display - no longer using XP/Levels system
                    Text("Score Global: \(globalScore)")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }

                // Stats row
                HStack(spacing: 32) {
                    // Days completed
                    VStack(spacing: 2) {
                        Text("\(completedDays)")
                            .font(.custom("Poppins-Bold", size: 20))
                            .foregroundColor(.white)
                        Text("jours")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    // Streak
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                            Text("\(globalStreak)")
                                .font(.custom("Poppins-Bold", size: 20))
                                .foregroundColor(.white)
                        }
                        Text("série")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    // Score
                    VStack(spacing: 2) {
                        Text("\(globalScore)")
                            .font(.custom("Poppins-Bold", size: 20))
                            .foregroundColor(.white)
                        Text("score")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)

            Divider()
                .background(Color.white.opacity(0.1))

            // Progress Grid Section (1/3 de la carte)
            VStack(spacing: 12) {
                // Title
                HStack {
                    Text("Programme 66 jours")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    Text("Jour \(currentDay)/66")
                        .font(.custom("Poppins-SemiBold", size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 16)

                // Grid of 66 days - 9 columns x 8 rows (last row has 3 empty spaces)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 3), count: columns), spacing: 3) {
                    ForEach(0..<totalDays, id: \.self) { day in
                        DaySquare(
                            dayNumber: day + 1,
                            isCompleted: day < completedDays,
                            isCurrent: day == currentDay - 1,
                            isLocked: day >= currentDay
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            .background(
                Color.white.opacity(0.05)
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1a0a2e"),
                            Color(hex: "0A0515")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        .onAppear {
            loadUserData()
        }
    }

    // MARK: - Helper Functions

    private func getUserName() -> String {
        if let user = Auth.auth().currentUser {
            return user.displayName ?? user.email?.components(separatedBy: "@").first ?? "Utilisateur"
        }
        return "Utilisateur"
    }

    private func getLevelName(_ level: Int) -> String {
        switch level {
        case 1: return "Débutant Serein"
        case 2: return "Novice Apaisé"
        case 3: return "Apprenti Zen"
        case 4: return "Pratiquant Éveillé"
        case 5: return "Méditant Confirmé"
        case 6: return "Expert du Calme"
        case 7: return "Maître du Calme"
        case 8: return "Guru Paisible"
        case 9: return "Sage Éclairé"
        case 10: return "Légende Immortelle"
        default: return level > 10 ? "Maître Suprême" : "Novice"
        }
    }

    private func loadUserData() {
        // Load real data from UserDefaults or Firebase
        if let savedDay = UserDefaults.standard.value(forKey: "currentProgramDay") as? Int {
            currentDay = savedDay
            completedDays = savedDay - 1
        }

        if let savedScore = UserDefaults.standard.value(forKey: "globalScore") as? Int {
            globalScore = savedScore
        } else {
            globalScore = 45 // Default
        }

        if let savedStreak = UserDefaults.standard.value(forKey: "globalStreak") as? Int {
            globalStreak = savedStreak
        }
    }
}

// Individual Day Square
struct DaySquare: View {
    let dayNumber: Int
    let isCompleted: Bool
    let isCurrent: Bool
    let isLocked: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
                .frame(width: 28, height: 28)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            } else if isCurrent {
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
            }
        }
        .opacity(isLocked && !isCurrent ? 0.3 : 1.0)
    }

    private var backgroundColor: Color {
        if isCompleted {
            return Color(hex: "B794F6")
        } else if isCurrent {
            return Color(hex: "B794F6").opacity(0.5)
        } else if isLocked {
            return Color.white.opacity(0.1)
        } else {
            return Color.white.opacity(0.2)
        }
    }
}

struct ProfileCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ProfileCardView()
                .padding()
        }
    }
}