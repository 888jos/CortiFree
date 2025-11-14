//
//  TaskManager.swift
//  CortiFree
//
//  Created by Claude on 10/11/2025.
//  Manages task database (local JSON) + user progress (Firestore)
//

import Foundation
import FirebaseFirestore
import Combine

class TaskManager: ObservableObject {
    static let shared = TaskManager()

    // MARK: - Published Properties
    @Published var taskDatabase: TaskDatabase?
    @Published var allTasks: [TaskDetail] = []
    @Published var tasksByCategory: [TaskCategoryType: [TaskDetail]] = [:]
    @Published var isLoaded: Bool = false

    // Task lookup dictionary for O(1) access
    private var tasksById: [String: TaskDetail] = [:]

    private init() {
        loadTaskDatabase()
    }

    // MARK: - Load Local JSON Database

    func loadTaskDatabase() {
        print("🔄 Starting to load task database...")

        guard let url = Bundle.main.url(forResource: "TASKS_DATABASE", withExtension: "json") else {
            print("❌ TASKS_DATABASE.json not found in bundle")
            print("📦 Bundle path: \(Bundle.main.bundlePath)")
            DispatchQueue.main.async {
                self.isLoaded = true // Set to true anyway to stop loading spinner
            }
            return
        }

        print("✅ Found JSON at: \(url.path)")

        do {
            let data = try Data(contentsOf: url)
            print("📄 Loaded \(data.count) bytes of JSON data")

            let decoder = JSONDecoder()
            let database = try decoder.decode(TaskDatabase.self, from: data)
            print("✅ Successfully decoded database")
            print("📊 Categories: \(database.categories.count)")

            // Extract all tasks from all categories
            var tasks: [TaskDetail] = []
            var taskDict: [String: TaskDetail] = [:]
            var categoryDict: [TaskCategoryType: [TaskDetail]] = [:]

            for category in database.categories {
                print("📁 Processing category: \(category.name) with \(category.tasks.count) tasks")
                for task in category.tasks {
                    tasks.append(task)
                    taskDict[task.id] = task

                    let categoryType = task.categoryType
                    if categoryDict[categoryType] == nil {
                        categoryDict[categoryType] = []
                    }
                    categoryDict[categoryType]?.append(task)
                }
            }

            DispatchQueue.main.async {
                self.taskDatabase = database
                self.allTasks = tasks
                self.tasksById = taskDict
                self.tasksByCategory = categoryDict
                self.isLoaded = true
                print("✅ Loaded \(tasks.count) tasks from database")
                print("🎯 isLoaded set to: \(self.isLoaded)")
            }
        } catch let DecodingError.keyNotFound(key, context) {
            print("❌ Decoding error - Key not found: \(key)")
            print("   Context: \(context.debugDescription)")
            print("   Coding path: \(context.codingPath)")
            DispatchQueue.main.async {
                self.isLoaded = true
            }
        } catch let DecodingError.typeMismatch(type, context) {
            print("❌ Decoding error - Type mismatch for type: \(type)")
            print("   Context: \(context.debugDescription)")
            print("   Coding path: \(context.codingPath)")
            DispatchQueue.main.async {
                self.isLoaded = true
            }
        } catch let DecodingError.valueNotFound(type, context) {
            print("❌ Decoding error - Value not found for type: \(type)")
            print("   Context: \(context.debugDescription)")
            print("   Coding path: \(context.codingPath)")
            DispatchQueue.main.async {
                self.isLoaded = true
            }
        } catch {
            print("❌ Error loading task database: \(error)")
            print("   Error details: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isLoaded = true
            }
        }
    }

    // MARK: - Task Lookup

    func getTask(byId id: String) -> TaskDetail? {
        return tasksById[id]
    }

    func getTasks(byIds ids: [String]) -> [TaskDetail] {
        return ids.compactMap { tasksById[$0] }
    }

    func getTasks(byCategory category: TaskCategoryType) -> [TaskDetail] {
        return tasksByCategory[category] ?? []
    }

    func getTasks(byDifficulty difficulty: TaskDifficultyLevel) -> [TaskDetail] {
        return allTasks.filter { $0.difficultyLevel == difficulty }
    }

    func getTasks(byTag tag: String) -> [TaskDetail] {
        return allTasks.filter { $0.tags.contains(tag) }
    }

