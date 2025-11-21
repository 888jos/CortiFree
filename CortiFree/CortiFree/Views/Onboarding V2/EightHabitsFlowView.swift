//
//  EightHabitsFlowView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Flow présentant les 8 habitudes clés avec leurs impacts
//

import SwiftUI

struct EightHabitsFlowView: View {
    let onComplete: () -> Void
    @State private var currentHabitIndex: Int = 0
    @State private var screenViewTime: Date?
    @State private var viewedHabits: Set<Int> = []

    // Les 8 habitudes avec leurs détails
    private let habits: [Habit] = [
        Habit(
            icon: "wind",
            title: "Respirer consciemment",
            benefits: [
                "Pratiquer des exercices de respiration profonde pendant 5 à 10 minutes active le système nerveux parasympathique et réduit le stress.",
                "La cohérence cardiaque améliore la variabilité de la fréquence cardiaque et renforce la résilience au stress.",
                "Une respiration consciente régulière améliore l'oxygénation des tissus et favorise la clarté mentale."
            ],
            impacts: [
                HabitImpact(emoji: "🫁", title: "Capacité\npulmonaire", value: "+12%"),
                HabitImpact(emoji: "😌", title: "Niveau de\nstress", value: "-15%"),
                HabitImpact(emoji: "❤️", title: "Santé\ncardiaque", value: "+10%")
            ]
        ),
        Habit(
            icon: "figure.mind.and.body",
            title: "Méditer",
            benefits: [
                "Méditer au moins 10 minutes par jour réduit les niveaux de cortisol et améliore la gestion du stress.",
                "La méditation de pleine conscience renforce la clarté mentale et la régulation émotionnelle.",
                "Une pratique régulière accroît la conscience de soi et favorise une meilleure prise de décision."
            ],
            impacts: [
                HabitImpact(emoji: "🧘", title: "Résilience\némotionnelle", value: "+12%"),
                HabitImpact(emoji: "📉", title: "Niveau de\ncortisol", value: "-14%"),
                HabitImpact(emoji: "🧠", title: "Focus\nmental", value: "+10%")
            ]
        ),
        Habit(
            icon: "book.pages",
            title: "Tenir un journal",
            benefits: [
                "Tenir un journal quotidien permet d'organiser ses pensées et de mieux comprendre ses émotions.",
                "L'écriture expressive réduit l'anxiété et améliore la gestion du stress chronique.",
                "La pratique du journaling favorise la gratitude et renforce le bien-être mental à long terme."
            ],
            impacts: [
                HabitImpact(emoji: "✍️", title: "Clarté\nmentale", value: "+15%"),
                HabitImpact(emoji: "💭", title: "Gestion\némotions", value: "+12%"),
                HabitImpact(emoji: "🙏", title: "Niveau de\ngratitude", value: "+18%")
            ]
        ),
        Habit(
            icon: "figure.walk",
            title: "Faire du sport",
            benefits: [
                "Bouger au moins 30 minutes par jour stimule la circulation sanguine et renforce le système cardiovasculaire.",
                "L'activité physique régulière libère des endorphines qui améliorent l'humeur et réduisent le stress.",
                "Le mouvement quotidien maintient la mobilité articulaire et prévient les douleurs chroniques."
            ],
            impacts: [
                HabitImpact(emoji: "💪", title: "Tonus\nmusculaire", value: "+10%"),
                HabitImpact(emoji: "😊", title: "Niveau\nd'endorphines", value: "+14%"),
                HabitImpact(emoji: "🦴", title: "Santé\narticulaire", value: "+12%")
            ]
        ),
        Habit(
            icon: "drop.fill",
            title: "Boire de l'eau",
            benefits: [
                "Boire suffisamment d'eau maintient une hydratation optimale et améliore les fonctions cognitives.",
                "Une bonne hydratation favorise l'élimination des toxines et améliore la santé de la peau.",
                "L'eau aide à réguler la température corporelle et soutient la digestion."
            ],
            impacts: [
                HabitImpact(emoji: "💧", title: "Niveau\nd'hydratation", value: "+20%"),
                HabitImpact(emoji: "🧠", title: "Clarté\nmentale", value: "+12%"),
                HabitImpact(emoji: "✨", title: "Qualité\npeau", value: "+14%")
            ]
        ),
        Habit(
            icon: "tree.fill",
            title: "Passer du temps en nature",
            benefits: [
                "Passer du temps dans la nature réduit le cortisol et améliore l'humeur générale.",
                "Le contact avec la nature renforce le système immunitaire et favorise la récupération mentale.",
                "Les activités en plein air augmentent les niveaux d'énergie et améliorent la qualité du sommeil."
            ],
            impacts: [
                HabitImpact(emoji: "🌳", title: "Connexion\nnature", value: "+20%"),
                HabitImpact(emoji: "🛡️", title: "Système\nimmunitaire", value: "+12%"),
                HabitImpact(emoji: "⚡", title: "Niveau\nd'énergie", value: "+14%")
            ]
        ),
        Habit(
            icon: "moon.zzz.fill",
            title: "Suivre une routine sommeil",
            benefits: [
                "Une routine de sommeil régulière améliore la qualité et la durée du repos nocturne.",
                "Un sommeil de qualité renforce le système immunitaire et favorise la récupération physique.",
                "Dormir suffisamment améliore la concentration, la mémoire et l'humeur."
            ],
            impacts: [
                HabitImpact(emoji: "😴", title: "Qualité\nsommeil", value: "+22%"),
                HabitImpact(emoji: "⚡", title: "Niveau\nd'énergie", value: "+18%"),
                HabitImpact(emoji: "🧠", title: "Performance\ncognitive", value: "+16%")
            ]
        ),
        Habit(
            icon: "person.2.fill",
            title: "Se connecter socialement",
            benefits: [
                "Les interactions sociales positives réduisent le stress et améliorent le bien-être émotionnel.",
                "Le soutien social renforce la résilience et aide à mieux gérer les défis quotidiens.",
                "Cultiver des relations enrichissantes augmente le sentiment d'appartenance et de bonheur."
            ],
            impacts: [
                HabitImpact(emoji: "👥", title: "Lien\nsocial", value: "+20%"),
                HabitImpact(emoji: "😊", title: "Bien-être\némotionnel", value: "+16%"),
                HabitImpact(emoji: "💪", title: "Résilience", value: "+14%")
            ]
        )
    ]

