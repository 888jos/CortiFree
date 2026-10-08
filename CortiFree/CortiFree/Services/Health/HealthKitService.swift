//
//  HealthKitService.swift
//  CortiFree
//
//  Apple Health bridge (opt-in). Health data stays on the device: it is read and written
//  through HealthKit only, never sent to Firestore, analytics or the assistant.
//
//  - GAD-7 (anxiety questionnaire): read the latest one, write the ones taken in the app
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

    private var shareTypes: Set<HKSampleType> { [gad7Type, stateOfMindType, mindfulType] }
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

    func save(_ result: AnxietyCheckResult) async {
        guard canWrite(gad7Type) else { return }
        let answers = result.answers.compactMap(HKGAD7Assessment.Answer.init(rawValue:))
        guard answers.count == AnxietyCheck.questionCount else { return }
        await save(HKGAD7Assessment(date: result.date, answers: answers))
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
