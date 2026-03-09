import SwiftUI

struct ReviewRequestsView: View {
    @EnvironmentObject var prVM: PRViewModel

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
                        Section {
                            ForEach(group.prs) { pr in
                                PRRowView(pr: pr)
                            }
                        } header: {
                            HStack {
                                Image(systemName: "folder")
                                    .font(.caption2)
                                Text(group.repoName)
                                    .font(.caption.bold())
                                Spacer()
                                Text("\(group.prs.count)")
                                    .font(.caption2.monospaced())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(.orange.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }
}
