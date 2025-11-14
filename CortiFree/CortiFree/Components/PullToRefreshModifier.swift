//
//  PullToRefreshModifier.swift
//  CortiFree
//
//  Custom pull-to-refresh implementation with animations
//

import SwiftUI

struct PullToRefreshModifier: ViewModifier {
    @Binding var isRefreshing: Bool
    let action: () async -> Void
    @State private var pullDistance: CGFloat = 0
    @State private var isPulling = false

    private let threshold: CGFloat = 80
    private let maxDistance: CGFloat = 150

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Pull to refresh indicator
                    PullToRefreshIndicator(
                        pullDistance: pullDistance,
                        threshold: threshold,
                        isRefreshing: isRefreshing
                    )
                    .frame(height: max(0, pullDistance))
                    .offset(y: -pullDistance)

                    // Main content
                    content
                        .anchorPreference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: .top
                        ) { geometry[$0].y }
                }
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                if !isRefreshing {
                    pullDistance = min(max(0, offset), maxDistance)

                    if offset > threshold && !isPulling {
                        isPulling = true
                        HapticManager.light()
                    } else if offset <= threshold && isPulling {
                        isPulling = false
                    }

                    if offset > threshold && offset <= 0 {
                        // Released after pulling past threshold
                        if isPulling {
                            refresh()
                        }
                    }
                }
            }
        }
    }

    private func refresh() {
        guard !isRefreshing else { return }

        withAnimation(.spring()) {
            isRefreshing = true
            pullDistance = 60
        }
        HapticManager.medium()

        Task {
            await action()
            await MainActor.run {
                withAnimation(.spring()) {
                    isRefreshing = false
                    pullDistance = 0
                    isPulling = false
                }
                HapticManager.light()
            }
        }
    }
}

struct PullToRefreshIndicator: View {
    let pullDistance: CGFloat
    let threshold: CGFloat
    let isRefreshing: Bool

    private var progress: CGFloat {
        min(1, pullDistance / threshold)
    }

    private var rotation: Double {
        Double(progress * 360)
    }

    var body: some View {
        ZStack {
            if pullDistance > 0 {
                VStack {
                    Spacer()

                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 3)
                            .frame(width: 40, height: 40)

                        if isRefreshing {
                            // Loading animation
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        } else {
                            // Pull progress
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "B794F6"),
                                            Color(hex: "9B59B6")
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(
                                        lineWidth: 3,
                                        lineCap: .round
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: progress)

                            // Arrow icon
                            Image(systemName: "arrow.down")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(rotation))
                                .scaleEffect(progress)
                                .opacity(progress)
                                .animation(.easeInOut, value: progress)
                        }
                    }
                    .scaleEffect(0.8 + (progress * 0.2))

                    if pullDistance > threshold && !isRefreshing {
                        Text("Relâcher pour rafraîchir")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 8)
                            .transition(.opacity)
                    } else if isRefreshing {
                        Text("Mise à jour...")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 8)
                            .transition(.opacity)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .animation(.easeInOut, value: pullDistance)
            }
        }
    }
}

// Preference key for tracking scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Extension for easy use

extension View {
    func pullToRefresh(isRefreshing: Binding<Bool>, action: @escaping () async -> Void) -> some View {
        self.modifier(PullToRefreshModifier(isRefreshing: isRefreshing, action: action))
    }
}

// MARK: - Simple Pull to Refresh for ScrollView

struct RefreshableScrollView<Content: View>: View {
    @Binding var isRefreshing: Bool
    let action: () async -> Void
    let content: Content

    init(
        isRefreshing: Binding<Bool>,
        action: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self._isRefreshing = isRefreshing
        self.action = action
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
        }
        .refreshable {
            isRefreshing = true
            await action()
            isRefreshing = false
        }
        .onAppear {
            // iOS 15+ native refreshable with haptic
            UIRefreshControl.appearance().tintColor = UIColor.white
        }
    }
}