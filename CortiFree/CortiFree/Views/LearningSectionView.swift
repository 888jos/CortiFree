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
                CategoriesGridView(onCategorySelected: { category in
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
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 40, height: 40)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassCircle(interactive: true)

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
                        Text(LanguageManager.shared.localizedString(for: "learning.title"))
                            .font(Font.Poppins.custom(.bold, size: 32))
                            .tracking(0.5)
                            .foregroundColor(.white)

                        Text(LanguageManager.shared.localizedString(for: "learning.subtitle"))
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
                        Color(hex: "F97316").opacity(0.08),
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
                    Text(category.localizedName)
                        .font(Font.Poppins.custom(.bold, size: 20))
                        .tracking(0.4)
                        .foregroundColor(.white)

                    Text("\(category.cardCount) \(LanguageManager.shared.localizedString(for: "learning.articles"))")
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
            .glassCard(cornerRadius: 24, interactive: true)
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassCircle(interactive: true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.localizedName)
                        .font(Font.Poppins.custom(.bold, size: 28))
                        .tracking(0.5)
                        .foregroundColor(.white)

                    Text("\(filteredCards.count) \(LanguageManager.shared.localizedString(for: "learning.articles"))")
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
            .glassCard(cornerRadius: 20, interactive: true)
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .glassCircle(interactive: true)

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
                            .glassCapsule(tint: card.categoryColor)
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
        .glassCard(cornerRadius: 22)
    }
}

// MARK: - Models

