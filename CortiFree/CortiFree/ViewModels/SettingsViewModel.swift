//
//  SettingsViewModel.swift
//  CortiFree
//
//  ViewModel for Settings management with Firebase sync
//  Created by Claude on 21/11/2025.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class SettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    // Profile & Objective
    @Published var currentObjective: String = ""
    @Published var notificationsEnabled: Bool = true

    // Experience & Habits
    @Published var morningRoutineEnabled: Bool = true
    @Published var afternoonRoutineEnabled: Bool = true
    @Published var eveningRoutineEnabled: Bool = true
    @Published var morningTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @Published var afternoonTime: Date = Calendar.current.date(from: DateComponents(hour: 14, minute: 0)) ?? Date()
    @Published var eveningTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @Published var defaultSound: String = "rain"
    @Published var voiceGuidance: Bool = true
    @Published var ambientVolume: Double = 0.7

    // Privacy
    @Published var syncEnabled: Bool = true
    @Published var localDataSize: String = "0 MB"

    // Subscription (read-only from RevenueCat — no local cache)
    @Published var subscriptionStatus: String = ""
    @Published var renewalDate: String = ""

    /// Premium status derived from RevenueCat — never set manually
    var isPremium: Bool {
        RevenueCatManager.shared.hasPremiumEntitlement
    }

    // Sync Status
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let notificationsEnabled = "notificationsEnabled"
        static let morningRoutineEnabled = "morningRoutineEnabled"
        static let afternoonRoutineEnabled = "afternoonRoutineEnabled"
        static let eveningRoutineEnabled = "eveningRoutineEnabled"
        static let morningTime = "morningTime"
        static let afternoonTime = "afternoonTime"
        static let eveningTime = "eveningTime"
        static let defaultSound = "defaultSound"
        static let voiceGuidance = "voiceGuidance"
        static let ambientVolume = "ambientVolume"
        static let syncEnabled = "syncEnabled"
        static let selectedRoutineTitle = "selectedRoutineTitle"
    }

    // MARK: - Initialization

    init() {
        loadSettings()
        setupObservers()
        calculateLocalDataSize()
        loadSubscriptionStatus()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Auto-save to UserDefaults when any property changes
        Publishers.CombineLatest4(
            $notificationsEnabled,
            $morningRoutineEnabled,
            $afternoonRoutineEnabled,
            $eveningRoutineEnabled
        )
        .dropFirst() // Ignore initial value
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.saveToUserDefaults()
            self?.syncToFirebase()
        }
        .store(in: &cancellables)

        Publishers.CombineLatest4(
            $voiceGuidance,
            $ambientVolume,
            $syncEnabled,
            $defaultSound
        )
        .dropFirst()
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.saveToUserDefaults()
            self?.syncToFirebase()
        }
        .store(in: &cancellables)

        // Time changes
        Publishers.CombineLatest3(
            $morningTime,
            $afternoonTime,
            $eveningTime
        )
        .dropFirst()
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.saveToUserDefaults()
            self?.syncToFirebase()
        }
        .store(in: &cancellables)
    }

    // MARK: - Load Settings

    func loadSettings() {
        // Load from UserDefaults first (instant)
        loadFromUserDefaults()

        // Then sync from Firebase if enabled
        if syncEnabled, userId != nil {
            Task {
                await loadFromFirebase()
            }
        }
    }

    private func loadFromUserDefaults() {
        let defaults = UserDefaults.standard

        notificationsEnabled = defaults.bool(forKey: Keys.notificationsEnabled, defaultValue: true)
        morningRoutineEnabled = defaults.bool(forKey: Keys.morningRoutineEnabled, defaultValue: true)
        afternoonRoutineEnabled = defaults.bool(forKey: Keys.afternoonRoutineEnabled, defaultValue: true)
        eveningRoutineEnabled = defaults.bool(forKey: Keys.eveningRoutineEnabled, defaultValue: true)
        voiceGuidance = defaults.bool(forKey: Keys.voiceGuidance, defaultValue: true)
        syncEnabled = defaults.bool(forKey: Keys.syncEnabled, defaultValue: true)

        ambientVolume = defaults.double(forKey: Keys.ambientVolume, defaultValue: 0.7)
        defaultSound = defaults.string(forKey: Keys.defaultSound) ?? "rain"
        currentObjective = defaults.string(forKey: Keys.selectedRoutineTitle) ?? ""

        // Load times
        if let morningData = defaults.data(forKey: Keys.morningTime),
           let decoded = try? JSONDecoder().decode(Date.self, from: morningData) {
            morningTime = decoded
        }
        if let afternoonData = defaults.data(forKey: Keys.afternoonTime),
           let decoded = try? JSONDecoder().decode(Date.self, from: afternoonData) {
            afternoonTime = decoded
        }
        if let eveningData = defaults.data(forKey: Keys.eveningTime),
           let decoded = try? JSONDecoder().decode(Date.self, from: eveningData) {
            eveningTime = decoded
        }
    }

    // MARK: - Save Settings

    private func saveToUserDefaults() {
        let defaults = UserDefaults.standard

        defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
        defaults.set(morningRoutineEnabled, forKey: Keys.morningRoutineEnabled)
        defaults.set(afternoonRoutineEnabled, forKey: Keys.afternoonRoutineEnabled)
        defaults.set(eveningRoutineEnabled, forKey: Keys.eveningRoutineEnabled)
        defaults.set(voiceGuidance, forKey: Keys.voiceGuidance)
        defaults.set(ambientVolume, forKey: Keys.ambientVolume)
        defaults.set(syncEnabled, forKey: Keys.syncEnabled)
        defaults.set(defaultSound, forKey: Keys.defaultSound)

        // Save times as encoded data
        if let encoded = try? JSONEncoder().encode(morningTime) {
            defaults.set(encoded, forKey: Keys.morningTime)
        }
        if let encoded = try? JSONEncoder().encode(afternoonTime) {
            defaults.set(encoded, forKey: Keys.afternoonTime)
        }
        if let encoded = try? JSONEncoder().encode(eveningTime) {
            defaults.set(encoded, forKey: Keys.eveningTime)
        }

        defaults.synchronize()
    }

    // MARK: - Firebase Sync

    func syncToFirebase() {
        guard syncEnabled, let userId = userId else { return }

        Task {
            isSyncing = true
            syncError = nil

            do {
                let settingsData: [String: Any] = [
                    "notifications": [
                        "enabled": notificationsEnabled,
                        "morning": [
                            "enabled": morningRoutineEnabled,
                            "time": formatTime(morningTime)
                        ],
                        "afternoon": [
                            "enabled": afternoonRoutineEnabled,
                            "time": formatTime(afternoonTime)
                        ],
                        "evening": [
                            "enabled": eveningRoutineEnabled,
                            "time": formatTime(eveningTime)
                        ]
                    ],
                    "experience": [
                        "defaultSound": defaultSound,
                        "voiceGuidance": voiceGuidance,
                        "ambientVolume": ambientVolume
                    ],
                    "privacy": [
                        "syncEnabled": syncEnabled
                    ],
                    "lastUpdated": FieldValue.serverTimestamp()
                ]

                try await db.collection("users")
                    .document(userId)
                    .collection("settings")
                    .document("preferences")
                    .setData(settingsData, merge: true)

                lastSyncDate = Date()
                #if DEBUG
                print("✅ Settings synced to Firebase")
                #endif

            } catch {
                syncError = error.localizedDescription
                #if DEBUG
                print("❌ Firebase sync error: \(error.localizedDescription)")
                #endif
            }

            isSyncing = false
        }
    }

    private func loadFromFirebase() async {
        guard let userId = userId else { return }

        isSyncing = true

        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("settings")
                .document("preferences")
                .getDocument()

            guard let data = snapshot.data() else {
                isSyncing = false
                return
            }

            // Parse notifications
            if let notifications = data["notifications"] as? [String: Any] {
                if let enabled = notifications["enabled"] as? Bool {
                    self.notificationsEnabled = enabled
                }
                if let morning = notifications["morning"] as? [String: Any] {
                    if let enabled = morning["enabled"] as? Bool {
                        self.morningRoutineEnabled = enabled
                    }
                    if let timeStr = morning["time"] as? String {
                        self.morningTime = parseTime(timeStr)
                    }
                }
                if let afternoon = notifications["afternoon"] as? [String: Any] {
                    if let enabled = afternoon["enabled"] as? Bool {
                        self.afternoonRoutineEnabled = enabled
                    }
                    if let timeStr = afternoon["time"] as? String {
                        self.afternoonTime = parseTime(timeStr)
                    }
                }
                if let evening = notifications["evening"] as? [String: Any] {
                    if let enabled = evening["enabled"] as? Bool {
                        self.eveningRoutineEnabled = enabled
                    }
                    if let timeStr = evening["time"] as? String {
                        self.eveningTime = parseTime(timeStr)
                    }
                }
            }

            // Parse experience
            if let experience = data["experience"] as? [String: Any] {
                if let sound = experience["defaultSound"] as? String {
                    self.defaultSound = sound
                }
                if let voice = experience["voiceGuidance"] as? Bool {
                    self.voiceGuidance = voice
                }
                if let volume = experience["ambientVolume"] as? Double {
                    self.ambientVolume = volume
                }
            }

            lastSyncDate = Date()
            #if DEBUG
            print("✅ Settings loaded from Firebase")
            #endif

        } catch {
            syncError = error.localizedDescription
            #if DEBUG
            print("❌ Firebase load error: \(error.localizedDescription)")
            #endif
        }

        isSyncing = false
    }

    // MARK: - Helper Methods

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func parseTime(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let date = formatter.date(from: timeString) {
            return date
        }
        return Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    }

    func calculateLocalDataSize() {
        Task {
            let fileManager = FileManager.default
            guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                localDataSize = "0 MB"
                return
            }

            var totalSize: Int64 = 0

            if let enumerator = fileManager.enumerator(at: documentsURL, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator {
                    do {
                        let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                        totalSize += Int64(resourceValues.fileSize ?? 0)
                    } catch {
                        continue
                    }
                }
            }

            let sizeInMB = Double(totalSize) / 1_048_576.0
            localDataSize = String(format: "%.1f MB", sizeInMB)
        }
    }

    private func loadSubscriptionStatus() {
        Task { @MainActor in
            // isPremium is now a computed property from RevenueCat — no local assignment
            self.subscriptionStatus = isPremium ? StringKeys.Settings.subscriptionPremium : StringKeys.Settings.subscriptionFree

            // Get renewal/expiration date
            if let expirationDate = RevenueCatManager.shared.getSubscriptionExpirationDate() {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                formatter.locale = Locale.current
                self.renewalDate = formatter.string(from: expirationDate)
            } else {
                self.renewalDate = ""
            }
        }
    }

    // MARK: - Validation

    func validateVolume(_ volume: Double) -> Double {
        return max(0.0, min(1.0, volume))
    }

    func validateTimeOrder() -> Bool {
        let calendar = Calendar.current
        let morningHour = calendar.component(.hour, from: morningTime)
        let afternoonHour = calendar.component(.hour, from: afternoonTime)
        let eveningHour = calendar.component(.hour, from: eveningTime)

        return morningHour < afternoonHour && afternoonHour < eveningHour
    }

    // MARK: - Reset

    func resetToDefaults() {
        notificationsEnabled = true
        morningRoutineEnabled = true
        afternoonRoutineEnabled = true
        eveningRoutineEnabled = true
        morningTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
        afternoonTime = Calendar.current.date(from: DateComponents(hour: 14, minute: 0)) ?? Date()
        eveningTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
        defaultSound = "rain"
        voiceGuidance = true
        ambientVolume = 0.7
        syncEnabled = true

        saveToUserDefaults()
        if syncEnabled {
            syncToFirebase()
        }
    }
}

// MARK: - UserDefaults Extension

private extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return bool(forKey: key)
    }

    func double(forKey key: String, defaultValue: Double) -> Double {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return double(forKey: key)
    }
}
