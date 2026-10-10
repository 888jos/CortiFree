//
//  PulseCameraMeter.swift
//  CortiFree
//
//  Heart rate from the back camera (photoplethysmography): with the flash on and a
//  fingertip over the lens, the red level of the image rises and falls with each beat.
//  About 12 seconds of clean signal give a reliable pulse. Wellness only, not medical.
//
//  The simulator has no camera: it plays a synthetic pulse so the flow can be tested.
//

import AVFoundation
import Combine
import Foundation

@MainActor
final class PulseCameraMeter: NSObject, ObservableObject {

    enum State: Equatable {
        case idle
        case waitingForFinger
        case measuring
        case done(Int)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    /// 0…1 while measuring.
    @Published private(set) var progress: Double = 0
    /// Last normalised samples (0…1) for the live waveform.
    @Published private(set) var waveform: [Double] = []
    /// Rough live estimate once a few beats were seen.
    @Published private(set) var liveBPM: Int?
    /// Final reading of the last measure, with how much the signal can be trusted.
    @Published private(set) var lastReading: Reading?
    /// What the user should fix right now (finger off the lens, flash uncovered, moving…).
    @Published private(set) var hint: Hint?

    enum Hint: Equatable {
        /// Nothing on the lens: the camera sees the room.
        case placeFinger
        /// The lens is covered but the image is dark: the flash is not under the finger.
        case coverFlash
        /// The finger slipped or the signal is jumping.
        case holdStill
        /// Ring almost full, a few more seconds of signal needed.
        case almostDone
    }

    struct Reading: Equatable {
        let bpm: Int
        /// False when the beats were irregular or the two estimates disagreed (finger moved,
        /// pressed too hard, ambient light…): the number may be wrong.
        let reliable: Bool
    }

    static let measureDuration: TimeInterval = 12
    /// Extra time a doubtful signal gets before its best guess is used (the ring fills during it).
    static let graceDuration: TimeInterval = 3

    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "cortifree.pulse.camera")
    private var device: AVCaptureDevice?
    private var samples: [PulseSignal.Sample] = []
    /// Exposure and white balance are frozen once the finger is on: auto-exposure fighting the
    /// flash moved the brightness far more than the pulse does.
    private var exposureLocked = false
    private var measureStart: TimeInterval?
    private var lastLiveUpdate: TimeInterval = 0
    /// When the finger was last seen: a brief slip (a frame or two) must not restart the measure.
    private var lastFingerTime: TimeInterval?
    /// Start of the wait for a finger: past a few seconds with the flash on, the measure starts
    /// anyway (some phones overexpose the fingertip and it no longer looks red).
    private var waitStart: TimeInterval?
    /// A hint is shown only once its cause lasted a moment, so it does not flicker frame to frame.
    private var pendingHint: (hint: Hint?, since: TimeInterval)?
    #if targetEnvironment(simulator)
    private var simulationTimer: Timer?
    /// Synthetic heart rate played by the simulator.
    var simulatedBPM: Double = 92
    #endif

    // MARK: Control

    func start() {
        samples = []
        exposureLocked = false
        measureStart = nil
        lastFingerTime = nil
        waitStart = nil
        lastLiveUpdate = 0
        progress = 0
        waveform = []
        liveBPM = nil
        lastReading = nil
        hint = nil
        pendingHint = nil
        state = .waitingForFinger

        #if targetEnvironment(simulator)
        startSimulation()
        #else
        Task {
            guard await Self.cameraAllowed() else {
                state = .failed(LanguageManager.shared.localizedString(for: "calm.pulse.error.camera"))
                return
            }
            configureAndRun()
        }
        #endif
    }

    func stop() {
        #if targetEnvironment(simulator)
        simulationTimer?.invalidate()
        simulationTimer = nil
        #else
        let session = session
        let device = device
        queue.async {
            if let device, device.hasTorch, (try? device.lockForConfiguration()) != nil {
                device.torchMode = .off
                device.unlockForConfiguration()
            }
            if session.isRunning { session.stopRunning() }
        }
        #endif
    }

