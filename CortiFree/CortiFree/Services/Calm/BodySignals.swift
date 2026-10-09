//
//  BodySignals.swift
//  CortiFree
//
//  Morning « body stress » from Apple Watch data: last night's heart rate variability and
//  resting heart rate against the user's own 30-day baseline, plus sleep. A wellness
//  indicator of how tense the body is, not a cortisol or medical measure.
//

import Foundation

struct BodySignals: Equatable {
    var hrv: Double?
    var hrvBaseline: Double?
    var restingHR: Double?
    var restingHRBaseline: Double?
    var sleepHours: Double?
    var date: Date

    enum Level: String { case calm, balanced, elevated, high }

    /// 0 (very relaxed) … 100 (very tense). Needs at least HRV or resting HR with a baseline.
    var score: Int? {
        var parts: [(value: Double, weight: Double)] = []
        if let hrv, let base = hrvBaseline, base > 0 {
            // 33 % under your usual HRV → maximum strain.
            parts.append((min(1, max(0, 0.5 + (base - hrv) / base * 1.5)), 0.45))
        }
        if let rhr = restingHR, let base = restingHRBaseline, base > 0 {
            // 10 % above your usual resting heart rate → maximum strain.
            parts.append((min(1, max(0, 0.5 + (rhr - base) / base * 5)), 0.3))
        }
        guard !parts.isEmpty else { return nil }
        if let sleepHours {
            parts.append((min(1, max(0, (7.5 - sleepHours) / 3 + 0.2)), 0.25))
        }
        let total = parts.reduce(0) { $0 + $1.weight }
        return Int((parts.reduce(0) { $0 + $1.value * $1.weight } / total * 100).rounded())
    }

    var level: Level {
        switch score ?? 0 {
        case ..<35: return .calm
        case ..<55: return .balanced
        case ..<75: return .elevated
        default: return .high
        }
    }

    /// HRV change vs baseline, in percent (negative = lower than usual).
    var hrvChange: Int? {
        guard let hrv, let base = hrvBaseline, base > 0 else { return nil }
        return Int(((hrv - base) / base * 100).rounded())
    }

    var contextLine: String {
        var line = "Body stress signals this morning (Apple Watch, wellness estimate): \(level.rawValue), score \(score ?? 0)/100"
        if let change = hrvChange { line += ", HRV \(change >= 0 ? "+" : "")\(change)% vs usual" }
        if let restingHR { line += ", resting heart rate \(Int(restingHR)) bpm" }
        if let sleepHours { line += ", slept \(String(format: "%.1f", sleepHours)) h" }
        return line + ". Adapt today's advice gently to it; never call it a cortisol measure."
    }
}