    func searchTasks(query: String) -> [TaskDetail] {
        let lowercaseQuery = query.lowercased()
        return allTasks.filter {
            $0.title.lowercased().contains(lowercaseQuery) ||
            $0.description.lowercased().contains(lowercaseQuery) ||
            $0.tags.contains(where: { $0.lowercased().contains(lowercaseQuery) })
        }
    }

    // MARK: - Firestore Integration (User Progress)

    private let db = Firestore.firestore()

    // Fetch today's program for user
    func fetchTodayProgram(userId: String, routineId: String, dayNumber: Int) async throws -> UserDailyProgram? {
        let query = db.collection("users")
            .document(userId)
            .collection("dailyPrograms")
            .whereField("routineId", isEqualTo: routineId)
            .whereField("dayNumber", isEqualTo: dayNumber)
            .limit(to: 1)

        let snapshot = try await query.getDocuments()
        guard let document = snapshot.documents.first else { return nil }

        var program = try document.data(as: UserDailyProgram.self)
        program.id = document.documentID
        return program
    }

    // Mark task as completed
    func completeTask(userId: String, programId: String, taskId: String) async throws {
        let programRef = db.collection("users")
            .document(userId)
            .collection("dailyPrograms")
            .document(programId)

        try await programRef.updateData([
            "completedTaskIds": FieldValue.arrayUnion([taskId])
        ])

        print("✅ Task \(taskId) marked as completed")
    }

    // Create daily program for user
    func createDailyProgram(userId: String, routineId: String, dayNumber: Int, taskIds: [String]) async throws -> String {
        let program = UserDailyProgram(
            userId: userId,
            routineId: routineId,
            dayNumber: dayNumber,
            taskIds: taskIds,
            date: Date()
        )

        let docRef = try db.collection("users")
            .document(userId)
            .collection("dailyPrograms")
            .addDocument(from: program)

        print("✅ Created daily program: \(docRef.documentID)")
        return docRef.documentID
    }

    // MARK: - Helper: Get Recommended Tasks

    func getRecommendedTasks(for routine: RoutinePlan, day: Int) -> [TaskDetail] {
        // Logic to recommend tasks based on routine and day
        // For now, return mix of tasks from relevant categories

        var recommendedIds: [String] = []

        switch routine.id {
        case "master-mind":
            // Focus on breathing, meditation, mental
            recommendedIds = [
                "breathing_coherence",
                "meditation_mindfulness",
                "meditation_grounding",
                "journal_emotions"
            ]

        case "recover-sleep":
            // Focus on sleep-related tasks
            recommendedIds = [
                "breathing_slow_6_6",
                "meditation_sleep",
                "screen_before_bed",
                "nature_breathing"
            ]

        case "boost-energy":
            // Focus on energy-boosting tasks
            recommendedIds = [
                "breathing_kapalabhati",
                "movement_walk",
                "movement_yoga_flow",
                "education_podcast"
            ]

        case "manage-stress":
            // Focus on stress management
            recommendedIds = [
                "breathing_coherence",
                "breathing_box",
                "meditation_body_scan_short",
                "nature_walk"
            ]

        default:
            recommendedIds = []
        }

        // Adjust based on progression (day number)
        if day <= 14 {
            // Week 1-2: Beginner tasks only
            return getTasks(byIds: recommendedIds).filter { $0.difficultyLevel == .beginner }
        } else if day <= 28 {
            // Week 3-4: Mix beginner + intermediate
            return getTasks(byIds: recommendedIds).filter { $0.difficultyLevel != .advanced }
        } else {
            // Week 5+: All levels
            return getTasks(byIds: recommendedIds)
        }
    }

    // MARK: - Statistics

    func getTotalXP() -> Int {
        return allTasks.reduce(0) { $0 + $1.xp }
    }

    func getAverageDuration() -> Int {
        guard !allTasks.isEmpty else { return 0 }
        return allTasks.reduce(0) { $0 + $1.durationMinutes } / allTasks.count
    }

    func getCategoryDistribution() -> [TaskCategoryType: Int] {
        var distribution: [TaskCategoryType: Int] = [:]
        for task in allTasks {
            distribution[task.categoryType, default: 0] += 1
        }
        return distribution
    }
}
