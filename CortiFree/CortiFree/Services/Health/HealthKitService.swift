//
//  HealthKitService.swift
//  CortiFree
//
//  Apple Health bridge (opt-in). Health data stays on the device: it is read and written
//  through HealthKit only, never sent to Firestore, analytics or the assistant.
//
//  - GAD-7 (anxiety questionnaire): read the latest one taken in Health, to tune the plan
//  - State of Mind: daily mood from the daily check-in
//  - Mindful minutes: finished breathing / meditation sessions
//

import Foundation
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    /// The user turned Apple Health on in CortiFree (HealthKit itself never says whether reads were denied).
    @Published private(set) var isEnabled: Bool

    private let store = HKHealthStore()
    private let enabledKey = "healthKit.enabled.v1"

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
    }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var gad7Type: HKScoredAssessmentType { HKScoredAssessmentType(.GAD7) }
    private var stateOfMindType: HKStateOfMindType { HKObjectType.stateOfMindType() }
    private var mindfulType: HKCategoryType { HKCategoryType(.mindfulSession) }

    private var shareTypes: Set<HKSampleType> { [stateOfMindType, mindfulType] }
    private var readTypes: Set<HKObjectType> { [gad7Type, stateOfMindType] }

    // MARK: - Opt-in

    /// Shows the Health permission sheet (only the first time) and turns the sync on.
    @discardableResult
    func enable() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            setEnabled(true)
            AnalyticsManager.shared.track(event: "health_connected")
            return true
        } catch {
            #if DEBUG
            print("⚠️ HealthKitService: authorization failed: \(error.localizedDescription)")
            #endif
            return false
        }
    }

    /// Stops reading / writing. Permissions themselves can only be revoked in the Health app.
    func disable() {
        setEnabled(false)
        AnalyticsManager.shared.track(event: "health_disconnected")
    }

    private func setEnabled(_ value: Bool) {
        isEnabled = value
        UserDefaults.standard.set(value, forKey: enabledKey)
    }

    private func canWrite(_ type: HKObjectType) -> Bool {
        isEnabled && isAvailable && store.authorizationStatus(for: type) == .sharingAuthorized
    }

    // MARK: - GAD-7

    /// Latest GAD-7 stored in Health (taken in the Health app or another app), if any.
    func latestGAD7() async -> AnxietyCheckResult? {
        guard isEnabled, isAvailable else { return nil }
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.gad7Assessment()],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        do {
            guard let sample = try await descriptor.result(for: store).first else { return nil }
            return AnxietyCheckResult(
                date: sample.endDate,
                answers: sample.answers.map(\.rawValue),
                source: sample.sourceRevision.source.bundleIdentifier == Bundle.main.bundleIdentifier ? .app : .health
            )
        } catch {
            return nil
        }
    }

    // MARK: - State of Mind

    /// Daily mood from the check-in (one per day; the Health app shows it under State of Mind).
    func saveDailyMood(_ mood: Mood, date: Date) async {
        guard canWrite(stateOfMindType) else { return }
        let sample = HKStateOfMind(
            date: date,
            kind: .dailyMood,
            valence: mood.healthValence,
            labels: mood.healthLabels,
            associations: []
        )
        await save(sample)
    }

    // MARK: - Mindful minutes

    func saveMindfulSession(durationSeconds: Int, endingAt end: Date = Date()) async {
        guard durationSeconds >= 30, canWrite(mindfulType) else { return }
        let start = end.addingTimeInterval(-TimeInterval(durationSeconds))
        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: start,
            end: end
        )
        await save(sample)
    }

    // MARK: - Heart rate (Apple Watch), for Milo's pulse check

    private var heartRateType: HKQuantityType { HKQuantityType(.heartRate) }

    /// Most recent heart rate saved by the watch in the last 24 h, after asking to read it.
    /// Nil when there is no watch, no recent sample, or reading was declined.
    func latestHeartRate() async -> (bpm: Int, date: Date)? {
        guard isAvailable else { return nil }
        try? await store.requestAuthorization(toShare: [], read: [heartRateType])
        let start = Date().addingTimeInterval(-24 * 3600)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: heartRateType, predicate: HKQuery.predicateForSamples(withStart: start, end: Date()))],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        guard let sample = try? await descriptor.result(for: store).first else { return nil }
        let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        return (Int(bpm.rounded()), sample.endDate)
    }

    // MARK: - Body stress signals (Apple Watch)

    private var hrvType: HKQuantityType { HKQuantityType(.heartRateVariabilitySDNN) }
    private var restingHRType: HKQuantityType { HKQuantityType(.restingHeartRate) }
    private var sleepType: HKCategoryType { HKCategoryType(.sleepAnalysis) }

    /// Asks for heart rate variability, resting heart rate and sleep (separate sheet, on demand).
    @discardableResult
    func enableBodySignals() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes.union([hrvType, restingHRType, sleepType]))
            setEnabled(true)
            UserDefaults.standard.set(true, forKey: "healthKit.bodySignals.v1")
            AnalyticsManager.shared.track(event: "health_body_signals_connected")
            return true
        } catch {
            return false
        }
    }

    /// Last computed body signals, for Milo's context.
    @Published private(set) var latestBodySignals: BodySignals?

    var bodySignalsRequested: Bool { UserDefaults.standard.bool(forKey: "healthKit.bodySignals.v1") }

    /// Last night vs the user's own 30-day baseline. Nil when there is not enough watch data.
    func bodySignals() async -> BodySignals? {
        guard isEnabled, isAvailable, bodySignalsRequested else { return nil }
        let now = Date()
        let dayAgo = now.addingTimeInterval(-24 * 3600)
        let monthAgo = now.addingTimeInterval(-30 * 24 * 3600)

        async let hrvRecent = average(hrvType, unit: .secondUnit(with: .milli), from: dayAgo, to: now)
        async let hrvBase = average(hrvType, unit: .secondUnit(with: .milli), from: monthAgo, to: dayAgo)
        async let rhrRecent = average(restingHRType, unit: HKUnit.count().unitDivided(by: .minute()), from: dayAgo, to: now)
        async let rhrBase = average(restingHRType, unit: HKUnit.count().unitDivided(by: .minute()), from: monthAgo, to: dayAgo)
        async let sleep = sleepHours(endingAt: now)

        let signals = BodySignals(hrv: await hrvRecent, hrvBaseline: await hrvBase,
                                  restingHR: await rhrRecent, restingHRBaseline: await rhrBase,
                                  sleepHours: await sleep, date: now)
        latestBodySignals = signals.score == nil ? nil : signals
        return latestBodySignals
    }

    private func average(_ type: HKQuantityType, unit: HKUnit, from start: Date, to end: Date) async -> Double? {
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: type, predicate: HKQuery.predicateForSamples(withStart: start, end: end)),
            options: .discreteAverage
        )
        return try? await descriptor.result(for: store)?.averageQuantity()?.doubleValue(for: unit)
    }

    /// Hours asleep since 18:00 yesterday (the night that ended this morning).
    private func sleepHours(endingAt end: Date) async -> Double? {
        let windowStart = Calendar.current.startOfDay(for: end).addingTimeInterval(-6 * 3600)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: HKQuery.predicateForSamples(withStart: windowStart, end: end))],
            sortDescriptors: []
        )
        guard let samples = try? await descriptor.result(for: store), !samples.isEmpty else { return nil }
        let asleepValues = HKCategoryValueSleepAnalysis.allAsleepValues.map(\.rawValue)
        let seconds = samples
            .filter { asleepValues.contains($0.value) }
            .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        return seconds > 0 ? seconds / 3600 : nil
    }

    private func save(_ sample: HKSample) async {
        do {
            try await store.save(sample)
        } catch {
            #if DEBUG
            print("⚠️ HealthKitService: save failed: \(error.localizedDescription)")
            #endif
        }
    }
}

// MARK: - Mood → State of Mind

private extension Mood {
    var healthValence: Double {
        switch self {
        case .awful: return -0.9
        case .angry: return -0.6
        case .low: return -0.4
        case .okay: return 0
        case .good: return 0.5
        case .amazing: return 0.9
        }
    }

    var healthLabels: [HKStateOfMind.Label] {
        switch self {
        case .awful: return [.overwhelmed]
        case .angry: return [.angry]
        case .low: return [.sad]
        case .okay: return [.indifferent]
        case .good: return [.content]
        case .amazing: return [.happy]
        }
    }
}