    private static func cameraAllowed() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }

    private func configureAndRun() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera)
        else {
            state = .failed(LanguageManager.shared.localizedString(for: "calm.pulse.error.camera"))
            return
        }
        device = camera
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)

        let session = session
        queue.async {
            session.beginConfiguration()
            session.sessionPreset = .low
            session.inputs.forEach(session.removeInput)
            session.outputs.forEach(session.removeOutput)
            if session.canAddInput(input) { session.addInput(input) }
            if session.canAddOutput(output) { session.addOutput(output) }
            session.commitConfiguration()
            session.startRunning()
            if (try? camera.lockForConfiguration()) != nil {
                if camera.hasTorch { try? camera.setTorchModeOn(level: 0.8) }
                if camera.isExposureModeSupported(.continuousAutoExposure) { camera.exposureMode = .continuousAutoExposure }
                if camera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) { camera.whiteBalanceMode = .continuousAutoWhiteBalance }
                // A little darker than auto: a fingertip under the flash otherwise clips at white.
                camera.setExposureTargetBias(max(camera.minExposureTargetBias, -1.5))
                // Steady 30 fps: the pulse maths need regular samples.
                let fps = CMTime(value: 1, timescale: 30)
                if camera.activeFormat.videoSupportedFrameRateRanges.contains(where: { $0.minFrameRate <= 30 && $0.maxFrameRate >= 30 }) {
                    camera.activeVideoMinFrameDuration = fps
                    camera.activeVideoMaxFrameDuration = fps
                }
                camera.unlockForConfiguration()
            }
        }
    }

    // MARK: Signal

    /// One frame: average colour of the centre, finger check, then the pulse maths.
    fileprivate func handle(red: Double, green: Double, blue: Double, spread: Double, time: TimeInterval) {
        guard state == .waitingForFinger || state == .measuring else { return }
        if waitStart == nil { waitStart = time }

        // A fingertip lit by the flash fills the image with a red, blurry, even colour. Some
        // phones overexpose it (red and green both near white): an even, bright, warm image counts too.
        let redDominant = red > 60 && red > green * 1.3 && red > blue * 1.3
        let evenAndWarm = spread < 14 && red > 60 && red >= green && red >= blue
        let fingerOn = redDominant || evenAndWarm
        if fingerOn { lastFingerTime = time }

        // Coaching: an even but dark image means the lens is covered and the flash is not.
        if fingerOn {
            updateHint(nil, at: time)
        } else if spread < 14, red < 60 {
            updateHint(.coverFlash, at: time)
        } else {
            updateHint(state == .measuring ? .holdStill : .placeFinger, at: time)
        }

        if state == .waitingForFinger {
            // After 6 s with the flash on, measure anyway: the rhythm decides, not the colour test.
            let waitedLong = time - (waitStart ?? time) > 6
            guard fingerOn || waitedLong else { return }
            state = .measuring
            HapticManager.light()
        } else if let last = lastFingerTime, time - last > 2.5, measureStart.map({ time - $0 < 6 }) ?? true {
            // Finger lifted early for a while: start over. Later on, keep going and let the maths judge.
            state = .waitingForFinger
            waitStart = time
            samples = []
            unlockExposure()
            measureStart = nil
            progress = 0
            liveBPM = nil
            return
        }
        if measureStart == nil { measureStart = time }

        // One second for the exposure to settle on the finger, then freeze it and start clean.
        if !exposureLocked, time - (measureStart ?? time) > 1 {
            lockExposure()
            samples = []
            measureStart = time
            lastLiveUpdate = time
        }

        samples.append(PulseSignal.Sample(time: time, red: red, green: green))
        // Keep ~20 s of samples.
        if let first = samples.first, time - first.time > 20 { samples.removeFirst() }

        let elapsed = time - (measureStart ?? time)
        // 90 % of the ring for the normal measure, the last 10 % for the grace time: the ring is
        // only full when the measure really ends.
        let total = Self.measureDuration + Self.graceDuration
        progress = elapsed <= Self.measureDuration
            ? 0.9 * elapsed / Self.measureDuration
            : min(1, 0.9 + 0.1 * (elapsed - Self.measureDuration) / Self.graceDuration)
        if elapsed > Self.measureDuration, fingerOn { hint = .almostDone }
        updateWaveform()

        if time - lastLiveUpdate > 1, elapsed > 5 {
            lastLiveUpdate = time
            // Keep the last good value while the signal is unclear for a moment.
            if let estimate = PulseSignal.estimate(samples) { liveBPM = estimate.bpm }
        }

        if elapsed >= Self.measureDuration {
            let estimate = PulseSignal.estimate(samples)
            if let estimate, estimate.reliable || elapsed >= total {
                // A doubtful signal gets a few more seconds to settle before giving its best guess.
                finish(with: Reading(bpm: estimate.bpm, reliable: estimate.reliable))
            } else if elapsed >= total {
                if let live = liveBPM {
                    finish(with: Reading(bpm: live, reliable: false))
                } else {
                    // No rhythm at all (finger not on the lens): no number rather than a wrong one.
                    state = .failed(LanguageManager.shared.localizedString(for: "calm.pulse.error.signal"))
                    stop()
                }
            }
        }
    }

    private func updateHint(_ candidate: Hint?, at time: TimeInterval) {
        if pendingHint?.hint != candidate { pendingHint = (candidate, time) }
        guard hint != candidate else { return }
        // A good finger keeps the "almost done" message; it is set again by the measure itself.
        if candidate == nil, hint == .almostDone { return }
        // Clearing is immediate; a new problem must last 0.6 s before it is shown.
        if candidate == nil || time - (pendingHint?.since ?? time) > 0.6 { hint = candidate }
    }

    private func finish(with reading: Reading) {
        hint = nil
        lastReading = reading
        state = .done(reading.bpm)
        HapticManager.success()
        stop()
    }

    private func updateWaveform() {
        let recent = samples.suffix(90).map { $0.red + $0.green }
        guard let low = recent.min(), let high = recent.max(), high - low > 0.0001 else { return }
        // The pulse makes the image darker (more blood absorbs light): flip it so beats point up.
        waveform = recent.map { 1 - ($0 - low) / (high - low) }
    }

    private func lockExposure() {
        exposureLocked = true
        #if !targetEnvironment(simulator)
        guard let device else { return }
        queue.async {
            guard (try? device.lockForConfiguration()) != nil else { return }
            if device.isExposureModeSupported(.locked) { device.exposureMode = .locked }
            if device.isWhiteBalanceModeSupported(.locked) { device.whiteBalanceMode = .locked }
            device.unlockForConfiguration()
        }
        #endif
    }

    private func unlockExposure() {
        exposureLocked = false
        #if !targetEnvironment(simulator)
        guard let device else { return }
        queue.async {
            guard (try? device.lockForConfiguration()) != nil else { return }
            if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) { device.whiteBalanceMode = .continuousAutoWhiteBalance }
            device.unlockForConfiguration()
        }
        #endif
    }

    // MARK: Simulator

    #if targetEnvironment(simulator)
    private func startSimulation() {
        let begin = Date().timeIntervalSinceReferenceDate
        simulationTimer?.invalidate()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let time = Date().timeIntervalSinceReferenceDate
                let phase = (time - begin) * self.simulatedBPM / 60 * 2 * .pi
                // Finger lands after a second, sharp systolic beat + small noise.
                let fingerOn = time - begin > 1
                let red = fingerOn ? 180 - 8 * pow(max(0, sin(phase)), 3) + Double.random(in: -0.6...0.6) : 40
                self.handle(red: red, green: fingerOn ? 30 : 40, blue: fingerOn ? 25 : 40, spread: fingerOn ? 4 : 30, time: time)
            }
        }
    }
    #endif
}

extension PulseCameraMeter: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return }
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let pixels = base.assumingMemoryBound(to: UInt8.self)

        // Centre half of the image, every 4th pixel: plenty for an average.
        var red = 0, green = 0, blue = 0, count = 0
        var lumaSum = 0.0, lumaSquares = 0.0
        for y in stride(from: height / 4, to: height * 3 / 4, by: 4) {
            let row = pixels + y * bytesPerRow
            for x in stride(from: width / 4, to: width * 3 / 4, by: 4) {
                let pixel = row + x * 4
                blue += Int(pixel[0]); green += Int(pixel[1]); red += Int(pixel[2])
                let luma = (Double(pixel[2]) + Double(pixel[1]) + Double(pixel[0])) / 3
                lumaSum += luma; lumaSquares += luma * luma
                count += 1
            }
        }
        guard count > 0 else { return }
        let n = Double(count)
        let r = Double(red) / n, g = Double(green) / n, b = Double(blue) / n
        // Spatial spread: a fingertip on the lens is a blurry, even surface.
        let spread = max(0, lumaSquares / n - pow(lumaSum / n, 2)).squareRoot()
        Task { @MainActor in self.handle(red: r, green: g, blue: b, spread: spread, time: time) }
    }
}
