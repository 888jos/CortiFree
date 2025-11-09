//
//  WeeklyStatusView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Redesigned to match Figma specifications
//

import SwiftUI

// MARK: - Day Status Enum

enum DayStatus {
    case none       // No activity
    case completed  // Task completed
    case missed     // Task not completed
}

// MARK: - Day Progress Model

struct DayProgress: Identifiable {
    let id = UUID()
    let label: String       // e.g., "L", "M", "M", "J", "V", "S", "D"
    let status: DayStatus
    let dayIndex: Int       // Unique index to differentiate days (0-6)

    init(label: String, status: DayStatus, dayIndex: Int = 0) {
        self.label = label
        self.status = status
        self.dayIndex = dayIndex
    }
}

// MARK: - Weekly Status View

struct WeeklyStatusView: View {
    let weekDays: [DayProgress]
    let onDaySelected: ((DayProgress) -> Void)?

    @State private var selectedDayId: UUID?
    @State private var animatingDayId: UUID?

    init(
        weekDays: [DayProgress],
        onDaySelected: ((DayProgress) -> Void)? = nil
    ) {
        self.weekDays = weekDays
        self.onDaySelected = onDaySelected
    }

    var body: some View {
        HStack(spacing: -2) {
            ForEach(Array(weekDays.enumerated()), id: \.element.id) { index, day in
                DayCircleView(
                    day: day,
                    isAnimating: animatingDayId == day.id,
                    onTap: {
                        handleDayTap(day)
                    }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Day Tap Handler

    private func handleDayTap(_ day: DayProgress) {
        // Haptic feedback
        HapticManager.light()

        // Trigger animation
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            animatingDayId = day.id
        }

        // Reset animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                animatingDayId = nil
            }
        }

        // Call selection handler
        onDaySelected?(day)
    }
}

// MARK: - Day Circle View

struct DayCircleView: View {
    let day: DayProgress
    let isAnimating: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Circle with status
                ZStack {
                    // Base circle
                    Circle()
                        .fill(Color(hex: "49288C"))
                        .frame(width: 40, height: 40)

                    // Gradient border for completed state
                    if day.status == .completed {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.appTheme,
                                        Color.appThemeSecondary
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 40, height: 40)
                            .shadow(
                                color: Color.appTheme.opacity(0.4),
                                radius: 4,
                                x: 0,
                                y: 0
                            )
                    }

                    // Status icon
                    Group {
                        switch day.status {
                        case .completed:
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                        case .missed:
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                        case .none:
                            EmptyView()
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .shadow(
                    color: Color.black.opacity(0.2),
                    radius: 4,
                    x: 0,
                    y: 2
                )

                // Day label
                Text(day.label)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Dark background for preview
        LinearGradient(
            colors: [
                Color(hex: "1F0140"),
                Color(hex: "0B011B"),
                Color(hex: "01000C")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 40) {
            // Example 1: Mixed states
            VStack(spacing: 12) {
                Text("Semaine en cours")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)

                WeeklyStatusView(
                    weekDays: [
                        DayProgress(label: "L", status: .completed, dayIndex: 0),
                        DayProgress(label: "M", status: .completed, dayIndex: 1),
                        DayProgress(label: "M", status: .none, dayIndex: 2),
                        DayProgress(label: "J", status: .missed, dayIndex: 3),
                        DayProgress(label: "V", status: .none, dayIndex: 4),
                        DayProgress(label: "S", status: .completed, dayIndex: 5),
                        DayProgress(label: "D", status: .none, dayIndex: 6)
                    ]
                ) { selectedDay in
                    print("Selected day \(selectedDay.dayIndex): \(selectedDay.label)")
                }
            }
            .padding(.horizontal, 24)

            // Example 2: All completed
            VStack(spacing: 12) {
                Text("Semaine parfaite")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)

                WeeklyStatusView(
                    weekDays: [
                        DayProgress(label: "L", status: .completed),
                        DayProgress(label: "M", status: .completed),
                        DayProgress(label: "M", status: .completed),
                        DayProgress(label: "J", status: .completed),
                        DayProgress(label: "V", status: .completed),
                        DayProgress(label: "S", status: .completed),
                        DayProgress(label: "D", status: .completed)
                    ]
                ) { selectedDay in
                    print("Selected \(selectedDay.label)")
                }
            }
            .padding(.horizontal, 24)

            // Example 3: All pending
            VStack(spacing: 12) {
                Text("Nouvelle semaine")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)

                WeeklyStatusView(
                    weekDays: [
                        DayProgress(label: "L", status: .none),
                        DayProgress(label: "M", status: .none),
                        DayProgress(label: "M", status: .none),
                        DayProgress(label: "J", status: .none),
                        DayProgress(label: "V", status: .none),
                        DayProgress(label: "S", status: .none),
                        DayProgress(label: "D", status: .none)
                    ]
                ) { selectedDay in
                    print("Selected \(selectedDay.label)")
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
