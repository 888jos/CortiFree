//
//  RoutineDetailView.swift
//  CortiFree
//
//  Created on 19/01/2026.
//

import SwiftUI

struct RoutineDetailView: View {
    let routine: Routine
    @Environment(\.dismiss) var dismiss
    @State private var showPlayer = false

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with back button
                animatedHeader

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Title and description
                        titleSection

                        // Duration and difficulty info
                        infoSection

                        // Impact domains
                        impactSection

                        // Steps preview
                        stepsSection

                        Spacer(minLength: 140)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                // Fixed bottom start button
                startButton
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            RoutinePlayerView(routine: routine)
        }
    }

    // MARK: - Header
    private var animatedHeader: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color(hex: "49288C").opacity(0.3), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .ignoresSafeArea(edges: .top)

            HStack {
                Button(action: {
                    HapticManager.light()
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "1A1B3A").opacity(0.8))
                            .frame(width: 40, height: 40)

                        Image(systemName: "chevron.left")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // Routine type badge
                HStack(spacing: 6) {
                    Image(systemName: routine.icon)
                        .font(.system(size: 12))
                    Text(NSLocalizedString("routines.badge", comment: ""))
                        .font(.custom("Poppins-Bold", size: 11))
                }
                .foregroundColor(Color(hex: routine.color))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(hex: routine.color).opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: routine.color).opacity(0.5), lineWidth: 1)
                        )
                )

                Spacer()

                // Placeholder for symmetry
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
        }
    }

    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(routine.localizedName)
                .font(.custom("Poppins-Bold", size: 28))
                .foregroundColor(.white)

            Text(routine.localizedDescription)
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Info Section
    private var infoSection: some View {
        HStack(spacing: 12) {
            // Duration
            InfoPill(icon: "clock.fill", text: routine.formattedDuration, color: routine.color)

            // Steps count
            InfoPill(icon: "list.number", text: "\(routine.steps.count) \(NSLocalizedString("routines.steps", comment: ""))", color: routine.color)

            // Difficulty
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i < routine.difficulty ? Color(hex: routine.color) : Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
            )
        }
    }

    // MARK: - Impact Section
    private var impactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("routines.impact", comment: ""))
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)

            HStack(spacing: 8) {
                ForEach(routine.impactDomains, id: \.self) { domain in
                    ImpactBadge(domain: domain, color: routine.color)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Steps Section
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("routines.program", comment: ""))
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)

            ForEach(Array(routine.steps.enumerated()), id: \.element.id) { index, step in
                StepPreviewRow(step: step, index: index + 1, color: routine.color)
            }
        }
    }

    // MARK: - Start Button
    private var startButton: some View {
        VStack(spacing: 16) {
            Button(action: {
                HapticManager.success()
                showPlayer = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))

                    Text(NSLocalizedString("routines.start", comment: ""))
                        .font(.custom("Poppins-Bold", size: 18))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: routine.color), Color(hex: routine.color).opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .blur(radius: 20)
                            .offset(y: 8)

                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: routine.color), Color(hex: routine.color).opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [Color(hex: "01000C"), Color(hex: "01000C").opacity(0.95)],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Helper Components
struct InfoPill: View {
    let icon: String
    let text: String
    let color: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.custom("Poppins-Medium", size: 13))
        }
        .foregroundColor(Color(hex: color))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(hex: color).opacity(0.15))
        )
    }
}

struct ImpactBadge: View {
    let domain: String
    let color: String

    var body: some View {
        Text(NSLocalizedString("domain.\(domain.lowercased())", comment: ""))
            .font(.custom("Poppins-Medium", size: 12))
            .foregroundColor(Color(hex: color))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(hex: color).opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: color).opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

struct StepPreviewRow: View {
    let step: RoutineStep
    let index: Int
    let color: String

    var body: some View {
        HStack(spacing: 16) {
            // Step number
            ZStack {
                Circle()
                    .fill(Color(hex: color).opacity(0.2))
                    .frame(width: 36, height: 36)

                Text("\(index)")
                    .font(.custom("Poppins-Bold", size: 14))
                    .foregroundColor(Color(hex: color))
            }

            // Icon
            Image(systemName: step.icon)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 32)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(step.localizedInstruction)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.white)

                Text(formatStepDuration(step.duration))
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(Color(hex: "B0B8D4"))
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func formatStepDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 && secs > 0 {
            return "\(minutes) min \(secs) sec"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "\(secs) sec"
        }
    }
}

#Preview {
    RoutineDetailView(routine: Routine.morningRoutine)
}
