import AVFoundation
import SwiftUI
import Vision

struct GlowCameraScannerView: View {
    let onComplete: (UIImage?) -> Void
    let onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanner = GlowCameraScannerModel()

    var body: some View {
        ZStack {
            CameraPreview(session: scanner.session)
                .ignoresSafeArea()

            Color.black.opacity(0.12)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                instructionCard
                Spacer()
                faceGuide
                Spacer()
                bottomControls
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .statusBarHidden(false)
        .onAppear { scanner.start() }
        .onDisappear { scanner.stop() }
        .onChange(of: scanner.completedImage) { _, image in
            guard let image else { return }
            onComplete(image)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                scanner.stop()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.45), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close face scan")

            Spacer()

            Text("Glow Scan")
                .font(.poppinsSemiBold(16))
                .foregroundStyle(.white)

            Spacer()
            Color.clear.frame(width: 42, height: 42)
        }
    }

    private var instructionCard: some View {
        VStack(spacing: 6) {
            HStack(spacing: 14) {
                Image(systemName: scanner.stage.icon)
                    .font(.system(size: 27, weight: .medium))
                    .foregroundStyle(Color(hex: "B794F6"))
                    .frame(width: 54, height: 54)
                    .background(Color(hex: "B794F6").opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(scanner.stage.title)
                        .font(.poppinsSemiBold(22))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(scanner.stage.subtitle)
                        .font(.poppinsRegular(14))
                        .foregroundStyle(.white.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 7) {
                ForEach(GlowScanStage.allCases, id: \.self) { stage in
                    Capsule()
                        .fill(stage.rawValue <= scanner.stage.rawValue ? Color(hex: "B794F6") : .white.opacity(0.16))
                        .frame(height: 6)
                }
            }
            .padding(.top, 9)
        }
        .padding(16)
        .background(.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
        .padding(.top, 18)
    }

    private var faceGuide: some View {
        ZStack {
            Ellipse()
                .fill(.white.opacity(0.06))
                .frame(width: 300, height: 390)

            FaceGrid()
                .stroke(.white.opacity(0.38), lineWidth: 1)
                .frame(width: 255, height: 335)
                .clipShape(Ellipse())

            Ellipse()
                .stroke(.white.opacity(0.72), style: StrokeStyle(lineWidth: 3, dash: [12, 10]))
                .frame(width: 300, height: 390)
                .overlay {
                    Ellipse()
                        .trim(from: 0, to: scanner.holdProgress)
                        .stroke(Color(hex: "B794F6"), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.12), value: scanner.holdProgress)
                }

            if !scanner.faceDetected {
                Image(systemName: "face.dashed")
                    .font(.system(size: 76, weight: .thin))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(scanner.faceDetected ? "Face detected" : "Position your face inside the oval")
    }

    private var bottomControls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Circle()
                    .fill(scanner.faceDetected ? Color(hex: "FF6B9D") : Color.red)
                    .frame(width: 10, height: 10)
                Text(scanner.faceDetected ? "Face detected" : "Center your face in the frame")
                    .font(.poppinsMedium(14))
                    .foregroundStyle(.white.opacity(0.88))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(.black.opacity(0.6), in: Capsule())

            HStack(spacing: 12) {
                Button("Restart scan") { scanner.restart() }
                    .buttonStyle(ScannerPillButtonStyle())
                Button("Skip for now") { onSkip() }
                    .buttonStyle(ScannerPillButtonStyle())
            }
        }
    }
}

enum GlowScanStage: Int, CaseIterable {
    case left = 0
    case center = 1
    case right = 2

    var title: String {
        switch self {
        case .left: return "Turn your head left"
        case .center: return "Look straight ahead"
        case .right: return "Turn your head right"
        }
    }

    var subtitle: String {
        switch self {
        case .left, .center, .right: return "Hold steady for 2 seconds"
        }
    }

    var icon: String {
        switch self {
        case .left: return "arrow.left"
        case .center: return "face.smiling"
        case .right: return "arrow.right"
        }
    }
}

private struct ScannerPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.poppinsRegular(16))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .background(.black.opacity(configuration.isPressed ? 0.78 : 0.58), in: Capsule())
    }
}