    private var currentHabit: Habit {
        habits[currentHabitIndex]
    }

    var body: some View {
        ZStack {
            // Solid dark purple background
            Color(hex: "1a0a2e")
                .ignoresSafeArea()

            // Main scrollable content
            VStack(spacing: 0) {
                // Title
                Text("Les 8 habitudes clés")
                    .font(.custom("Faro-BoldLucky", size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "B794F6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 60)
                    .padding(.bottom, 24)

                // Habit carousel with navigation arrows and dark starry background
                ZStack {
                    // Dark starry sky background with subtle organic curves
                    GeometryReader { geometry in
                        Path { path in
                            let width = geometry.size.width
                            let height: CGFloat = 180

                            // Très léger arrondi - 10px de déviation maximum
                            let curveDepth: CGFloat = 15

                            // Commence en haut à gauche
                            path.move(to: CGPoint(x: 0, y: 0))

                            // Ligne du haut avec légère voûte (descend au centre)
                            path.addQuadCurve(
                                to: CGPoint(x: width, y: 0),
                                control: CGPoint(x: width / 2, y: curveDepth)
                            )

                            // Ligne droite à droite
                            path.addLine(to: CGPoint(x: width, y: height))

                            // Ligne du bas avec légère bosse (monte au centre)
                            path.addQuadCurve(
                                to: CGPoint(x: 0, y: height),
                                control: CGPoint(x: width / 2, y: height - curveDepth)
                            )

                            // Ferme le path
                            path.closeSubpath()
                        }
                        .fill(Color(hex: "01000C"))
                    }
                    .frame(height: 180)

                    // Simple stars without gradient
                    Canvas { context, size in
                        // Add some simple stars
                        let starPositions: [(CGFloat, CGFloat)] = [
                            (0.15, 0.3), (0.25, 0.6), (0.35, 0.2), (0.45, 0.7),
                            (0.55, 0.4), (0.65, 0.8), (0.75, 0.3), (0.85, 0.6),
                            (0.2, 0.5), (0.4, 0.35), (0.6, 0.55), (0.8, 0.45),
                            (0.3, 0.75), (0.5, 0.25), (0.7, 0.65), (0.9, 0.35)
                        ]

                        for (x, y) in starPositions {
                            let starX = x * size.width
                            let starY = y * size.height
                            let starSize = CGFloat.random(in: 1.0...2.5)

                            let rect = CGRect(
                                x: starX - starSize / 2,
                                y: starY - starSize / 2,
                                width: starSize,
                                height: starSize
                            )

                            context.fill(
                                Path(ellipseIn: rect),
                                with: .color(.white.opacity(Double.random(in: 0.3...0.8)))
                            )
                        }
                    }
                    .frame(height: 180)
                    .mask(
                        GeometryReader { geometry in
                            Path { path in
                                let width = geometry.size.width
                                let height: CGFloat = 180
                                let curveDepth: CGFloat = 10

                                path.move(to: CGPoint(x: 0, y: 0))
                                path.addQuadCurve(
                                    to: CGPoint(x: width, y: 0),
                                    control: CGPoint(x: width / 2, y: curveDepth)
                                )
                                path.addLine(to: CGPoint(x: width, y: height))
                                path.addQuadCurve(
                                    to: CGPoint(x: 0, y: height),
                                    control: CGPoint(x: width / 2, y: height - curveDepth)
                                )
                                path.closeSubpath()
                            }
                            .fill(Color.white)
                        }
                    )

                    ZStack {
                        // Previous habit (left, 40% cut off on the left edge)
                        // Always visible - wraps to last habit when at index 0
                        let previousIndex = (currentHabitIndex - 1 + habits.count) % habits.count
                        HabitCard(habit: habits[previousIndex], habitIndex: previousIndex)
                            .opacity(0.3)
                            .scaleEffect(0.85)
                            .offset(x: -183)
                            .onTapGesture {
                                HapticManager.light()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentHabitIndex = previousIndex
                                }
                            }

                        // Current habit (center, full opacity)
                        HabitCard(habit: currentHabit, isSelected: true, habitIndex: currentHabitIndex)
                            .opacity(1.0)

                        // Next habit (right, 40% cut off on the right edge)
                        // Always visible - wraps to first habit when at last index
                        let nextIndex = (currentHabitIndex + 1) % habits.count
                        HabitCard(habit: habits[nextIndex], habitIndex: nextIndex)
                            .opacity(0.3)
                            .scaleEffect(0.85)
                            .offset(x: 183)
                            .onTapGesture {
                                HapticManager.light()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentHabitIndex = nextIndex
                                }
                            }

                        // Left arrow button - always visible
                        HStack {
                            Button(action: {
                                HapticManager.light()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentHabitIndex = (currentHabitIndex - 1 + habits.count) % habits.count
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                    )
                            }
                            .padding(.leading, 16)

                            Spacer()
                        }

                        // Right arrow button - always visible
                        HStack {
                            Spacer()

                            Button(action: {
                                HapticManager.light()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentHabitIndex = (currentHabitIndex + 1) % habits.count
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                    )
                            }
                            .padding(.trailing, 16)
                        }
                    }
                }
                .frame(height: 180)
                .clipped()
                .padding(.bottom, 24)

                // Benefits list
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(currentHabit.benefits, id: \.self) { benefit in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "B794F6"))
                                    .padding(.top, 4)

                                Text(highlightedBenefit(benefit))
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .lineSpacing(4)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)

                    // Impact section - Single rectangle
                    VStack(alignment: .leading, spacing: 16) {
                        // Title inside rectangle
                        Text("Impact après 10 semaines")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(hex: "B794F6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // All impacts in one row without separate cards
                        HStack(spacing: 12) {
                            ForEach(Array(currentHabit.impacts.enumerated()), id: \.element.title) { index, impact in
                                VStack(alignment: .leading, spacing: 8) {
                                    // Icon + Title
                                    HStack(spacing: 6) {
                                        Image(systemName: iconForEmoji(impact.emoji))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))

                                        Text(impact.title)
                                            .font(.custom("Poppins-Regular", size: 10))
                                            .foregroundColor(.white.opacity(0.7))
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    // Value with arrow
                                    HStack(spacing: 4) {
                                        Image(systemName: impact.value.hasPrefix("+") ? "arrow.up" : "arrow.down")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: impactColor(for: impact.value),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )

                                        Text(impact.value.replacingOccurrences(of: "+", with: "").replacingOccurrences(of: "-", with: ""))
                                            .font(.custom("Faro Lucky", size: 24, relativeTo: .title))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: impactColor(for: impact.value),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxWidth: .infinity)

                                // Vertical divider between impacts (except after last one)
                                if index < currentHabit.impacts.count - 1 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 1)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "B794F6").opacity(0.15),
                                        Color(hex: "B794F6").opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "B794F6").opacity(0.3),
                                                Color(hex: "D4B4FF").opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
                .id(currentHabitIndex)
            }
            .ignoresSafeArea(.keyboard)

