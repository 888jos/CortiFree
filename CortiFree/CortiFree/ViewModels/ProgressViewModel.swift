import Foundation
import FirebaseAuth

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published private(set) var data: ProgressDashboardData = .empty
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?

    private let service: ProgressAnalyticsService
    private let cacheKeyPrefix = "progressDashboardCacheV2"
    private var didLoad = false

    init(service: ProgressAnalyticsService = .shared) {
        self.service = service
        loadCache()
    }

    var visibleDays: [ProgressDay] {
        data.days
    }

    var activeDays: Int {
        data.days.filter(\.isActive).count
    }

    var averageMood: Double? {
        let scores = visibleDays.compactMap(\.moodScore)
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    var completedSessions: Int {
        visibleDays.reduce(0) { $0 + $1.completionCount }
    }

    func loadIfNeeded() async {
        guard !didLoad else { return }
        didLoad = true
        await refresh()
    }

    func refresh() async {
        let userID = Auth.auth().currentUser?.uid ?? UserPersistence.localUserID

        if data.days.isEmpty { isLoading = true }
        errorMessage = nil

        do {
            data = try await service.fetchDashboard(userID: userID)
            saveCache()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadCache() {
        guard let cached = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode(ProgressDashboardData.self, from: cached) else { return }
        data = decoded
        isLoading = false
    }

    private func saveCache() {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        UserDefaults.standard.set(encoded, forKey: cacheKey)
    }

    private var cacheKey: String {
        "\(cacheKeyPrefix).lifetime"
    }
}
