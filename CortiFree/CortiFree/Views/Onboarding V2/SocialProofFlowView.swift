//
//  SocialProofFlowView.swift
//  CortiFree
//
//  Created by Claude on 07/11/2025.
//  Social proof flow before paywall
//

import SwiftUI

struct SocialProofFlowView: View {
    @State private var currentPage = 0
    @Environment(\.dismiss) var dismiss
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView()
                .ignoresSafeArea()

            ZStack {
                // Screen 1: Testimonials
                if currentPage == 0 {
                    TestimonialsView(onContinue: {
                        withAnimation {
                            currentPage = 1
                        }
                    })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }

                // Screen 2: Before/After Statistics
                if currentPage == 1 {
                    BeforeAfterStatsView(onContinue: {
                        withAnimation {
                            currentPage = 2
                        }
                    })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }

                // Screen 3: Goals Selection
                if currentPage == 2 {
                    GoalsSelectionView(onContinue: {
                        onComplete()
                    })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Screen 1: Testimonials

struct TestimonialsView: View {
    var onContinue: () -> Void

    private let testimonials = [
        Testimonial(
            name: "Sophie",
            age: 31,
            title: "Ma vie a changé",
            text: "Avant CortiFree, je dormais mal et je me sentais épuisée tout le temps. Après deux semaines, j'ai remarqué que je me réveillais plus reposée et que mon stress au boulot avait diminué. L'app m'appris des exercices simples de respiration mais qui font une vraie différence. Je recommande à tous ceux qui se sentent débordés par leur quotidien.",
            rating: 5
        ),
        Testimonial(
            name: "Julien",
            age: 28,
            title: "Enfin du calme",
            text: "J'étais sceptique, mais CortiFree m'a surpris. Mon anxiété était constante à cause du travail, et je ne savais plus me concentrer. Grâce aux sessions guidées et aux rappels, j'ai repris le contrôle petit à petit. Après un mois, mes collègues ont même remarqué que j'étais plus détendu. Vraiment utile !",
            rating: 5
        ),
        Testimonial(
            name: "Claire",
            age: 34,
            title: "Un regain d'énergie",
            text: "Entre les enfants et mon job, j'étais à bout et mes migraines revenaient souvent. CortiFree m'a aidé à identifier mes triggers de stress et à les gérer. Aujourd'hui, je me sens plus sereine et j'ai retrouvé de l'énergie pour profiter de ma famille.",
            rating: 5
        ),
        Testimonial(
            name: "Marc",
            age: 42,
            title: "Meilleur sommeil",
            text: "Je me réveillais plusieurs fois par nuit et je traînais une fatigue constante. CortiFree m'a appris des techniques de relaxation qui ont transformé mes nuits. Maintenant je dors profondément et je me réveille en forme. Un changement radical pour ma qualité de vie.",
            rating: 5
        ),
        Testimonial(
            name: "Emma",
            age: 26,
            title: "Plus sereine",
            text: "Mon stress au quotidien me rendait irritable et fatiguée. Avec CortiFree, j'ai découvert comment mieux gérer mes émotions et prendre du recul. Les exercices sont simples mais efficaces. Je me sens tellement mieux dans ma peau maintenant !",
            rating: 5
        ),
        Testimonial(
            name: "Thomas",
            age: 37,
            title: "Concentration retrouvée",
            text: "J'avais du mal à me concentrer plus de 10 minutes et ça impactait mon travail. Les techniques de pleine conscience de CortiFree ont vraiment fait la différence. Aujourd'hui je peux me focaliser sur mes tâches pendant des heures sans perdre le fil.",
            rating: 5
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Testimonials cards with header
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Title
                    VStack(spacing: 12) {
                        Text("Des milliers de vies changées grâce à CortiFree")
                            .font(.custom("Poppins-Bold", size: 24))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(hex: "B794F6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        (Text("Découvre comment des personnes comme toi ont retrouvé leur ")
                            .foregroundColor(.white.opacity(0.85)) +
                        Text("sérénité")
                            .foregroundColor(Color(hex: "B794F6")))
                            .font(.custom("Poppins-Regular", size: 16))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 80)
                    .padding(.bottom, 40)

                    // Testimonial cards
                    VStack(spacing: 20) {
                        ForEach(testimonials) { testimonial in
                            TestimonialCard(testimonial: testimonial)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 140)
                }
            }

            Spacer()

            // Continue button
            Button(action: {
                HapticManager.light()
                onContinue()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "1A1A4E"))

                    Text("Continuer")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(Color(hex: "1A1A4E"))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 40))
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 80)
        }
    }
}

struct Testimonial: Identifiable {
    let id = UUID()
    let name: String
    let age: Int
    let title: String
    let text: String
    let rating: Int
}

struct TestimonialCard: View {
    let testimonial: Testimonial

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Icon/Avatar on left (outside rectangle)
            ZStack {
                Circle()
                    .fill(Color(hex: "53D7D9").opacity(0.3))
                    .frame(width: 50, height: 50)

                Text(String(testimonial.name.prefix(1)))
                    .font(.custom("Poppins-Bold", size: 20))
                    .foregroundColor(.white)
            }
            .padding(.trailing, 12)

