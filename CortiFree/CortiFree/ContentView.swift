//
//  ContentView.swift
//  CortiFree
//
//  Created by Josselin Biot on 25/09/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: Tab = .home
    @ObservedObject private var soundPlayer = SoundPlayer.shared
    @ObservedObject private var planetSettings = PlanetSettings.shared
    @State private var isScrolling = false
    @State private var scrollTimer: Timer?

    enum Tab {
        case home
        case tasks
        case library
        case profile
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content - Optimized with lazy loading
            Group {
                switch selectedTab {
                case .home:
                    HomeView(isScrolling: $isScrolling, scrollTimer: $scrollTimer)
                        .id(Tab.home) // Force view refresh on tab change
                case .tasks:
                    TasksV2View()
                        .id(Tab.tasks)
                case .library:
                    LibraryView()
                        .id(Tab.library)
                case .profile:
                    ProfileView()
                        .id(Tab.profile)
                }
            }

            // Custom Tab Bar - Smart hide/show on scroll
            CustomTabBar(selectedTab: $selectedTab, themeColor: Color(hex: "B794F6"))
                .offset(y: isScrolling ? 100 : 0)
                .animation(.easeInOut(duration: 0.3), value: isScrolling)

            // Mini Player (if playing) - positioned above TabBar
            if soundPlayer.currentExercise != nil {
                VStack(spacing: 8) {
                    Spacer()
                    MiniPlayer()
                        .padding(.horizontal, 24)
                        .padding(.bottom, isScrolling ? 8 : 88)
                }
                .animation(.easeInOut(duration: 0.3), value: isScrolling)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: ContentView.Tab
    let themeColor: Color

    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "house.fill",
                title: NSLocalizedString("tab.home", comment: ""),
                isSelected: selectedTab == .home,
                themeColor: themeColor
            ) {
                if selectedTab != .home {
                    selectedTab = .home
                }
            }

            TabBarButton(
                icon: "checkmark.circle.fill",
                title: NSLocalizedString("tab.plan", comment: ""),
                isSelected: selectedTab == .tasks,
                themeColor: themeColor
            ) {
                if selectedTab != .tasks {
                    selectedTab = .tasks
                }
            }

            TabBarButton(
                icon: "book.fill",
                title: NSLocalizedString("tab.library", comment: ""),
                isSelected: selectedTab == .library,
                themeColor: themeColor
            ) {
                if selectedTab != .library {
                    selectedTab = .library
                }
            }

            TabBarButton(
                icon: "person.fill",
                title: NSLocalizedString("tab.profile", comment: ""),
                isSelected: selectedTab == .profile,
                themeColor: themeColor
            ) {
                if selectedTab != .profile {
                    selectedTab = .profile
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "1A1B3A"))
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let themeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.custom("Poppins-SemiBold", size: 20))
                    .foregroundColor(isSelected ? themeColor : .white.opacity(0.4))

                Text(title)
                    .font(.custom("Poppins-Medium", size: 10))
                    .foregroundColor(isSelected ? themeColor : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? themeColor.opacity(0.1) : .clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
}
