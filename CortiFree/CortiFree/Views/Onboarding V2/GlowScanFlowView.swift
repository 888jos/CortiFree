//
//  GlowScanFlowView.swift
//  CortiFree
//

import AVFoundation
import SwiftUI
import UIKit

struct GlowScanFlowView: View {
    let context: GlowOnboardingContext
    let onComplete: () -> Void
    let onExit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var store = GlowScanStore()
    @State private var screen: Screen = .intro
    @State private var capturedImage: UIImage?
    @State private var showPicker = false
    @State private var showLiveScanner = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var permissionMessage = ""
    @State private var analysis: GlowAnalysis?
    @State private var analysisProgress = 0
    @State private var analysisTask: Task<Void, Never>?
    @State private var hasExited = false

    private let analyzer = LocalGlowAnalysisService()

    private enum Screen: Equatable {
        case intro, capture, analyzing, results, reset
    }

    init(
        context: GlowOnboardingContext = .empty,
        onComplete: @escaping () -> Void,
        onExit: @escaping () -> Void = {}
    ) {
        self.context = context
        self.onComplete = onComplete
        self.onExit = onExit
    }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            switch screen {
            case .intro: introView
            case .capture: captureView
            case .analyzing: analyzingView
            case .results: resultsView
            case .reset: resetView
            }
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(image: $capturedImage, sourceType: pickerSource)
        }
        .fullScreenCover(isPresented: $showLiveScanner) {
            GlowCameraScannerView(
                onComplete: { image in
                    showLiveScanner = false
                    capturedImage = image
                },
                onSkip: {
                    showLiveScanner = false
                    beginAnalysis(image: nil, source: "camera_skipped")
                }
            )
        }
        .onChange(of: capturedImage) { _, image in
            guard let image else { return }
            beginAnalysis(image: image, source: pickerSource == .camera ? "camera" : "library")
        }
        .onDisappear {
            analysisTask?.cancel()
            capturedImage = nil
        }
    }

    private var introView: some View {
        pageScaffold {
            Spacer(minLength: 24)
            Image("glow_scan_hero")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 360)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)

            Text(NSLocalizedString("glow.intro.title", comment: ""))
                .font(.faroBold(34))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(NSLocalizedString("glow.intro.body", comment: ""))
                .font(.poppinsRegular(16))
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)

            glowTrustBadges

            VStack(alignment: .leading, spacing: 14) {
                glowBenefit("checkmark.circle.fill", key: "glow.intro.benefit_one")
                glowBenefit("sparkles", key: "glow.intro.benefit_two")
                glowBenefit("lock.shield.fill", key: "glow.intro.benefit_three")
            }
            .padding(18)
            .background(Color(hex: "1A1A4E").opacity(0.68))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.top, 24)

            Spacer()

            primaryButton(NSLocalizedString("glow.cta.start", comment: ""), systemImage: "camera.fill") {
                MixpanelManager.shared.track(event: "onboarding_glow_scan_started")
                screen = .capture
            }
        }
    }

    private var captureView: some View {
        pageScaffold {
            Text(NSLocalizedString("glow.capture.eyebrow", comment: ""))
                .font(.poppinsSemiBold(13))
                .foregroundStyle(Color(hex: "B794F6"))
                .textCase(.uppercase)
                .padding(.bottom, 8)

            Text(NSLocalizedString("glow.capture.title", comment: ""))
                .font(.faroBold(30))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(NSLocalizedString("glow.capture.body", comment: ""))
                .font(.poppinsRegular(15))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)

            scannerGuide

            if !permissionMessage.isEmpty {
                Text(permissionMessage)
                    .font(.poppinsRegular(13))
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
            }

            primaryButton(NSLocalizedString("glow.cta.take_photo", comment: ""), systemImage: "camera.fill") {
                requestCameraOrFallback()
            }

            Button {
                pickerSource = .photoLibrary
                showPicker = true
            } label: {
                Label(NSLocalizedString("glow.cta.choose_photo", comment: ""), systemImage: "photo.on.rectangle")
                    .font(.poppinsSemiBold(15))
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
            }
            .buttonStyle(.plain)

            #if DEBUG
            Button {
                beginAnalysis(image: nil, source: "debug")
            } label: {
                Text(NSLocalizedString("glow.debug.preview", comment: ""))
                    .font(.poppinsRegular(13))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            #endif
        }
    }

    private var analyzingView: some View {
        pageScaffold {
            Spacer(minLength: 24)
            ZStack {
                Circle()
                    .stroke(Color(hex: "B794F6").opacity(0.2), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: CGFloat(analysisProgress + 1) / 4)
                    .stroke(Color(hex: "D4B4FF"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: analysisProgress)
                Image(systemName: "face.smiling")
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(.white)
            }
            .frame(width: 170, height: 170)

            Text(NSLocalizedString("glow.analyzing.title", comment: ""))
                .font(.faroBold(30))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 28)

            Text(analysisMessage)
                .font(.poppinsRegular(16))
                .foregroundStyle(.white.opacity(0.76))
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 13) {
                analysisStep("glow.analyzing.step.one", index: 0)
                analysisStep("glow.analyzing.step.two", index: 1)
                analysisStep("glow.analyzing.step.three", index: 2)
                analysisStep("glow.analyzing.step.four", index: 3)
            }
            .padding(20)
            .background(Color(hex: "1A1A4E").opacity(0.68))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.top, 26)
            Spacer()
        }
    }

    private var resultsView: some View {
        pageScaffold {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Text(NSLocalizedString("glow.results.eyebrow", comment: ""))
                        .font(.poppinsSemiBold(13))
                        .foregroundStyle(Color(hex: "B794F6"))
                        .textCase(.uppercase)

                    Text(NSLocalizedString("glow.results.title", comment: ""))
                        .font(.faroBold(34))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)

                    scoreView
                        .padding(.top, 20)

                    Text(NSLocalizedString("glow.results.body", comment: ""))
                        .font(.poppinsRegular(15))
                        .foregroundStyle(.white.opacity(0.76))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.top, 14)

                    scoreGrid
                        .padding(.top, 24)

                    VStack(alignment: .leading, spacing: 14) {
                        Text(NSLocalizedString("glow.results.insights", comment: ""))
                            .font(.faroBold(22))
                            .foregroundStyle(.white)
                        ForEach(analysis?.insights ?? []) { insight in
                            insightRow(insight)
                        }
                    }
                    .padding(.top, 28)

                    primaryButton(NSLocalizedString("glow.cta.reset", comment: ""), systemImage: "arrow.right") {
                        MixpanelManager.shared.track(event: "onboarding_glow_reset_viewed")
                        screen = .reset
                    }
                    .padding(.top, 28)
                }
            }
        }
    }

    private var resetView: some View {
        pageScaffold {
            Spacer(minLength: 24)
            Image(systemName: "sparkles")
                .font(.system(size: 58, weight: .light))
                .foregroundStyle(Color(hex: "B794F6"))

            Text(NSLocalizedString("glow.reset.title", comment: ""))
                .font(.faroBold(32))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 24)

            Text(NSLocalizedString("glow.reset.body", comment: ""))
                .font(.poppinsRegular(16))
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 14)

            VStack(alignment: .leading, spacing: 14) {
                resetRow("moon.stars.fill", key: "glow.reset.sleep")
                resetRow("wind", key: "glow.reset.regulation")
                resetRow("calendar", key: "glow.reset.consistency")
            }
            .padding(20)
            .background(Color(hex: "1A1A4E").opacity(0.68))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.top, 26)

            Spacer()

            primaryButton(NSLocalizedString("glow.cta.complete", comment: ""), systemImage: "arrow.right") {
                MixpanelManager.shared.track(event: "onboarding_glow_completed", properties: [
                    "glow_score_bucket": analysis?.scoreBucket ?? "unknown"
                ])
                onComplete()
            }
        }
    }

    private func pageScaffold<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    HapticManager.light()
                    if screen == .intro { exitScan() } else if screen == .capture { screen = .intro } else if screen == .results { screen = .capture } else if screen == .reset { screen = .results }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(NSLocalizedString("glow.accessibility.back", comment: ""))
                Spacer()

                if screen == .intro || screen == .capture {
                    Button(NSLocalizedString("glow.cta.skip", comment: "")) {
                        HapticManager.light()
                        exitScan()
                    }
                    .font(.poppinsMedium(14))
                    .foregroundStyle(.white.opacity(0.78))
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)

            content()
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func exitScan() {
        guard !hasExited else { return }
        hasExited = true
        onExit()
    }

    private var scoreView: some View {
        VStack(spacing: 2) {
            Text("\(analysis?.overallScore ?? 0)")
                .font(.faroBold(74))
                .foregroundStyle(.white)
            Text(NSLocalizedString("glow.results.out_of", comment: ""))
                .font(.poppinsRegular(14))
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    private var scoreGrid: some View {
        let scores: [(String, String, Int)] = [
            ("glow.score.recovery", "heart.text.square.fill", analysis?.recoveryScore ?? 0),
            ("glow.score.under_eye", "eye.fill", analysis?.underEyeScore ?? 0),
            ("glow.score.clarity", "circle.lefthalf.filled", analysis?.skinClarityScore ?? 0),
            ("glow.score.puffiness", "face.smiling", analysis?.puffinessScore ?? 0)
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(scores, id: \.0) { score in
                VStack(alignment: .leading, spacing: 9) {
                    Image(systemName: score.1)
                        .foregroundStyle(Color(hex: "B794F6"))
                    Text(NSLocalizedString(score.0, comment: ""))
                        .font(.poppinsRegular(13))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(score.2)")
                        .font(.faroBold(25))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(hex: "1A1A4E").opacity(0.68))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func insightRow(_ insight: GlowInsight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(hex: "B794F6"))
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: 3) {
                Text(insight.title)
                    .font(.poppinsSemiBold(14))
                    .foregroundStyle(.white)
                Text(insight.detail)
                    .font(.poppinsRegular(13))
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func resetRow(_ icon: String, key: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: "B794F6"))
                .frame(width: 22)
            Text(NSLocalizedString(key, comment: ""))
                .font(.poppinsRegular(14))
                .foregroundStyle(.white.opacity(0.86))
        }
    }

    private var scannerGuide: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.28))
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.32), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                    Circle()
                        .stroke(Color(hex: "B794F6"), lineWidth: 5)
                        .padding(8)
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 80, weight: .thin))
                        .foregroundStyle(.white.opacity(0.82))
                }
                .frame(width: 190, height: 190)

                Text(NSLocalizedString("glow.capture.guide", comment: ""))
                    .font(.poppinsMedium(15))
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
        .frame(maxWidth: 310)
        .aspectRatio(0.82, contentMode: .fit)
        .padding(.vertical, 22)
    }

    private func glowBenefit(_ icon: String, key: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: "B794F6"))
            Text(NSLocalizedString(key, comment: ""))
                .font(.poppinsRegular(14))
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var glowTrustBadges: some View {
        Image("glow_trust_badges")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 340)
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private func analysisStep(_ key: String, index: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: analysisProgress >= index ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(analysisProgress >= index ? Color(hex: "FF6B9D") : .white.opacity(0.28))
            Text(NSLocalizedString(key, comment: ""))
                .font(.poppinsRegular(14))
                .foregroundStyle(analysisProgress >= index ? .white : .white.opacity(0.38))
        }
    }

    private func primaryButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.poppinsSemiBold(16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "8B5CF6"), Color(hex: "B794F6")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.bottom, 28)
    }

    private var analysisMessage: String {
        switch analysisProgress {
        case 0: return NSLocalizedString("glow.analyzing.step.one", comment: "")
        case 1: return NSLocalizedString("glow.analyzing.step.two", comment: "")
        case 2: return NSLocalizedString("glow.analyzing.step.three", comment: "")
        default: return NSLocalizedString("glow.analyzing.step.four", comment: "")
        }
    }

    private func requestCameraOrFallback() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            permissionMessage = NSLocalizedString("glow.capture.camera_unavailable", comment: "")
            pickerSource = .photoLibrary
            showPicker = true
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            MixpanelManager.shared.track(event: "onboarding_glow_camera_permission_granted")
            showLiveScanner = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        MixpanelManager.shared.track(event: "onboarding_glow_camera_permission_granted")
                        showLiveScanner = true
                    } else {
                        MixpanelManager.shared.track(event: "onboarding_glow_camera_permission_denied")
                        permissionMessage = NSLocalizedString("glow.capture.camera_denied", comment: "")
                    }
                }
            }
        default:
            MixpanelManager.shared.track(event: "onboarding_glow_camera_permission_denied")
            permissionMessage = NSLocalizedString("glow.capture.camera_denied", comment: "")
        }
    }

    private func beginAnalysis(image: UIImage?, source: String) {
        guard screen == .capture else { return }
        MixpanelManager.shared.track(event: "onboarding_glow_photo_captured", properties: ["source": source])
        screen = .analyzing
        analysisProgress = 0

        analysisTask?.cancel()
        analysisTask = Task { @MainActor in
            let delay: UInt64 = reduceMotion ? 200_000_000 : 700_000_000
            for step in 0...3 {
                guard !Task.isCancelled else { return }
                analysisProgress = step
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            let result = analyzer.analyze(image: image, context: context)
            analysis = result
            store.save(result)
            capturedImage = nil
            MixpanelManager.shared.track(event: "onboarding_glow_analysis_completed", properties: [
                "glow_score_bucket": result.scoreBucket
            ])
            MixpanelManager.shared.track(event: "onboarding_glow_result_viewed", properties: [
                "glow_score_bucket": result.scoreBucket
            ])
            screen = .results
        }
    }
}

#Preview {
    GlowScanFlowView(onComplete: {})
}
