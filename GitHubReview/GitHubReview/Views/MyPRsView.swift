import SwiftUI

struct MyPRsView: View {
    @EnvironmentObject var prVM: PRViewModel
    @State private var expandedRepos: Set<String> = []

    var body: some View {
        Group {
            if prVM.myPRGroups.isEmpty && !prVM.isLoading {
                ContentUnavailableView(
                    "No Open PRs",
                    systemImage: "checkmark.circle",
                    description: Text("You don't have any open pull requests.")
                )
            } else {
                List {
                    ForEach(prVM.myPRGroups) { group in
                        RepoSectionView(
                            group: group,
                            badgeColor: .blue,
                            isExpanded: binding(for: group.id),
                            onArchive: { prVM.archiveRepo(group.repoName) }
                        )
                    }
                }
                .listStyle(.plain)
                .onAppear { expandAll() }
                .onChange(of: prVM.myPRGroups) { _, groups in
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
        for group in prVM.myPRGroups {
            expandedRepos.insert(group.id)
        }
    }
}
