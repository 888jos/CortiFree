import Foundation

/// Transitional value used by older local models. Convex stores timestamps as epoch milliseconds.
struct Timestamp: Codable, Hashable {
    private let milliseconds: Double

    init(date: Date = Date()) { milliseconds = date.timeIntervalSince1970 * 1000 }
    init() { self.init(date: Date()) }
    func dateValue() -> Date { Date(timeIntervalSince1970: milliseconds / 1000) }
}

@propertyWrapper
struct DocumentID: Codable, Hashable {
    var wrappedValue: String?

    init() { wrappedValue = nil }
    init(wrappedValue: String?) { self.wrappedValue = wrappedValue }
}

/// Read-only bridge for legacy model conversion helpers during the Convex cutover.
struct DocumentSnapshot {
    let documentID: String
    private let fields: [String: Any]

    init(documentID: String = "", fields: [String: Any] = [:]) {
        self.documentID = documentID
        self.fields = fields
    }

    var exists: Bool { !fields.isEmpty }
    func data() -> [String: Any] { fields }
}

typealias QueryDocumentSnapshot = DocumentSnapshot
