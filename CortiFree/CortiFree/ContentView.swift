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
    @ObservedObject private var sessionPlayer = GuidedSessionPlayer.shared
    @ObservedObject private var planetSettings = PlanetSettings.shared
    @State private var isScrolling = false
    @State private var isEditingPlan = false
    @State private var scrollTimer: Timer?
    @State private var isAssistantPresented = false
    @State private var assistantPulse = false
    @ObservedObject private var bilanCenter = PlanBilanCenter.shared

    private var isMiniPlayerVisible: Bool {
        soundPlayer.currentExercise != nil || sessionPlayer.currentSession != nil
    }

    enum Tab {
        case home
        case tasks
        case progress
        case library
        case profile
    }


    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            // IMPORTANT: Do NOT use .id() on tabs — it forces full view recreation
            // and re-triggers all .onAppear Firestore reads on every tab switch
            Group {
                switch selectedTab {
                case .home:
                    HomeView(isScrolling: $isScrolling, scrollTimer: $scrollTimer)
                case .tasks:
                    TasksV2View(isScrolling: $isScrolling, isEditingPlan: $isEditingPlan)
                case .progress:
                    ProgressDashboardView()
                case .library:
                    LibraryView()
                case .profile:
                    ProfileView(selectedTab: $selectedTab)
                }
            }

            // Custom Tab Bar - Smart hide/show on scroll
            CustomTabBar(selectedTab: $selectedTab)
                .overlay(alignment: .topTrailing) {
                    Button {
                        HapticManager.light()
                        isAssistantPresented = true
                    } label: {
                        Image("cortifree_assistant_avatar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 96)
                            .scaleEffect(assistantPulse ? 1.025 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open CortiFree Assistant")
                    // Keep the floating assistant above the tab bar, and above the mini player when one is showing.
                    .offset(x: -10, y: isMiniPlayerVisible ? -176 : -104)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isMiniPlayerVisible)
                    // Out of the way while the content scrolls (it would cover the cards' checkmarks).
                    .opacity(isScrolling || isEditingPlan ? 0 : 1)
                    .allowsHitTesting(!(isScrolling || isEditingPlan))
                    .animation(.easeInOut(duration: 0.2), value: isEditingPlan)
                }
                .offset(y: isScrolling ? 100 : 0)
                .animation(.easeInOut(duration: 0.3), value: isScrolling)

            // Mini Player (guided session or ambient sound) - positioned above TabBar
            if isMiniPlayerVisible {
                VStack(spacing: 8) {
                    Spacer()
                    MiniPlayer()
                        .padding(.horizontal, 24)
                        .padding(.bottom, isScrolling ? 8 : 96)
                }
                .animation(.easeInOut(duration: 0.3), value: isScrolling)
            }

        }
        // Streak / day-complete banners and unlock screens, one at a time, above every tab.
        .overlay(alignment: .top) { CelebrationHost() }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: sessionPlayer.currentSession?.id)
        .ignoresSafeArea(.keyboard)
        // « Ton bilan des 28 jours », once per cycle (day 28, or the first days of the next cycle).
        .fullScreenCover(item: $bilanCenter.request) { request in
            PlanBilanView(request: request)
        }
        // Plan reminders (PlanReminderScheduler): open the plan, the review or Milo.
        .onReceive(NotificationRouter.shared.$pendingAppLink.compactMap { $0 }) { url in
            NotificationRouter.shared.pendingAppLink = nil
            if url.host == "milo" {
                isAssistantPresented = true
            } else {
                selectedTab = .tasks
                PlanBilanCenter.shared.checkAfterLaunch(source: "notification")
            }
        }
        .fullScreenCover(isPresented: $sessionPlayer.isFullPlayerPresented) {
            NowPlayingView()
                .presentationBackground(.clear)
        }
        // Streak shown on Home / Profile must be right without opening the Plan tab first.
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            StreakService.shared.refresh()
            PlanBilanCenter.shared.checkAfterLaunch(source: "app_open")
        }
        .sheet(isPresented: $isAssistantPresented) {
            AssistantChatView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            StreakService.shared.refresh()
            PlanReminderScheduler.shared.start()
            PlanBilanCenter.shared.checkAfterLaunch(source: "app_open")
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                assistantPulse = true
            }
            #if DEBUG
            if ProcessInfo.processInfo.environment["CORTIFREE_DEBUG_PROGRESS"] == "1" {
                selectedTab = .progress
            }
            #endif
        }
        .onOpenURL { url in
            // A PDF or text file shared to CortiFree (« Open in CortiFree »): Milo reads it.
            if url.isFileURL {
                MiloImportCenter.shared.receive(url)
                isAssistantPresented = true
            } else if url.scheme == "cortifree" && url.host == "tasks" {
                selectedTab = .tasks
            } else if url.scheme == "cortifree" && url.host == "progress" {
                selectedTab = .progress
            }
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: ContentView.Tab
    // Refresh tab titles immediately after a language change in Settings
    @ObservedObject private var languageManager = LanguageManager.shared

    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *) {
            tabButtons
                .glassEffect(
                    .regular
                        .tint(Color(hex: "17182E").opacity(0.82))
                        .interactive(),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .environment(\.colorScheme, .dark)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
        } else {
            tabButtons
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .environment(\.colorScheme, .dark)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
        }
    }

    private var tabButtons: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "house.fill",
                title: LanguageManager.shared.localizedString(for: "tab.home"),
                isSelected: selectedTab == .home
            ) {
                if selectedTab != .home {
                    selectedTab = .home
                }
            }

            TabBarButton(
                icon: "list.bullet.clipboard.fill",
                title: LanguageManager.shared.localizedString(for: "tab.plan"),
                isSelected: selectedTab == .tasks
            ) {
                if selectedTab != .tasks {
                    selectedTab = .tasks
                }
            }

            TabBarButton(
                icon: "chart.line.uptrend.xyaxis",
                title: LanguageManager.shared.localizedString(for: "tab.progress"),
                isSelected: selectedTab == .progress
            ) {
                if selectedTab != .progress {
                    selectedTab = .progress
                }
            }

            TabBarButton(
                icon: "books.vertical.fill",
                title: LanguageManager.shared.localizedString(for: "tab.library"),
                isSelected: selectedTab == .library
            ) {
                if selectedTab != .library {
                    selectedTab = .library
                }
            }

            TabBarButton(
                icon: "person.fill",
                title: LanguageManager.shared.localizedString(for: "tab.profile"),
                isSelected: selectedTab == .profile
            ) {
                if selectedTab != .profile {
                    selectedTab = .profile
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .frame(height: 62)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void


    var body: some View {
        Button(action: {
            HapticManager.light()
            withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                action()
            }
        }) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                    .frame(height: 24)

                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.primary.opacity(0.1))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

}

#Preview {
    ContentView()
}
