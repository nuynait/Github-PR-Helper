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
    @Published var repoOrder: [String] {
        didSet {
            saveRepoOrder()
            applyFilters()
        }
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
    private static let repoOrderKey = "repoOrder"

    var myPRCount: Int { myPRs.count }
    var reviewRequestCount: Int { reviewRequests.count }

    /// All visible (non-archived) repos seen across both tabs, in user-defined order.
    var orderedVisibleRepos: [String] {
        let allRepoNames = Set(allMyPRs.map(\.repoFullName) + allReviewRequests.map(\.repoFullName))
        let visible = allRepoNames.subtracting(archivedRepos)
        // Return repos in the saved order, appending any new ones at the bottom
        var result = repoOrder.filter { visible.contains($0) }
        let unsorted = visible.subtracting(Set(result)).sorted()
        result.append(contentsOf: unsorted)
        return result
    }

    init() {
        let savedArchived = UserDefaults.standard.stringArray(forKey: Self.archivedReposKey) ?? []
        self.archivedRepos = Set(savedArchived)
        self.repoOrder = UserDefaults.standard.stringArray(forKey: Self.repoOrderKey) ?? []
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
        // Append to order if not already tracked
        if !repoOrder.contains(repoName) {
            repoOrder.append(repoName)
        }
        applyFilters()
    }

    func moveRepos(from source: IndexSet, to destination: Int) {
        var ordered = orderedVisibleRepos
        ordered.move(fromOffsets: source, toOffset: destination)
        repoOrder = ordered
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

            // Add any new repos to the order list
            let allRepoNames = Set(myPRs.map(\.repoFullName) + reviews.map(\.repoFullName))
            let newRepos = allRepoNames.subtracting(Set(repoOrder)).subtracting(archivedRepos).sorted()
            if !newRepos.isEmpty {
                repoOrder.append(contentsOf: newRepos)
            }

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
        let groups = grouped.map { PRGroup(id: $0.key, repoName: $0.key, prs: $0.value) }

        // Sort by user-defined order; unknown repos go to the end alphabetically
        return groups.sorted { a, b in
            let indexA = repoOrder.firstIndex(of: a.repoName)
            let indexB = repoOrder.firstIndex(of: b.repoName)
            switch (indexA, indexB) {
            case let (ia?, ib?): return ia < ib
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return a.repoName < b.repoName
            }
        }
    }

    private func saveArchivedRepos() {
        UserDefaults.standard.set(Array(archivedRepos), forKey: Self.archivedReposKey)
    }

    private func saveRepoOrder() {
        UserDefaults.standard.set(repoOrder, forKey: Self.repoOrderKey)
    }
}
