//
//  StatsChart.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import SwiftUI

struct StatsChart: View {
    let data: [(date: Date, rate: Double)]
    let period: Int // 7, 30, or 90 days

    @State private var animatedData: [CGFloat] = []

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let leftMargin: CGFloat = 40
            let bottomMargin: CGFloat = 30
            let chartWidth = width - leftMargin
            let chartHeight = height - bottomMargin
            let stepX = chartWidth / CGFloat(max(data.count - 1, 1))

            ZStack(alignment: .topLeading) {
                // Y-axis labels (percentages)
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach([100, 75, 50, 25, 0], id: \.self) { value in
                        Text("\(value)%")
                            .font(.custom("Poppins-Regular", size: 10))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(height: chartHeight / 4, alignment: .top)
                    }
                }
                .frame(width: leftMargin - 5)
                .offset(y: 0)

                VStack(spacing: 0) {
                    ZStack {
                        // Grid lines
                        ForEach(0..<5) { i in
                            let y = chartHeight * CGFloat(i) / 4
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: chartWidth, y: y))
                            }
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        }

                        // Line chart
                        Path { path in
                            guard !animatedData.isEmpty else { return }

                            let startPoint = CGPoint(x: 0, y: chartHeight - (chartHeight * animatedData[0]))
                            path.move(to: startPoint)

                            for (index, value) in animatedData.enumerated() {
                                let x = CGFloat(index) * stepX
                                let y = chartHeight - (chartHeight * value)
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        .stroke(
                            LinearGradient(
                                colors: [Color.appTheme, Color.appThemeSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )

                        // Gradient fill
                        Path { path in
                            guard !animatedData.isEmpty else { return }

                            let startPoint = CGPoint(x: 0, y: chartHeight - (chartHeight * animatedData[0]))
                            path.move(to: startPoint)

                            for (index, value) in animatedData.enumerated() {
                                let x = CGFloat(index) * stepX
                                let y = chartHeight - (chartHeight * value)
                                path.addLine(to: CGPoint(x: x, y: y))
                            }

                            path.addLine(to: CGPoint(x: chartWidth, y: chartHeight))
                            path.addLine(to: CGPoint(x: 0, y: chartHeight))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appTheme.opacity(0.3),
                                    Color.appThemeSecondary.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // Data points
                        ForEach(animatedData.indices, id: \.self) { index in
                            let x = CGFloat(index) * stepX
                            let y = chartHeight - (chartHeight * animatedData[index])

                            Circle()
                                .fill(Color.appTheme)
                                .frame(width: 6, height: 6)
                                .position(x: x, y: y)
                        }
                    }
                    .frame(height: chartHeight)

                    // X-axis labels (days) - centered below each data point
                    GeometryReader { geo in
                        ForEach(data.indices, id: \.self) { index in
                            Text(formatDate(data[index].date))
                                .font(.custom("Poppins-Regular", size: 8))
                                .foregroundColor(.white.opacity(0.6))
                                .fixedSize()
                                .frame(width: stepX, alignment: .center)
                                .offset(x: CGFloat(index) * stepX - stepX/2, y: 6)
                        }
                    }
                    .frame(height: bottomMargin)
                }
                .offset(x: leftMargin, y: 0)
            }
        }
        .onAppear {
            animateChart()
        }
        .onChange(of: data.count) { _, _ in
            animateChart()
        }
    }

    private func animateChart() {
        // Start with actual values (no animation from 0)
        animatedData = data.map { CGFloat($0.rate * 0.8) }

        // Different animation durations based on period
        let duration: Double = {
            switch period {
            case 7: return 1.0  // 1s for 7 days
            case 30: return 4.0 // 4s for 30 days
            case 90: return 8.0 // 8s for 90 days
            default: return 1.0
            }
        }()

        // Subtle animation to final values
        withAnimation(.easeOut(duration: duration)) {
            animatedData = data.map { CGFloat($0.rate) }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")

        if period == 7 {
            // Pour 7 jours, afficher la première lettre du jour de la semaine
            formatter.dateFormat = "EEEEE" // L, M, M, J, V, S, D
            return formatter.string(from: date).uppercased()
        } else {
            // Pour 30 ou 90 jours, afficher JJ/MM
            formatter.dateFormat = "dd/MM"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    ZStack {
        Color.black

        StatsChart(
            data: [
                (Date(), 0.6),
                (Date(), 0.8),
                (Date(), 0.7),
                (Date(), 0.9),
                (Date(), 0.5),
                (Date(), 0.8),
                (Date(), 0.95)
            ],
            period: 7
        )
        .frame(height: 200)
        .padding()
    }
}