            // Bottom button - Always on top with explicit hit testing
            VStack {
                Spacer()

                Button(action: {
                    print("🔘 EightHabitsFlowView: Bouton Continuer cliqué - Navigation vers NotificationPermissions")
                    HapticManager.medium()

                    // Track continue action with analytics
                    let timeSpent = screenViewTime.map { Date().timeIntervalSince($0) } ?? 0
                    MixpanelManager.shared.trackOnboardingEightHabitsContinue(
                        habitsViewedCount: viewedHabits.count,
                        timeSpent: timeSpent
                    )

                    onComplete()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))

                        Text("Continuer")
                            .font(.custom("Poppins-SemiBold", size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "B794F6"), Color(hex: "D4B4FF")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
                .allowsHitTesting(true)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .zIndex(100)
        }
        .background(Color.black.opacity(0.001))
        .onAppear {
            screenViewTime = Date()
            viewedHabits.insert(currentHabitIndex)
            MixpanelManager.shared.trackOnboardingEightHabitsFlowViewed()
        }
        .onChange(of: currentHabitIndex) { newIndex in
            viewedHabits.insert(newIndex)
        }
    }

    // MARK: - Helper Function

    private func highlightedBenefit(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        attributedString.foregroundColor = .white

        // Bénéfices complets à mettre en bleu
        let keywords = [
            "réduit le stress",
            "améliore l'humeur",
            "renforce le système immunitaire",
            "améliore la qualité du sommeil",
            "améliore la concentration",
            "favorise la clarté mentale",
            "augmente les niveaux d'énergie"
        ]

        for keyword in keywords {
            if let range = attributedString.range(of: keyword, options: .caseInsensitive) {
                attributedString[range].foregroundColor = Color(hex: "B794F6")
            }
        }

        return attributedString
    }

