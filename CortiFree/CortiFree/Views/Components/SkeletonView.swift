//
//  SkeletonView.swift
//  CortiFree
//
//  Created on 21/01/2026.
//  Animated skeleton loading placeholders
//

import SwiftUI

// MARK: - Skeleton Modifier
struct SkeletonModifier: ViewModifier {
    @State private var isAnimating = false

    let isLoading: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if isLoading {
            content
                .hidden()
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            Color.white.opacity(0.1),
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: isAnimating ? 300 : -300)
                        )
                        .clipped()
                )
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                    ) {
                        isAnimating = true
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    /// Apply skeleton loading animation
    func skeleton(isLoading: Bool, cornerRadius: CGFloat = 8) -> some View {
        modifier(SkeletonModifier(isLoading: isLoading, cornerRadius: cornerRadius))
    }
}

// MARK: - Skeleton Shapes
struct SkeletonRect: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    @State private var isAnimating = false

    init(width: CGFloat? = nil, height: CGFloat = 20, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.white.opacity(0.08))
            .frame(width: width, height: height)
            .overlay(
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.5)
                        .offset(x: isAnimating ? geo.size.width : -geo.size.width * 0.5)
                }
            )
            .clipped()
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.2)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

struct SkeletonCircle: View {
    let size: CGFloat

    @State private var isAnimating = false

    init(size: CGFloat = 48) {
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.08))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? size : -size)
            )
            .clipped()
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.2)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Preset Skeleton Views

/// Card skeleton for list items
struct SkeletonCard: View {
    var body: some View {
        HStack(spacing: 14) {
            SkeletonCircle(size: 50)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonRect(width: 140, height: 16, cornerRadius: 6)
                SkeletonRect(width: 100, height: 12, cornerRadius: 4)
            }

            Spacer()

            SkeletonCircle(size: 44)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
        )
    }
}

/// Task row skeleton
struct SkeletonTaskRow: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonCircle(size: 24)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonRect(width: 120, height: 14, cornerRadius: 4)
                SkeletonRect(width: 80, height: 10, cornerRadius: 3)
            }

            Spacer()

            SkeletonRect(width: 60, height: 28, cornerRadius: 14)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

/// Stats card skeleton
struct SkeletonStatsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonCircle(size: 36)
                Spacer()
            }

            SkeletonRect(width: 80, height: 28, cornerRadius: 6)
            SkeletonRect(width: 100, height: 12, cornerRadius: 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
        )
    }
}

/// Full page loading skeleton
struct SkeletonPageLoader: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                SkeletonCircle(size: 40)
                Spacer()
                SkeletonRect(width: 100, height: 20, cornerRadius: 6)
                Spacer()
                SkeletonCircle(size: 40)
            }
            .padding(.horizontal, 24)

            // Content cards
            VStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonCard()
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.top, 60)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        GalaxyBackgroundView(intensity: 1.0)
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                Text("Skeleton Components")
                    .font(.custom("Poppins-Bold", size: 20))
                    .foregroundColor(.white)

                // Shapes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Shapes")
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(.white.opacity(0.6))

                    HStack(spacing: 16) {
                        SkeletonCircle(size: 48)
                        VStack(alignment: .leading, spacing: 8) {
                            SkeletonRect(width: 150, height: 16)
                            SkeletonRect(width: 100, height: 12)
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Card")
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(.white.opacity(0.6))

                    SkeletonCard()
                }
                .padding(.horizontal, 24)

                // Task Row
                VStack(alignment: .leading, spacing: 12) {
                    Text("Task Row")
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(.white.opacity(0.6))

                    SkeletonTaskRow()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.03))
                        )
                }
                .padding(.horizontal, 24)

                // Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stats Card")
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(.white.opacity(0.6))

                    HStack(spacing: 16) {
                        SkeletonStatsCard()
                        SkeletonStatsCard()
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 60)
        }
    }
}
