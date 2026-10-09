//
//  PlanStressLoader.swift
//  CortiFree
//
//  Felt stress (1…5) of the daily check-ins taken during a plan cycle, per plan day, for the
//  cycle review: the before / after comes from what the user already logs every day.
//

import Foundation

@MainActor
enum PlanStressLoader {
    private struct Row: Decodable {
        let date: String
        let stress: Double
    }

    /// Stress per plan day (1...28). Empty when signed out or offline.
    static func stress(for plan: PersonalPlan) async -> [Int: Int] {
        guard Auth.auth().currentUser != nil else { return [:] }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: plan.startDate)
        guard let end = calendar.date(byAdding: .day, value: PersonalPlan.length - 1, to: start) else { return [:] }
        let rows: [Row] = (try? await ConvexBackend.shared.call(.query, path: "checkins:listCheckins", args: [
            "fromDate": dayKey(start), "toDate": dayKey(end), "limit": PersonalPlan.length,
        ])) ?? []
        var result: [Int: Int] = [:]
        for row in rows {
            guard let date = dayFormatter.date(from: row.date),
                  let offset = calendar.dateComponents([.day], from: start, to: date).day,
                  (0..<PersonalPlan.length).contains(offset) else { continue }
            result[offset + 1] = Int(row.stress.rounded())
        }
        return result
    }

    private static func dayKey(_ date: Date) -> String { dayFormatter.string(from: date) }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
