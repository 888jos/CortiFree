//
//  AvatarProgressCard.swift
//  CortiFree
//
//  Carte avatar minimaliste avec grille de progression 66 jours
//

import SwiftUI
import FirebaseAuth

struct AvatarProgressCard: View {
    @State private var completedDays: Int = 23
    @State private var currentDay: Int = 24
    @State private var isPressed: Bool = false
    @State private var isFlipped: Bool = false
    @State private var startDate: Date = Date()
    @State private var currentStreak: Int = 5
    @State private var bestStreak: Int = 12

    private let totalDays = 66
    private let columns = 8   // 8 colonnes pour cellules plus grandes
    private let rows = 9      // 9 lignes (72 cases, on n'affiche que 66)

    var body: some View {
        ZStack {
            // RECTO - Avatar with grid
            frontCard
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )

            // VERSO - Stats motivantes
            backCard
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(width: 240, height: 320)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            HapticManager.light()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
        .onAppear {
            loadProgress()
        }
    }

    // MARK: - Front Card (Recto)

    private var frontCard: some View {
        ZStack(alignment: .bottom) {
            // Avatar image
            Image("profile_avatar")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 240)
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            // Grid overlay INSIDE the image, in the last quarter
            VStack(spacing: 0) {
                // Grid of 66 days with sequential reveal animation
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(12), spacing: 3), count: columns), spacing: 3) {
                    ForEach(0..<totalDays, id: \.self) { day in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(dayColor(for: day))
                            .frame(width: 12, height: 12)
                            .opacity(day >= currentDay ? 0.3 : 1.0)
                            .cascadeAppear(index: day, totalCount: totalDays, baseDelay: 0.01)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)

                // Date and username row
                HStack {
                    Text(formatStartDate(startDate))
                        .font(.custom("Poppins-Medium", size: 10))
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    Text(getUserFirstName())
                        .font(.custom("Poppins-SemiBold", size: 10))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .padding(.bottom, 8)
            .background(
                Color.black.opacity(0.15)
            )
        }
        .frame(width: 240, height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    // MARK: - Back Card (Verso)

    private var backCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "B794F6"))

                Text("MA PROGRESSION")
                    .font(.custom("Poppins-Bold", size: 16))
                    .foregroundColor(.white)
            }
            .padding(.top, 20)
            .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Stats principales
                    VStack(spacing: 8) {
                        Text("\(completedDays)/\(totalDays) jours")
                            .font(.custom("HankenGrotesk-Bold", size: 32))
                            .foregroundColor(.white)

                        Text("\(progressPercentage)% complété")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    // Barre de progression
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "B794F6"), Color(hex: "B794F6").opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * (Double(completedDays) / Double(totalDays)), height: 8)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 16)

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)

                    // Streaks
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "FF8800"))
                                Text("\(currentStreak)j")
                                    .font(.custom("HankenGrotesk-Bold", size: 20))
                                    .foregroundColor(.white)
                            }
                            Text("Streak actuel")
                                .font(.custom("Poppins-Regular", size: 10))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "FFD700"))
                                Text("\(bestStreak)j")
                                    .font(.custom("HankenGrotesk-Bold", size: 20))
                                    .foregroundColor(.white)
                            }
                            Text("Meilleur")
                                .font(.custom("Poppins-Regular", size: 10))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)

                    // Dates
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                            Text("Début: \(formatFullDate(startDate))")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                        }

                        HStack {
                            Image(systemName: "flag.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "B794F6"))
                            Text("Fin prévue: \(formatFullDate(endDate))")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 16)

                    // Message motivant
                    VStack(spacing: 8) {
                        Text(motivationalMessage)
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(Color(hex: "B794F6"))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

                        if let nextMilestone = nextBadgeMilestone {
                            Text(nextMilestone)
                                .font(.custom("Poppins-Regular", size: 11))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "B794F6").opacity(0.15))
                    )
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 16)
            }
        }
        .frame(width: 240, height: 320)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "1A1B3A"),
                    Color(hex: "0D0E1F")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    private func dayColor(for day: Int) -> Color {
        if day < completedDays {
            return Color(hex: "B794F6") // Violet for completed
        } else if day == currentDay - 1 {
            return Color(hex: "B794F6").opacity(0.5) // Current day
        } else {
            return Color.white.opacity(0.2) // Future days
        }
    }

    private func loadProgress() {
        // Load from UserDefaults
        if let savedDay = UserDefaults.standard.value(forKey: "currentProgramDay") as? Int {
            currentDay = savedDay
            completedDays = savedDay - 1
        }

        // Load start date
        if let savedDate = UserDefaults.standard.value(forKey: "programStartDate") as? Date {
            startDate = savedDate
        }
    }

    private func getUserFirstName() -> String {
        if let user = Auth.auth().currentUser {
            if let displayName = user.displayName {
                return displayName.components(separatedBy: " ").first ?? "Champion"
            } else if let email = user.email {
                return email.components(separatedBy: "@").first ?? "Champion"
            }
        }
        return "Champion"
    }

    private func formatStartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }

    // MARK: - Computed Properties for Back Card

    private var progressPercentage: Int {
        guard totalDays > 0 else { return 0 }
        return Int((Double(completedDays) / Double(totalDays)) * 100)
    }

    private var endDate: Date {
        Calendar.current.date(byAdding: .day, value: totalDays, to: startDate) ?? startDate
    }

    private var motivationalMessage: String {
        let percentage = progressPercentage
        if percentage < 10 {
            return "Chaque grand voyage commence par un premier pas !"
        } else if percentage < 25 {
            return "Tu es sur la bonne voie, continue comme ça !"
        } else if percentage < 50 {
            return "Tu as déjà accompli \(percentage)% du chemin, bravo !"
        } else if percentage < 75 {
            return "Plus de la moitié ! Tu es incroyable !"
        } else if percentage < 100 {
            return "La ligne d'arrivée est proche, ne lâche rien !"
        } else {
            return "Programme complété ! Tu es une légende ! 🏆"
        }
    }

    private var nextBadgeMilestone: String? {
        let milestones = [3, 7, 14, 21, 30, 40, 50, 60, 66]
        let badgeTitles = ["Débutant", "Motivé", "Déterminé", "Engagé", "Assidu", "Champion", "Invincible", "Légende", "Maître"]

        for (index, milestone) in milestones.enumerated() {
            if completedDays < milestone {
                let daysLeft = milestone - completedDays
                return "Plus que \(daysLeft) jour\(daysLeft > 1 ? "s" : "") pour le badge '\(badgeTitles[index])' !"
            }
        }

        return nil // All badges unlocked
    }
}

struct AvatarProgressCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AvatarProgressCard()
                .padding()
                .frame(height: 300)
        }
    }
}