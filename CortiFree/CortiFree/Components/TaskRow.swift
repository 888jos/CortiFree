//
//  TaskRow.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import SwiftUI

struct TaskRow: View {
    let task: TaskItem
    let onComplete: () -> Void
    let onDelete: () -> Void
    var onTap: (() -> Void)? = nil

    @State private var isCompleted: Bool = false

    var body: some View {
        // Main task row
        Button(action: {
            // Open detail on tap
            if onTap != nil {
                triggerHaptic(.light)
                onTap?()
            }
        }) {
            ZStack(alignment: .topLeading) {
                // Main content
                HStack(alignment: .center, spacing: 12) {
                    // SF Symbol Icon (left)
                    if let symbol = task.sfSymbol {
                        Image(systemName: symbol)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.appTheme, Color.appThemeSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                    }

                    // Task title
                    Text(task.title)
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(isCompleted ? .white.opacity(0.5) : .white)
                        .strikethrough(isCompleted, color: .white.opacity(0.5))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Checkmark (right)
                    Button(action: {
                        // Toggle completion when checkmark is clicked
                        triggerHaptic(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isCompleted.toggle()
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onComplete()
                        }
                    }) {
                        ZStack {
                            // Background circle
                            Circle()
                                .fill(
                                    isCompleted
                                        ? LinearGradient(
                                            colors: [Color.appTheme, Color.appThemeSecondary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                .frame(width: 28, height: 28)

                            // Checkmark icon
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "2A2B5A").opacity(0.6))
                )

                // Recommended time (top left corner inside the card)
                if let time = task.recommendedTime {
                    Text(time)
                        .font(.custom("Poppins-Regular", size: 10))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.4))
                        )
                        .offset(x: 12, y: 6)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            isCompleted = task.completed
        }
        .onChange(of: task.completed) { _, newValue in
            isCompleted = newValue
        }
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "1A1B3A"), Color(hex: "0D0E1F")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 12) {
            TaskRow(
                task: TaskItem(
                    title: "Respiration 4-7-8",
                    category: . morning,
                    sfSymbol: "wind",
                    recommendedTime: "07:00"
                ),
                onComplete: {},
                onDelete: {}
            )

            TaskRow(
                task: TaskItem(
                    title: "Méditer 5 minutes",
                    category: .morning,
                    completed: true,
                    sfSymbol: "figure.mind.and.body",
                    recommendedTime: "08:00"
                ),
                onComplete: {},
                onDelete: {}
            )
        }
        .padding()
    }
}
