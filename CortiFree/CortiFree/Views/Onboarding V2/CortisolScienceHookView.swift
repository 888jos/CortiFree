//
//  CortisolScienceHookView.swift
//  CortiFree
//
//  Animated cortisol curve over 24h — "you now" vs "you in 66 days"
//  Shows the science behind cortisol dysregulation in a tangible, visual way
//

import SwiftUI

struct CortisolScienceHookView: View {
    let onContinue: () -> Void

    @State private var screenViewTime: Date?

    // Animation state — only the curves animate
    @State private var curveProgress: CGFloat = 0       // 0→1 draw the curves

    // MARK: - Cortisol curve data points (normalized 0-1, over 24h)
    // "You now" — chronically stressed profile: high morning, crashes afternoon, spikes evening
    private let stressedCurve: [CGFloat] = [
        0.45, 0.60, 0.82, 0.95, 0.88, 0.80, // 00h → 05h (poor sleep, never fully resets)
        0.92, 0.98, 0.90, 0.82, 0.75, 0.68, // 06h → 11h (morning spike too high)
        0.60, 0.55, 0.62, 0.70, 0.65, 0.58, // 12h → 17h (afternoon crash then stress spike)
        0.72, 0.78, 0.70, 0.62, 0.55, 0.48  // 18h → 23h (evening too elevated, can't sleep)
    ]

    // "You in 66 days" — healthy profile: high morning, drops steadily, low at night
    private let healthyCurve: [CGFloat] = [
        0.10, 0.12, 0.15, 0.20, 0.30, 0.45, // 00h → 05h (very low, deep sleep)
        0.70, 0.88, 0.82, 0.72, 0.60, 0.50, // 06h → 11h (healthy morning spike)
        0.40, 0.35, 0.30, 0.28, 0.25, 0.22, // 12h → 17h (gradual decline)
        0.18, 0.15, 0.13, 0.12, 0.11, 0.10  // 18h → 23h (low and ready for sleep)
    ]

    private let timeLabels = ["00h", "06h", "12h", "18h", "23h"]

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Title
                VStack(spacing: 6) {
                    Text("cortisol_hook.title".localized)
                        .font(.faroBold(22))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("cortisol_hook.subtitle".localized)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.45))
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 24)

                // Chart — only the curves inside animate
                cortisolChart
                    .padding(.horizontal, 24)

                Spacer().frame(height: 20)

                // Legend
                HStack(spacing: 20) {
                    legendItem(color: Color(hex: "FF8A80"), label: "cortisol_hook.legend_now".localized)
                    legendItem(color: Color(hex: "4FC3A1"), label: "cortisol_hook.legend_66".localized)
                }

                Spacer().frame(height: 28)

                // Insights — plain editorial style
                VStack(alignment: .leading, spacing: 0) {
                    insightRow(number: "01", text: "cortisol_hook.insight_1".localized)
                    Divider()
                        .background(Color.white.opacity(0.08))
                        .padding(.vertical, 12)
                    insightRow(number: "02", text: "cortisol_hook.insight_2".localized)
                    Divider()
                        .background(Color.white.opacity(0.08))
                        .padding(.vertical, 12)
                    insightRow(number: "03", text: "cortisol_hook.insight_3".localized)
                }
                .padding(.horizontal, 28)

                Spacer()

                // Continue button
                Button(action: {
                    HapticManager.medium()
                    if let startTime = screenViewTime {
                        MixpanelManager.shared.track(
                            event: "onboarding_science_hook_continue",
                            properties: ["time_spent": Date().timeIntervalSince(startTime)]
                        )
                    }
                    onContinue()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "1A1A4E"))

                        Text("cortisol_hook.cta".localized)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(Color(hex: "1A1A4E"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            screenViewTime = Date()
            MixpanelManager.shared.track(event: "onboarding_science_hook_viewed")
            startAnimations()
        }
    }

    // MARK: - Cortisol Chart

    private var cortisolChart: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<4) { i in
                        Spacer()
                        Rectangle()
                            .fill(Color.white.opacity(i == 3 ? 0.15 : 0.06))
                            .frame(height: 1)
                    }
                }

                // Zone labels (right side)
                GeometryReader { geo in
                    let h = geo.size.height
                    VStack(spacing: 0) {
                        Text("cortisol_hook.level_high".localized)
                            .font(.custom("Poppins-Regular", size: 9))
                            .foregroundColor(Color(hex: "FF8A80").opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Spacer()
                        Text("cortisol_hook.level_normal".localized)
                            .font(.custom("Poppins-Regular", size: 9))
                            .foregroundColor(Color(hex: "4FC3A1").opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Spacer()
                        Text("cortisol_hook.level_low".localized)
                            .font(.custom("Poppins-Regular", size: 9))
                            .foregroundColor(.white.opacity(0.3))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.trailing, 4)
                    .frame(height: h)
                }

                // Curves
                GeometryReader { geo in
                    let w = geo.size.width - 30 // leave room for labels
                    let h = geo.size.height

                    ZStack {
                        // Healthy area fill (under healthy curve)
                        CortisolAreaShape(
                            points: healthyCurve,
                            width: w,
                            height: h,
                            progress: curveProgress
                        )
                        .fill(Color(hex: "4FC3A1").opacity(0.08))

                        // Healthy curve line
                        CortisolCurveShape(
                            points: healthyCurve,
                            width: w,
                            height: h,
                            progress: curveProgress
                        )
                        .stroke(
                            Color(hex: "4FC3A1"),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )

                        // Stressed area fill (between stressed and healthy)
                        CortisolAreaShape(
                            points: stressedCurve,
                            width: w,
                            height: h,
                            progress: curveProgress
                        )
                        .fill(Color(hex: "FF8A80").opacity(0.07))

                        // Stressed curve line
                        CortisolCurveShape(
                            points: stressedCurve,
                            width: w,
                            height: h,
                            progress: curveProgress
                        )
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "FF8A80"), Color(hex: "FF5252")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [6, 3])
                        )
                    }
                    .frame(width: w, height: h)
                }
                .frame(height: 160)
                .padding(.trailing, 30)
            }
            .frame(height: 160)

            // Time axis labels
            HStack {
                ForEach(timeLabels, id: \.self) { label in
                    Text(label)
                        .font(.custom("Poppins-Regular", size: 9))
                        .foregroundColor(.white.opacity(0.35))
                    if label != timeLabels.last {
                        Spacer()
                    }
                }
            }
            .padding(.top, 6)
            .padding(.trailing, 30)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "0A0A2E").opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    // MARK: - Legend item

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 16, height: 3)
            Text(label)
                .font(.custom("Poppins-Medium", size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    // MARK: - Insight row

    private func insightRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.custom("Poppins-Medium", size: 11))
                .foregroundColor(.white.opacity(0.25))
                .frame(width: 20, alignment: .leading)
                .padding(.top, 2)

            Text(text)
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.8).delay(0.3)) {
            curveProgress = 1.0
        }
    }
}

