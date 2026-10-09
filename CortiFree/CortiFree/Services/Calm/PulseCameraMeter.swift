//
//  PulseCameraMeter.swift
//  CortiFree
//
//  Heart rate from the back camera (photoplethysmography): with the flash on and a
//  fingertip over the lens, the red level of the image rises and falls with each beat.
//  About 15 seconds of clean signal give a reliable pulse. Wellness only, not medical.
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

    struct Reading: Equatable {
        let bpm: Int
        /// False when the beats were irregular or the two estimates disagreed (finger moved,
        /// pressed too hard, ambient light…): the number may be wrong.
        let reliable: Bool
    }

    static let measureDuration: TimeInterval = 15

    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "cortifree.pulse.camera")
    private var device: AVCaptureDevice?
    private var samples: [(time: TimeInterval, value: Double)] = []
    private var measureStart: TimeInterval?
    private var lastLiveUpdate: TimeInterval = 0
    /// When the finger was last seen: a brief slip (a frame or two) must not restart the measure.
    private var lastFingerTime: TimeInterval?
    /// Start of the wait for a finger: past a few seconds with the flash on, the measure starts
    /// anyway (some phones overexpose the fingertip and it no longer looks red).
    private var waitStart: TimeInterval?
    #if targetEnvironment(simulator)
    private var simulationTimer: Timer?
    /// Synthetic heart rate played by the simulator.
    var simulatedBPM: Double = 92
    #endif

    // MARK: Control

    func start() {
        samples = []
        measureStart = nil
        lastFingerTime = nil
        waitStart = nil
        lastLiveUpdate = 0
        progress = 0
        waveform = []
        liveBPM = nil
        lastReading = nil
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

        if state == .waitingForFinger {
            // After 6 s with the flash on, measure anyway: the result decides, not the colour test.
            let waitedLong = time - (waitStart ?? time) > 6
            guard fingerOn || waitedLong else { return }
            state = .measuring
            HapticManager.light()
        } else if let last = lastFingerTime, time - last > 2.5, measureStart.map({ time - $0 < 6 }) ?? true {
            // Finger lifted early for a while: start over. Later on, keep going and let the maths judge.
            state = .waitingForFinger
            waitStart = time
            samples = []
            measureStart = nil
            progress = 0
            liveBPM = nil
            return
        }
        if measureStart == nil { measureStart = time }

        // Red carries the pulse; when it clips at white, green still moves with each beat.
        samples.append((time, red + green))
        // Keep ~20 s of samples.
        if let first = samples.first, time - first.time > 20 { samples.removeFirst() }

        let elapsed = time - (measureStart ?? time)
        progress = min(1, elapsed / Self.measureDuration)
        updateWaveform()

        if time - lastLiveUpdate > 1, elapsed > 5 {
            lastLiveUpdate = time
            liveBPM = Self.bpm(from: samples)
        }

        if elapsed >= Self.measureDuration {
            let reading = Self.reading(from: samples)
            if let reading, reading.reliable || elapsed > Self.measureDuration * 1.5 {
                // A doubtful signal gets ~7 more seconds to settle before giving its best guess.
                finish(with: reading)
            } else if elapsed > Self.measureDuration * 1.5 {
                // Always end with a number: the last live estimate, flagged as doubtful.
                if let live = liveBPM ?? Self.reading(from: samples, lenient: true)?.bpm {
                    finish(with: Reading(bpm: live, reliable: false))
                } else {
                    state = .failed(LanguageManager.shared.localizedString(for: "calm.pulse.error.signal"))
                    stop()
                }
            }
        }
    }

    private func finish(with reading: Reading) {
        lastReading = reading
        state = .done(reading.bpm)
        HapticManager.success()
        stop()
    }

    private func updateWaveform() {
        let recent = samples.suffix(90).map(\.value)
        guard let low = recent.min(), let high = recent.max(), high - low > 0.0001 else { return }
        // The pulse makes the image darker (more blood absorbs light): flip it so beats point up.
        waveform = recent.map { 1 - ($0 - low) / (high - low) }
    }

    nonisolated static func bpm(from samples: [(time: TimeInterval, value: Double)]) -> Int? {
        reading(from: samples)?.bpm
    }

    /// Detrend and smooth the red level, then estimate the pulse two ways: the beats
    /// themselves (median interval) and the autocorrelation of the signal (its period).
    /// Noise and motion add false beats and push the first estimate up (150 bpm while lying
    /// in bed); the period is much more robust. The reading is reliable when both agree and
    /// the beats are regular.
    nonisolated static func reading(from samples: [(time: TimeInterval, value: Double)], lenient: Bool = false) -> Reading? {
        guard samples.count > (lenient ? 20 : 60), let start = samples.first?.time, let end = samples.last?.time, end - start > 4 else { return nil }
        let rate = Double(samples.count) / (end - start)
        let values = samples.map { -$0.value }

        func movingAverage(_ input: [Double], window: Int) -> [Double] {
            guard window > 1 else { return input }
            var output = [Double](repeating: 0, count: input.count)
            var sum = 0.0
            for index in input.indices {
                sum += input[index]
                if index >= window { sum -= input[index - window] }
                output[index] = sum / Double(min(index + 1, window))
            }
            return output
        }

        let trend = movingAverage(values, window: max(3, Int(rate * 1.2)))
        let detrended = zip(values, trend).map { $0 - $1 }
        let smooth = movingAverage(detrended, window: max(2, Int(rate * 0.12)))

        // 1. Period of the signal (autocorrelation over 40…180 bpm).
        let count = smooth.count
        let mean = smooth.reduce(0, +) / Double(count)
        let centered = smooth.map { $0 - mean }
        let energy = centered.reduce(0) { $0 + $1 * $1 }
        let minLag = max(1, Int(rate * 60 / 180))
        let maxLag = min(count / 2, Int(rate * 60 / 40))
        guard energy > 0, maxLag > minLag else { return nil }
        var correlation = [Double](repeating: 0, count: maxLag + 1)
        for lag in minLag...maxLag {
            var sum = 0.0
            for index in 0..<(count - lag) { sum += centered[index] * centered[index + lag] }
            correlation[lag] = sum / energy * Double(count) / Double(count - lag)
        }
        guard var bestLag = (minLag...maxLag).max(by: { correlation[$0] < correlation[$1] }) else { return nil }
        // The period also shows at twice its length: keep the shorter one when it is as strong.
        let half = bestLag / 2
        if half >= minLag, half > 0, half < maxLag,
           correlation[half] >= correlation[half - 1], correlation[half] >= correlation[half + 1],
           correlation[half] > correlation[bestLag] * 0.9 {
            bestLag = half
        }
        let periodicity = correlation[bestLag]
        let periodBPM = 60 * rate / Double(bestLag)

        // 2. The beats themselves: peaks at least 0.33 s apart, clearly above the noise.
        let spread = (centered.reduce(0) { $0 + $1 * $1 } / Double(count)).squareRoot()
        let minGap = Int(rate * 0.33)
        var peaks: [Int] = []
        if smooth.count > 2 {
            for index in 1..<(smooth.count - 1)
            where smooth[index] > spread * 0.3 && smooth[index] >= smooth[index - 1] && smooth[index] > smooth[index + 1] {
                if let last = peaks.last, index - last < minGap {
                    if smooth[index] > smooth[last] { peaks[peaks.count - 1] = index }
                } else {
                    peaks.append(index)
                }
            }
        }
        var peakBPM: Double?
        var regularity = 1.0
        if peaks.count >= 5 {
            let intervals = zip(peaks.dropFirst(), peaks).map { samples[$0].time - samples[$1].time }.sorted()
            let median = intervals[intervals.count / 2]
            if median > 0 { peakBPM = 60 / median }
            let average = intervals.reduce(0, +) / Double(intervals.count)
            let variance = intervals.reduce(0) { $0 + pow($1 - average, 2) } / Double(intervals.count)
            if average > 0 { regularity = variance.squareRoot() / average }
        }

        let agree = peakBPM.map { abs($0 - periodBPM) / periodBPM < 0.15 } ?? false
        let reliable = periodicity > 0.4 && agree && regularity < 0.25
        let bpm = Int(periodBPM.rounded())
        guard (40...180).contains(bpm) else { return lenient ? Reading(bpm: min(180, max(40, bpm)), reliable: false) : nil }
        return Reading(bpm: bpm, reliable: reliable)
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
