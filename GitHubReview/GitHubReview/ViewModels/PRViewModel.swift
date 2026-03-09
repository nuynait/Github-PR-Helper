import Foundation
import SwiftUI

struct PRGroup: Identifiable, Equatable {
    let id: String // repo full name
    let repoName: String
    let prs: [PullRequest]
}

@MainActor
class PRViewModel: ObservableObject {
    @Published var myPRs: [PullRequest] = []
    @Published var reviewRequests: [PullRequest] = []
    @Published var myPRGroups: [PRGroup] = []
    @Published var reviewGroups: [PRGroup] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastUpdated: Date?
    @Published var archivedRepos: Set<String> {
        didSet { saveArchivedRepos() }
    }

    private var allMyPRs: [PullRequest] = []
    private var allReviewRequests: [PullRequest] = []
    private var service: GitHubService?
    private var username: String?
    private var pollTask: Task<Void, Never>?
    private var knownMyPRIds: Set<Int> = []
    private var knownReviewIds: Set<Int> = []
    private var hasLoadedOnce = false

    private static let archivedReposKey = "archivedRepos"

    var myPRCount: Int { myPRs.count }
    var reviewRequestCount: Int { reviewRequests.count }

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: Self.archivedReposKey) ?? []
        self.archivedRepos = Set(saved)
    }

    func configure(token: String, username: String) {
        self.service = GitHubService(token: token)
        self.username = username
        startPolling()
    }

    func refresh() {
        Task { await fetchAll() }
    }

    func startPolling() {
        pollTask?.cancel()
        pollTask = Task {
            await fetchAll()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Constants.pollInterval))
                if Task.isCancelled { break }
                await fetchAll()
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
    }

    func archiveRepo(_ repoName: String) {
        archivedRepos.insert(repoName)
        applyFilters()
    }

    func unarchiveRepo(_ repoName: String) {
        archivedRepos.remove(repoName)
        applyFilters()
    }

    private func fetchAll() async {
        guard let service, let username else { return }

        isLoading = true
        error = nil

        do {
            async let myPRsResult = service.fetchMyPRs(username: username)
            async let reviewResult = service.fetchReviewRequests(username: username)

            let (myPRs, reviews) = try await (myPRsResult, reviewResult)

            if hasLoadedOnce {
                let newMyPRIds = Set(myPRs.map(\.id)).subtracting(knownMyPRIds)
                let newReviewIds = Set(reviews.map(\.id)).subtracting(knownReviewIds)

                let newMyPRs = myPRs.filter { newMyPRIds.contains($0.id) && !archivedRepos.contains($0.repoFullName) }
                let newReviews = reviews.filter { newReviewIds.contains($0.id) && !archivedRepos.contains($0.repoFullName) }

                NotificationService.sendNewPRNotification(prs: newMyPRs, isReviewRequest: false)
                NotificationService.sendNewPRNotification(prs: newReviews, isReviewRequest: true)
            }

            knownMyPRIds = Set(myPRs.map(\.id))
            knownReviewIds = Set(reviews.map(\.id))
            hasLoadedOnce = true

            self.allMyPRs = myPRs
            self.allReviewRequests = reviews
            applyFilters()
            self.lastUpdated = Date()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func applyFilters() {
        let filteredMyPRs = allMyPRs.filter { !archivedRepos.contains($0.repoFullName) }
        let filteredReviews = allReviewRequests.filter { !archivedRepos.contains($0.repoFullName) }

        self.myPRs = filteredMyPRs
        self.reviewRequests = filteredReviews
        self.myPRGroups = groupByRepo(filteredMyPRs)
        self.reviewGroups = groupByRepo(filteredReviews)
    }

    private func groupByRepo(_ prs: [PullRequest]) -> [PRGroup] {
        let grouped = Dictionary(grouping: prs) { $0.repoFullName }
        return grouped.map { PRGroup(id: $0.key, repoName: $0.key, prs: $0.value) }
            .sorted { $0.repoName < $1.repoName }
    }

    private func saveArchivedRepos() {
        UserDefaults.standard.set(Array(archivedRepos), forKey: Self.archivedReposKey)
    }
}
