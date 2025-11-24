//
//  DistractionsAndROIView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Combined screen: Distractions time + ROI calculation
//

import SwiftUI

struct DistractionsAndROIView: View {
    let onContinue: () -> Void

    @State private var currentStep: Step = .distractions
    @State private var selectedHours: Int = 22
    @State private var hourlyValue: Double = 10

    enum Step {
        case distractions
        case roi
    }

    private var progress: Double {
        currentStep == .distractions ? 2.0 / 5.0 : 3.0 / 5.0
    }

    private var yearlySavings: Int {
        Int(hourlyValue * Double(selectedHours) * 52)
    }

    private var currentWeek: Int {
        3
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation header
                HStack(spacing: 0) {
                    // Back button
                    Button(action: {
                        HapticManager.light()
                        if currentStep == .roi {
                            withAnimation {
                                currentStep = .distractions
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.custom("Poppins-Bold", size: 22))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                    }
                    .padding(.leading, 30)

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "1D1D1D"))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "B794F6"),
                                            Color(hex: "D4B4FF")
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 8)
                                .animation(.easeInOut, value: progress)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 16)

                    // Language flag
                    Text("🇫🇷 FRA")
                        .font(.custom("Poppins-Medium", size: 10))
                        .foregroundColor(.white)
                        .padding(.trailing, 30)
                }
                .frame(height: 20)
                .padding(.top, 50)

                Spacer()

                // Content based on current step
                if currentStep == .distractions {
                    distractionsContent
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                } else {
                    roiContent
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }

                Spacer()

                // Bottom button
                Button(action: {
                    HapticManager.medium()
                    if currentStep == .distractions {
                        withAnimation {
                            currentStep = .roi
                        }
                    } else {
                        onContinue()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Suivant")
                            .font(.custom("Poppins-SemiBold", size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "B794F6"), Color(hex: "D4B4FF")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Distractions Content

    private var distractionsContent: some View {
        VStack(spacing: 0) {
            // Title
            Text("Combien d'heures par\nsemaine gaspillez-vous en\ndistractions ?")
                .font(Font.Poppins.custom(.bold, size: 28))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)

            // Subtitle
            Text("Ex : défilement inutile, procrastination")
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)

            // Circular picker with segments
            ZStack {
                ForEach(0..<50, id: \.self) { index in
                    SegmentLine(
                        isActive: index < selectedHours,
                        angle: Double(index) * (360.0 / 50.0)
                    )
                }

                Text("\(selectedHours)h")
                    .font(Font.Poppins.custom(.bold, size: 48))
                    .foregroundColor(Color(hex: "FF2222"))
            }
            .frame(width: 168, height: 168)
            .padding(.bottom, 60)

            // Slider section
            VStack(spacing: 16) {
                Text("Environ \(selectedHours) heures")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)

                SliderWithClockThumb(value: Binding(
                    get: { Double(selectedHours) },
                    set: { selectedHours = Int($0) }
                ), in: 0...50)
                .frame(height: 62)
                .scaleEffect(x: 0.9, y: 1.0, anchor: .center)
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - ROI Content

    private var roiContent: some View {
        VStack(spacing: 0) {
            // Title
            Text("Retour potentiel de\nLife Reset")
                .font(Font.Poppins.custom(.bold, size: 32))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)

            // Subtitle
            Text("Si vous vendiez une heure de votre vie,\ncombien demanderiez-vous ?")
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.bottom, 60)

            // Main card - Two sections: gray top, green bottom
            VStack(spacing: 0) {
                // Top section: Gray background with slider and circles
                VStack(spacing: 0) {
                    // Slider section - tightened spacing
                    VStack(spacing: 8) {
                        Text("Si une heure de votre temps vaut")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.8))

                        Text("€\(Int(hourlyValue)) par heure")
                            .font(Font.Poppins.custom(.bold, size: 32))
                            .foregroundColor(.white)

                        Slider(value: $hourlyValue, in: 5...100, step: 5)
                            .accentColor(.white.opacity(0.5))
                            .frame(height: 40)
                            .padding(.horizontal, 12)
                    }
                    .padding(.top, 24)

                    // Spacer to push circles to bottom
                    Spacer()

                    // Timeline visualization with 20 circles (one per 5€ lock) + curve
                    ZStack(alignment: .bottom) {
                        // White circle with green stroke indicator + "Vous êtes ici" label
                        GeometryReader { geometry in
                            ZStack {
                                // White circle with green stroke - follows slider thumb position
                                let index = Int(hourlyValue / 5) - 1
                                if index >= 0 && index < 20 {
                                    let width = geometry.size.width
                                    let height: CGFloat = 120

                                    // Match slider thumb behavior: thumb diameter ~28px
                                    let thumbRadius: CGFloat = 14
                                    let usableWidth = width - (thumbRadius * 2)

                                    // Calculate position based on value progression (0 to 19)
                                    let normalizedProgress = Double(index) / 19.0
                                    let x = thumbRadius + CGFloat(normalizedProgress) * usableWidth

                                    // Y position: start just above rectangles, grow upward (20% higher for 100€)
                                    let y = height - 20 - normalizedProgress * 96

                                    // "Vous êtes ici" label above the circle
                                    Text("Vous êtes ici")
                                        .font(.custom("Poppins-SemiBold", size: 10))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.green)
                                        )
                                        .position(x: x, y: y - 20)

                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 12, height: 12)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.green, lineWidth: 2)
                                        )
                                        .position(x: x, y: y)
                                }
                            }
                        }
                        .frame(height: 120)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 16)

                        // Rectangles - only one green at current position
                        GeometryReader { geometry in
                            let width = geometry.size.width
                            let thumbRadius: CGFloat = 14
                            let usableWidth = width - (thumbRadius * 2)
                            let rectangleWidth: CGFloat = 8

                            ZStack(alignment: .leading) {
                                ForEach(0..<20, id: \.self) { index in
                                    let normalizedPosition = Double(index) / 19.0
                                    let xPosition = thumbRadius + CGFloat(normalizedPosition) * usableWidth - rectangleWidth / 2

                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(index == Int(hourlyValue / 5) - 1 ? Color.green : Color.gray.opacity(0.3))
                                        .frame(width: rectangleWidth, height: 16)
                                        .offset(x: xPosition, y: 0)
                                }
                            }
                        }
                        .frame(height: 16)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 16)
                    }
                }
                .padding(.horizontal, 24)
                .background(Color(hex: "2A2A2A"))

                // Bottom section: Green background with savings
                HStack(spacing: 8) {
                    Text("Vous pourriez économiser")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white)

                    Text("€\(yearlySavings)")
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundColor(.white)

                    Text("par an")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.green)
            }
            .clipShape(RoundedRectangle(cornerRadius: 40))
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }
}

// MARK: - Growth Curve Shape

struct GrowthCurve: Shape {
    let progress: Double  // 0.0 to 1.0
    let activeCircles: Int  // Number of active circles

    func path(in rect: CGRect) -> Path {
        var path = Path()

        guard activeCircles > 0 else { return path }

        let width = rect.width
        let height = rect.height
        let circleSpacing = width / 19.0  // 20 circles with 19 spaces

        // Start from first circle
        path.move(to: CGPoint(x: 0, y: height))

        // Draw curve through active circles
        for i in 0..<activeCircles {
            let x = CGFloat(i) * circleSpacing
            // Y position grows proportionally - exponential curve
            let normalizedProgress = Double(i) / 19.0
            let y = height * (1.0 - normalizedProgress * progress)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

#Preview {
    DistractionsAndROIView(onContinue: {})
}