    private func iconForEmoji(_ emoji: String) -> String {
        switch emoji {
        case "🫁": return "lungs.fill"
        case "😌", "😊": return "face.smiling"
        case "❤️": return "heart.fill"
        case "🧘": return "figure.mind.and.body"
        case "📉": return "chart.line.downtrend.xyaxis"
        case "🧠": return "brain.head.profile"
        case "✍️": return "pencil.line"
        case "💭": return "bubble.left.fill"
        case "🙏": return "hands.sparkles.fill"
        case "💪": return "dumbbell.fill"
        case "🦴": return "figure.flexibility"
        case "💧": return "drop.fill"
        case "✨": return "sparkles"
        case "🌳": return "tree.fill"
        case "🛡️": return "shield.fill"
        case "⚡": return "bolt.fill"
        case "😴": return "moon.zzz.fill"
        case "👥": return "person.2.fill"
        default: return "star.fill"
        }
    }

    private func impactColor(for value: String) -> [Color] {
        // All impacts use purple gradient
        return [Color(hex: "B794F6"), Color(hex: "D4B4FF")]
    }
}

// MARK: - Habit Model

struct Habit {
    let icon: String
    let title: String
    let benefits: [String]
    let impacts: [HabitImpact]
}

struct HabitImpact {
    let emoji: String
    let title: String
    let value: String
}

// MARK: - Habit Card

struct HabitCard: View {
    let habit: Habit
    var isSelected: Bool = false
    var habitIndex: Int = 0

    private var backgroundImage: String {
        switch habitIndex {
        case 0: return "habit_breathe"      // Respirer consciemment
        case 1: return "habit_meditate"     // Méditer
        case 2: return "habit_water"        // Tenir un journal (inversé avec eau)
        case 3: return "habit_nature"       // Faire du sport (inversé avec nature)
        case 4: return "habit_journal"      // Boire de l'eau (inversé avec journal)
        case 5: return "habit_sleep"        // Passer du temps en nature (inversé avec sleep après sport)
        case 6: return "habit_sport"        // Suivre une routine sommeil (inversé avec nature après sport)
        case 7: return "habit_social"       // Se connecter socialement
        default: return "habit_breathe"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: habit.icon)
                .font(.system(size: 32))
                .foregroundColor(.white)

            Text(habit.title)
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 12)
        }
        .frame(width: 180, height: 140)
        .background(
            ZStack {
                // Background image
                Image(backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                // Dark overlay for readability
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.5))

                // Border
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.3), lineWidth: 3)
            }
        )
        .padding(.horizontal, 8)
    }
}

#Preview {
    EightHabitsFlowView(onComplete: {})
}
