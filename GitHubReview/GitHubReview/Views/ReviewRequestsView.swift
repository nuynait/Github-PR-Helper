import SwiftUI

struct ReviewRequestsView: View {
    @EnvironmentObject var prVM: PRViewModel
    @State private var expandedRepos: Set<String> = []

    var body: some View {
        Group {
            if prVM.reviewGroups.isEmpty && !prVM.isLoading {
                ContentUnavailableView(
                    "No Review Requests",
                    systemImage: "eye",
                    description: Text("No one has requested your review.")
                )
            } else {
                List {
                    ForEach(prVM.reviewGroups) { group in
                        RepoSectionView(
                            group: group,
                            badgeColor: .orange,
                            isExpanded: binding(for: group.id),
                            onArchive: { prVM.archiveRepo(group.repoName) }
                        )
                    }
                }
                .listStyle(.plain)
                .onAppear { expandAll() }
                .onChange(of: prVM.reviewGroups) { _, groups in
                    for group in groups where !expandedRepos.contains(group.id) {
                        expandedRepos.insert(group.id)
                    }
                }
            }
        }
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { expandedRepos.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    expandedRepos.insert(id)
                } else {
                    expandedRepos.remove(id)
                }
            }
        )
    }

    private func expandAll() {
        for group in prVM.reviewGroups {
            expandedRepos.insert(group.id)
        }
    }
}