            // Content rectangle
            VStack(alignment: .leading, spacing: 6) {
                // Name and age on same line
                HStack(spacing: 4) {
                    Text(testimonial.name)
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.white)

                    Text("• \(testimonial.age) ans")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }

                // Stars
                HStack(spacing: 3) {
                    ForEach(0..<testimonial.rating, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "B794F6"))
                    }
                }

                // Title in bold
                Text(testimonial.title)
                    .font(.custom("Poppins-Bold", size: 14))
                    .foregroundColor(.white)
                    .lineSpacing(2)

                // Review text
                Text(testimonial.text)
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "B794F6").opacity(0.4), Color.black.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
        }
    }
}

// MARK: - Screen 2: Before/After Statistics

struct BeforeAfterStatsView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(spacing: 12) {
                Text("Des résultats mesurables")
                    .font(.custom("Poppins-Bold", size: 32))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("En moyenne, une réduction de 68% du stress ressenti en seulement 60 jours")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 80)
            .padding(.bottom, 40)

            // Stress evolution chart
            StressEvolutionChart()
                .padding(.horizontal, 34)
                .padding(.vertical, 20)

            Spacer()

            // Continue button
            Button(action: {
                HapticManager.light()
                onContinue()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "1A1A4E"))

                    Text("Continuer")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(Color(hex: "1A1A4E"))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 40))
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 80)
        }
    }
}

struct StressEvolutionChart: View {
    // Data points for the curves (0-100 scale)
    private let withoutAppData: [Double] = [75, 78, 80, 82, 85, 87, 90]
    private let withAppData: [Double] = [75, 65, 55, 45, 35, 28, 22]
    private let timeLabels = ["Jour 1", "Sem. 1", "Sem. 2", "Sem. 3", "Sem. 4", "Sem. 5", "Sem. 6"]

    @State private var animationProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Legend
            HStack(spacing: 24) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red.opacity(0.8))
                        .frame(width: 12, height: 12)
                    Text("Sans CortiFree")
                        .font(.custom("Poppins-Medium", size: 13))
                        .foregroundColor(.white.opacity(0.85))
                }

                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    Text("Avec CortiFree")
                        .font(.custom("Poppins-Medium", size: 13))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(.bottom, 24)

            // Chart
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height - 40
                let chartHeight = height - 20

                ZStack(alignment: .bottomLeading) {
                    // Grid lines
                    GridLinesView(chartHeight: chartHeight)

                    // Chart curves and points
                    ChartCurvesView(
                        withoutAppData: withoutAppData,
                        withAppData: withAppData,
                        width: width,
                        chartHeight: chartHeight,
                        animationProgress: animationProgress
                    )

                    // X-axis labels
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: chartHeight)

                        HStack(spacing: 0) {
                            Spacer().frame(width: 35)
                            ForEach(timeLabels.indices, id: \.self) { index in
                                Text(timeLabels[index])
                                    .font(.custom("Poppins-Regular", size: 10))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.top, 12)
                    }
                }

                // Y-axis label
                Text("Niveau de stress")
                    .font(.custom("Poppins-Medium", size: 11))
                    .foregroundColor(.white.opacity(0.6))
                    .rotationEffect(.degrees(-90))
                    .offset(x: -height / 2 + 10, y: height / 2 - 15)
            }
            .frame(height: 300)

            // X-axis label
            Text("Durée")
                .font(.custom("Poppins-Medium", size: 11))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0)) {
                animationProgress = 1.0
            }
        }
    }
}

// MARK: - Screen 3: Goals Selection

struct GoalsSelectionView: View {
    @State private var selectedGoals: Set<Int> = []
    var onContinue: () -> Void

    private let goals = [
        "Réduire mon stress",
        "Mieux dormir",
        "Améliorer ma concentration",
        "Retrouver mon énergie",
        "Gérer mes émotions",
        "Me sentir plus calme",
        "Réduire mon anxiété",
        "Améliorer ma santé mentale"
    ]