private struct FaceGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let columns = 8
        let rows = 10
        for column in 0...columns {
            let x = rect.minX + rect.width * CGFloat(column) / CGFloat(columns)
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        for row in 0...rows {
            let y = rect.minY + rect.height * CGFloat(row) / CGFloat(rows)
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return path
    }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

final class GlowCameraScannerModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()

    @Published private(set) var stage: GlowScanStage = .left
    @Published private(set) var faceDetected = false
    @Published private(set) var holdProgress: CGFloat = 0
    @Published private(set) var completedImage: UIImage?

    private let sessionQueue = DispatchQueue(label: "com.cortifree.glow-camera")
    private let visionQueue = DispatchQueue(label: "com.cortifree.glow-vision")
    private let visionHandler = VNSequenceRequestHandler()
    private let output = AVCaptureVideoDataOutput()
    private let ciContext = CIContext()
    private var isConfigured = false
    private var isRunning = false
    private var holdStartedAt: Date?
    private var didComplete = false

    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured { self.configure() }
            guard !self.isRunning else { return }
            self.isRunning = true
            self.session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.isRunning else { return }
            self.isRunning = false
            self.session.stopRunning()
        }
    }

    func restart() {
        DispatchQueue.main.async {
            self.stage = .left
            self.faceDetected = false
            self.holdProgress = 0
            self.holdStartedAt = nil
            self.didComplete = false
        }
    }

    private func configure() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        defer {
            session.commitConfiguration()
            isConfigured = true
        }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else { return }
        session.addInput(input)

        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: visionQueue)
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        if let connection = output.connection(with: .video) {
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = true
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !didComplete, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceLandmarksRequest()
        let orientation: CGImagePropertyOrientation = .leftMirrored
        try? visionHandler.perform([request], on: pixelBuffer, orientation: orientation)
        let observation = (request.results as? [VNFaceObservation])?.max { $0.boundingBox.width < $1.boundingBox.width }
        let yaw = observation?.yaw?.doubleValue
        let faceFound = observation != nil
        let matchesStage: Bool
        switch currentStage {
        case .left: matchesStage = faceFound && (yaw ?? 0) > 0.22
        case .center: matchesStage = faceFound && abs(yaw ?? 0) < 0.16
        case .right: matchesStage = faceFound && (yaw ?? 0) < -0.22
        }

        let now = Date()
        if matchesStage {
            holdStartedAt = holdStartedAt ?? now
            let progress = min(1, now.timeIntervalSince(holdStartedAt ?? now) / 2.0)
            publish(faceFound: faceFound, progress: progress)
            if progress >= 1 { advanceStageOrFinish(pixelBuffer: pixelBuffer) }
        } else {
            holdStartedAt = nil
            publish(faceFound: faceFound, progress: 0)
        }
    }

    private var currentStage: GlowScanStage {
        DispatchQueue.main.sync { stage }
    }

    private func publish(faceFound: Bool, progress: Double) {
        DispatchQueue.main.async {
            self.faceDetected = faceFound
            self.holdProgress = CGFloat(progress)
        }
    }

    private func advanceStageOrFinish(pixelBuffer: CVPixelBuffer) {
        guard !didComplete else { return }
        holdStartedAt = nil
        switch currentStage {
        case .left:
            DispatchQueue.main.async { self.stage = .center; self.holdProgress = 0 }
        case .center:
            DispatchQueue.main.async { self.stage = .right; self.holdProgress = 0 }
        case .right:
            didComplete = true
            let image = makeImage(from: pixelBuffer)
            DispatchQueue.main.async { self.completedImage = image }
        }
    }

    private func makeImage(from pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: 1, orientation: .leftMirrored)
    }
}
