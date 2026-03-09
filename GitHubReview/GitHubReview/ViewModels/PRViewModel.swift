import Foundation
import SwiftUI

struct PRGroup: Identifiable {
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

    private var service: GitHubService?
    private var username: String?
    private var pollTask: Task<Void, Never>?

    var myPRCount: Int { myPRs.count }
    var reviewRequestCount: Int { reviewRequests.count }

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

    private func fetchAll() async {
        guard let service, let username else { return }

        isLoading = true
        error = nil

        do {
            async let myPRsResult = service.fetchMyPRs(username: username)
            async let reviewResult = service.fetchReviewRequests(username: username)

            let (myPRs, reviews) = try await (myPRsResult, reviewResult)

            self.myPRs = myPRs
            self.reviewRequests = reviews
            self.myPRGroups = groupByRepo(myPRs)
            self.reviewGroups = groupByRepo(reviews)
            self.lastUpdated = Date()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func groupByRepo(_ prs: [PullRequest]) -> [PRGroup] {
        let grouped = Dictionary(grouping: prs) { $0.repoFullName }
        return grouped.map { PRGroup(id: $0.key, repoName: $0.key, prs: $0.value) }
            .sorted { $0.repoName < $1.repoName }
    }
}
