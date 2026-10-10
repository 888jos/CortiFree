//
//  PulseSignal.swift
//  CortiFree
//
//  The pulse maths of the camera measure (PulseCameraMeter), kept free of the camera so they
//  can be checked on recorded or synthetic signals.
//
//  Each colour channel is band-passed (detrend + low-pass), then its period is found with
//  the autocorrelation. Only a real peak of the autocorrelation counts: noise has none and
//  used to land on the edge of the search range (« 180 bpm » with no pulse at all). The
//  channel with the clearest rhythm wins: red usually, green when the flash clips red at white.
//
//  The camera does not deliver frames at a perfectly steady rate (dropped frames, a busy main
//  thread, thermal throttling): the samples are first put back on an even 30 Hz grid from their
//  timestamps, otherwise the autocorrelation lags no longer match a fixed duration.
//

import Foundation

enum PulseSignal {

    struct Sample {
        let time: TimeInterval
        let red: Double
        let green: Double
    }

    struct Estimate: Equatable {
        let bpm: Int
        /// 0…1: how strongly the signal repeats at that period.
        let periodicity: Double
        let reliable: Bool
        /// "red" or "green": the channel the number comes from.
        var channel = "red"
        /// Length of signal (s) the number comes from.
        var window: Double = 0
    }

    static let bpmRange = 40.0...180.0
    /// Below this the signal has no rhythm to speak of: no number rather than a wrong one.
    static let minimumPeriodicity = 0.4
    /// Even grid the samples are put back on.
    static let gridRate = 30.0
    /// Signal lengths tried, newest samples first: a finger that settled after a few seconds
    /// gives a clean recent window even when the start of the measure was messy. Shorter
    /// windows found rhythms in pure noise.
    static let windows: [Double] = [8, 10]
    /// Rhythm strength needed for a reliable number.
    static let reliablePeriodicity = 0.55
    /// Share of the expected beats that must be found for a reliable number.
    static let minimumBeatCoverage = 0.7
    /// Beat-to-beat variation (std / mean) above which the rhythm is not trusted.
    static let maximumBeatVariation = 0.15

    /// Best estimate over the whole signal and over its most recent windows: a reliable one
    /// first, then the clearest rhythm.
    static func estimate(_ samples: [Sample]) -> Estimate? {
        guard let end = samples.last?.time else { return nil }
        var candidates: [Estimate] = []
        if let whole = single(samples) { candidates.append(whole) }
        for window in windows {
            let recent = samples.filter { $0.time >= end - window }
            guard recent.count < samples.count, let estimate = single(recent) else { continue }
            candidates.append(estimate)
        }
        return candidates.max { lhs, rhs in
            lhs.reliable != rhs.reliable ? !lhs.reliable : lhs.periodicity < rhs.periodicity
        }
    }

    /// One estimate over all the given samples.
    static func single(_ samples: [Sample]) -> Estimate? {
        let sorted = samples.sorted { $0.time < $1.time }
        guard sorted.count > 60, let start = sorted.first?.time, let end = sorted.last?.time, end - start > 4 else { return nil }
        let grid = resample(sorted, rate: gridRate)
        guard grid.count > 60 else { return nil }
        let times = grid.indices.map { start + Double($0) / gridRate }
        // Blood absorbs light: a beat darkens the image, so flip the sign to make beats point up.
        let channels = [("red", grid.map { -$0.red }), ("green", grid.map { -$0.green })]
        return channels
            .compactMap { name, values -> Estimate? in
                guard var estimate = estimate(values: values, times: times, rate: gridRate) else { return nil }
                estimate.channel = name
                estimate.window = end - start
                return estimate
            }
            .max { $0.periodicity < $1.periodicity }
    }

    /// Linear interpolation of time-sorted samples onto an even grid.
    private static func resample(_ samples: [Sample], rate: Double) -> [(red: Double, green: Double)] {
        guard let start = samples.first?.time, let end = samples.last?.time, end > start else { return [] }
        let count = Int((end - start) * rate) + 1
        var output: [(red: Double, green: Double)] = []
        output.reserveCapacity(count)
        var index = 0
        for step in 0..<count {
            let time = start + Double(step) / rate
            while index < samples.count - 2, samples[index + 1].time < time { index += 1 }
            let a = samples[index], b = samples[min(index + 1, samples.count - 1)]
            let span = b.time - a.time
            let t = span > 0 ? max(0, min(1, (time - a.time) / span)) : 0
            output.append((a.red + (b.red - a.red) * t, a.green + (b.green - a.green) * t))
        }
        return output
    }

    // MARK: One channel