    private let goalColors = [
        Color(hex: "FF6B6B"), // Red-pink
        Color(hex: "4ECDC4"), // Turquoise
        Color(hex: "FFE66D"), // Yellow
        Color(hex: "95E1D3"), // Mint green
        Color(hex: "C7CEEA"), // Lavender
        Color(hex: "FFB6B9"), // Light pink
        Color(hex: "A8E6CF"), // Pastel green
        Color(hex: "FFDAC1")  // Peach
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(spacing: 12) {
                Text("Tes objectifs")
                    .font(.custom("Poppins-Bold", size: 32))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Sélectionne ce que tu souhaites améliorer")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 80)
            .padding(.bottom, 40)

            // Goals grid
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(0..<goals.count, id: \.self) { index in
                        GoalButton(
                            text: goals[index],
                            isSelected: selectedGoals.contains(index),
                            color: goalColors[index],
                            onTap: {
                                HapticManager.light()
                                if selectedGoals.contains(index) {
                                    selectedGoals.remove(index)
                                } else {
                                    selectedGoals.insert(index)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 140)
            }

            Spacer()

            // Continue button
            Button(action: {
                HapticManager.light()
                // Save selected goals to UserDefaults
                UserDefaults.standard.set(Array(selectedGoals), forKey: "selectedGoals")
                onContinue()
            }) {
                Text("Voir mes options")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(Color(hex: "1A1A4E"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 80)
            .disabled(selectedGoals.isEmpty)
            .opacity(selectedGoals.isEmpty ? 0.5 : 1.0)
        }
    }
}

struct GoalButton: View {
    let text: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Text(text)
                    .font(.custom("Poppins-Medium", size: 15))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? color : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Helper Views for Chart

struct GridLinesView: View {
    let chartHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<5) { index in
                HStack {
                    Text("\(100 - index * 25)")
                        .font(.custom("Poppins-Regular", size: 10))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 30, alignment: .trailing)

                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                }
                if index < 4 {
                    Spacer()
                }
            }
        }
        .frame(height: chartHeight)
        .padding(.leading, 35)
    }
}

struct ChartCurvesView: View {
    let withoutAppData: [Double]
    let withAppData: [Double]
    let width: CGFloat
    let chartHeight: CGFloat
    let animationProgress: CGFloat

    var body: some View {
        ZStack {
            // Red curve (without app)
            CurvePathView(data: withoutAppData, width: width, chartHeight: chartHeight, color: Color.red.opacity(0.8), animationProgress: animationProgress)

            // Green curve (with app)
            CurvePathView(data: withAppData, width: width, chartHeight: chartHeight, color: Color.green, animationProgress: animationProgress)

            // Data points for red curve
            DataPointsView(data: withoutAppData, width: width, chartHeight: chartHeight, color: Color.red.opacity(0.8), animationProgress: animationProgress)

            // Data points for green curve
            DataPointsView(data: withAppData, width: width, chartHeight: chartHeight, color: Color.green, animationProgress: animationProgress)

            // Annotations
            AnnotationsView(
                withoutAppData: withoutAppData,
                withAppData: withAppData,
                width: width,
                chartHeight: chartHeight,
                animationProgress: animationProgress
            )
        }
        .frame(height: chartHeight)
    }
}

struct CurvePathView: View {
    let data: [Double]
    let width: CGFloat
    let chartHeight: CGFloat
    let color: Color
    let animationProgress: CGFloat

    var body: some View {
        Path { path in
            let points = data.enumerated().map { index, value in
                CGPoint(
                    x: 35 + CGFloat(index) * (width - 35) / CGFloat(data.count - 1),
                    y: chartHeight - (CGFloat(value) / 100.0 * chartHeight)
                )
            }

            if let first = points.first {
                path.move(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
        }
        .trim(from: 0, to: animationProgress)
        .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }
}

struct DataPointsView: View {
    let data: [Double]
    let width: CGFloat
    let chartHeight: CGFloat
    let color: Color
    let animationProgress: CGFloat

    var body: some View {
        ForEach(data.indices, id: \.self) { index in
            let value = data[index]
            let pointProgress = CGFloat(index) / CGFloat(data.count - 1)
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .position(
                    x: 35 + CGFloat(index) * (width - 35) / CGFloat(data.count - 1),
                    y: chartHeight - (CGFloat(value) / 100.0 * chartHeight)
                )
                .opacity(animationProgress >= pointProgress ? 1 : 0)
                .scaleEffect(animationProgress >= pointProgress ? 1 : 0.5)
        }
    }
}

struct AnnotationsView: View {
    let withoutAppData: [Double]
    let withAppData: [Double]
    let width: CGFloat
    let chartHeight: CGFloat
    let animationProgress: CGFloat

    var body: some View {
        ZStack {
            // Red curve annotation
            VStack(alignment: .trailing, spacing: 2) {
                Text("+90%")
                    .font(.custom("Poppins-Bold", size: 12))
                    .foregroundColor(.red.opacity(0.9))
                Text("Stress élevé")
                    .font(.custom("Poppins-Regular", size: 9))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.5))
            )
            .position(
                x: width - 50,
                y: chartHeight - (CGFloat(withoutAppData.last ?? 90) / 100.0 * chartHeight) - 30
            )
            .opacity(animationProgress >= 0.9 ? 1 : 0)
            .scaleEffect(animationProgress >= 0.9 ? 1 : 0.8)

            // Green curve annotation
            VStack(alignment: .leading, spacing: 2) {
                Text("-70%")
                    .font(.custom("Poppins-Bold", size: 12))
                    .foregroundColor(.green)
                Text("Stress faible")
                    .font(.custom("Poppins-Regular", size: 9))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.5))
            )
            .position(
                x: width - 50,
                y: chartHeight - (CGFloat(withAppData.last ?? 22) / 100.0 * chartHeight) + 25
            )
            .opacity(animationProgress >= 0.9 ? 1 : 0)
            .scaleEffect(animationProgress >= 0.9 ? 1 : 0.8)
        }
    }
}

#Preview {
    SocialProofFlowView(onComplete: {})
}
