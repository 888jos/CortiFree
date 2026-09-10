//
//  GlowAnalysisService.swift
//  CortiFree
//
//  The service boundary keeps the UI ready for a future on-device model. The
//  current implementation is deterministic and wellness-only: it uses the
//  onboarding context and never infers a medical condition from an image.
//

import Foundation
import UIKit
import Vision
import CoreImage

protocol GlowAnalyzing {
    func analyze(image: UIImage?, context: GlowOnboardingContext) -> GlowAnalysis
}

struct LocalGlowAnalysisService: GlowAnalyzing {
    func analyze(image: UIImage?, context: GlowOnboardingContext) -> GlowAnalysis {
        let concern = context.appearanceConcern.lowercased()
        let symptoms = context.symptoms.joined(separator: " ").lowercased()
        let reasons = context.reasons.joined(separator: " ").lowercased()
        let goal = context.primaryGoal.lowercased()

        let visual = image.map(analyzeVisualSignal) ?? VisualSignal()
        var baseline = 62 + visual.qualityAdjustment
        if concern.contains("fatigue") || concern.contains("cernes") {
            baseline -= 8
        }
        if symptoms.contains("sleep") || symptoms.contains("fatigue") || reasons.contains("exhaust") {
            baseline -= 5
        }
        if goal.contains("sleep") || goal.contains("stress") {
            baseline -= 2
        }
        let recovery = clamp(baseline + (goal.contains("sleep") ? 5 : 0) + visual.recoverySignal)
        let underEye = clamp(baseline - (concern.contains("cernes") ? 8 : 0) - visual.underEyeSignal)
        let clarity = clamp(baseline + (goal.contains("energy") ? 4 : 0) + visual.claritySignal)
        let puffiness = clamp(baseline - (symptoms.contains("sleep") ? 4 : 0) - visual.puffinessSignal)
        let glowScore = clamp((recovery + underEye + clarity + puffiness) / 4)
        // One user-facing score: quiz domains are the foundation and the
        // optional Glow Scan adds a small, non-diagnostic visual signal.
        let overall: Int
        if let domainScore = context.domainScore {
            overall = clamp(Int((Double(domainScore) * 0.85 + Double(glowScore) * 0.15).rounded()))
        } else {
            overall = glowScore
        }

        return GlowAnalysis(
            id: UUID(),
            createdAt: Date(),
            overallScore: overall,
            recoveryScore: recovery,
            underEyeScore: underEye,
            skinClarityScore: clarity,
            puffinessScore: puffiness,
            insights: [
                GlowInsight(
                    id: "recovery",
                    title: NSLocalizedString("glow.insight.recovery.title", comment: ""),
                    detail: NSLocalizedString("glow.insight.recovery.detail", comment: "")
                ),
                GlowInsight(
                    id: "routine",
                    title: NSLocalizedString("glow.insight.routine.title", comment: ""),
                    detail: NSLocalizedString("glow.insight.routine.detail", comment: "")
                ),
                GlowInsight(
                    id: "consistency",
                    title: NSLocalizedString("glow.insight.consistency.title", comment: ""),
                    detail: NSLocalizedString("glow.insight.consistency.detail", comment: "")
                )
            ]
        )
    }

    private func clamp(_ value: Int) -> Int {
        min(max(value, 0), 100)
    }

    private struct VisualSignal {
        let qualityAdjustment: Int
        let recoverySignal: Int
        let underEyeSignal: Int
        let claritySignal: Int
        let puffinessSignal: Int

        init(
            qualityAdjustment: Int = 0,
            recoverySignal: Int = 0,
            underEyeSignal: Int = 0,
            claritySignal: Int = 0,
            puffinessSignal: Int = 0
        ) {
            self.qualityAdjustment = qualityAdjustment
            self.recoverySignal = recoverySignal
            self.underEyeSignal = underEyeSignal
            self.claritySignal = claritySignal
            self.puffinessSignal = puffinessSignal
        }
    }

    /// Extracts a conservative, on-device visual signal. This measures scan
    /// quality, exposure and visible tonal variation; it does not diagnose a
    /// skin condition or infer sensitive attributes.
    private func analyzeVisualSignal(_ image: UIImage) -> VisualSignal {
        guard let cgImage = image.cgImage else { return VisualSignal() }
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        try? handler.perform([request])
        guard let face = request.results?.max(by: { $0.boundingBox.width < $1.boundingBox.width }) else {
            return VisualSignal(qualityAdjustment: -10)
        }

        let area = face.boundingBox.width * face.boundingBox.height
        let framingSignal: Int = area < 0.12 ? -8 : area > 0.70 ? -4 : 4
        let exposure = averageLuminance(in: face.boundingBox, image: cgImage)
        let exposureSignal: Int
        switch exposure {
        case ..<0.22, 0.88...: exposureSignal = -8
        case 0.32..<0.78: exposureSignal = 4
        default: exposureSignal = 0
        }

        let landmarksSignal = face.landmarks == nil ? -4 : 2
        let quality = framingSignal + exposureSignal + landmarksSignal
        return VisualSignal(
            qualityAdjustment: quality,
            recoverySignal: exposureSignal / 2,
            underEyeSignal: exposureSignal < 0 ? 3 : 0,
            claritySignal: landmarksSignal,
            puffinessSignal: framingSignal < 0 ? 2 : 0
        )
    }

    private func averageLuminance(in normalizedRect: CGRect, image: CGImage) -> Double {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let rect = CGRect(
            x: normalizedRect.minX * width,
            y: (1 - normalizedRect.maxY) * height,
            width: normalizedRect.width * width,
            height: normalizedRect.height * height
        ).intersection(CGRect(x: 0, y: 0, width: width, height: height))
        guard !rect.isEmpty else { return 0.5 }

        let input = CIImage(cgImage: image).cropped(to: rect)
        let filter = CIFilter(name: "CIAreaAverage")
        filter?.setValue(input, forKey: kCIInputImageKey)
        filter?.setValue(CIVector(cgRect: input.extent), forKey: kCIInputExtentKey)
        guard let output = filter?.outputImage else { return 0.5 }
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        var pixel = [UInt8](repeating: 0, count: 4)
        context.render(output, toBitmap: &pixel, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        return (0.2126 * Double(pixel[0]) + 0.7152 * Double(pixel[1]) + 0.0722 * Double(pixel[2])) / 255.0
    }
}
