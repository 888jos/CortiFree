import Foundation

/// Transitional name kept to avoid a risky UI-wide rename during the backend cutover.
@MainActor
final class UnifiedFirebaseService {
    static let shared = UnifiedFirebaseService()
    let auth = AuthModule()
    private init() {}

    var currentUserId: String? { auth.currentUserId }
    var isAuthenticated: Bool { auth.isAuthenticated }
    var currentUser: ConvexUser? { auth.currentUser }
}