struct LearningCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let cardCount: Int

    var localizedName: String {
        return LanguageManager.shared.localizedString(for: "learning.category.\(name.lowercased())")
    }

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
            title: LanguageManager.shared.localizedString(for: "learning.card.cortisol.title"),
            category: "Science",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.cortisol.description"),
            sections: [
                ContentSection(
                    icon: "info.circle.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.cortisol.section1.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.cortisol.section1.content")
                ),
                ContentSection(
                    icon: "sparkles",
                    title: LanguageManager.shared.localizedString(for: "learning.card.cortisol.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.cortisol.section2.content")
                ),
                ContentSection(
                    icon: "exclamationmark.triangle.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.cortisol.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.cortisol.section3.content")
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.cortisol.section4.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.cortisol.section4.content")
                ),
                ContentSection(
                    icon: "target",
                    title: LanguageManager.shared.localizedString(for: "learning.card.cortisol.section5.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.cortisol.section5.content")
                )
            ]
        ),
        LearningCard(
            icon: "figure.mind.and.body",
            title: LanguageManager.shared.localizedString(for: "learning.card.meditation_science.title"),
            category: "Science",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.meditation_science.description"),
            sections: [
                ContentSection(
                    icon: "flask.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.meditation_science.section1.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.meditation_science.section1.content")
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.meditation_science.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.meditation_science.section2.content")
                ),
                ContentSection(
                    icon: "clock.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.meditation_science.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.meditation_science.section3.content")
                )
            ]
        ),
        LearningCard(
            icon: "book.fill",
            title: LanguageManager.shared.localizedString(for: "learning.card.66days.title"),
            category: "Science",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.66days.description"),
            sections: [
                ContentSection(
                    icon: "flask.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.66days.section1.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.66days.section1.content")
                ),
                ContentSection(
                    icon: "chart.line.uptrend.xyaxis",
                    title: LanguageManager.shared.localizedString(for: "learning.card.66days.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.66days.section2.content")
                ),
                ContentSection(
                    icon: "figure.strengthtraining.traditional",
                    title: LanguageManager.shared.localizedString(for: "learning.card.66days.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.66days.section3.content")
                ),
                ContentSection(
                    icon: "target",
                    title: LanguageManager.shared.localizedString(for: "learning.card.66days.section4.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.66days.section4.content")
                )
            ]
        ),
        LearningCard(
            icon: "brain",
            title: LanguageManager.shared.localizedString(for: "learning.card.neuroplasticity.title"),
            category: "Science",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.neuroplasticity.description"),
            sections: [
                ContentSection(
                    icon: "brain.head.profile",
                    title: LanguageManager.shared.localizedString(for: "learning.card.neuroplasticity.section1.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.neuroplasticity.section1.content")
                ),
                ContentSection(
                    icon: "flask.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.neuroplasticity.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.neuroplasticity.section2.content")
                ),
                ContentSection(
                    icon: "clock.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.neuroplasticity.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.neuroplasticity.section3.content")
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.neuroplasticity.section4.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.neuroplasticity.section4.content")
                )
            ]
        ),
        LearningCard(
            icon: "moon.zzz.fill",
            title: LanguageManager.shared.localizedString(for: "learning.card.sleep_cycles.title"),
            category: "Science",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.sleep_cycles.description"),
            sections: [
                ContentSection(
                    icon: "moon.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.sleep_cycles.section1.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.sleep_cycles.section1.content")
                ),
                ContentSection(
                    icon: "clock.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.sleep_cycles.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.sleep_cycles.section2.content")
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.sleep_cycles.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.sleep_cycles.section3.content")
                ),
                ContentSection(
                    icon: "star.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.sleep_cycles.section4.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.sleep_cycles.section4.content")
                )
            ]
        ),

        // SANTÉ CATEGORY
        LearningCard(
            icon: "heart.text.square.fill",
            title: LanguageManager.shared.localizedString(for: "learning.card.stress_body.title"),
            category: "Santé",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.stress_body.description"),
            sections: [
                ContentSection(
                    icon: "brain.head.profile",
                    title: LanguageManager.shared.localizedString(for: "learning.card.stress_body.section1.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.stress_body.section1.content")
                ),
                ContentSection(
                    icon: "heart.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.stress_body.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.stress_body.section2.content")
                ),
                ContentSection(
                    icon: "figure.strengthtraining.traditional",
                    title: LanguageManager.shared.localizedString(for: "learning.card.stress_body.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.stress_body.section3.content")
                ),
                ContentSection(
                    icon: "bolt.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.stress_body.section4.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.stress_body.section4.content")
                )
            ]
        ),
        LearningCard(
            icon: "fork.knife",
            title: LanguageManager.shared.localizedString(for: "learning.card.food.title"),
            category: "Santé",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.food.description"),
            sections: [
                ContentSection(
                    icon: "checkmark.circle.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.food.section1.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.food.section1.content")
                ),
                ContentSection(
                    icon: "xmark.circle.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.food.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.food.section2.content")
                ),
                ContentSection(
                    icon: "clock.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.food.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.food.section3.content")
                )
            ]
        ),

        // TECHNIQUES CATEGORY
        LearningCard(
            icon: "wind",
            title: LanguageManager.shared.localizedString(for: "learning.card.breathing.title"),
            category: "Techniques",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.breathing.description"),
            sections: [
                ContentSection(
                    icon: "star.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.breathing.section1.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.breathing.section1.content")
                ),
                ContentSection(
                    icon: "figure.mind.and.body",
                    title: LanguageManager.shared.localizedString(for: "learning.card.breathing.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.breathing.section2.content")
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.breathing.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.breathing.section3.content")
                )
            ]
        ),
        LearningCard(
            icon: "leaf.fill",
            title: LanguageManager.shared.localizedString(for: "learning.card.nature.title"),
            category: "Techniques",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.nature.description"),
            sections: [
                ContentSection(
                    icon: "chart.bar.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.nature.section1.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.nature.section1.content")
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
                    title: LanguageManager.shared.localizedString(for: "learning.card.nature.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.nature.section3.content")
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.nature.section4.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.nature.section4.content")
                )
            ]
        ),
        LearningCard(
            icon: "waveform.path.ecg",
            title: LanguageManager.shared.localizedString(for: "learning.card.cardiac_coherence.title"),
            category: "Techniques",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.cardiac_coherence.description"),
            sections: [
                ContentSection(
                    icon: "heart.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.cardiac_coherence.section1.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.cardiac_coherence.section1.content")
                ),
                ContentSection(
                    icon: "star.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.cardiac_coherence.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.cardiac_coherence.section2.content")
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.cardiac_coherence.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.cardiac_coherence.section3.content")
                ),
                ContentSection(
                    icon: "person.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.cardiac_coherence.section4.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.cardiac_coherence.section4.content")
                ),
                ContentSection(
                    icon: "checkmark.circle.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.cardiac_coherence.section5.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.cardiac_coherence.section5.content")
                )
            ]
        ),
        LearningCard(
            icon: "figure.yoga",
            title: LanguageManager.shared.localizedString(for: "learning.card.yoga.title"),
            category: "Techniques",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.yoga.description"),
            sections: [
                ContentSection(
                    icon: "figure.mind.and.body",
                    title: LanguageManager.shared.localizedString(for: "learning.card.yoga.section1.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.yoga.section1.content")
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.yoga.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.yoga.section2.content")
                ),
                ContentSection(
                    icon: "brain.head.profile",
                    title: LanguageManager.shared.localizedString(for: "learning.card.yoga.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.yoga.section3.content")
                ),
                ContentSection(
                    icon: "flask.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.yoga.section4.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.yoga.section4.content")
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.yoga.section5.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.yoga.section5.content")
                )
            ]
        ),

        // HABITUDES CATEGORY
        LearningCard(
            icon: "bed.double.fill",
            title: LanguageManager.shared.localizedString(for: "learning.card.sleep_cortisol.title"),
            category: "Habitudes",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.sleep_cortisol.description"),
            sections: [
                ContentSection(
                    icon: "sun.max.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.sleep_cortisol.section1.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.sleep_cortisol.section1.content")
                ),
                ContentSection(
                    icon: "exclamationmark.triangle.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.sleep_cortisol.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.sleep_cortisol.section2.content")
                ),
                ContentSection(
                    icon: "checkmark.circle.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.sleep_cortisol.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.sleep_cortisol.section3.content")
                ),
                ContentSection(
                    icon: "moon.zzz.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.breathing.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.sleep_cortisol.section4.content")
                )
            ]
        ),
        LearningCard(
            icon: "drop.fill",
            title: LanguageManager.shared.localizedString(for: "learning.card.hydration.title"),
            category: "Habitudes",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.hydration.description"),
            sections: [
                ContentSection(
                    icon: "exclamationmark.triangle.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.hydration.section1.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.hydration.section1.content")
                ),
                ContentSection(
                    icon: "sparkles",
                    title: LanguageManager.shared.localizedString(for: "learning.card.hydration.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.hydration.section2.content")
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.hydration.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.hydration.section3.content")
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.hydration.section4.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.hydration.section4.content")
                )
            ]
        ),
        LearningCard(
            icon: "figure.run",
            title: LanguageManager.shared.localizedString(for: "learning.card.exercise.title"),
            category: "Habitudes",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.exercise.description"),
            sections: [
                ContentSection(
                    icon: "chart.bar.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.yoga.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.yoga.section2.content")
                ),
                ContentSection(
                    icon: "star.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.exercise.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.exercise.section2.content")
                ),
                ContentSection(
                    icon: "clock.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.exercise.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.exercise.section3.content")
                ),
                ContentSection(
                    icon: "exclamationmark.triangle.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.exercise.section4.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.exercise.section4.content")
                )
            ]
        ),
        LearningCard(
            icon: "person.2.fill",
            title: LanguageManager.shared.localizedString(for: "learning.card.social.title"),
            category: "Habitudes",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.social.description"),
            sections: [
                ContentSection(
                    icon: "heart.circle.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.social.section1.title"),
                    content: """
                    Les connexions sociales de qualité sont essentielles pour gérer le stress :

                    • Interactions positives → -20% de cortisol
                    • Libération d'ocytocine ("hormone de l'amour")
                    • Sentiment de sécurité et d'appartenance
                    """
                ),
                ContentSection(
                    icon: "person.2.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.social.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.social.section2.content")
                ),
                ContentSection(
                    icon: "exclamationmark.triangle.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.social.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.social.section3.content")
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.breathing.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.social.section4.content")
                )
            ]
        ),
        LearningCard(
            icon: "sun.max.fill",
            title: LanguageManager.shared.localizedString(for: "learning.card.light.title"),
            category: "Habitudes",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.light.description"),
            sections: [
                ContentSection(
                    icon: "sun.max.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.light.section1.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.light.section1.content")
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.light.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.light.section2.content")
                ),
                ContentSection(
                    icon: "flask.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.nature.section1.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.nature.section1.content")
                ),
                ContentSection(
                    icon: "moon.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.light.section4.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.light.section4.content")
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.light.section5.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.light.section5.content")
                )
            ]
        ),

        // PSYCHOLOGIE CATEGORY
        LearningCard(
            icon: "quote.bubble.fill",
            title: LanguageManager.shared.localizedString(for: "learning.card.negative_thoughts.title"),
            category: "Psychologie",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.negative_thoughts.description"),
            sections: [
                ContentSection(
                    icon: "brain.head.profile",
                    title: LanguageManager.shared.localizedString(for: "learning.card.negative_thoughts.section1.title"),
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
                    title: LanguageManager.shared.localizedString(for: "learning.card.negative_thoughts.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.negative_thoughts.section2.content")
                ),
                ContentSection(
                    icon: "chart.bar.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.negative_thoughts.section3.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.negative_thoughts.section3.content")
                ),
                ContentSection(
                    icon: "lightbulb.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.negative_thoughts.section4.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.negative_thoughts.section4.content")
                )
            ]
        ),
        LearningCard(
            icon: "sparkles",
            title: LanguageManager.shared.localizedString(for: "learning.card.gratitude.title"),
            category: "Psychologie",
            shortDescription: LanguageManager.shared.localizedString(for: "learning.card.gratitude.description"),
            sections: [
                ContentSection(
                    icon: "brain.head.profile",
                    title: LanguageManager.shared.localizedString(for: "learning.card.yoga.section4.title"),
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
                    title: LanguageManager.shared.localizedString(for: "learning.card.gratitude.section2.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.gratitude.section2.content")
                ),
                ContentSection(
                    icon: "pencil.and.list.clipboard",
                    title: LanguageManager.shared.localizedString(for: "learning.card.gratitude.section3.title"),
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
                    title: LanguageManager.shared.localizedString(for: "learning.card.gratitude.section4.title"),
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
                    title: LanguageManager.shared.localizedString(for: "learning.card.gratitude.section5.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.gratitude.section5.content")
                ),
                ContentSection(
                    icon: "info.circle.fill",
                    title: LanguageManager.shared.localizedString(for: "learning.card.gratitude.section6.title"),
                    content: LanguageManager.shared.localizedString(for: "learning.card.gratitude.section6.content")
                )
            ]
        )
    ]
}

#Preview {
    LearningSectionView()
}