// MARK: - Curve Shape (draws progressively with `progress`)

private struct CortisolCurveShape: Shape {
    var points: [CGFloat]
    var width: CGFloat
    var height: CGFloat
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard points.count > 1 else { return Path() }

        let totalPoints = points.count
        let visibleCount = max(2, Int(CGFloat(totalPoints - 1) * progress) + 1)
        let usedPoints = Array(points.prefix(visibleCount))

        let stepX = width / CGFloat(totalPoints - 1)
        var path = Path()

        func x(_ i: Int) -> CGFloat { CGFloat(i) * stepX }
        func y(_ v: CGFloat) -> CGFloat { height - v * height }

        path.move(to: CGPoint(x: x(0), y: y(usedPoints[0])))

        for i in 1..<usedPoints.count {
            let prev = CGPoint(x: x(i - 1), y: y(usedPoints[i - 1]))
            let curr = CGPoint(x: x(i), y: y(usedPoints[i]))
            let cp1 = CGPoint(x: prev.x + stepX * 0.4, y: prev.y)
            let cp2 = CGPoint(x: curr.x - stepX * 0.4, y: curr.y)
            path.addCurve(to: curr, control1: cp1, control2: cp2)
        }

        return path
    }
}

// MARK: - Area Shape (closed fill under the curve)

private struct CortisolAreaShape: Shape {
    var points: [CGFloat]
    var width: CGFloat
    var height: CGFloat
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard points.count > 1 else { return Path() }

        let totalPoints = points.count
        let visibleCount = max(2, Int(CGFloat(totalPoints - 1) * progress) + 1)
        let usedPoints = Array(points.prefix(visibleCount))

        let stepX = width / CGFloat(totalPoints - 1)
        var path = Path()

        func x(_ i: Int) -> CGFloat { CGFloat(i) * stepX }
        func y(_ v: CGFloat) -> CGFloat { height - v * height }

        path.move(to: CGPoint(x: x(0), y: height))
        path.addLine(to: CGPoint(x: x(0), y: y(usedPoints[0])))

        for i in 1..<usedPoints.count {
            let prev = CGPoint(x: x(i - 1), y: y(usedPoints[i - 1]))
            let curr = CGPoint(x: x(i), y: y(usedPoints[i]))
            let cp1 = CGPoint(x: prev.x + stepX * 0.4, y: prev.y)
            let cp2 = CGPoint(x: curr.x - stepX * 0.4, y: curr.y)
            path.addCurve(to: curr, control1: cp1, control2: cp2)
        }

        path.addLine(to: CGPoint(x: x(usedPoints.count - 1), y: height))
        path.closeSubpath()

        return path
    }
}

#Preview {
    CortisolScienceHookView(onContinue: {})
}
