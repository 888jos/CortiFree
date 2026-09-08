import Foundation

struct DailyCheckInRecord: Codable, Identifiable {
    var id: String
    let date: Date
    let mood: Mood
    let stress: Int
    let sleep: Int
    let energy: Int
    let note: String
    let createdAt: Date
}
