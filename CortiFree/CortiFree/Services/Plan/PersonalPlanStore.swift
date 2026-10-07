//
//  PersonalPlanStore.swift
//  CortiFree
//
//  Owns the current personalized plan: local Codable cache (per user), Firestore mirror
//  (users/{uid}/personalized_plan/current), onboarding profile persistence and migration
//  of existing users (built from their stored onboarding answers, starting today).
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class PersonalPlanStore: ObservableObject {
    static let shared = PersonalPlanStore()

    @Published private(set) var plan: PersonalPlan?
    @Published private(set) var isLoading = false

    private let defaults = UserDefaults.standard
    /// Last onboarding answers (not per-user: onboarding can happen before sign-in).
    private let onboardingProfileKey = "personalPlan.onboardingProfile.v1"
    private var ensureTask: Task<Void, Never>?
    private var loadedForUser: String = ""

    private init() {
        loadedForUser = userKey
        plan = loadLocalPlan()
    }

    private var userKey: String { Auth.auth().currentUser?.uid ?? UserPersistence.localUserID }
    private var planKey: String { "personalPlan.current.v1.\(userKey)" }

    // MARK: - Public API

    /// Today's plan day (1...28, can exceed 28 when the plan is finished).
    var todayIndex: Int { plan?.dayIndex() ?? 1 }

    /// Loads (or creates) the plan. Safe to call repeatedly; never throws.
    func ensurePlan() async {
        // Account switch: reload the cache for the signed-in user.
        if loadedForUser != userKey {
            loadedForUser = userKey
            plan = loadLocalPlan()
        }
        if plan == nil { plan = loadLocalPlan() }
        if plan != nil { return }

        if let ensureTask { await ensureTask.value; return }
        let task = Task { [weak self] in
            guard let self else { return }
            self.isLoading = true
            defer { self.isLoading = false }

            if let remote = await self.fetchRemotePlan() {
                self.plan = remote
                self.saveLocal(remote)
                return
            }
            let profile = await self.bestAvailableProfile()
            let newPlan = PersonalPlanGenerator.generate(profile: profile, startDate: Date())
            self.apply(newPlan)
        }
        ensureTask = task
        await task.value
        ensureTask = nil
    }

    /// Called at the end of onboarding with the user's answers.
    func createPlanFromOnboarding(_ profile: PlanProfile) {
        var profile = profile
        profile.source = "onboarding"
        saveOnboardingProfile(profile)
        let newPlan = PersonalPlanGenerator.generate(profile: profile, startDate: Date())
        apply(newPlan)
    }

    /// Change goal (or regenerate with the same inputs). Restarts at day 1 today.
    func regenerate(goal: PlanGoal?) {
        let profile = plan?.profile ?? storedOnboardingProfile() ?? PlanProfile()
        let newPlan = PersonalPlanGenerator.generate(profile: profile, overrideGoal: goal, startDate: Date(), cycle: plan?.cycle ?? 1)
        apply(newPlan)
    }

    /// After day 28: start a follow-up cycle with the same or a new goal.
    func startNextCycle(goal: PlanGoal?) {
        let profile = plan?.profile ?? storedOnboardingProfile() ?? PlanProfile()
        let keepGoal = goal ?? plan?.goal
        let override: PlanGoal? = (plan?.goalChosenByUser ?? false) || goal != nil ? keepGoal : nil
        let newPlan = PersonalPlanGenerator.generate(profile: profile, overrideGoal: override, startDate: Date(), cycle: (plan?.cycle ?? 1) + 1)
        apply(newPlan)
    }

    // MARK: - Onboarding profile

    func saveOnboardingProfile(_ profile: PlanProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: onboardingProfileKey)
        }
    }

    func storedOnboardingProfile() -> PlanProfile? {
        guard let data = defaults.data(forKey: onboardingProfileKey) else { return nil }
        return try? JSONDecoder().decode(PlanProfile.self, from: data)
    }

    // MARK: - Persistence

    private func apply(_ newPlan: PersonalPlan) {
        plan = newPlan
        saveLocal(newPlan)
        Task { await saveRemote(newPlan) }
        NotificationCenter.default.post(name: .personalPlanDidChange, object: nil)
    }

    private func loadLocalPlan() -> PersonalPlan? {
        guard let data = defaults.data(forKey: planKey),
              let decoded = try? JSONDecoder().decode(PersonalPlan.self, from: data),
              decoded.days.count == PersonalPlan.length else { return nil }
        return decoded
    }

    private func saveLocal(_ plan: PersonalPlan) {
        if let data = try? JSONEncoder().encode(plan) {
            defaults.set(data, forKey: planKey)
        }
    }

    private func saveRemote(_ plan: PersonalPlan) async {
        guard let uid = Auth.auth().currentUser?.uid,
              let data = try? JSONEncoder().encode(plan),
              let json = String(data: data, encoding: .utf8) else { return }
        let doc: [String: Any] = [
            "version": plan.version,
            "goal": plan.goal.rawValue,
            "secondaryGoal": plan.secondaryGoal.rawValue,
            "gentle": plan.gentle,
            "compact": plan.compact,
            "cycle": plan.cycle,
            "lengthDays": PersonalPlan.length,
            "startDate": Timestamp(date: plan.startDate),
            "goalChosenByUser": plan.goalChosenByUser,
            "profileSource": plan.profile.source,
            "planJSON": json,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        do {
            try await Firestore.firestore()
                .collection("users").document(uid)
                .collection("personalized_plan").document("current")
                .setData(doc)
        } catch {
            #if DEBUG
            print("⚠️ PersonalPlanStore: remote save failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func fetchRemotePlan() async -> PersonalPlan? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        do {
            let snapshot = try await Firestore.firestore()
                .collection("users").document(uid)
                .collection("personalized_plan").document("current")
                .getDocument()
            guard let json = snapshot.data()?["planJSON"] as? String,
                  let data = json.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode(PersonalPlan.self, from: data),
                  decoded.days.count == PersonalPlan.length else { return nil }
            return decoded
        } catch {
            return nil
        }
    }

    // MARK: - Migration (existing users)

    /// Local onboarding answers, else Firestore profile/baseline, else empty (→ stress track).
    private func bestAvailableProfile() async -> PlanProfile {
        if let local = storedOnboardingProfile(), !local.isEmpty { return local }
        var profile = PlanProfile()
        profile.genderCode = defaults.string(forKey: "onboarding_gender")

        guard let uid = Auth.auth().currentUser?.uid else { return profile }
        let db = Firestore.firestore()
        if let user = try? await db.collection("users").document(uid).getDocument().data() {
            if let reasons = user["stressReasons"] as? [String] {
                profile.reasonCodes = reasons.compactMap {
                    PlanLocalizationLookup.code(for: $0, prefix: "onboarding_v2.overall.reason_",
                                                codes: ["sleep", "anxiety", "energy", "focus", "mental", "difficult", "habits"])
                }
            }
            if let duration = user["stressDuration"] as? String {
                profile.durationCode = PlanLocalizationLookup.code(for: duration, prefix: "onboarding_v2.overall.duration_",
                                                                   codes: ["weeks", "2_6_months", "6_12_months", "1_year_plus", "years"])
            }
            if let age = user["age"] as? String {
                profile.ageCode = PlanLocalizationLookup.code(for: age, prefix: "onboarding_v2.overall.age_",
                                                              codes: ["under_18", "18_24", "25_34", "35_44", "45_54", "55_plus"])
            }
            if let gender = user["genderCode"] as? String { profile.genderCode = gender }
        }
        if let baseline = try? await db.collection("users").document(uid).collection("baseline").document("initial").getDocument().data() {
            if let answers = baseline["quizAnswers"] as? [Int], answers.count >= 8 { profile.quizAnswers = answers }
            if let prefs = baseline["preferences"] as? [String: Any] {
                profile.improvementGoal = prefs["primaryGoal"] as? String
                profile.availableMinutes = prefs["availableTime"] as? Int
            }
        }
        profile.source = profile.isEmpty ? "default" : "migrated"
        return profile
    }
}

extension Notification.Name {
    static let personalPlanDidChange = Notification.Name("PersonalPlanDidChange")
}

// MARK: - Reverse localization (stored answers are localized strings)

enum PlanLocalizationLookup {
    private static let bundles: [Bundle] = LanguageManager.Language.allCases.compactMap { lang in
        Bundle.main.path(forResource: lang.rawValue, ofType: "lproj").flatMap(Bundle.init(path:))
    }

    /// Finds the code whose localized string (`prefix + code`, any app language) equals `text`.
    static func code(for text: String, prefix: String, codes: [String]) -> String? {
        let needle = normalize(text)
        for code in codes {
            let key = prefix + code
            for bundle in bundles where normalize(bundle.localizedString(forKey: key, value: nil, table: nil)) == needle {
                return code
            }
        }
        return nil
    }

    /// Maps selected symptom labels (localized) to stable ids ("mental.1", "physical.4"...).
    static func symptomIDs(from labels: Set<String>) -> [String] {
        let groups: [(String, Int)] = [("mental", 6), ("physical", 6), ("social", 5)]
        var ids: [String] = []
        let needles = Set(labels.map(normalize))
        for (group, count) in groups {
            for i in 1...count {
                let key = "symptom_checker.\(group).\(i)"
                let current = normalize(LanguageManager.shared.localizedString(for: key))
                if needles.contains(current) || bundles.contains(where: { needles.contains(normalize($0.localizedString(forKey: key, value: nil, table: nil))) }) {
                    ids.append("\(group).\(i)")
                }
            }
        }
        return ids
    }

    private static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
