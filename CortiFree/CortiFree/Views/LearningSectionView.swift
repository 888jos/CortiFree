//
//  LearningSectionView.swift
//  CortiFree
//
//  Created by Claude on 18/11/2025.
//  Section Apprendre avec navigation par catégories
//

import SwiftUI

struct LearningSectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: LearningCategory?
    @State private var selectedCard: LearningCard?

    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                colors: [
                    Color(hex: "0A0515"),
                    Color(hex: "1a0a2e"),
                    Color(hex: "16082e"),
                    Color(hex: "0A0515")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if let category = selectedCategory {
                // Show cards in selected category
                CategoryCardsView(
                    category: category,
                    onBack: { selectedCategory = nil },
                    onCardSelected: { card in selectedCard = card }
                )
            } else {
                // Show category grid
                CategoriesGridView(onCategorySelected: { category in
                    selectedCategory = category
                })
            }
        }
        .fullScreenCover(item: $selectedCard) { card in
            LearningCardDetailView(card: card)
        }
    }
}

// MARK: - Categories Grid View

struct CategoriesGridView: View {
    @Environment(\.dismiss) private var dismiss
    let onCategorySelected: (LearningCategory) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Title with accent bar
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "F97316"),
                                    Color(hex: "FB923C")
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 4, height: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apprendre")
                            .font(.custom("HankenGrotesk-Bold", size: 32))
                            .tracking(0.5)
                            .foregroundColor(.white)

                        Text("Découvre les secrets de la gestion du stress")
                            .font(.custom("Poppins-Regular", size: 14))
                            .tracking(0.3)
                            .foregroundColor(.white.opacity(0.65))
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "B794F6").opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140)
                .ignoresSafeArea(edges: .top)
            )

            // Categories
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(LearningCategory.allCategories) { category in
                        CategoryCardView(category: category) {
                            HapticManager.medium()
                            onCategorySelected(category)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Category Card View

struct CategoryCardView: View {
    let category: LearningCategory
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    category.color.opacity(0.25),
                                    category.color.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    category.color.opacity(0.6),
                                    category.color.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )

                    Image(systemName: category.icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(category.color)
                        .shadow(color: category.color.opacity(0.3), radius: 8)
                }
                .frame(width: 80, height: 80)

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(category.name)
                        .font(.custom("HankenGrotesk-Bold", size: 20))
                        .tracking(0.4)
                        .foregroundColor(.white)

                    Text("\(category.cardCount) articles")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                category.color.opacity(0.9),
                                category.color.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.10),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    category.color.opacity(0.4),
                                    category.color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .shadow(
                            color: category.color.opacity(0.2),
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                }
            )
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .brightness(isPressed ? 0.05 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Cards View

struct CategoryCardsView: View {
    let category: LearningCategory
    let onBack: () -> Void
    let onCardSelected: (LearningCard) -> Void

    var filteredCards: [LearningCard] {
        LearningCard.allCards.filter { $0.category == category.name }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack(spacing: 16) {
                Button(action: {
                    HapticManager.light()
                    onBack()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.custom("HankenGrotesk-Bold", size: 28))
                        .tracking(0.5)
                        .foregroundColor(.white)

                    Text("\(filteredCards.count) articles")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.65))
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)

            // Cards
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(filteredCards) { card in
                        LearningCardView(card: card) {
                            onCardSelected(card)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Learning Card View

struct LearningCardView: View {
    let card: LearningCard
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.medium()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                action()
            }
        }) {
            HStack(spacing: 16) {
                // Premium Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    card.categoryColor.opacity(0.25),
                                    card.categoryColor.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    card.categoryColor.opacity(0.6),
                                    card.categoryColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )

                    Image(systemName: card.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(card.categoryColor)
                        .shadow(color: card.categoryColor.opacity(0.3), radius: 6)
                }
                .frame(width: 64, height: 64)

                // Content
                VStack(alignment: .leading, spacing: 7) {
                    Text(card.title)
                        .font(.custom("HankenGrotesk-Bold", size: 17))
                        .tracking(0.3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(1.2)

                    Text(card.shortDescription)
                        .font(.custom("Poppins-Regular", size: 14))
                        .tracking(0.2)
                        .lineSpacing(1.4)
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                card.categoryColor.opacity(0.9),
                                card.categoryColor.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .padding(18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.10),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    card.categoryColor.opacity(0.4),
                                    card.categoryColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .shadow(
                            color: card.categoryColor.opacity(0.2),
                            radius: 12,
                            x: 0,
                            y: 4
                        )

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .padding(1)
                }
            )
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .brightness(isPressed ? 0.05 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Learning Card Detail View

struct LearningCardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let card: LearningCard

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "0A0515"),
                    Color(hex: "1a0a2e"),
                    Color(hex: "16082e"),
                    Color(hex: "0A0515")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Back button
                    HStack {
                        Button(action: {
                            HapticManager.light()
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                )
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 28)

                    // Icon and category
                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            card.categoryColor.opacity(0.3),
                                            card.categoryColor.opacity(0.1),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 30,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 120, height: 120)

                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            card.categoryColor.opacity(0.25),
                                            card.categoryColor.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)

                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            card.categoryColor.opacity(0.7),
                                            card.categoryColor.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: 90, height: 90)

                            Image(systemName: card.icon)
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(card.categoryColor)
                                .shadow(color: card.categoryColor.opacity(0.4), radius: 8)
                        }

                        Text(card.category.uppercased())
                            .font(.custom("HankenGrotesk-SemiBold", size: 12))
                            .tracking(1.2)
                            .foregroundColor(card.categoryColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                card.categoryColor.opacity(0.25),
                                                card.categoryColor.opacity(0.12)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(card.categoryColor.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.bottom, 24)

                    // Title
                    Text(card.title)
                        .font(.custom("HankenGrotesk-Bold", size: 28))
                        .tracking(0.4)
                        .lineSpacing(1.3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 32)

                    // Sections
                    VStack(spacing: 24) {
                        ForEach(card.sections) { section in
                            ContentSectionView(section: section, color: card.categoryColor)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

// MARK: - Content Section View

struct ContentSectionView: View {
    let section: ContentSection
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 12) {
                Image(systemName: section.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        color.opacity(0.2),
                                        color.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

                Text(section.title)
                    .font(.custom("HankenGrotesk-Bold", size: 18))
                    .tracking(0.3)
                    .foregroundColor(.white)
            }

            // Section content
            Text(section.content)
                .font(.custom("Poppins-Regular", size: 15))
                .tracking(0.3)
                .lineSpacing(7)
                .foregroundColor(.white.opacity(0.88))
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(0.3),
                                color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
    }
}

// MARK: - Models

struct LearningCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let cardCount: Int

    static let allCategories: [LearningCategory] = [
        LearningCategory(
            name: "Science",
            icon: "flask.fill",
            color: Color(hex: "B794F6"),
            cardCount: 5
        ),
        LearningCategory(
            name: "Santé",
            icon: "heart.fill",
            color: Color(hex: "F97316"),
            cardCount: 2
        ),
        LearningCategory(
            name: "Techniques",
            icon: "sparkles",
            color: Color(hex: "10B981"),
            cardCount: 4
        ),
        LearningCategory(
            name: "Habitudes",
            icon: "calendar",
            color: Color(hex: "3B82F6"),
            cardCount: 5
        ),
        LearningCategory(
            name: "Psychologie",
            icon: "brain.head.profile",
            color: Color(hex: "EC4899"),
            cardCount: 2
        )
    ]
}

struct ContentSection: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let content: String
}