    private static func estimate(values: [Double], times: [TimeInterval], rate: Double) -> Estimate? {
        let count = values.count
        // Band-pass ~0.7…4 Hz: remove the slow drift (1 s window), then smooth twice (0.15 s).
        let trend = centeredAverage(values, window: max(3, Int(rate * 1.0)))
        let detrended = zip(values, trend).map { $0 - $1 }
        let smoothWindow = max(2, Int(rate * 0.15))
        let filtered = centeredAverage(centeredAverage(detrended, window: smoothWindow), window: smoothWindow)

        let mean = filtered.reduce(0, +) / Double(count)
        let centered = filtered.map { $0 - mean }
        let energy = centered.reduce(0) { $0 + $1 * $1 }
        guard energy > 1e-9 else { return nil }

        // Autocorrelation over the plausible lags.
        let minLag = max(2, Int((rate * 60 / bpmRange.upperBound).rounded(.down)))
        let maxLag = min(count / 2, Int((rate * 60 / bpmRange.lowerBound).rounded(.up)))
        guard maxLag > minLag + 2 else { return nil }
        var correlation = [Double](repeating: 0, count: maxLag + 2)
        for lag in (minLag - 1)...(maxLag + 1) where lag < count {
            var sum = 0.0
            for index in 0..<(count - lag) { sum += centered[index] * centered[index + lag] }
            correlation[lag] = sum / energy * Double(count) / Double(count - lag)
        }

        // Real peaks only (a local maximum inside the range), never the edge of the range.
        let peaks = (minLag...maxLag).filter { correlation[$0] > correlation[$0 - 1] && correlation[$0] >= correlation[$0 + 1] }
        guard let strongest = peaks.max(by: { correlation[$0] < correlation[$1] }) else { return nil }
        // The period also repeats at 2×, 3×… its length, and the long lags are boosted by the
        // normalisation: the true period is the shortest peak nearly as strong as the strongest
        // (picking the strongest read 120 bpm as 60 or 40).
        var best = peaks.first { correlation[$0] >= correlation[strongest] * 0.8 } ?? strongest
        // Half the period: for a true period its correlation is negative (beat against trough),
        // so a clearly positive peak there means the rhythm is really twice as fast.
        while let half = peaks.last(where: { abs(Double(best) / Double($0) - 2) < 0.3 }),
              correlation[half] >= correlation[best] * 0.5 {
            best = half
        }
        let periodicity = correlation[best]
        guard periodicity >= minimumPeriodicity else { return nil }

        // Parabolic interpolation around the peak for a finer period.
        let left = correlation[best - 1], middle = correlation[best], right = correlation[best + 1]
        let denominator = left - 2 * middle + right
        let offset = denominator != 0 ? max(-0.5, min(0.5, 0.5 * (left - right) / denominator)) : 0
        var periodBPM = 60 * rate / (Double(best) + offset)
        guard bpmRange.contains(periodBPM) else { return nil }

        // Cross-check with the beats themselves.
        let spread = (energy / Double(count)).squareRoot()
        var beats = beatCheck(centered, times: times, spread: spread, period: Double(best) + offset, bpm: periodBPM)
        // Noise can drown the half-period peak of a fast pulse (115 bpm read as 58): when the
        // beats line up at twice the rate, that is the rhythm.
        if periodBPM * 2 <= bpmRange.upperBound {
            let half = beatCheck(centered, times: times, spread: spread, period: (Double(best) + offset) / 2, bpm: periodBPM * 2)
            if half.agree && half.regular {
                periodBPM *= 2
                beats = half
            }
        }

        let reliable = periodicity > reliablePeriodicity && beats.agree && beats.regular
        return Estimate(bpm: Int(periodBPM.rounded()), periodicity: periodicity, reliable: reliable)
    }

    /// Beats (peaks at least 60 % of a period apart) and whether their spacing matches `bpm`
    /// and is regular.
    private static func beatCheck(_ centered: [Double], times: [TimeInterval], spread: Double, period: Double, bpm: Double) -> (agree: Bool, regular: Bool) {
        let count = centered.count
        let minGap = Int(period * 0.6)
        var beats: [Int] = []
        if count > 2 {
            for index in 1..<(count - 1)
            where centered[index] > spread * 0.2 && centered[index] >= centered[index - 1] && centered[index] > centered[index + 1] {
                if let last = beats.last, index - last < minGap {
                    if centered[index] > centered[last] { beats[beats.count - 1] = index }
                } else {
                    beats.append(index)
                }
            }
        }
        guard beats.count >= 5 else { return (false, false) }
        // Noise only shows a « beat » here and there: most of the expected beats must be found.
        let expected = (times.last.map { $0 - times[0] } ?? 0) * bpm / 60
        guard Double(beats.count) >= minimumBeatCoverage * expected else { return (false, false) }
        let intervals = zip(beats.dropFirst(), beats).map { times[$0] - times[$1] }
        let sorted = intervals.sorted()
        let median = sorted[sorted.count / 2]
        let agree = median > 0 && abs(60 / median - bpm) / bpm < 0.12
        let average = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.reduce(0) { $0 + pow($1 - average, 2) } / Double(intervals.count)
        let regular = average > 0 && variance.squareRoot() / average < maximumBeatVariation
        return (agree, regular)
    }

    /// Moving average centred on each sample (no phase shift), shrinking at the edges.
    private static func centeredAverage(_ input: [Double], window: Int) -> [Double] {
        guard window > 1, !input.isEmpty else { return input }
        var prefix = [0.0]
        prefix.reserveCapacity(input.count + 1)
        for value in input { prefix.append(prefix[prefix.count - 1] + value) }
        let half = window / 2
        return input.indices.map { index in
            let low = max(0, index - half), high = min(input.count, index + half + 1)
            return (prefix[high] - prefix[low]) / Double(high - low)
        }
    }
}
