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
                    onBack: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedCategory = nil
                        }
                    },
                    onCardSelected: { card in selectedCard = card }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            } else {
                // Show category grid
                TipsCategoriesGridView(onCategorySelected: { category in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedCategory = category
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .leading),
                    removal: .move(edge: .trailing)
                ))
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
                        Text(NSLocalizedString("tips.title", comment: ""))
                            .font(Font.Poppins.custom(.bold, size: 32))
                            .tracking(0.5)
                            .foregroundColor(.white)

                        Text(NSLocalizedString("tips.subtitle", comment: ""))
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
                        Color(hex: "EC4899").opacity(0.08),
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
                        .font(Font.Poppins.custom(.bold, size: 20))
                        .tracking(0.4)
                        .foregroundColor(.white)

                    Text("\(category.cardCount) \(category.cardCount > 1 ? NSLocalizedString("tips.count.plural", comment: "") : NSLocalizedString("tips.count.singular", comment: ""))")
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
                        .font(Font.Poppins.custom(.bold, size: 28))
                        .tracking(0.5)
                        .foregroundColor(.white)

                    Text("\(filteredCards.count) \(filteredCards.count > 1 ? NSLocalizedString("tips.count.plural", comment: "") : NSLocalizedString("tips.count.singular", comment: ""))")
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
                        .font(Font.Poppins.custom(.bold, size: 17))
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
                            .font(Font.Poppins.custom(.semiBold, size: 12))
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
                        .font(Font.Poppins.custom(.bold, size: 28))
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
                    .font(Font.Poppins.custom(.bold, size: 18))
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
            name: NSLocalizedString("tips.category.routine", comment: ""),
            icon: "alarm.fill",
            color: Color(hex: "F59E0B"),
            cardCount: 1
        ),
        TipsCategory(
            name: NSLocalizedString("tips.category.sommeil", comment: ""),
            icon: "moon.stars.fill",
            color: Color(hex: "8B5CF6"),
            cardCount: 1
        ),
        TipsCategory(
            name: NSLocalizedString("tips.category.travail", comment: ""),
            icon: "laptopcomputer",
            color: Color(hex: "3B82F6"),
            cardCount: 1
        ),
        TipsCategory(
            name: NSLocalizedString("tips.category.nutrition", comment: ""),
            icon: "fork.knife",
            color: Color(hex: "10B981"),
            cardCount: 1
        ),
        TipsCategory(
            name: NSLocalizedString("tips.category.emotions", comment: ""),
            icon: "heart.fill",
            color: Color(hex: "EC4899"),
            cardCount: 1
        ),
        TipsCategory(
            name: NSLocalizedString("tips.category.mindfulness", comment: ""),
            icon: "figure.mind.and.body",
            color: Color(hex: "06B6D4"),
            cardCount: 1
        ),
        TipsCategory(
            name: NSLocalizedString("tips.category.relations", comment: ""),
            icon: "person.2.fill",
            color: Color(hex: "F43F5E"),
            cardCount: 2
        ),
        TipsCategory(
            name: NSLocalizedString("tips.category.productivite", comment: ""),
            icon: "chart.line.uptrend.xyaxis",
            color: Color(hex: "6366F1"),
            cardCount: 1
        ),
        TipsCategory(
            name: NSLocalizedString("tips.category.environnement", comment: ""),
            icon: "house.fill",
            color: Color(hex: "22C55E"),
            cardCount: 1
        ),
        TipsCategory(
            name: NSLocalizedString("tips.category.urgence", comment: ""),
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
            title: NSLocalizedString("tips.card.morning_routine.title", comment: ""),
            category: NSLocalizedString("tips.category.routine", comment: ""),
            shortDescription: NSLocalizedString("tips.card.morning_routine.short_description", comment: ""),
            sections: [
                TipContentSection(
                    icon: "info.circle.fill",
                    title: NSLocalizedString("tips.card.morning_routine.section1.title", comment: ""),
                    content: NSLocalizedString("tips.card.morning_routine.section1.content", comment: "")
                ),
                TipContentSection(
                    icon: "sun.max.fill",
                    title: NSLocalizedString("tips.card.morning_routine.section2.title", comment: ""),
                    content: NSLocalizedString("tips.card.morning_routine.section2.content", comment: "")
                ),
                TipContentSection(
                    icon: "xmark.circle.fill",
                    title: NSLocalizedString("tips.card.morning_routine.section3.title", comment: ""),
                    content: NSLocalizedString("tips.card.morning_routine.section3.content", comment: "")
                ),
                TipContentSection(
                    icon: "lightbulb.fill",
                    title: NSLocalizedString("tips.card.morning_routine.section4.title", comment: ""),
                    content: NSLocalizedString("tips.card.morning_routine.section4.content", comment: "")
                )
            ]
        ),

        // SOMMEIL CATEGORY
        TipCard(
            icon: "moon.stars.fill",
            title: NSLocalizedString("tips.card.sleep_ritual.title", comment: ""),
            category: NSLocalizedString("tips.category.sommeil", comment: ""),
            shortDescription: NSLocalizedString("tips.card.sleep_ritual.short_description", comment: ""),
            sections: [
                TipContentSection(
                    icon: "moon.fill",
                    title: NSLocalizedString("tips.card.sleep_ritual.section1.title", comment: ""),
                    content: NSLocalizedString("tips.card.sleep_ritual.section1.content", comment: "")
                ),
                TipContentSection(
                    icon: "star.fill",
                    title: NSLocalizedString("tips.card.sleep_ritual.section2.title", comment: ""),
                    content: NSLocalizedString("tips.card.sleep_ritual.section2.content", comment: "")
                )
            ]
        ),

        // TRAVAIL CATEGORY
        TipCard(
            icon: "laptopcomputer",
            title: NSLocalizedString("tips.card.work_stress.title", comment: ""),
            category: NSLocalizedString("tips.category.travail", comment: ""),
            shortDescription: NSLocalizedString("tips.card.work_stress.short_description", comment: ""),
            sections: [
                TipContentSection(
                    icon: "clock.fill",
                    title: NSLocalizedString("tips.card.work_stress.section1.title", comment: ""),
                    content: NSLocalizedString("tips.card.work_stress.section1.content", comment: "")
                ),
                TipContentSection(
                    icon: "list.bullet.clipboard.fill",
                    title: NSLocalizedString("tips.card.work_stress.section2.title", comment: ""),
                    content: NSLocalizedString("tips.card.work_stress.section2.content", comment: "")
                ),
                TipContentSection(
                    icon: "bell.slash.fill",
                    title: NSLocalizedString("tips.card.work_stress.section3.title", comment: ""),
                    content: NSLocalizedString("tips.card.work_stress.section3.content", comment: "")
                ),
                TipContentSection(
                    icon: "xmark.circle.fill",
                    title: NSLocalizedString("tips.card.work_stress.section4.title", comment: ""),
                    content: NSLocalizedString("tips.card.work_stress.section4.content", comment: "")
                )
            ]
        ),

        // NUTRITION CATEGORY
        TipCard(
            icon: "fork.knife",
            title: NSLocalizedString("tips.card.nutrition.title", comment: ""),
            category: NSLocalizedString("tips.category.nutrition", comment: ""),
            shortDescription: NSLocalizedString("tips.card.nutrition.short_description", comment: ""),
            sections: [
                TipContentSection(
                    icon: "sun.max.fill",
                    title: NSLocalizedString("tips.card.nutrition.section1.title", comment: ""),
                    content: NSLocalizedString("tips.card.nutrition.section1.content", comment: "")
                ),
                TipContentSection(
                    icon: "leaf.circle.fill",
                    title: NSLocalizedString("tips.card.nutrition.section2.title", comment: ""),
                    content: NSLocalizedString("tips.card.nutrition.section2.content", comment: "")
                ),
                TipContentSection(
                    icon: "drop.fill",
                    title: NSLocalizedString("tips.card.nutrition.section3.title", comment: ""),
                    content: NSLocalizedString("tips.card.nutrition.section3.content", comment: "")
                ),
                TipContentSection(
                    icon: "moon.fill",
                    title: NSLocalizedString("tips.card.nutrition.section4.title", comment: ""),
                    content: NSLocalizedString("tips.card.nutrition.section4.content", comment: "")
                )
            ]
        ),

        // ÉMOTIONS CATEGORY
        TipCard(
            icon: "heart.fill",
            title: NSLocalizedString("tips.card.emotions.title", comment: ""),
            category: NSLocalizedString("tips.category.emotions", comment: ""),
            shortDescription: NSLocalizedString("tips.card.emotions.short_description", comment: ""),
            sections: [
                TipContentSection(
                    icon: "wind",
                    title: NSLocalizedString("tips.card.emotions.section1.title", comment: ""),
                    content: NSLocalizedString("tips.card.emotions.section1.content", comment: "")
                ),
                TipContentSection(
                    icon: "hand.raised.fill",
                    title: NSLocalizedString("tips.card.emotions.section2.title", comment: ""),
                    content: NSLocalizedString("tips.card.emotions.section2.content", comment: "")
                ),
                TipContentSection(
                    icon: "pencil.and.list.clipboard",
                    title: NSLocalizedString("tips.card.emotions.section3.title", comment: ""),
                    content: NSLocalizedString("tips.card.emotions.section3.content", comment: "")
                ),
                TipContentSection(
                    icon: "figure.walk",
                    title: NSLocalizedString("tips.card.emotions.section4.title", comment: ""),
                    content: NSLocalizedString("tips.card.emotions.section4.content", comment: "")
                )
            ]
        ),

        // MINDFULNESS CATEGORY
        TipCard(
            icon: "figure.mind.and.body",
            title: NSLocalizedString("tips.card.mindfulness.title", comment: ""),
            category: NSLocalizedString("tips.category.mindfulness", comment: ""),
            shortDescription: NSLocalizedString("tips.card.mindfulness.short_description", comment: ""),
            sections: [
                TipContentSection(
                    icon: "cup.and.saucer.fill",
                    title: NSLocalizedString("tips.card.mindfulness.section1.title", comment: ""),
                    content: NSLocalizedString("tips.card.mindfulness.section1.content", comment: "")
                ),
                TipContentSection(
                    icon: "figure.walk",
                    title: NSLocalizedString("tips.card.mindfulness.section2.title", comment: ""),
                    content: NSLocalizedString("tips.card.mindfulness.section2.content", comment: "")
                ),
                TipContentSection(
                    icon: "shower.fill",
                    title: NSLocalizedString("tips.card.mindfulness.section3.title", comment: ""),
                    content: NSLocalizedString("tips.card.mindfulness.section3.content", comment: "")
                ),
                TipContentSection(
                    icon: "fork.knife",
                    title: NSLocalizedString("tips.card.mindfulness.section4.title", comment: ""),
                    content: NSLocalizedString("tips.card.mindfulness.section4.content", comment: "")
                )
            ]
        ),

        // RELATIONS CATEGORY (2 cards)
        TipCard(
            icon: "person.2.fill",
            title: NSLocalizedString("tips.card.nvc.title", comment: ""),
            category: NSLocalizedString("tips.category.relations", comment: ""),
            shortDescription: NSLocalizedString("tips.card.nvc.short_description", comment: ""),
            sections: [
                TipContentSection(
                    icon: "list.bullet.clipboard.fill",
                    title: NSLocalizedString("tips.card.nvc.section1.title", comment: ""),
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
                    title: NSLocalizedString("tips.card.nvc.section2.title", comment: ""),
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
                    title: NSLocalizedString("tips.card.nvc.section3.title", comment: ""),
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
            title: NSLocalizedString("tips.card.positive_relations.title", comment: ""),
            category: NSLocalizedString("tips.category.relations", comment: ""),
            shortDescription: NSLocalizedString("tips.card.positive_relations.short_description", comment: ""),
            sections: [
                TipContentSection(
                    icon: "calendar",
                    title: NSLocalizedString("tips.card.positive_relations.section1.title", comment: ""),
                    content: NSLocalizedString("tips.card.positive_relations.section1.content", comment: "")
                ),
                TipContentSection(
                    icon: "heart.fill",
                    title: NSLocalizedString("tips.card.positive_relations.section2.title", comment: ""),
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
                    title: NSLocalizedString("tips.card.positive_relations.section3.title", comment: ""),
                    content: NSLocalizedString("tips.card.positive_relations.section3.content", comment: "")
                ),
                TipContentSection(
                    icon: "figure.2.and.child.holdinghands",
                    title: NSLocalizedString("tips.card.positive_relations.section4.title", comment: ""),
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
            title: NSLocalizedString("tips.card.productivity.title", comment: ""),
            category: NSLocalizedString("tips.category.productivite", comment: ""),
            shortDescription: NSLocalizedString("tips.card.productivity.short_description", comment: ""),
            sections: [
                TipContentSection(
                    icon: "clock.fill",
                    title: NSLocalizedString("tips.card.productivity.section1.title", comment: ""),
                    content: NSLocalizedString("tips.card.productivity.section1.content", comment: "")
                ),
                TipContentSection(
                    icon: "brain.head.profile",
                    title: NSLocalizedString("tips.card.productivity.section2.title", comment: ""),
                    content: NSLocalizedString("tips.card.productivity.section2.content", comment: "")
                ),
                TipContentSection(
                    icon: "checkmark.circle.fill",
                    title: NSLocalizedString("tips.card.productivity.section3.title", comment: ""),
                    content: NSLocalizedString("tips.card.productivity.section3.content", comment: "")
                ),
                TipContentSection(
                    icon: "xmark.circle.fill",
                    title: NSLocalizedString("tips.card.productivity.section4.title", comment: ""),
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
            title: NSLocalizedString("tips.card.environment.title", comment: ""),
            category: NSLocalizedString("tips.category.environnement", comment: ""),
            shortDescription: NSLocalizedString("tips.card.environment.short_description", comment: ""),
            sections: [
                TipContentSection(
                    icon: "sparkles",
                    title: NSLocalizedString("tips.card.environment.section1.title", comment: ""),
                    content: NSLocalizedString("tips.card.environment.section1.content", comment: "")
                ),
                TipContentSection(
                    icon: "leaf.fill",
                    title: NSLocalizedString("tips.card.environment.section2.title", comment: ""),
                    content: NSLocalizedString("tips.card.environment.section2.content", comment: "")
                ),
                TipContentSection(
                    icon: "sun.max.fill",
                    title: NSLocalizedString("tips.card.environment.section3.title", comment: ""),
                    content: NSLocalizedString("tips.card.environment.section3.content", comment: "")
                ),
                TipContentSection(
                    icon: "speaker.wave.3.fill",
                    title: NSLocalizedString("tips.card.environment.section4.title", comment: ""),
                    content: NSLocalizedString("tips.card.environment.section4.content", comment: "")
                ),
                TipContentSection(
                    icon: "thermometer.medium",
                    title: NSLocalizedString("tips.card.environment.section5.title", comment: ""),
                    content: NSLocalizedString("tips.card.environment.section5.content", comment: "")
                )
            ]
        ),

        // URGENCE CATEGORY
        TipCard(
            icon: "exclamationmark.triangle.fill",
            title: NSLocalizedString("tips.card.emergency_kit.title", comment: ""),
            category: NSLocalizedString("tips.category.urgence", comment: ""),
            shortDescription: NSLocalizedString("tips.card.emergency_kit.short_description", comment: ""),
            sections: [
                TipContentSection(
                    icon: "exclamationmark.circle.fill",
                    title: NSLocalizedString("tips.card.emergency_kit.section1.title", comment: ""),
                    content: NSLocalizedString("tips.card.emergency_kit.section1.content", comment: "")
                ),
                TipContentSection(
                    icon: "figure.run",
                    title: NSLocalizedString("tips.card.emergency_kit.section2.title", comment: ""),
                    content: NSLocalizedString("tips.card.emergency_kit.section2.content", comment: "")
                ),
                TipContentSection(
                    icon: "phone.fill",
                    title: NSLocalizedString("tips.card.emergency_kit.section3.title", comment: ""),
                    content: NSLocalizedString("tips.card.emergency_kit.section3.content", comment: "")
                ),
                TipContentSection(
                    icon: "heart.fill",
                    title: NSLocalizedString("tips.card.emergency_kit.section4.title", comment: ""),
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
                    title: NSLocalizedString("tips.card.emergency_kit.section5.title", comment: ""),
                    content: NSLocalizedString("tips.card.emergency_kit.section5.content", comment: "")
                )
            ]
        )
    ]
}

#Preview {
    TipsSectionView()
}
