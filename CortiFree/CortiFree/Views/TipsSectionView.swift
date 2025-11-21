//
//  TipsSectionView.swift
//  CortiFree
//
//  Created by Claude on 18/11/2025.
//  Section Conseils avec navigation par catégories
//

import SwiftUI

struct TipsSectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: TipsCategory?
    @State private var selectedCard: TipCard?

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
                TipsCategoryCardsView(
                    category: category,
                    onBack: { selectedCategory = nil },
                    onCardSelected: { card in selectedCard = card }
                )
            } else {
                // Show category grid
                TipsCategoriesGridView(onCategorySelected: { category in
                    selectedCategory = category
                })
            }
        }
        .fullScreenCover(item: $selectedCard) { card in
            TipCardDetailView(card: card)
        }
    }
}

// MARK: - Categories Grid View

struct TipsCategoriesGridView: View {
    @Environment(\.dismiss) private var dismiss
    let onCategorySelected: (TipsCategory) -> Void

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
                                    Color(hex: "EC4899"),
                                    Color(hex: "F472B6")
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 4, height: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Conseils")
                            .font(.custom("HankenGrotesk-Bold", size: 32))
                            .tracking(0.5)
                            .foregroundColor(.white)

                        Text("Des conseils pratiques pour ton quotidien")
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
                        Color(hex: "F59E0B").opacity(0.08),
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
                    ForEach(TipsCategory.allCategories) { category in
                        TipsCategoryCardView(category: category) {
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

// MARK: - Tips Category Card View

struct TipsCategoryCardView: View {
    let category: TipsCategory
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

                    Text("\(category.cardCount) conseil\(category.cardCount > 1 ? "s" : "")")
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

// MARK: - Tips Category Cards View

struct TipsCategoryCardsView: View {
    let category: TipsCategory
    let onBack: () -> Void
    let onCardSelected: (TipCard) -> Void

    var filteredCards: [TipCard] {
        TipCard.allCards.filter { $0.category == category.name }
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

                    Text("\(filteredCards.count) conseil\(filteredCards.count > 1 ? "s" : "")")
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
                        TipCardView(card: card) {
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

// MARK: - Tip Card View

struct TipCardView: View {
    let card: TipCard
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

// MARK: - Tip Card Detail View

struct TipCardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let card: TipCard

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
                            TipContentSectionView(section: section, color: card.categoryColor)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

// MARK: - Tip Content Section View

struct TipContentSectionView: View {
    let section: TipContentSection
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

struct TipsCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let cardCount: Int

    static let allCategories: [TipsCategory] = [
        TipsCategory(
            name: "Routine",
            icon: "alarm.fill",
            color: Color(hex: "F59E0B"),
            cardCount: 1
        ),
        TipsCategory(
            name: "Sommeil",
            icon: "moon.stars.fill",
            color: Color(hex: "8B5CF6"),
            cardCount: 1
        ),
        TipsCategory(
            name: "Travail",
            icon: "laptopcomputer",
            color: Color(hex: "3B82F6"),
            cardCount: 1
        ),
        TipsCategory(
            name: "Nutrition",
            icon: "fork.knife",
            color: Color(hex: "10B981"),
            cardCount: 1
        ),
        TipsCategory(
            name: "Émotions",
            icon: "heart.fill",
            color: Color(hex: "EC4899"),
            cardCount: 1
        ),
        TipsCategory(
            name: "Mindfulness",
            icon: "figure.mind.and.body",
            color: Color(hex: "06B6D4"),
            cardCount: 1
        ),
        TipsCategory(
            name: "Relations",
            icon: "person.2.fill",
            color: Color(hex: "F43F5E"),
            cardCount: 2
        ),
        TipsCategory(
            name: "Productivité",
            icon: "chart.line.uptrend.xyaxis",
            color: Color(hex: "6366F1"),
            cardCount: 1
        ),
        TipsCategory(
            name: "Environnement",
            icon: "house.fill",
            color: Color(hex: "22C55E"),
            cardCount: 1
        ),
        TipsCategory(
            name: "Urgence",
            icon: "exclamationmark.triangle.fill",
            color: Color(hex: "EF4444"),
            cardCount: 1
        )
    ]
}

struct TipContentSection: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let content: String
}

struct TipCard: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let category: String
    let shortDescription: String
    let sections: [TipContentSection]

    var categoryColor: Color {
        switch category {
        case "Routine":
            return Color(hex: "F59E0B")
        case "Sommeil":
            return Color(hex: "8B5CF6")
        case "Travail":
            return Color(hex: "3B82F6")
        case "Nutrition":
            return Color(hex: "10B981")
        case "Émotions":
            return Color(hex: "EC4899")
        case "Mindfulness":
            return Color(hex: "06B6D4")
        case "Relations":
            return Color(hex: "F43F5E")
        case "Productivité":
            return Color(hex: "6366F1")
        case "Environnement":
            return Color(hex: "22C55E")
        case "Urgence":
            return Color(hex: "EF4444")
        default:
            return Color(hex: "F59E0B")
        }
    }

    static let allCards: [TipCard] = [
        // ROUTINE CATEGORY
        TipCard(
            icon: "alarm.fill",
            title: "Routine matinale anti-stress",
            category: "Routine",
            shortDescription: "Commence ta journée du bon pied",
            sections: [
                TipContentSection(
                    icon: "info.circle.fill",
                    title: "Pourquoi c'est important",
                    content: "Les premières 60 minutes de ta journée déterminent ton niveau de cortisol pour toute la journée."
                ),
                TipContentSection(
                    icon: "sun.max.fill",
                    title: "La routine idéale (60 min)",
                    content: """
                    6h00-6h15 : Réveil et hydratation
                    • Boire 500ml d'eau dès le réveil
                    • Réhydrate ton corps après 8h de sommeil
                    • Active ton métabolisme

                    6h15-6h30 : Exposition à la lumière
                    • Sortir dehors ou près d'une fenêtre
                    • 15-30 min de lumière naturelle
                    • Stoppe la mélatonine, active le cortisol matinal sain

                    6h30-6h45 : Mouvement doux
                    • Étirements, yoga doux, ou marche
                    • Réveille le corps en douceur
                    • Libère les endorphines

                    6h45-7h00 : Pratique de pleine conscience
                    • 5-10 min de méditation ou respiration
                    • Cohérence cardiaque
                    • Définit l'intention de la journée
                    """
                ),
                TipContentSection(
                    icon: "xmark.circle.fill",
                    title: "À ÉVITER les 60 premières minutes",
                    content: """
                    • Téléphone/emails/réseaux sociaux
                    • Actualités (souvent négatives)
                    • Situations stressantes
                    • Caféine avant hydratation
                    """
                ),
                TipContentSection(
                    icon: "lightbulb.fill",
                    title: "Pourquoi ça marche",
                    content: "Cette routine synchronise ton rythme circadien, optimise ton pic de cortisol matinal (bénéfique) et te met dans un état mental positif pour la journée."
                )
            ]
        ),

        // SOMMEIL CATEGORY
        TipCard(
            icon: "moon.stars.fill",
            title: "Rituel du coucher optimal",
            category: "Sommeil",
            shortDescription: "Prépare ton corps et esprit au repos",
            sections: [
                TipContentSection(
                    icon: "moon.fill",
                    title: "Le rituel parfait",
                    content: """
                    Un bon sommeil commence 90 minutes avant de se coucher.

                    21h30 : Baisse de lumière
                    • Tamiser les lumières dans la maison
                    • Activer mode nuit sur téléphone/ordinateur
                    • Lumières chaudes uniquement

                    21h45 : Arrêt des écrans
                    • Plus de téléphone, TV, ordinateur
                    • Lire un livre papier à la place
                    • La lumière bleue bloque la mélatonine

                    22h00 : Hygiène et routine
                    • Douche tiède (pas chaude)
                    • Routine soins visage/dents
                    • Préparation vêtements du lendemain

                    22h15 : Activité relaxante
                    • Lecture légère (pas thriller!)
                    • Journaling/gratitudes
                    • Méditation ou respiration douce
                    • Étirements légers

                    22h30 : Préparation de la chambre
                    • Température fraîche (18-19°C)
                    • Obscurité totale (rideaux occultants)
                    • Silence (bouchons d'oreille si besoin)

                    22h45-23h00 : Coucher
                    • Toujours à la même heure
                    • Même le week-end
                    • Cohérence = meilleur sommeil
                    """
                ),
                TipContentSection(
                    icon: "star.fill",
                    title: "Tips supplémentaires",
                    content: """
                    • Pas de sport intense après 20h
                    • Dernier repas 2-3h avant coucher
                    • Éviter alcool et caféine après 16h
                    • Chambre réservée au sommeil (pas de travail)
                    """
                )
            ]
        ),

        // TRAVAIL CATEGORY
        TipCard(
            icon: "laptopcomputer",
            title: "Gérer le stress au travail",
            category: "Travail",
            shortDescription: "Stratégies pour rester zen au bureau",
            sections: [
                TipContentSection(
                    icon: "clock.fill",
                    title: "Micro-pauses toutes les heures",
                    content: """
                    • 2 min de respiration profonde
                    • Étirements au bureau
                    • Regarder au loin (détend les yeux)
                    • Marcher quelques pas
                    """
                ),
                TipContentSection(
                    icon: "list.bullet.clipboard.fill",
                    title: "Priorisation intelligente",
                    content: """
                    Matrice d'Eisenhower :
                    • Urgent + Important = Faire maintenant
                    • Important + Non urgent = Planifier
                    • Urgent + Non important = Déléguer
                    • Non urgent + Non important = Éliminer

                    Méthode 1-3-5 :
                    • 1 tâche principale par jour
                    • 3 tâches moyennes
                    • 5 petites tâches
                    """
                ),
                TipContentSection(
                    icon: "bell.slash.fill",
                    title: "Gestion des interruptions",
                    content: """
                    • Mode concentration : 90 min sans interruption
                    • Désactiver notifications non urgentes
                    • Créneaux "portes ouvertes" pour collègues
                    • Email : vérifier 3 fois/jour maximum
                    """
                ),
                TipContentSection(
                    icon: "xmark.circle.fill",
                    title: "Dire non avec diplomatie",
                    content: """
                    \"J'aimerais t'aider, mais j'ai déjà pris des engagements pour [X]. Je peux te proposer [alternative] ou être disponible à partir de [date].\"

                    Ton temps est précieux. Protège-le.
                    """
                )
            ]
        ),

        // NUTRITION CATEGORY
        TipCard(
            icon: "fork.knife",
            title: "Alimentation quotidienne anti-stress",
            category: "Nutrition",
            shortDescription: "Repas et snacks qui calment",
            sections: [
                TipContentSection(
                    icon: "sun.max.fill",
                    title: "Petit-déjeuner idéal",
                    content: """
                    Protéines + Graisses saines + Fibres :

                    Option 1 : Œufs + Avocat + Pain complet
                    Option 2 : Yaourt grec + Noix + Fruits rouges
                    Option 3 : Smoothie (banane, épinards, beurre amandes, lait végétal)

                    Pourquoi : Stabilise la glycémie et le cortisol pour toute la matinée.
                    """
                ),
                TipContentSection(
                    icon: "leaf.circle.fill",
                    title: "Snacks anti-stress",
                    content: """
                    Quand une fringale arrive (10h ou 16h) :

                    • Amandes (15-20) + 1 carré chocolat noir
                    • Pomme + Beurre d'amande
                    • Yaourt nature + Myrtilles
                    • Houmous + Bâtonnets de légumes
                    • Banane + Quelques noix

                    Éviter : Barres industrielles, viennoiseries, sodas
                    """
                ),
                TipContentSection(
                    icon: "drop.fill",
                    title: "Hydratation intelligente",
                    content: """
                    • 2L d'eau/jour minimum
                    • Infusions calmantes (camomille, verveine, tilleul)
                    • Thé vert (L-théanine anti-stress)
                    • Eau citronnée le matin

                    Limiter :
                    • Café : max 2-3 par jour, pas après 14h
                    • Alcool : max 1 verre/jour
                    • Sodas : occasionnellement uniquement
                    """
                ),
                TipContentSection(
                    icon: "moon.fill",
                    title: "Dîner léger",
                    content: """
                    2-3h avant coucher :

                    • Légumes + Protéines maigres (poisson, poulet, tofu)
                    • Glucides complexes en petite quantité (riz, quinoa)
                    • Éviter fritures, plats lourds, épices fortes
                    • Tisane digestive après le repas
                    """
                )
            ]
        ),

        // ÉMOTIONS CATEGORY
        TipCard(
            icon: "heart.fill",
            title: "Gérer les émotions difficiles",
            category: "Émotions",
            shortDescription: "Techniques d'urgence émotionnelle",
            sections: [
                TipContentSection(
                    icon: "wind",
                    title: "Technique 4-7-8 (urgence anxiété)",
                    content: """
                    1. Expire complètement par la bouche (whoosh)
                    2. Inspire par le nez en comptant jusqu'à 4
                    3. Retiens ta respiration en comptant jusqu'à 7
                    4. Expire par la bouche en comptant jusqu'à 8

                    Répéter 4 cycles.
                    Effet : Active le système parasympathique, calme en 90 secondes.
                    """
                ),
                TipContentSection(
                    icon: "hand.raised.fill",
                    title: "Technique 5-4-3-2-1 (ancrage présent)",
                    content: """
                    Quand tu te sens submergé, nomme à voix haute :

                    • 5 choses que tu VOIS autour de toi
                    • 4 choses que tu TOUCHES
                    • 3 choses que tu ENTENDS
                    • 2 choses que tu SENS (odorat)
                    • 1 chose que tu GOÛTES

                    Ramène ton esprit dans le moment présent et stoppe la spirale anxieuse.
                    """
                ),
                TipContentSection(
                    icon: "pencil.and.list.clipboard",
                    title: "Journaling émotionnel",
                    content: """
                    Quand une émotion forte arrive, écris :

                    1. Quelle est cette émotion ? (nom exact)
                    2. Où la sens-tu dans ton corps ?
                    3. Quelle pensée l'a déclenchée ?
                    4. Cette pensée est-elle un fait ou une interprétation ?
                    5. Quelle serait une pensée alternative plus réaliste ?

                    Écrire = Traiter l'émotion au lieu de la ruminer.
                    """
                ),
                TipContentSection(
                    icon: "figure.walk",
                    title: "Mouvement libérateur",
                    content: """
                    L'émotion = énergie coincée dans le corps.

                    • Marche rapide 10-15 min
                    • Secoue tes bras/jambes vigoureusement
                    • Dance sur une musique énergique
                    • Étirements profonds
                    • Cri dans un oreiller (si besoin)

                    Le corps DOIT évacuer le stress physiquement.
                    """
                )
            ]
        ),

        // MINDFULNESS CATEGORY
        TipCard(
            icon: "figure.mind.and.body",
            title: "Pleine conscience au quotidien",
            category: "Mindfulness",
            shortDescription: "Intégrer la mindfulness partout",
            sections: [
                TipContentSection(
                    icon: "cup.and.saucer.fill",
                    title: "Mindfulness du café/thé",
                    content: """
                    Au lieu de boire distraitement :

                    1. Observe la couleur du liquide
                    2. Sens l'arôme profondément
                    3. Ressens la chaleur de la tasse dans tes mains
                    4. Prends une petite gorgée, laisse-la en bouche
                    5. Remarque le goût, la texture, la température
                    6. Ressens la chaleur qui descend

                    5 minutes de présence pure.
                    """
                ),
                TipContentSection(
                    icon: "figure.walk",
                    title: "Marche consciente",
                    content: """
                    Transforme n'importe quelle marche en méditation :

                    • Sens le contact du pied avec le sol à chaque pas
                    • Remarque le mouvement de tes bras
                    • Observe ce que tu vois sans jugement
                    • Écoute les sons autour de toi
                    • Sens l'air sur ta peau, le vent dans tes cheveux

                    5-10 min suffisent pour reset ton esprit.
                    """
                ),
                TipContentSection(
                    icon: "shower.fill",
                    title: "Douche mindful",
                    content: """
                    • Sens la température de l'eau
                    • Remarque les gouttes qui coulent sur ta peau
                    • Concentre-toi sur les sensations corporelles
                    • Observe le bruit de l'eau
                    • Sens l'odeur du savon/shampoing

                    Chaque activité quotidienne = opportunité de méditation.
                    """
                ),
                TipContentSection(
                    icon: "fork.knife",
                    title: "Alimentation consciente",
                    content: """
                    1 repas/jour minimum sans distraction :

                    • Pas de téléphone, TV, ordinateur
                    • Observe ton assiette (couleurs, textures)
                    • Sens les odeurs
                    • Mâche lentement (20-30 fois par bouchée)
                    • Remarque les saveurs, textures
                    • Pose ta fourchette entre chaque bouchée

                    Meilleure digestion + Satiété naturelle + Moment de calme
                    """
                )
            ]
        ),

        // RELATIONS CATEGORY (2 cards)
        TipCard(
            icon: "person.2.fill",
            title: "Communication non-violente",
            category: "Relations",
            shortDescription: "Exprimer ses besoins sans conflit",
            sections: [
                TipContentSection(
                    icon: "list.bullet.clipboard.fill",
                    title: "Les 4 étapes de la CNV",
                    content: """
                    1. OBSERVATION (fait objectif)
                    \"Quand tu arrives en retard aux rendez-vous...\"
                    (PAS \"Tu es toujours en retard\" = jugement)

                    2. SENTIMENT (ton émotion)
                    \"...je me sens stressé et frustré...\"
                    (PAS \"Tu me stresses\" = accusation)

                    3. BESOIN (ce dont tu as besoin)
                    \"...parce que j'ai besoin de pouvoir compter sur nos engagements...\"

                    4. DEMANDE (action concrète)
                    \"...pourrais-tu m'envoyer un message si tu as du retard ?\"
                    (PAS \"Il faut que tu sois à l'heure\" = ordre)
                    """
                ),
                TipContentSection(
                    icon: "ear.fill",
                    title: "Écoute active",
                    content: """
                    Quand quelqu'un te parle :

                    • Arrête ce que tu fais
                    • Regarde la personne dans les yeux
                    • Ne prépare pas ta réponse pendant qu'elle parle
                    • Reformule pour vérifier ta compréhension
                    • Valide l'émotion avant de donner un conseil

                    \"Si je comprends bien, tu te sens [émotion] parce que [situation] ?\"
                    """
                ),
                TipContentSection(
                    icon: "exclamationmark.triangle.fill",
                    title: "Gérer les critiques",
                    content: """
                    • Respire profondément avant de répondre
                    • Cherche la part de vérité (même petite)
                    • Remercie pour le feedback
                    • Demande des précisions si besoin
                    • Prends du recul avant de décider d'une action

                    \"Merci de me le dire. Peux-tu me donner un exemple concret ?\"

                    Ne pas prendre personnellement ≠ Se laisser maltraiter
                    """
                )
            ]
        ),
        TipCard(
            icon: "heart.circle.fill",
            title: "Cultiver des relations positives",
            category: "Relations",
            shortDescription: "Renforcer tes liens sociaux",
            sections: [
                TipContentSection(
                    icon: "calendar",
                    title: "Rituels de connexion",
                    content: """
                    • 1 appel vidéo/semaine avec un proche
                    • 1 café/repas en face à face par semaine
                    • Message de check-in à 2-3 amis/semaine
                    • Activité de groupe mensuelle (sport, loisir)

                    La qualité > quantité, mais la régularité compte.
                    """
                ),
                TipContentSection(
                    icon: "heart.fill",
                    title: "Exprimer de la gratitude",
                    content: """
                    1 fois/jour minimum, dis à quelqu'un :

                    \"J'apprécie vraiment que tu [action concrète]. Ça m'a fait [émotion positive].\"

                    Exemples :
                    • \"Merci d'avoir écouté mes préoccupations hier. Je me suis senti compris.\"
                    • \"J'apprécie que tu aies pensé à moi. Ça m'a fait sourire.\"

                    Renforce les liens + Libère ocytocine (hormone du bonheur)
                    """
                ),
                TipContentSection(
                    icon: "xmark.circle.fill",
                    title: "Identifier les relations toxiques",
                    content: """
                    Signaux d'alarme :

                    • Tu te sens drainé après les interactions
                    • Critique constante, jamais de soutien
                    • Vampirisation émotionnelle (toujours eux, jamais toi)
                    • Manipulation ou culpabilisation
                    • Pas de respect de tes limites

                    Action : Distanciation progressive ou conversation franche.
                    Tu as le droit de protéger ton énergie.
                    """
                ),
                TipContentSection(
                    icon: "figure.2.and.child.holdinghands",
                    title: "Demander du soutien",
                    content: """
                    Demander de l'aide ≠ faiblesse :

                    \"J'ai besoin d'aide avec [situation]. Est-ce que tu aurais [temps/compétence] pour m'aider ?\"

                    Ou simplement :
                    \"Je passe une période difficile. Est-ce qu'on peut prendre un café pour en parler ?\"

                    Les gens veulent aider, mais ne savent pas toujours comment. Sois spécifique.
                    """
                )
            ]
        ),

        // PRODUCTIVITÉ CATEGORY
        TipCard(
            icon: "chart.line.uptrend.xyaxis",
            title: "Productivité sans stress",
            category: "Productivité",
            shortDescription: "Efficace ET zen",
            sections: [
                TipContentSection(
                    icon: "clock.fill",
                    title: "Technique Pomodoro adaptée",
                    content: """
                    Travail par sessions :

                    • 25 min focus total sur UNE tâche
                    • 5 min pause (marche, étirements, respiration)
                    • Répéter 4 fois
                    • Grande pause de 20-30 min

                    Règles :
                    • Timer visible
                    • Téléphone en mode avion
                    • Notifications désactivées
                    • Si interruption = reset le Pomodoro

                    Résultat : 4h de vrai travail valent mieux que 8h de distraction.
                    """
                ),
                TipContentSection(
                    icon: "brain.head.profile",
                    title: "Travailler avec ton cerveau",
                    content: """
                    Chaque cerveau a ses pics d'énergie :

                    Matinaux (lève-tôt) :
                    • 8h-12h : Tâches complexes/créatives
                    • 14h-16h : Tâches routinières
                    • Après 16h : Organisation/emails

                    Soireux (couche-tard) :
                    • Matin : Routine/emails
                    • 14h-18h : Tâches complexes
                    • Soirée : Créativité/projets

                    Identifie TON rythme et adapte ton planning.
                    """
                ),
                TipContentSection(
                    icon: "checkmark.circle.fill",
                    title: "Liste 'Done' en plus de 'To-Do'",
                    content: """
                    En fin de journée, écris ce que tu AS fait :

                    • Valide tes accomplissements
                    • Combat le syndrome de l'imposteur
                    • Montre le chemin parcouru
                    • Boost confiance en soi

                    Ton cerveau se souvient du négatif (biais de négativité).
                    Force-le à voir le positif.
                    """
                ),
                TipContentSection(
                    icon: "xmark.circle.fill",
                    title: "L'art du 'presque parfait'",
                    content: """
                    Perfectionnisme = Source majeure de stress.

                    Règle 80/20 (Pareto) :
                    • 80% du résultat vient de 20% de l'effort
                    • Les 20% restants du résultat demandent 80% d'effort supplémentaire

                    Question : \"Ce dernier 20% vaut-il vraiment mon temps et mon stress ?\"

                    Souvent, \"assez bon\" EST parfait.
                    """
                )
            ]
        ),

        // ENVIRONNEMENT CATEGORY
        TipCard(
            icon: "house.fill",
            title: "Optimiser ton environnement",
            category: "Environnement",
            shortDescription: "Espace de vie anti-stress",
            sections: [
                TipContentSection(
                    icon: "sparkles",
                    title: "Désencombrement (règle KonMari adaptée)",
                    content: """
                    1 zone/semaine :

                    Prends chaque objet et demande-toi :
                    • Est-ce que je l'ai utilisé dans les 6 derniers mois ?
                    • Est-ce que ça m'apporte de la joie ?
                    • Est-ce vraiment utile ?

                    Si 3x non → Don, recyclage, ou poubelle.

                    Désordre visuel = Surcharge mentale.
                    Espace dégagé = Esprit dégagé.
                    """
                ),
                TipContentSection(
                    icon: "leaf.fill",
                    title: "Plantes d'intérieur",
                    content: """
                    Top 5 anti-stress faciles d'entretien :

                    1. Pothos (air + stress)
                    2. Sansevieria (oxygène la nuit)
                    3. Aloe Vera (purifie l'air)
                    4. Plante araignée (facile, efficace)
                    5. Lavande (parfum calmant)

                    Bénéfices prouvés :
                    • -15% de cortisol
                    • Meilleure qualité de l'air
                    • Effet visuel apaisant
                    """
                ),
                TipContentSection(
                    icon: "sun.max.fill",
                    title: "Lumière naturelle maximale",
                    content: """
                    • Ouvre rideaux dès le réveil
                    • Bureau près fenêtre si possible
                    • Ampoules lumière du jour (5000-6500K) le matin
                    • Ampoules chaudes (2700-3000K) le soir
                    • Variateurs de lumière dans chambres

                    Lumière = régulateur #1 du rythme circadien.
                    """
                ),
                TipContentSection(
                    icon: "speaker.wave.3.fill",
                    title: "Sons et musique",
                    content: """
                    Travail/Concentration :
                    • Bruits blancs/bruns
                    • Musique classique baroque (60 bpm)
                    • Sons de la nature (pluie, forêt)
                    • Pas de paroles

                    Relaxation :
                    • Fréquences 432Hz
                    • Bols tibétains
                    • Musique méditative
                    • Sons binauraux (theta/delta)

                    Créer une playlist par activité.
                    """
                ),
                TipContentSection(
                    icon: "thermometer.medium",
                    title: "Température et air",
                    content: """
                    Température optimale :
                    • Journée active : 20-22°C
                    • Sommeil : 18-19°C
                    • Trop chaud = fatigue, irritabilité

                    Air :
                    • Aérer 10-15 min matin et soir
                    • Humidificateur en hiver (40-60% humidité)
                    • Éviter encens/bougies parfumées toxiques

                    Ton corps régule mieux le stress dans un environnement optimal.
                    """
                )
            ]
        ),

        // URGENCE CATEGORY
        TipCard(
            icon: "exclamationmark.triangle.fill",
            title: "Kit d'urgence anti-stress",
            category: "Urgence",
            shortDescription: "Quand tu sens que tu vas craquer",
            sections: [
                TipContentSection(
                    icon: "exclamationmark.circle.fill",
                    title: "Crise de panique imminente",
                    content: """
                    MAINTENANT (dans l'ordre) :

                    1. Respiration 4-7-8 (décrit plus haut)
                    2. Eau glacée sur visage ou douche froide
                    3. Technique 5-4-3-2-1 (ancrage sensoriel)
                    4. Sortir dehors si possible
                    5. Appeler quelqu'un de confiance

                    Rappel : Crise de panique = désagréable mais PAS dangereuse.
                    Ça passe en 10-20 min maximum.
                    """
                ),
                TipContentSection(
                    icon: "figure.run",
                    title: "Libération physique urgente",
                    content: """
                    Quand le stress est DANS ton corps :

                    • Sprint 30 secondes à fond (si lieu sûr)
                    • 20 jumping jacks
                    • Serrer fort un oreiller/coussin puis relâcher (5x)
                    • Pousser contre un mur de toutes tes forces (10 sec)

                    L'énergie du stress DOIT sortir du corps.
                    """
                ),
                TipContentSection(
                    icon: "phone.fill",
                    title: "Qui appeler",
                    content: """
                    Prépare cette liste MAINTENANT (dans ton téléphone) :

                    • 3 amis/famille de confiance
                    • Ligne d'écoute (SOS Amitié : 09 72 39 40 50)
                    • Ton thérapeute si tu en as un
                    • Urgences si danger immédiat : 112

                    En crise, tu ne penses pas clairement.
                    Liste préparée = bouée de sauvetage.
                    """
                ),
                TipContentSection(
                    icon: "heart.fill",
                    title: "Permission de faire une pause",
                    content: """
                    Tu as le DROIT de :

                    • Annuler des plans
                    • Dire \"Je ne peux pas aujourd'hui\"
                    • Prendre une journée de repos mental
                    • Déléguer ce qui peut l'être
                    • Mettre ton téléphone en mode avion

                    Prendre soin de toi ≠ Égoïsme.
                    C'est de la SURVIE.

                    Si tu ne vas pas bien, tu ne peux aider personne.
                    """
                ),
                TipContentSection(
                    icon: "checkmark.circle.fill",
                    title: "Après la crise",
                    content: """
                    Une fois calmé :

                    1. Bois de l'eau
                    2. Mange quelque chose de léger
                    3. Note ce qui a déclenché (pour identifier les patterns)
                    4. Pratique de l'auto-compassion (pas de jugement)
                    5. Prévois aide professionnelle si récurrent

                    Avoir besoin d'aide ≠ Faiblesse.
                    C'est du courage.
                    """
                )
            ]
        )
    ]
}

#Preview {
    TipsSectionView()
}