struct LearningCard: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let category: String
    let shortDescription: String
    let sections: [ContentSection]

    var categoryColor: Color {
        switch category {
        case "Science":
            return Color(hex: "B794F6")
        case "Santé":
            return Color(hex: "F97316")
        case "Techniques":
            return Color(hex: "10B981")
        case "Habitudes":
            return Color(hex: "3B82F6")
        case "Psychologie":
            return Color(hex: "EC4899")
        default:
            return Color(hex: "B794F6")
        }
    }

    static let allCards: [LearningCard] = [
        // SCIENCE CATEGORY
        LearningCard(
            icon: "brain.head.profile",
            title: "Le cortisol, c'est quoi ?",
            category: "Science",
            shortDescription: "Comprendre l'hormone du stress",
            sections: [
                ContentSection(
                    icon: "info.circle.fill",
                    title: "Introduction",
                    content: "Le cortisol est souvent appelé \"l'hormone du stress\". Il est produit par les glandes surrénales et joue un rôle essentiel dans la réponse de ton corps au stress."
                ),
                ContentSection(
                    icon: "sparkles",
                    title: "Rôles positifs du cortisol",
                    content: """
                    • Régule ton niveau d'énergie tout au long de la journée
                    • Aide à gérer les situations difficiles et stressantes
                    • Contrôle la pression artérielle et la glycémie
                    • Réduit l'inflammation dans le corps
                    • Participe au métabolisme des graisses, protéines et glucides
                    • Régule le cycle veille-sommeil (rythme circadien)
                    """
                ),
                ContentSection(
                    icon: "exclamationmark.triangle.fill",
                    title: "Problèmes d'un excès chronique",
                    content: """
                    • Anxiété chronique et troubles du sommeil
                    • Prise de poids (surtout au niveau abdominal)
                    • Système immunitaire affaibli
                    • Hypertension artérielle
                    • Difficulté de concentration et problèmes de mémoire
                    • Vieillissement prématuré de la peau
                    • Fatigue persistante malgré le repos
                    • Troubles digestifs
                    """
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: "Les niveaux normaux",
                    content: "Le cortisol suit un rythme naturel : élevé le matin (pic vers 8h) pour te réveiller, puis diminue progressivement dans la journée pour être au plus bas le soir (vers 23h) et te permettre de dormir."
                ),
                ContentSection(
                    icon: "target",
                    title: "L'objectif de CortiFree",
                    content: "T'aider à maintenir un niveau de cortisol sain et équilibré grâce à des habitudes scientifiquement prouvées qui régulent naturellement cette hormone."
                )
            ]
        ),
        LearningCard(
            icon: "figure.mind.and.body",
            title: "La science de la méditation",
            category: "Science",
            shortDescription: "Ce que disent les neurosciences",
            sections: [
                ContentSection(
                    icon: "flask.fill",
                    title: "Preuves scientifiques",
                    content: """
                    Des milliers d'études scientifiques ont démontré les bienfaits de la méditation :

                    • Épaississement du cortex préfrontal
                    • Réduction de l'amygdale (centre de la peur)
                    • Augmentation de la matière grise
                    """
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: "Résultats mesurables",
                    content: """
                    • -30% de cortisol après 8 semaines
                    • Amélioration de 40% de la concentration
                    • Réduction de 50% des symptômes anxieux
                    """
                ),
                ContentSection(
                    icon: "clock.fill",
                    title: "Durée nécessaire",
                    content: "Des changements cérébraux visibles apparaissent après seulement 8 semaines de pratique quotidienne de 10-15 minutes.\n\nTu es déjà sur la bonne voie avec CortiFree !"
                )
            ]
        ),
        LearningCard(
            icon: "book.fill",
            title: "Les 66 jours pour former une habitude",
            category: "Science",
            shortDescription: "Pourquoi le programme dure 66 jours",
            sections: [
                ContentSection(
                    icon: "flask.fill",
                    title: "L'étude de référence",
                    content: """
                    • University College London (2009)
                    • 66 jours = temps moyen pour automatiser une habitude
                    • Varie de 18 à 254 jours selon la complexité
                    """
                ),
                ContentSection(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Les 3 phases",
                    content: """
                    1. Semaines 1-3 : Période d'effort conscient
                    2. Semaines 4-7 : Début d'automatisation
                    3. Semaines 8-10 : Habitude ancrée
                    """
                ),
                ContentSection(
                    icon: "figure.strengthtraining.traditional",
                    title: "Pourquoi ça marche",
                    content: """
                    • Création de nouvelles connexions neuronales
                    • Renforcement progressif
                    • Transformation en réflexe automatique
                    """
                ),
                ContentSection(
                    icon: "target",
                    title: "Ton objectif",
                    content: "À la fin des 66 jours, tes nouvelles habitudes anti-stress feront partie intégrante de ta vie !"
                )
            ]
        ),
        LearningCard(
            icon: "brain",
            title: "La neuroplasticité : ton cerveau peut changer",
            category: "Science",
            shortDescription: "Comment ton cerveau s'adapte et évolue",
            sections: [
                ContentSection(
                    icon: "brain.head.profile",
                    title: "Ce que cela signifie",
                    content: """
                    La neuroplasticité est la capacité de ton cerveau à se recâbler et à créer de nouvelles connexions neuronales tout au long de ta vie.

                    • Ton cerveau n'est pas figé, il évolue constamment
                    • Chaque nouvelle habitude crée de nouveaux circuits neuronaux
                    • Les vieilles habitudes peuvent être "désapprises"
                    • Plus tu pratiques, plus les connexions se renforcent
                    """
                ),
                ContentSection(
                    icon: "flask.fill",
                    title: "Preuves scientifiques",
                    content: """
                    • Des scans IRM montrent des changements structurels après 8 semaines de méditation
                    • Les zones du cerveau liées au stress (amygdale) peuvent diminuer de volume
                    • Les zones liées à la concentration (cortex préfrontal) peuvent s'épaissir
                    • La matière grise augmente dans les zones utilisées régulièrement
                    """
                ),
                ContentSection(
                    icon: "clock.fill",
                    title: "Combien de temps ça prend",
                    content: """
                    • Premiers changements : 2-4 semaines
                    • Changements mesurables : 6-8 semaines
                    • Changements durables : 2-3 mois
                    """
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: "Le message important",
                    content: "Tu n'es pas condamné à rester stressé. Avec CortiFree, tu reprogrammes littéralement ton cerveau pour mieux gérer le stress !"
                )
            ]
        ),
        LearningCard(
            icon: "moon.zzz.fill",
            title: "Les cycles de sommeil",
            category: "Science",
            shortDescription: "Comprendre et optimiser ton repos",
            sections: [
                ContentSection(
                    icon: "moon.fill",
                    title: "Les 4 phases du sommeil",
                    content: """
                    Le sommeil est composé de cycles de 90 minutes qui se répètent 4-6 fois par nuit :

                    1️⃣ Sommeil léger (5-10 min) : Transition veille-sommeil, muscles se détendent, facile de se réveiller

                    2️⃣ Sommeil léger profond (20 min) : Rythme cardiaque ralentit, température corporelle baisse, 50% du temps total

                    3️⃣ Sommeil profond (20-40 min) : Phase la plus réparatrice, régénération physique, RÉDUCTION MAXIMALE DU CORTISOL

                    4️⃣ Sommeil paradoxal / REM (10-60 min) : Rêves intenses, consolidation émotionnelle, traitement du stress
                    """
                ),
                ContentSection(
                    icon: "clock.fill",
                    title: "Optimiser tes cycles",
                    content: """
                    • Vise 7h30 ou 9h de sommeil (5 ou 6 cycles complets)
                    • Évite 6h ou 8h (réveil en milieu de cycle = fatigue)
                    • Se coucher et se lever à heures fixes (même le week-end)
                    """
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: "Impact sur le cortisol",
                    content: """
                    • Sommeil profond = baisse de 70% du cortisol
                    • Manque de sommeil = +37% de cortisol le lendemain
                    • 3 nuits mauvaises = résistance à l'insuline (pré-diabète)
                    """
                ),
                ContentSection(
                    icon: "star.fill",
                    title: "Qualité > Quantité",
                    content: "Mieux vaut 6h avec beaucoup de sommeil profond que 8h de sommeil léger et fragmenté !"
                )
            ]
        ),

        // SANTÉ CATEGORY
        LearningCard(
            icon: "heart.text.square.fill",
            title: "Comment le stress affecte ton corps",
            category: "Santé",
            shortDescription: "Les impacts physiques du stress chronique",
            sections: [
                ContentSection(
                    icon: "brain.head.profile",
                    title: "Cerveau",
                    content: """
                    • Difficulté de concentration
                    • Problèmes de mémoire
                    • Anxiété et dépression
                    """
                ),
                ContentSection(
                    icon: "heart.fill",
                    title: "Cœur",
                    content: """
                    • Augmentation de la pression artérielle
                    • Risque cardiovasculaire accru
                    • Palpitations
                    """
                ),
                ContentSection(
                    icon: "figure.strengthtraining.traditional",
                    title: "Muscles",
                    content: """
                    • Tensions et douleurs
                    • Maux de tête
                    • Fatigue chronique
                    """
                ),
                ContentSection(
                    icon: "bolt.fill",
                    title: "Énergie",
                    content: """
                    • Épuisement
                    • Troubles du sommeil
                    • Baisse de motivation

                    C'est pour ça qu'il est crucial de gérer son stress au quotidien.
                    """
                )
            ]
        ),
        LearningCard(
            icon: "fork.knife",
            title: "L'alimentation anti-stress",
            category: "Santé",
            shortDescription: "Les aliments qui régulent le cortisol",
            sections: [
                ContentSection(
                    icon: "checkmark.circle.fill",
                    title: "Aliments qui RÉDUISENT le cortisol",
                    content: """
                    Graisses saines :
                    • Avocats, noix, amandes
                    • Huile d'olive, poissons gras (saumon, maquereau)
                    • Riches en oméga-3 anti-inflammatoires

                    Aliments riches en magnésium :
                    • Chocolat noir (>70% cacao)
                    • Épinards, bananes
                    • Graines de courge, amandes
                    • Le magnésium réduit l'anxiété et le cortisol

                    Vitamine C :
                    • Agrumes, kiwis, poivrons
                    • Réduit le cortisol de 15-20%
                    • Renforce le système immunitaire

                    Thé vert et noir :
                    • L-théanine qui calme l'esprit
                    • Réduction de 20% du cortisol après 6 semaines
                    """
                ),
                ContentSection(
                    icon: "xmark.circle.fill",
                    title: "Aliments qui AUGMENTENT le cortisol",
                    content: """
                    Excès de caféine :
                    • Plus de 400mg/jour (4 cafés)
                    • Augmente le cortisol de 30%
                    • Perturbe le sommeil

                    Sucres raffinés :
                    • Pics de glycémie = pics de cortisol
                    • Inflammation systémique
                    • Addiction et fringales

                    Alcool :
                    • Perturbe le sommeil profond
                    • Augmente le cortisol nocturne
                    • Déshydratation
                    """
                ),
                ContentSection(
                    icon: "clock.fill",
                    title: "Le timing compte",
                    content: """
                    • Petit-déjeuner riche en protéines (stabilise cortisol)
                    • Éviter sucres et caféine le soir
                    • Dîner léger 2-3h avant coucher
                    """
                )
            ]
        ),

        // TECHNIQUES CATEGORY
        LearningCard(
            icon: "wind",
            title: "Les bienfaits de la respiration consciente",
            category: "Techniques",
            shortDescription: "Pourquoi respirer consciemment fonctionne",
            sections: [
                ContentSection(
                    icon: "star.fill",
                    title: "Effets immédiats",
                    content: """
                    La respiration consciente est l'un des outils les plus puissants pour réguler ton stress :

                    • Active le système nerveux parasympathique (relaxation)
                    • Réduit le rythme cardiaque
                    • Diminue la tension artérielle
                    """
                ),
                ContentSection(
                    icon: "figure.mind.and.body",
                    title: "Bénéfices à long terme",
                    content: """
                    • Améliore la gestion du stress
                    • Augmente la capacité pulmonaire
                    • Favorise la clarté mentale
                    """
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: "Le saviez-vous ?",
                    content: "Une respiration profonde peut réduire ton niveau de cortisol en seulement 2-3 minutes !\n\nC'est pourquoi les exercices de respiration sont au cœur du programme CortiFree."
                )
            ]
        ),
        LearningCard(
            icon: "leaf.fill",
            title: "Le pouvoir de la nature",
            category: "Techniques",
            shortDescription: "Pourquoi la nature apaise",
            sections: [
                ContentSection(
                    icon: "chart.bar.fill",
                    title: "Études scientifiques",
                    content: """
                    Le contact avec la nature a un effet prouvé sur le stress :

                    • -15% de cortisol après 20 min en nature
                    • Baisse de la pression artérielle
                    • Amélioration de l'humeur
                    """
                ),
                ContentSection(
                    icon: "tree.fill",
                    title: "Le \"bain de forêt\" (Shinrin-yoku)",
                    content: """
                    • Pratique japonaise millénaire
                    • Marche lente en forêt
                    • Connexion avec les 5 sens
                    """
                ),
                ContentSection(
                    icon: "sparkles",
                    title: "Bénéfices",
                    content: """
                    • Renforcement du système immunitaire
                    • Réduction de l'anxiété
                    • Meilleure créativité
                    """
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: "Même en ville",
                    content: "Un parc, un jardin ou des plantes d'intérieur ont déjà des effets positifs !"
                )
            ]
        ),
        LearningCard(
            icon: "waveform.path.ecg",
            title: "La cohérence cardiaque",
            category: "Techniques",
            shortDescription: "Synchroniser cœur et cerveau",
            sections: [
                ContentSection(
                    icon: "heart.fill",
                    title: "Comment ça marche",
                    content: """
                    La cohérence cardiaque est une technique de respiration qui synchronise ton rythme cardiaque avec ton cerveau pour un effet anti-stress puissant.

                    • Respiration : 6 cycles par minute (5 sec inspiration, 5 sec expiration)
                    • Durée : 5 minutes
                    • Fréquence : 3 fois par jour (matin, midi, soir)
                    • C'est la méthode 365 : 3 fois/jour, 6 respirations/min, 5 minutes
                    """
                ),
                ContentSection(
                    icon: "star.fill",
                    title: "Bienfaits immédiats",
                    content: """
                    • Réduction du cortisol en 3-5 minutes
                    • Baisse de la fréquence cardiaque
                    • Diminution de la pression artérielle
                    • Sentiment de calme et clarté mentale
                    """
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: "Effets à long terme (après 2 semaines)",
                    content: """
                    • -24% de cortisol en moyenne
                    • Meilleure régulation émotionnelle
                    • Amélioration de la qualité du sommeil
                    • Renforcement du système immunitaire
                    • +17% de DHEA (hormone anti-vieillissement)
                    """
                ),
                ContentSection(
                    icon: "person.fill",
                    title: "Utilisé par",
                    content: """
                    • Pilotes de chasse
                    • Sportifs de haut niveau
                    • Médecins et personnels soignants
                    • Dirigeants d'entreprise
                    """
                ),
                ContentSection(
                    icon: "checkmark.circle.fill",
                    title: "Dans CortiFree",
                    content: "L'exercice \"Cohérence cardiaque 5-5\" dans la section Respiration suit exactement cette méthode scientifique."
                )
            ]
        ),
        LearningCard(
            icon: "figure.yoga",
            title: "Le yoga et la flexibilité mentale",
            category: "Techniques",
            shortDescription: "Au-delà de la simple souplesse",
            sections: [
                ContentSection(
                    icon: "figure.mind.and.body",
                    title: "Les types de yoga anti-stress",
                    content: """
                    Le yoga est bien plus qu'une pratique physique. C'est un outil puissant de régulation du stress qui agit sur ton corps ET ton esprit.

                    • Hatha Yoga : doux, parfait pour débuter
                    • Yin Yoga : postures longues, très relaxant
                    • Yoga Nidra : méditation guidée allongée
                    • Vinyasa : dynamique mais méditatif
                    """
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: "Effets sur le cortisol",
                    content: """
                    • -27% après une session de 60 min
                    • Effets cumulatifs avec pratique régulière
                    • -41% de cortisol après 12 semaines (3x/semaine)
                    """
                ),
                ContentSection(
                    icon: "brain.head.profile",
                    title: "Bénéfices prouvés scientifiquement",
                    content: """
                    Physiques :
                    • Flexibilité et force musculaire
                    • Meilleure posture
                    • Réduction des douleurs chroniques
                    • Amélioration de l'équilibre

                    Mentaux :
                    • -65% des symptômes anxieux
                    • Meilleure régulation émotionnelle
                    • Augmentation de la matière grise
                    • Amélioration de la concentration

                    Physiologiques :
                    • Activation du système parasympathique (relaxation)
                    • Meilleure variabilité de la fréquence cardiaque
                    • Réduction de l'inflammation
                    • Amélioration de la digestion
                    """
                ),
                ContentSection(
                    icon: "flask.fill",
                    title: "Ce qui se passe dans ton cerveau",
                    content: """
                    • Augmentation GABA (neurotransmetteur calmant)
                    • Réduction activité de l'amygdale (peur/stress)
                    • Activation cortex préfrontal (contrôle émotionnel)
                    """
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: "Pas besoin d'être souple",
                    content: "Le yoga n'est pas une compétition. Chaque corps est différent, et les bénéfices anti-stress arrivent dès les premières séances, même avec des adaptations !"
                )
            ]
        ),

        // HABITUDES CATEGORY
        LearningCard(
            icon: "bed.double.fill",
            title: "Le sommeil et le cortisol",
            category: "Habitudes",
            shortDescription: "L'importance d'un bon rythme circadien",
            sections: [
                ContentSection(
                    icon: "sun.max.fill",
                    title: "Le rythme naturel",
                    content: """
                    Ton sommeil et ton niveau de cortisol sont intimement liés :

                    • Cortisol élevé le matin (pour te réveiller)
                    • Cortisol bas le soir (pour dormir)
                    """
                ),
                ContentSection(
                    icon: "exclamationmark.triangle.fill",
                    title: "Quand ça déraille",
                    content: """
                    • Sommeil perturbé → Cortisol élevé 24h/24
                    • Cercle vicieux : stress → mauvais sommeil → plus de stress
                    """
                ),
                ContentSection(
                    icon: "checkmark.circle.fill",
                    title: "Solutions CortiFree",
                    content: """
                    • Se lever avant 7h (routine matinale)
                    • Se coucher avant 23h (récupération)
                    • Méditation du soir (préparation au sommeil)
                    """
                ),
                ContentSection(
                    icon: "moon.zzz.fill",
                    title: "Le saviez-vous ?",
                    content: "Une seule nuit de mauvais sommeil peut augmenter ton cortisol de 37% le lendemain !"
                )
            ]
        ),
        LearningCard(
            icon: "drop.fill",
            title: "L'hydratation et le stress",
            category: "Habitudes",
            shortDescription: "Pourquoi boire de l'eau réduit le stress",
            sections: [
                ContentSection(
                    icon: "exclamationmark.triangle.fill",
                    title: "Effets de la déshydratation",
                    content: """
                    L'eau joue un rôle crucial dans la régulation du stress :

                    • Augmentation du cortisol (+25%)
                    • Fatigue et irritabilité
                    • Difficulté de concentration
                    """
                ),
                ContentSection(
                    icon: "sparkles",
                    title: "Bienfaits d'une bonne hydratation",
                    content: """
                    • Régulation de la température corporelle
                    • Élimination des toxines
                    • Meilleur fonctionnement cérébral
                    """
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: "Recommandation",
                    content: """
                    • Minimum 2L d'eau par jour
                    • Plus si activité physique
                    • Répartir tout au long de la journée
                    """
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: "Astuce",
                    content: "Commence ta journée avec un grand verre d'eau pour réveiller ton métabolisme !"
                )
            ]
        ),
        LearningCard(
            icon: "figure.run",
            title: "L'exercice physique anti-stress",
            category: "Habitudes",
            shortDescription: "Comment le sport régule le cortisol",
            sections: [
                ContentSection(
                    icon: "chart.bar.fill",
                    title: "Effets sur le cortisol",
                    content: """
                    L'activité physique est un régulateur naturel du stress :

                    • Court terme : légère augmentation (normale)
                    • Long terme : baisse significative du cortisol de base
                    """
                ),
                ContentSection(
                    icon: "star.fill",
                    title: "Bénéfices supplémentaires",
                    content: """
                    • Libération d'endorphines (hormones du bonheur)
                    • Amélioration du sommeil
                    • Meilleure estime de soi
                    """
                ),
                ContentSection(
                    icon: "clock.fill",
                    title: "Durée idéale",
                    content: """
                    • 20-30 min par session
                    • 3-5 fois par semaine
                    • Intensité modérée
                    """
                ),
                ContentSection(
                    icon: "exclamationmark.triangle.fill",
                    title: "Attention",
                    content: "Trop d'exercice intense peut augmenter le cortisol. L'équilibre est la clé !"
                )
            ]
        ),
        LearningCard(
            icon: "person.2.fill",
            title: "Les relations sociales positives",
            category: "Habitudes",
            shortDescription: "L'importance du soutien social",
            sections: [
                ContentSection(
                    icon: "heart.circle.fill",
                    title: "Impact sur le cortisol",
                    content: """
                    Les connexions sociales de qualité sont essentielles pour gérer le stress :

                    • Interactions positives → -20% de cortisol
                    • Libération d'ocytocine ("hormone de l'amour")
                    • Sentiment de sécurité et d'appartenance
                    """
                ),
                ContentSection(
                    icon: "person.2.fill",
                    title: "Types de connexions bénéfiques",
                    content: """
                    • Conversations profondes avec amis
                    • Moments de qualité en famille
                    • Activités de groupe (sport, loisirs)
                    """
                ),
                ContentSection(
                    icon: "exclamationmark.triangle.fill",
                    title: "À éviter",
                    content: """
                    • Isolement prolongé
                    • Relations toxiques ou conflictuelles
                    """
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: "Le saviez-vous ?",
                    content: "Un simple câlin de 20 secondes peut réduire significativement ton niveau de stress !"
                )
            ]
        ),
        LearningCard(
            icon: "sun.max.fill",
            title: "L'exposition à la lumière naturelle",
            category: "Habitudes",
            shortDescription: "Régule ton horloge biologique",
            sections: [
                ContentSection(
                    icon: "sun.max.fill",
                    title: "L'importance du matin",
                    content: """
                    La lumière naturelle joue un rôle crucial dans la régulation de ton cortisol et de ton rythme circadien :

                    • S'exposer à la lumière dans les 30-60 min après le réveil
                    • 10-30 minutes minimum dehors (même par temps nuageux)
                    • Active la production de cortisol matinal (normal et bénéfique)
                    • Stoppe la production de mélatonine (hormone du sommeil)
                    """
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: "Impact sur ton horloge biologique",
                    content: """
                    • Régule le cycle cortisol/mélatonine
                    • Améliore la qualité du sommeil nocturne
                    • Augmente l'énergie et la vigilance diurne
                    • Synchronise tous tes rythmes biologiques
                    """
                ),
                ContentSection(
                    icon: "flask.fill",
                    title: "Études scientifiques",
                    content: """
                    • +25% d'énergie diurne avec exposition matinale
                    • Endormissement 1h plus rapide le soir
                    • -35% de symptômes dépressifs
                    • Meilleure régulation de l'appétit
                    """
                ),
                ContentSection(
                    icon: "moon.fill",
                    title: "Le soir, éviter",
                    content: """
                    • Les écrans 1-2h avant le coucher
                    • Les lumières vives (préférer lumières chaudes/tamisées)
                    • La lumière bleue qui bloque la mélatonine
                    """
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: "Astuce CortiFree",
                    content: "Combine ta marche matinale avec l'exposition à la lumière naturelle pour un effet démultiplié sur ton énergie et ton stress !"
                )
            ]
        ),

        // PSYCHOLOGIE CATEGORY
        LearningCard(
            icon: "quote.bubble.fill",
            title: "Les pensées automatiques négatives",
            category: "Psychologie",
            shortDescription: "Identifier et remplacer les schémas toxiques",
            sections: [
                ContentSection(
                    icon: "brain.head.profile",
                    title: "Les 7 types de pensées toxiques",
                    content: """
                    Tes pensées influencent directement ton niveau de stress et de cortisol. Apprendre à identifier et modifier les pensées automatiques négatives est crucial.

                    1️⃣ Catastrophisme : "Si je rate cet examen, ma vie est finie"
                    → Réalité : Un échec n'est pas une fin

                    2️⃣ Pensée tout ou rien : "Si ce n'est pas parfait, c'est un échec"
                    → Réalité : La vie est faite de nuances

                    3️⃣ Surgénéralisation : "J'ai échoué une fois, j'échoue toujours"
                    → Réalité : Une situation ≠ toutes les situations

                    4️⃣ Filtre mental : Ignorer le positif, se focaliser sur le négatif
                    → Réalité : Chercher aussi ce qui va bien

                    5️⃣ Lecture de pensées : "Ils pensent que je suis incompétent"
                    → Réalité : Tu ne peux pas lire dans les pensées

                    6️⃣ Personnalisation : "C'est forcément de ma faute"
                    → Réalité : Tout ne dépend pas de toi

                    7️⃣ Obligations tyranniques : "Je DOIS être parfait"
                    → Réalité : Personne n'est parfait
                    """
                ),
                ContentSection(
                    icon: "pencil.and.list.clipboard",
                    title: "La technique des 3 colonnes",
                    content: """
                    Colonne 1 : Situation
                    Colonne 2 : Pensée automatique
                    Colonne 3 : Pensée alternative réaliste
                    """
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: "Impact mesurable",
                    content: """
                    • -40% d'anxiété avec thérapie cognitive
                    • -28% de cortisol en identifiant et modifiant ces pensées
                    • Amélioration durable après 8-12 semaines
                    """
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: "Astuce du journaling",
                    content: "Écrire tes pensées dans le journal CortiFree t'aide à les identifier, les questionner et les transformer !"
                )
            ]
        ),
        LearningCard(
            icon: "sparkles",
            title: "La gratitude et le cerveau",
            category: "Psychologie",
            shortDescription: "L'effet scientifique de la reconnaissance",
            sections: [
                ContentSection(
                    icon: "brain.head.profile",
                    title: "Ce qui se passe dans ton cerveau",
                    content: """
                    Pratiquer la gratitude n'est pas juste du "positive thinking" : c'est une technique scientifiquement validée qui modifie ton cerveau et ton niveau de stress.

                    • Activation du cortex préfrontal médian (bien-être)
                    • Libération de dopamine et sérotonine (bonheur)
                    • Réduction activité de l'amygdale (stress/peur)
                    • -23% de cortisol en moyenne
                    """
                ),
                ContentSection(
                    icon: "flask.fill",
                    title: "Études scientifiques majeures",
                    content: """
                    UC Berkeley (2015) :
                    • Journaling de gratitude 3x/semaine
                    • -27% de dépression après 12 semaines
                    • Amélioration sommeil et relations sociales

                    Harvard Medical School (2021) :
                    • 5 minutes de gratitude par jour
                    • +25% de bonheur ressenti
                    • -18% d'anxiété
                    """
                ),
                ContentSection(
                    icon: "pencil.and.list.clipboard",
                    title: "Comment pratiquer efficacement",
                    content: """
                    Méthode des 3 gratitudes (5 min/jour) :
                    1. Note 3 choses pour lesquelles tu es reconnaissant
                    2. Sois spécifique (pas juste "ma famille")
                    3. Ressens l'émotion en écrivant
                    4. Varie les gratitudes chaque jour

                    Exemples :
                    Trop vague : "Je suis reconnaissant pour ma santé"
                    Spécifique : "Je suis reconnaissant d'avoir pu faire ma marche matinale sans douleur et de sentir l'air frais sur mon visage"
                    """
                ),
                ContentSection(
                    icon: "star.fill",
                    title: "Effets à long terme",
                    content: """
                    Après 4 semaines :
                    • Changements mesurables dans le cerveau
                    • Meilleure qualité de sommeil
                    • Plus d'émotions positives

                    Après 12 semaines :
                    • Nouvelle "baseline" de bonheur plus élevée
                    • Résilience accrue face au stress
                    • Meilleures relations interpersonnelles
                    """
                ),
                ContentSection(
                    icon: "target",
                    title: "Intégré dans CortiFree",
                    content: "Le journal te permet de noter tes gratitudes quotidiennes. Cette simple pratique de 2-3 minutes peut transformer ton rapport au stress !"
                ),
                ContentSection(
                    icon: "info.circle.fill",
                    title: "Important",
                    content: "La gratitude ne nie pas les problèmes, elle entraîne ton cerveau à aussi voir le positif au lieu de se focaliser uniquement sur le négatif."
                )
            ]
        )
    ]
}

#Preview {
    LearningSectionView()
}
