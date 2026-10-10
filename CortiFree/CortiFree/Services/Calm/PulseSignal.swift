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
    }

    static let bpmRange = 40.0...180.0
    /// Below this the signal has no rhythm to speak of: no number rather than a wrong one.
    static let minimumPeriodicity = 0.4

    static func estimate(_ samples: [Sample]) -> Estimate? {
        guard samples.count > 60, let start = samples.first?.time, let end = samples.last?.time, end - start > 4 else { return nil }
        let rate = Double(samples.count) / (end - start)
        let times = samples.map(\.time)
        // Blood absorbs light: a beat darkens the image, so flip the sign to make beats point up.
        let channels = [samples.map { -$0.red }, samples.map { -$0.green }]
        return channels
            .compactMap { estimate(values: $0, times: times, rate: rate) }
            .max { $0.periodicity < $1.periodicity }
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
        guard var best = peaks.max(by: { correlation[$0] < correlation[$1] }) else { return nil }
        // The period also repeats at twice its length: keep the shorter one when it is nearly as strong.
        if let shorter = peaks.first(where: { abs(Double(best) / Double($0) - 2) < 0.2 }),
           correlation[shorter] > correlation[best] * 0.8 {
            best = shorter
        }
        let periodicity = correlation[best]
        guard periodicity >= minimumPeriodicity else { return nil }

        // Parabolic interpolation around the peak for a finer period.
        let left = correlation[best - 1], middle = correlation[best], right = correlation[best + 1]
        let denominator = left - 2 * middle + right
        let offset = denominator != 0 ? max(-0.5, min(0.5, 0.5 * (left - right) / denominator)) : 0
        let periodBPM = 60 * rate / (Double(best) + offset)
        guard bpmRange.contains(periodBPM) else { return nil }

        // Cross-check with the beats themselves: peaks at least 60 % of a period apart.
        let spread = (energy / Double(count)).squareRoot()
        let minGap = Int(Double(best) * 0.6)
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
        var agree = false
        var regular = false
        if beats.count >= 5 {
            let intervals = zip(beats.dropFirst(), beats).map { times[$0] - times[$1] }
            let sorted = intervals.sorted()
            let median = sorted[sorted.count / 2]
            if median > 0 { agree = abs(60 / median - periodBPM) / periodBPM < 0.12 }
            let average = intervals.reduce(0, +) / Double(intervals.count)
            let variance = intervals.reduce(0) { $0 + pow($1 - average, 2) } / Double(intervals.count)
            regular = average > 0 && variance.squareRoot() / average < 0.2
        }

        let reliable = periodicity > 0.5 && agree && regular
        return Estimate(bpm: Int(periodBPM.rounded()), periodicity: periodicity, reliable: reliable)
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
