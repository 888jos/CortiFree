import Foundation

enum ProgressPeriod: Int, CaseIterable, Identifiable {
    case week = 7
    case month = 28

    var id: Int { rawValue }
}

enum ProgressActivityCategory: String, Codable, CaseIterable, Identifiable {
    case breathing
    case meditation
    case sounds
    case other

    var id: String { rawValue }
}

struct ProgressDay: Codable, Identifiable, Equatable {
    let date: Date
    let completionCount: Int
    let moodScore: Double?

    var id: Date { date }
    var isActive: Bool { completionCount > 0 }
}

struct ProgressActivityMetric: Codable, Identifiable, Equatable {
    let category: ProgressActivityCategory
    let durationSeconds: Int
    let sessionCount: Int

    var id: String { category.rawValue }
}

struct ProgressScorePoint: Codable, Identifiable, Equatable {
    let date: Date
    let score: Double

    var id: Date { date }
}

struct ProgressDomainTrend: Codable, Identifiable, Equatable {
    enum Domain: String, Codable, CaseIterable {
        case serenity
        case sleep
        case energy
        case focus
        case balance
    }

    let domain: Domain
    let currentValue: Double
    let previousValue: Double?
    let dayOneValue: Double?

    init(
        domain: Domain,
        currentValue: Double,
        previousValue: Double? = nil,
        dayOneValue: Double? = nil
    ) {
        self.domain = domain
        self.currentValue = currentValue
        self.previousValue = previousValue
        self.dayOneValue = dayOneValue
    }

    var id: String { domain.rawValue }
    var change: Double? {
        guard let previousValue else { return nil }
        return currentValue - previousValue
    }
}

struct ProgressDashboardData: Codable, Equatable {
    let generatedAt: Date
    let programStartDate: Date
    let days: [ProgressDay]
    let currentStreak: Int
    let bestStreak: Int
    let activities: [ProgressActivityMetric]
    let domainTrends: [ProgressDomainTrend]
    let topActivity: ProgressActivityCategory?
    let baselineScore: Double?
    let currentScore: Double?
    let scoreHistory: [ProgressScorePoint]

    static let empty = ProgressDashboardData(
        generatedAt: Date(),
        programStartDate: Date(),
        days: [],
        currentStreak: 0,
        bestStreak: 0,
        activities: ProgressActivityCategory.allCases.map {
            ProgressActivityMetric(category: $0, durationSeconds: 0, sessionCount: 0)
        },
        domainTrends: [],
        topActivity: nil,
        baselineScore: nil,
        currentScore: nil,
        scoreHistory: []
    )

    func days(in period: ProgressPeriod, relativeTo now: Date = Date(), calendar: Calendar = .current) -> [ProgressDay] {
        let start = calendar.date(byAdding: .day, value: -(period.rawValue - 1), to: calendar.startOfDay(for: now)) ?? now
        return days.filter { $0.date >= start }
    }

    func activeDayCount(in period: ProgressPeriod, relativeTo now: Date = Date(), calendar: Calendar = .current) -> Int {
        days(in: period, relativeTo: now, calendar: calendar).filter(\.isActive).count
    }

    func totalMinutes(for category: ProgressActivityCategory) -> Int {
        let seconds = activities.first(where: { $0.category == category })?.durationSeconds ?? 0
        return Int((Double(seconds) / 60.0).rounded())
    }
}

enum ProgressAggregation {
    static func days(
        programStartDate: Date,
        taskCompletionsByProgramDay: [Int: Int],
        exerciseDates: [Date],
        moodScoresByDate: [Date: Double],
        checkInDates: [Date] = [],
        range: Int = 28,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [ProgressDay] {
        let today = calendar.startOfDay(for: now)
        var completionCounts: [Date: Int] = [:]

        for (programDay, count) in taskCompletionsByProgramDay where count > 0 {
            guard let date = calendar.date(byAdding: .day, value: programDay - 1, to: calendar.startOfDay(for: programStartDate)) else { continue }
            completionCounts[calendar.startOfDay(for: date), default: 0] += count
        }

        for date in exerciseDates {
            completionCounts[calendar.startOfDay(for: date), default: 0] += 1
        }

        // A check-in makes a day active without adding a duplicate activity.
        for date in checkInDates {
            let day = calendar.startOfDay(for: date)
            completionCounts[day] = max(completionCounts[day, default: 0], 1)
        }

        return (0..<range).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return ProgressDay(
                date: date,
                completionCount: completionCounts[date, default: 0],
                moodScore: moodScoresByDate[date]
            )
        }
    }

    static func streaks(from days: [ProgressDay]) -> (current: Int, best: Int) {
        var best = 0
        var running = 0

        for day in days {
            if day.isActive {
                running += 1
                best = max(best, running)
            } else {
                running = 0
            }
        }

        var current = 0
        var reversedDays = Array(days.reversed())
        if reversedDays.first?.isActive == false {
            reversedDays.removeFirst()
        }
        for day in reversedDays {
            if day.isActive {
                current += 1
            } else {
                break
            }
        }

        return (current, best)
    }
}
